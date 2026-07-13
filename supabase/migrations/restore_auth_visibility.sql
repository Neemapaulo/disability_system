-- ──────────────────────────────────────────────────────────
-- RESTORE AUTH VISIBILITY
-- ──────────────────────────────────────────────────────────

-- 1. Ensure the 'auth' schema is usable again
GRANT USAGE ON SCHEMA auth TO postgres, anon, authenticated, authenticator, service_role;

-- 2. Restore the link to the users table
GRANT SELECT ON auth.users TO postgres, anon, authenticated, authenticator, service_role;

-- 3. RESET THE SEARCH PATH TO INCLUDE AUTH
-- This is what was removed in the last bypass attempt.
-- We must have this for the login to function correctly.
ALTER ROLE authenticator SET search_path = 'public', 'auth';
ALTER ROLE anon SET search_path = 'public', 'auth';
ALTER ROLE authenticated SET search_path = 'public', 'auth';

-- 4. REFRESH API
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 5. VERIFICATION QUERY (Corrected Syntax)
SELECT email FROM auth.users LIMIT 1;
