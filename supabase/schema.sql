-- ============================================================
-- PamojaMove — complete database schema
--
-- Run this ONCE, in full, on a BRAND NEW Supabase project.
-- Dashboard → SQL Editor → New query → paste all of this → Run.
--
-- It creates everything the app needs: tables, permissions, the photo
-- bucket, live updates, and the account-recovery function. You do not
-- need to run 0001 or 0002 as well — they are already included here.
--
-- Reconstructed from the app code and the original database.
-- ============================================================


-- ============================================================
-- 1. PROFILES — one row per registered user
-- ============================================================
create table if not exists public.profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  email          text not null,
  full_name      text,
  phone_number   text,
  role           text not null default 'citizen',   -- 'citizen' | 'admin'
  mkoa           text default 'Dar es Salaam',
  wilaya         text,
  -- For admin/council accounts: which area this admin oversees.
  -- Left null for ordinary citizens.
  managed_mkoa   text,
  managed_wilaya text,
  managed_kata   text,
  image          text,
  created_at     timestamptz not null default now()
);

-- NOTE: the user's secret question/answer are deliberately NOT stored here.
-- They live in auth.users.raw_user_meta_data, which the app cannot read,
-- and are only ever checked inside retrieve_account() below.


-- When someone signs up, copy their details from the signup form into
-- profiles automatically.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, phone_number, mkoa, wilaya, role)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'phone_number',
    coalesce(new.raw_user_meta_data ->> 'mkoa', 'Dar es Salaam'),
    new.raw_user_meta_data ->> 'wilaya',
    coalesce(new.raw_user_meta_data ->> 'role', 'citizen')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ============================================================
-- 2. RIPOTI — the accessibility reports
-- ============================================================
create table if not exists public.ripoti (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,

  aina            text not null,   -- njia_kutopitika | kituo_hakina_rampu |
                                   -- makutano_yasio_salama | ukosefu_miongozo | nyingine
  maelezo         text not null,

  latitude        double precision not null,
  longitude       double precision not null,
  eneo_jina       text,            -- human-readable place name
  mkoa            text,
  wilaya          text,
  kata            text,

  picha_url       text,

  hali            text not null default 'mpya',
                  -- mpya | inaangaliwa | imepewa_mamlaka | inashughulikiwa | imekamilika
  maoni_ya_admin  text,

  -- Infrastructure Priority Index. The app reads these to colour map pins.
  -- In the original database only one report had a non-zero score, set by
  -- hand — there was no automatic formula. Defaults mirror that: 0 until an
  -- admin sets it. See the commented-out trigger at the bottom if you later
  -- want scores computed automatically.
  frequency_count  integer       not null default 1,
  severity_weight  numeric(4,2)  not null default 1.0,
  priority_score   numeric(6,2)  not null default 0.0,

  created_at       timestamptz not null default now(),
  admin_updated_at timestamptz
);

create index if not exists ripoti_user_id_idx    on public.ripoti (user_id);
create index if not exists ripoti_created_at_idx on public.ripoti (created_at desc);
create index if not exists ripoti_wilaya_idx     on public.ripoti (wilaya);


-- ============================================================
-- 3. MATANGAZO — announcements shown on the dashboard
-- ============================================================
create table if not exists public.matangazo (
  id         uuid primary key default gen_random_uuid(),
  kichwa     text not null,          -- headline
  maudhui    text not null,          -- body
  wilaya     text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);


-- ============================================================
-- 4. PERMISSIONS (Row Level Security)
--
-- With RLS on, anything not explicitly allowed is denied. This is what
-- was misconfigured in the original project: reports could be read but
-- never inserted, and every profile was readable by anyone.
-- ============================================================

-- ── profiles: a user sees and edits only their own row ──────
alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ── ripoti: everyone can read (the gap map is public),
--    signed-in users file reports only in their own name ────
alter table public.ripoti enable row level security;

drop policy if exists "ripoti_select_all" on public.ripoti;
create policy "ripoti_select_all"
  on public.ripoti for select
  to anon, authenticated
  using (true);

drop policy if exists "ripoti_insert_own" on public.ripoti;
create policy "ripoti_insert_own"
  on public.ripoti for insert
  to authenticated
  with check (auth.uid() = user_id);

-- ── matangazo: readable by all, written only by admins ──────
alter table public.matangazo enable row level security;

drop policy if exists "matangazo_select_all" on public.matangazo;
create policy "matangazo_select_all"
  on public.matangazo for select
  to anon, authenticated
  using (true);


-- ============================================================
-- 5. PHOTO STORAGE — bucket "mkmu-picha"
-- ============================================================
insert into storage.buckets (id, name, public)
values ('mkmu-picha', 'mkmu-picha', true)
on conflict (id) do update set public = true;

-- Anyone can view report photos (they appear on the public map).
drop policy if exists "picha_public_read" on storage.objects;
create policy "picha_public_read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'mkmu-picha');

-- A signed-in user may upload only into their own folder. The app saves
-- photos as "<user-id>/<timestamp>.jpg", so the first path segment must
-- match their own id.
drop policy if exists "picha_insert_own" on storage.objects;
create policy "picha_insert_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'mkmu-picha'
    and (storage.foldername(name))[1] = auth.uid()::text
  );


-- ============================================================
-- 6. LIVE UPDATES
-- The report timeline screen watches a report's status in real time.
-- ============================================================
alter publication supabase_realtime add table public.ripoti;


-- ============================================================
-- 7. ACCOUNT RECOVERY
--
-- Checks full name + phone + secret answer entirely inside the database,
-- so the app never reads the answer. On success it returns a MASKED email
-- ("mw*****a@gmail.com") — enough for the user to recognise their account,
-- useless for harvesting addresses. Returns null on any failure, and the
-- app shows the same message either way, so it cannot be used to probe
-- which accounts exist.
-- ============================================================
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
   where lower(trim(p.full_name)) = lower(trim(p_full_name))
     and regexp_replace(p.phone_number, '\D', '', 'g')
       = regexp_replace(p_phone,        '\D', '', 'g')
   limit 1;

  if v_email is null or coalesce(v_answer, '') = '' then
    return null;
  end if;

  if lower(trim(v_answer)) <> lower(trim(p_answer)) then
    return null;
  end if;

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


-- ============================================================
-- 8. OPTIONAL — automatic priority scoring
--
-- The original database had no working formula, so this is left OFF.
-- If you later want scores computed automatically, uncomment this and
-- adjust the formula to whatever your council agrees on.
-- ============================================================
-- create or replace function public.calculate_priority()
-- returns trigger language plpgsql as $$
-- begin
--   new.priority_score := round(
--     (new.severity_weight * ln(1 + new.frequency_count))::numeric, 2
--   );
--   return new;
-- end;
-- $$;
--
-- drop trigger if exists ripoti_priority on public.ripoti;
-- create trigger ripoti_priority
--   before insert or update of frequency_count, severity_weight
--   on public.ripoti
--   for each row execute function public.calculate_priority();
