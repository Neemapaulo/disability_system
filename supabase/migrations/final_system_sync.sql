-- ──────────────────────────────────────────────────────────
-- FINAL SYSTEM SYNC & PERMISSION FIX
-- ──────────────────────────────────────────────────────────

-- 1. Ensure the public schema is exposed to API (Internal Supabase Check)
-- Note: This is usually default, but ensuring permissions are explicitly granted.

-- 2. Force Create/Update Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT DEFAULT 'citizen',
    managed_wilaya TEXT,
    managed_mkoa TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable RLS but ensure READ is open for login checks
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT USING (true);

-- 4. Sync Auth Users to Profiles
-- This ensures even manually created dashboard users have a record.
INSERT INTO public.profiles (id, email)
SELECT id, email FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 5. Set System Admins (Update existing records)
UPDATE public.profiles SET role = 'admin', managed_mkoa = 'Dar es Salaam' WHERE email = 'mkmudaradmi@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Ilala' WHERE email = 'mkmuilalaadmin@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Kigamboni' WHERE email = 'mkmuadminkigamboni@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Ubungo' WHERE email = 'mkmuadminubungo@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Kinondoni' WHERE email = 'mkmuadminkinondoni@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Temeke' WHERE email = 'mkmuadmintemeke@mkmu.com';

-- 6. CRITICAL: Grant API Schema Permissions
-- This tells Supabase/PostgREST that the web app is allowed to see these structures.
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated, service_role;
GRANT ALL ON public.ripoti TO anon, authenticated, service_role;
GRANT ALL ON public.active_map_reports TO anon, authenticated, service_role;

-- 7. Notify PostgREST of schema changes (Internal Cache Refresh)
NOTIFY pgrst, 'reload schema';
