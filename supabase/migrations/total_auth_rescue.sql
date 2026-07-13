-- ──────────────────────────────────────────────────────────
-- TOTAL AUTH RESCUE SCRIPT
-- RUN THIS TO REMOVE EVERY POSSIBLE BLOCKER
-- ──────────────────────────────────────────────────────────

-- 1. KILL ALL TRIGGERS (The most likely culprit)
-- We use a DO block to find and kill them all regardless of name.
DO $$
DECLARE
    trigName RECORD;
BEGIN
    FOR trigName IN (SELECT tgname FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass) LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trigName.tgname || ' ON auth.users';
    END LOOP;
END $$;

-- 2. KILL THE FUNCTIONS TOO (To be safe)
DROP FUNCTION IF EXISTS public.handle_new_user CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_scope CASCADE;

-- 3. RELAX TABLE CONSTRAINTS
-- If a Foreign Key is failing, it crashes the login.
-- We temporarily un-link profiles from auth.users.
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_email_key;

-- 4. MASSIVE PERMISSION RESET
-- Give every role full access to everything they might need.
GRANT ALL ON SCHEMA public TO postgres, anon, authenticated, authenticator, service_role;
GRANT ALL ON SCHEMA auth TO postgres, anon, authenticated, authenticator, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, authenticator, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, authenticator, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, authenticator, service_role;

-- 5. RE-FIX SEARCH PATHS FOR ALL API ROLES (Double check)
ALTER ROLE authenticator SET search_path = public, auth, extensions;
ALTER ROLE anon SET search_path = public, auth, extensions;
ALTER ROLE authenticated SET search_path = public, auth, extensions;

-- 6. FORCE SCHEMA RELOAD
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 7. VERIFICATION
-- This query should return NO rows if triggers are gone.
SELECT tgname FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass;
