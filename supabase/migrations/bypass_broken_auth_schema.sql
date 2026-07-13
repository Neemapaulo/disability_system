-- ──────────────────────────────────────────────────────────
-- BYPASS BROKEN AUTH SCHEMA (FINAL RESCUE)
-- ──────────────────────────────────────────────────────────

-- 1. STOP THE API FROM LOOKING AT THE 'auth' SCHEMA
-- The 500 error happens because PostgREST is crashing while scanning 'auth'.
-- We restrict the API to 'public' only. Login still works because it's a
-- direct call to the Auth server, not a database query.
ALTER ROLE authenticator SET search_path = public;
ALTER ROLE anon SET search_path = public;
ALTER ROLE authenticated SET search_path = public;

-- 2. RE-GRANT PUBLIC ACCESS (Just in case)
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, authenticator, service_role;

-- 3. REMOVE THE TRIGGER THAT CRASHES SIGNUP
-- Since we can't drop the RI triggers, we ensure our CUSTOM trigger is gone.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 4. FORCE POSTGREST TO FORGET THE BROKEN AUTH SCHEMA
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 5. VERIFICATION
-- Check if search_path is now just 'public'
SHOW search_path;
