-- ============================================================
-- PamojaMove — PART 2 of 2: photo storage
--
-- Run this AFTER part 1 succeeds.
--
-- If this script errors with something like
--   "must be owner of table objects"
-- then your project does not allow storage policies to be created from
-- the SQL Editor. That is fine — see the manual fallback at the bottom.
-- Part 1 (the tables) is unaffected either way.
-- ============================================================


-- Create the photo bucket, public so images show on the map.
insert into storage.buckets (id, name, public)
values ('mkmu-picha', 'mkmu-picha', true)
on conflict (id) do update set public = true;


-- Anyone may view report photos.
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
-- MANUAL FALLBACK — only if the policies above errored
--
-- 1. Dashboard → Storage → New bucket
--      Name:   mkmu-picha
--      Public: ON
--      Save.
--
-- 2. Dashboard → Storage → Policies → mkmu-picha → New policy
--
--    Policy A — let anyone view photos:
--      Name:        picha_public_read
--      Operation:   SELECT
--      Target roles: anon, authenticated
--      USING expression:
--          bucket_id = 'mkmu-picha'
--
--    Policy B — let signed-in users upload:
--      Name:        picha_insert_own
--      Operation:   INSERT
--      Target roles: authenticated
--      WITH CHECK expression:
--          bucket_id = 'mkmu-picha'
--          and (storage.foldername(name))[1] = auth.uid()::text
-- ============================================================
