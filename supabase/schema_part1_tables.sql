-- ============================================================
-- PamojaMove — PART 1 of 2: tables, permissions, account recovery
--
-- Run this FIRST, on its own. Dashboard → SQL Editor → New query →
-- paste → Run. Expect: "Success. No rows returned."
--
-- Part 2 (storage) is separate because it can fail on some projects,
-- and if it were in the same script that failure would roll back these
-- tables too.
-- ============================================================


-- ── PROFILES ────────────────────────────────────────────────
create table if not exists public.profiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  email          text not null,
  full_name      text,
  phone_number   text,
  role           text not null default 'citizen',
  mkoa           text default 'Dar es Salaam',
  wilaya         text,
  managed_mkoa   text,
  managed_wilaya text,
  managed_kata   text,
  image          text,
  created_at     timestamptz not null default now()
);

-- Secret question/answer are deliberately NOT stored here. They live in
-- auth.users.raw_user_meta_data and are only read inside retrieve_account().

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


-- ── RIPOTI (reports) ────────────────────────────────────────
create table if not exists public.ripoti (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references auth.users(id) on delete cascade,

  aina            text not null,
  maelezo         text not null,

  latitude        double precision not null,
  longitude       double precision not null,
  eneo_jina       text,
  mkoa            text,
  wilaya          text,
  kata            text,

  picha_url       text,

  hali            text not null default 'mpya',
  maoni_ya_admin  text,

  frequency_count  integer      not null default 1,
  severity_weight  numeric(4,2) not null default 1.0,
  priority_score   numeric(6,2) not null default 0.0,

  created_at       timestamptz not null default now(),
  admin_updated_at timestamptz
);

create index if not exists ripoti_user_id_idx    on public.ripoti (user_id);
create index if not exists ripoti_created_at_idx on public.ripoti (created_at desc);
create index if not exists ripoti_wilaya_idx     on public.ripoti (wilaya);


-- ── MATANGAZO (announcements) ───────────────────────────────
create table if not exists public.matangazo (
  id         uuid primary key default gen_random_uuid(),
  kichwa     text not null,
  maudhui    text not null,
  wilaya     text,
  is_active  boolean not null default true,
  created_at timestamptz not null default now()
);


-- ── PERMISSIONS (row level security) ────────────────────────
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

alter table public.matangazo enable row level security;

drop policy if exists "matangazo_select_all" on public.matangazo;
create policy "matangazo_select_all"
  on public.matangazo for select
  to anon, authenticated
  using (true);


-- ── ACCOUNT RECOVERY ────────────────────────────────────────
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


-- ── LIVE UPDATES (report timeline screen) ───────────────────
-- Wrapped so that "already a member" is not treated as an error.
do $$
begin
  alter publication supabase_realtime add table public.ripoti;
exception
  when duplicate_object then null;
  when others then null;
end;
$$;
