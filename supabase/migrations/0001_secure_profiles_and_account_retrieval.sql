-- ============================================================
-- PamojaMove — security migration
--
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor).
-- It fixes two problems:
--
--   1. The `anon` key can currently read every row of `profiles`,
--      exposing all users' emails and phone numbers to anyone who
--      has the key (it ships inside the app, so: anyone).
--
--   2. Account retrieval compared the user's secret answer in the
--      Flutter client, which required the client to read the answer
--      first. The answer is verified here instead, and the caller
--      never receives the answer or the full email address.
-- ============================================================


-- ------------------------------------------------------------
-- 1. Lock down `profiles`
-- ------------------------------------------------------------
alter table public.profiles enable row level security;

-- Drop any permissive policies that allow blanket reads.
drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
drop policy if exists "Enable read access for all users"        on public.profiles;
drop policy if exists "profiles_select_own"                     on public.profiles;
drop policy if exists "profiles_update_own"                     on public.profiles;

-- A signed-in user may read and update only their own row.
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Note: no policy is granted to `anon`, so unauthenticated callers
-- now read zero rows instead of all of them.


-- ------------------------------------------------------------
-- 2. Server-side account retrieval
-- ------------------------------------------------------------
-- Verifies full name + phone + secret answer, and on success returns
-- a MASKED email (e.g. "mw*******a@gmail.com") so the user can
-- recognise their own account without the address being harvestable.
--
-- Returns NULL on any failure. The Flutter client shows the same
-- message either way, so this cannot be used to test whether a given
-- name/phone pair is registered.
--
-- The secret answer is stored in auth.users.raw_user_meta_data by
-- AuthService.signUp(). Comparison is trimmed + case-insensitive.
-- ------------------------------------------------------------
create or replace function public.retrieve_account(
  p_full_name text,
  p_phone     text,
  p_answer    text
)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_email  text;
  v_answer text;
  v_local  text;
  v_domain text;
begin
  if coalesce(trim(p_full_name), '') = ''
     or coalesce(trim(p_phone), '')  = ''
     or coalesce(trim(p_answer), '') = '' then
    return null;
  end if;

  select u.email,
         u.raw_user_meta_data ->> 'secret_answer'
    into v_email, v_answer
    from public.profiles p
    join auth.users u on u.id = p.id
   where lower(trim(p.full_name))    = lower(trim(p_full_name))
     and regexp_replace(p.phone_number, '\D', '', 'g')
       = regexp_replace(p_phone,        '\D', '', 'g')
   limit 1;

  if v_email is null or coalesce(v_answer, '') = '' then
    return null;
  end if;

  if lower(trim(v_answer)) <> lower(trim(p_answer)) then
    return null;
  end if;

  -- Mask the local part: keep first 2 and last 1 characters.
  v_local  := split_part(v_email, '@', 1);
  v_domain := split_part(v_email, '@', 2);

  if length(v_local) <= 3 then
    return repeat('*', length(v_local)) || '@' || v_domain;
  end if;

  return left(v_local, 2)
      || repeat('*', length(v_local) - 3)
      || right(v_local, 1)
      || '@' || v_domain;
end;
$$;

revoke all on function public.retrieve_account(text, text, text) from public;
grant execute on function public.retrieve_account(text, text, text) to anon, authenticated;
