-- ──────────────────────────────────────────────────────────
-- LINTER FIX & INTERNAL AUTH REPAIR (V2)
-- ──────────────────────────────────────────────────────────

-- 1. DROP CONFLICTING FUNCTIONS FIRST
DROP FUNCTION IF EXISTS public.get_admin_scope();
DROP FUNCTION IF EXISTS public.handle_new_user();

-- 2. RE-CREATE handle_new_user (The most likely culprit for login 500)
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

-- 3. RE-CREATE get_admin_scope (With correct security path)
CREATE OR REPLACE FUNCTION public.get_admin_scope()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN json_build_object('role', 'admin');
END;
$$;

-- 4. RE-ATTACH TRIGGER (Ensuring it exists after drop)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. ENSURE PERMISSIONS ARE OPEN
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, authenticator, service_role;

-- 6. ENSURE SEARCH PATHS ARE CORRECT FOR ROLES
ALTER ROLE authenticator SET search_path = public, auth, extensions;
ALTER ROLE anon SET search_path = public, auth, extensions;
ALTER ROLE authenticated SET search_path = public, auth, extensions;

-- 7. RELOAD
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
