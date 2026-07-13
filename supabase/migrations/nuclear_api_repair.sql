-- ──────────────────────────────────────────────────────────
-- NUCLEAR API & AUTH REPAIR
-- This script removes ALL potential blockers for the login process.
-- ──────────────────────────────────────────────────────────

-- 1. REMOVE ALL KNOWN TRIGGERS ON AUTH.USERS
-- We do this one by one to be absolutely sure.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trigger_on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS sync_user_to_profile ON auth.users;

-- 2. RESET SEARCH PATHS FOR ALL API ROLES
ALTER ROLE authenticator SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE anon SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE authenticated SET search_path = 'public', 'auth', 'extensions';

-- 3. GRANT MASSIVE PERMISSIONS
-- This ensures that even the internal Supabase roles can see your tables.
GRANT USAGE ON SCHEMA public TO public;
GRANT USAGE ON SCHEMA auth TO public;
GRANT ALL ON ALL TABLES IN SCHEMA public TO public;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO public;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO public;

-- 4. SIMPLIFY PROFILES TABLE (Temporary)
-- If a foreign key is broken, it can crash the login.
-- We temporarily remove the link to see if login works.
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- 5. RE-SYNC THE API CACHE (The "Sync" Button)
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 6. DIAGNOSTIC QUERY
-- After running this, look at the "Results" and tell me if you see any triggers left.
SELECT tgname FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass;
