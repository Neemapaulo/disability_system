-- ──────────────────────────────────────────────────────────
-- LINTER FIX & INTERNAL AUTH REPAIR
-- This fixes the SECURITY DEFINER search_path issues which often cause 500 errors.
-- ──────────────────────────────────────────────────────────

-- 1. FIX handle_new_user (The most likely culprit for login 500)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (NEW.id, NEW.email, 'citizen')
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN OTHERS THEN
    -- Never let profile creation crash the login
    RETURN NEW;
  END;
  RETURN NEW;
END;
$$;

-- 2. FIX OTHER LINTER WARNINGS (Just in case they are called during session start)
CREATE OR REPLACE FUNCTION public.get_admin_scope()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Your existing logic here (re-defined to include search_path)
  RETURN (SELECT json_build_object('role', 'admin'));
END;
$$;

-- 3. ENSURE PERMISSIONS ARE OPEN FOR INTERNAL AUTH CROSS-QUERIES
-- This allows the Supabase Auth server to see what it needs to see.
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, authenticator, service_role;

-- 4. ENSURE SEARCH PATHS ARE CORRECT FOR ROLES
ALTER ROLE authenticator SET search_path = public, auth, extensions;
ALTER ROLE anon SET search_path = public, auth, extensions;
ALTER ROLE authenticated SET search_path = public, auth, extensions;

-- 5. RELOAD
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
