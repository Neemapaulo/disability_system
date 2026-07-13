-- ──────────────────────────────────────────────────────────
-- SAFE TRIGGER & PERMISSION FIX (NON-RESERVED ROLES)
-- ──────────────────────────────────────────────────────────

-- 1. DROP THE TRIGGER FIRST
-- This is the most likely cause of the 500 error.
-- Dropping it allows users to log in even if the profile creation is broken.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. FIX SEARCH PATHS FOR STANDARD API ROLES ONLY
ALTER ROLE authenticator SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE anon SET search_path = 'public', 'auth', 'extensions';
ALTER ROLE authenticated SET search_path = 'public', 'auth', 'extensions';

-- 3. GRANT PERMISSIONS TO STANDARD ROLES
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;
GRANT ALL ON TABLE public.profiles TO anon, authenticated, authenticator, service_role;

-- 4. RE-CREATE THE PROFILE FUNCTION WITH EXTREME SAFETY
-- This version will NOT crash the login process even if the profiles table is missing columns.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Wrap in a nested block to catch ALL errors
  BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'citizen')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    -- Log the error to the Postgres log but DON'T stop the login
    RAISE WARNING 'Profile creation failed for user %: %', NEW.id, SQLERRM;
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RE-ATTACH THE TRIGGER
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. SYNC CACHE
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
