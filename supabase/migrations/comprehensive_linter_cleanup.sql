-- ──────────────────────────────────────────────────────────
-- COMPREHENSIVE LINTER CLEANUP & SECURITY HARDENING (v3)
-- ──────────────────────────────────────────────────────────

-- 1. FIX MUTABLE SEARCH PATHS WITHOUT DROPPING (Avoids dependency errors)
-- Using ALTER FUNCTION is safer because it doesn't require dropping the function
-- or its dependent triggers.

ALTER FUNCTION public.generate_member_id() SET search_path = public;
ALTER FUNCTION public.update_updated_at() SET search_path = public;
ALTER FUNCTION public.calculate_ipi_score() SET search_path = public;
ALTER FUNCTION public.handle_new_user() SET search_path = public;
ALTER FUNCTION public.get_admin_scope() SET search_path = public;

-- 2. RESTRICT EXECUTION OF SECURITY DEFINER FUNCTIONS
-- Revoke PUBLIC execute and only allow it for internal/authenticated use.

REVOKE EXECUTE ON FUNCTION public.get_admin_scope() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_admin_scope() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;

-- 3. STORAGE BUCKET SECURITY
-- Fixes broad SELECT on 'mkmu-picha'.
DROP POLICY IF EXISTS "Allow public reads" ON storage.objects;
CREATE POLICY "Allow public reads" ON storage.objects FOR SELECT USING (bucket_id = 'mkmu-picha');

-- 4. FINAL PERMISSION SYNC
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT USAGE ON SCHEMA auth TO anon, authenticated;

-- 5. RELOAD POSTGREST
NOTIFY pgrst, 'reload schema';
