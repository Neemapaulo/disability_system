-- ============================================================
-- PamojaMove — allow citizens to file reports
--
-- Run this in the Supabase SQL editor (Dashboard → SQL Editor).
--
-- Row level security is enabled on `ripoti` and a read policy exists
-- (the gap map is public), but there is no INSERT policy. With RLS on,
-- Postgres denies any action that no policy explicitly allows — so every
-- report submission fails with:
--
--   42501: new row violates row-level security policy for table "ripoti"
--
-- This adds the missing INSERT policy: a signed-in user may create a
-- report, but only one attributed to themselves. They cannot file a
-- report in another user's name.
-- ============================================================

alter table public.ripoti enable row level security;

drop policy if exists "ripoti_insert_own" on public.ripoti;

create policy "ripoti_insert_own"
  on public.ripoti for insert
  to authenticated
  with check (auth.uid() = user_id);
