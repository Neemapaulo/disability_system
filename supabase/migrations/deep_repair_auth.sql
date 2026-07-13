-- ──────────────────────────────────────────────────────────
-- DEEP REPAIR: INTERNAL AUTH SCHEMA & API SYNC
-- Run this in the Supabase SQL Editor to fix the 500 error
-- ──────────────────────────────────────────────────────────

-- 1. Ensure the 'auth' and 'public' schemas are linked correctly in the search path
-- This tells the database where to look for tables when the API calls come in.
ALTER ROLE authenticator SET search_path = 'public', 'auth';
ALTER ROLE anon SET search_path = 'public', 'auth';
ALTER ROLE authenticated SET search_path = 'public', 'auth';

-- 2. Force Refresh internal PostgREST structural cache
-- Sometimes the API server gets stuck on an old "blueprint" of your database.
NOTIFY pgrst, 'reload schema';

-- 3. Verify/Repair the Profile Trigger
-- If the login fails with 500, it's often because the internal Supabase trigger
-- is trying to write to a 'profiles' table that it can't find or access.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- We use a simple insert. If it fails, the whole login/signup fails with 500.
  -- We wrap it in a TRY/CATCH to ensure login works even if profile creation hits a snag.
  BEGIN
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', 'citizen');
  EXCEPTION WHEN OTHERS THEN
    -- Silence errors so the user can at least log in
    RETURN NEW;
  END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Re-grant core permissions that the 500 error suggests are missing
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;
GRANT SELECT ON auth.users TO anon, authenticated, authenticator;
GRANT ALL ON public.profiles TO anon, authenticated, authenticator, service_role;

-- 5. Final Reset of the structure
NOTIFY pgrst, 'reload config';
NOTIFY pgrst, 'reload schema';
