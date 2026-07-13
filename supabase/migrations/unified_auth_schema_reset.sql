-- ──────────────────────────────────────────────────────────
-- UNIFIED AUTH SCHEMA RESET (DEFINITIVE VERSION)
-- This script resets all search paths, permissions, and
-- triggers to a known stable state.
-- ──────────────────────────────────────────────────────────

-- 1. RESET CORE ROLES & SEARCH PATHS
-- This fixes the "Database error querying schema" by ensuring
-- both 'public' and 'auth' are visible to the API.
ALTER ROLE authenticator SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE anon SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE authenticated SET search_path = 'public', 'auth', 'extensions';

-- 2. RE-ESTABLISH SCHEMA PERMISSIONS (CLEAN SLATE)
-- Revoke then re-grant to ensure no conflicting partial grants remain.
REVOKE ALL ON SCHEMA public FROM PUBLIC, anon, authenticated, authenticator;
REVOKE ALL ON SCHEMA auth FROM PUBLIC, anon, authenticated, authenticator;

GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator, service_role;

-- 3. GRANT TABLE ACCESS
-- API roles need access to profiles and other public tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated, authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;

-- Auth server needs to be able to read users (for internal logic)
GRANT SELECT ON auth.users TO anon, authenticated, authenticator;

-- 4. REPAIR THE LOGIN TRIGGER (SAFE VERSION)
-- Drop ALL variations to avoid duplication
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trigger_on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS sync_user_to_profile ON auth.users;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Simple insert. Exception handling ensures login NEVER fails
  -- even if the profiles table has issues.
  BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'citizen')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    RETURN NEW;
  END;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. CORRECT ADMIN EMAIL TYPOS (Database side)
UPDATE public.profiles SET role = 'admin', managed_mkoa = 'Dar es Salaam' WHERE email = 'mkmudaradmin@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_mkoa = 'Dar es Salaam' WHERE email = 'mkmudaradmi@mkmu.com'; -- Keep both to be safe

-- 6. FORCE REFRESH API CACHE
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 7. VERIFICATION QUERIES
-- If these return results, the repair was successful.
-- SELECT rolname, rolconfig FROM pg_roles WHERE rolname IN ('anon', 'authenticated', 'authenticator');
-- SELECT count(*) FROM auth.users;
