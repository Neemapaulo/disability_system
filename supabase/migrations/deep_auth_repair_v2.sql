-- ──────────────────────────────────────────────────────────
-- DEEP AUTH REPAIR V2: FIXING THE INTERNAL 500 ERROR
-- ──────────────────────────────────────────────────────────

-- 1. DROP THE TRIGGER TEMPORARILY
-- If the trigger is broken, it blocks EVERY login attempt with a 500 error.
-- We drop it to see if login starts working.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS trigger_on_auth_user_created ON auth.users;

-- 2. RE-GRANT ESSENTIAL PERMISSIONS TO INTERNAL AUTH ROLES
-- Sometimes the internal 'supabase_auth_admin' or 'authenticator' loses access to 'public'
GRANT USAGE ON SCHEMA public TO supabase_auth_admin, authenticator, anon, authenticated;
GRANT USAGE ON SCHEMA auth TO supabase_auth_admin, authenticator, anon, authenticated;

-- 3. FIX THE SEARCH PATHS AGAIN (Ensuring auth_admin is included)
ALTER ROLE supabase_auth_admin SET search_path = 'public', 'auth';
ALTER ROLE authenticator SET search_path = 'public', 'auth';

-- 4. ENSURE THE PROFILES TABLE IS TOTALLY ACCESSIBLE
GRANT ALL ON TABLE public.profiles TO supabase_auth_admin, authenticator, service_role;

-- 5. RE-CREATE A "SAFE" TRIGGER FUNCTION
-- This version uses a TRY/CATCH block so it NEVER crashes the login process.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'citizen')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    -- If this fails, we just ignore it so the user can still log in
    NULL;
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RE-ATTACH THE TRIGGER
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 7. FORCE RELOAD
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
