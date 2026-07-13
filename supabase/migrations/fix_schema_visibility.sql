-- ──────────────────────────────────────────────────────────
-- DEFINITIVE SCHEMA VISIBILITY & SEARCH PATH FIX
-- ──────────────────────────────────────────────────────────

-- 1. FIX SEARCH PATHS GLOBALLY FOR API ROLES
-- This ensures 'auth' is always visible when querying 'public'
ALTER ROLE authenticator SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE anon SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE authenticated SET search_path = 'public', 'auth', 'extensions';

-- 2. ENSURE AUTH SCHEMA IS EXPOSED
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;
GRANT SELECT ON auth.users TO anon, authenticated, authenticator;

-- 3. ENSURE PUBLIC SCHEMA IS EXPOSED
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, authenticator, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, authenticator, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, authenticator, service_role;

-- 4. REFRESH POSTGREST CACHE
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 5. VERIFICATION
-- Check if search_path actually changed for the roles
SELECT rolname, rolconfig FROM pg_roles WHERE rolname IN ('authenticator', 'anon', 'authenticated');
