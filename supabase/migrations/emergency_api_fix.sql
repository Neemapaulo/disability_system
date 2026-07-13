-- ──────────────────────────────────────────────────────────
-- EMERGENCY API & SCHEMA REPAIR SCRIPT
-- ──────────────────────────────────────────────────────────

-- 1. FIX SEARCH PATHS (Critical for PostgREST to find tables)
ALTER ROLE authenticator SET search_path = 'public', 'auth';
ALTER ROLE anon SET search_path = 'public', 'auth';
ALTER ROLE authenticated SET search_path = 'public', 'auth';

-- 2. RE-GRANT SCHEMA PERMISSIONS
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;

-- 3. ENSURE PROFILES TABLE IS ACCESSIBLE
-- Grant permissions to ALL roles involved in the API
GRANT ALL ON public.profiles TO anon, authenticated, authenticator, service_role;

-- 4. FIX RLS (Ensure admins can always be read during login)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow system read for login" ON public.profiles;
CREATE POLICY "Allow system read for login" ON public.profiles
FOR SELECT USING (true);

-- 5. SYNC MISSING PROFILES
-- If a user exists in auth but not in profiles, login might fail if the app expects a profile.
INSERT INTO public.profiles (id, email, role)
SELECT id, email, 'citizen' FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 6. ENSURE ADMIN EMAILS HAVE ADMIN ROLE
UPDATE public.profiles SET role = 'admin' WHERE email IN (
    'mkmudaradmi@mkmu.com',
    'mkmuilalaadmin@mkmu.com',
    'mkmuadminkigamboni@mkmu.com',
    'mkmuadminubungo@mkmu.com',
    'mkmuadminkinondoni@mkmu.com',
    'mkmuadmintemeke@mkmu.com'
);

-- 7. FORCE POSTGREST TO RELOAD EVERYTHING
-- This is the most important part for "Schema out of sync"
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 8. VERIFICATION QUERY (Run this to see if things look right)
-- SELECT rolname, rolconfig FROM pg_roles WHERE rolname IN ('authenticator', 'anon', 'authenticated');
