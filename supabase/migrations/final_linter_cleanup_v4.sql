-- ──────────────────────────────────────────────────────────
-- FINAL LINTER CLEANUP & SECURITY HARDENING (v4)
-- ──────────────────────────────────────────────────────────

-- 1. FIX get_admin_scope (Change to SECURITY INVOKER)
-- By making it INVOKER, it uses the caller's permissions, which is safer
-- and removes the linter warning for SECURITY DEFINER.
DROP FUNCTION IF EXISTS public.get_admin_scope();
CREATE OR REPLACE FUNCTION public.get_admin_scope()
RETURNS TABLE (mkoa TEXT, wilaya TEXT)
LANGUAGE plpgsql
SECURITY INVOKER -- Safer than DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY SELECT p.managed_mkoa, p.managed_wilaya
               FROM profiles p WHERE p.id = auth.uid();
END;
$$;

-- 2. FULLY REVOKE API ACCESS FOR TRIGGER FUNCTIONS
-- handle_new_user should NEVER be called via the API (REST).
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

-- 3. FIX STORAGE BUCKET LISTING WARNING
-- The linter warns that broad SELECT allows listing all files.
-- Public buckets don't need SELECT for public URL access.
-- If your app needs to LIST files, we should restrict it to authenticated users.
DROP POLICY IF EXISTS "Allow public reads" ON storage.objects;

-- If you want anyone to see images via URL, you don't need a SELECT policy.
-- If your ADMIN panel needs to see a list of images, use this:
CREATE POLICY "Admins can list images"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'mkmu-picha');

-- 4. RE-PATCH ALL SEARCH PATHS (Final check)
ALTER FUNCTION public.generate_member_id() SET search_path = public;
ALTER FUNCTION public.update_updated_at() SET search_path = public;
ALTER FUNCTION public.calculate_ipi_score() SET search_path = public;
ALTER FUNCTION public.handle_new_user() SET search_path = public;

-- 5. REFRESH CACHE
NOTIFY pgrst, 'reload schema';
