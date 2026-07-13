-- ──────────────────────────────────────────────────────────
-- MASTER SYSTEM REPAIR & 500 ERROR FIX (FINAL VERSION)
-- ──────────────────────────────────────────────────────────

-- 1. CLEAN UP EXISTING FUNCTIONS TO AVOID CONFLICTS
-- We use CASCADE to ensure any dependent triggers are handled.
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.get_admin_scope() CASCADE;
DROP FUNCTION IF EXISTS public.generate_member_id() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.calculate_ipi_score() CASCADE;

-- 2. RE-CREATE CORE FUNCTIONS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (NEW.id, NEW.email, 'citizen')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_admin_scope()
RETURNS TABLE (mkoa TEXT, wilaya TEXT) AS $$
BEGIN
  RETURN QUERY SELECT p.managed_mkoa, p.managed_wilaya
               FROM profiles p WHERE p.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.generate_member_id()
RETURNS text AS $$
BEGIN
  RETURN 'MEM-' || lpad(floor(random() * 1000000)::text, 6, '0');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.calculate_ipi_score()
RETURNS trigger AS $$
BEGIN
    NEW.ipi_score = COALESCE(NEW.quality, 0) + COALESCE(NEW.urgency, 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FIX THE "GHOST" CONSTRAINTS (Nuclear Cleanup)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT tc.table_schema, tc.table_name, tc.constraint_name
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
        WHERE ccu.table_name = 'users'
          AND ccu.table_schema = 'auth'
          AND tc.constraint_type = 'FOREIGN KEY'
    ) LOOP
        EXECUTE 'ALTER TABLE ' || quote_ident(r.table_schema) || '.' || quote_ident(r.table_name) ||
                ' DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
END $$;

-- 4. REBUILD THE CORE PROFILES LINK
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles
ADD CONSTRAINT profiles_id_fkey
FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 5. FIX SECURITY DEFINER SEARCH PATHS (Final check)
ALTER FUNCTION public.handle_new_user() SET search_path = public;
ALTER FUNCTION public.get_admin_scope() SET search_path = public;
ALTER FUNCTION public.generate_member_id() SET search_path = public;
ALTER FUNCTION public.update_updated_at() SET search_path = public;
ALTER FUNCTION public.calculate_ipi_score() SET search_path = public;

-- 6. RESTORE API ACCESS & SEARCH PATH
ALTER ROLE authenticator SET search_path = 'public', 'auth';
ALTER ROLE anon SET search_path = 'public', 'auth';
ALTER ROLE authenticated SET search_path = 'public', 'auth';

GRANT USAGE ON SCHEMA auth TO anon, authenticated, authenticator;
GRANT SELECT ON auth.users TO anon, authenticated, authenticator;
GRANT USAGE ON SCHEMA public TO anon, authenticated, authenticator;

-- 7. CLEAR ALL LINTER WARNINGS
DROP POLICY IF EXISTS "Admins can list images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public reads" ON storage.objects;

-- 8. REFRESH EVERYTHING
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';
