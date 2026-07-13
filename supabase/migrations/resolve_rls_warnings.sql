-- ──────────────────────────────────────────────────────────
-- RESOLVE RLS POLICY WARNINGS
-- ──────────────────────────────────────────────────────────

-- 1. admin_audit_logs (Strictly for admins/service_role)
DROP POLICY IF EXISTS "Admins can view audit logs" ON public.admin_audit_logs;
CREATE POLICY "Admins can view audit logs"
ON public.admin_audit_logs FOR SELECT
TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- 2. admin_profiles (Restrictive access)
DROP POLICY IF EXISTS "Admins can view admin profiles" ON public.admin_profiles;
CREATE POLICY "Admins can view admin profiles"
ON public.admin_profiles FOR SELECT
TO authenticated
USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- 3. mtaa_kata (Public reference data)
DROP POLICY IF EXISTS "Mtaa Kata is publicly readable" ON public.mtaa_kata;
CREATE POLICY "Mtaa Kata is publicly readable"
ON public.mtaa_kata FOR SELECT
USING (true);

-- 4. ENSURE ALL TABLES HAVE RLS (Double check)
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mtaa_kata ENABLE ROW LEVEL SECURITY;

-- 5. REFRESH
NOTIFY pgrst, 'reload schema';
