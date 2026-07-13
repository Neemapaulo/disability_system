-- ──────────────────────────────────────────────────────────
-- FIX FOR "DATABASE ERROR QUERYING SCHEMA"
-- Run this script in your Supabase SQL Editor
-- ──────────────────────────────────────────────────────────

-- 1. Ensure the profiles table exists with correct schema
CREATE TABLE IF NOT EXISTS public.profiles (
    id                 UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email              TEXT UNIQUE NOT NULL,
    full_name          TEXT,
    phone_number       TEXT,
    mkoa               TEXT DEFAULT 'Dar es Salaam',
    wilaya             TEXT,
    secret_question    TEXT,
    secret_answer      TEXT,
    role               TEXT DEFAULT 'citizen',
    managed_mkoa       TEXT,
    managed_wilaya      TEXT,
    managed_kata        TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Sync any existing auth users into the profiles table
-- This is critical if users were created manually in the Dashboard
INSERT INTO public.profiles (id, email, full_name, role)
SELECT id, email, raw_user_meta_data->>'full_name', COALESCE(raw_user_meta_data->>'role', 'citizen')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 3. Explicitly set admin roles for system accounts
UPDATE public.profiles SET role = 'admin', managed_mkoa = 'Dar es Salaam' WHERE email = 'mkmudaradmi@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Ilala' WHERE email = 'mkmuilalaadmin@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Kigamboni' WHERE email = 'mkmuadminkigamboni@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Ubungo' WHERE email = 'mkmuadminubungo@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Kinondoni' WHERE email = 'mkmuadminkinondoni@mkmu.com';
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Temeke' WHERE email = 'mkmuadmintemeke@mkmu.com';

-- 4. Ensure RLS is configured correctly
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read access for all users" ON public.profiles;
CREATE POLICY "Enable read access for all users" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Enable update for users based on id" ON public.profiles;
CREATE POLICY "Enable update for users based on id" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- 5. Grant permissions to the anon and authenticated roles
GRANT ALL ON public.profiles TO anon, authenticated, service_role;
GRANT ALL ON public.ripoti TO anon, authenticated, service_role;
GRANT ALL ON public.active_map_reports TO anon, authenticated, service_role;
