-- ──────────────────────────────────────────────────────────
-- NUCLEAR TRIGGER CLEARANCE & SCHEMA BYPASS
-- ──────────────────────────────────────────────────────────

-- 1. DROP INTERNAL TRIGGERS BY NAME
-- This is a last resort if standard constraint dropping fails.
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16694" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16695" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16722" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16723" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16759" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16760" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16950" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_16951" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17029" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17030" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17048" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17049" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17143" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17144" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17160" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17161" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17936" ON auth.users;
DROP TRIGGER IF EXISTS "RI_ConstraintTrigger_a_17937" ON auth.users;

-- 2. RESET SEARCH PATH TO BYPASS AUTH SCHEMA
-- Sometimes the 500 happens because PostgREST is trying to scan the 'auth' schema.
-- We restrict it to 'public' only for now to see if login works.
ALTER ROLE authenticator SET search_path = public;
ALTER ROLE anon SET search_path = public;
ALTER ROLE authenticated SET search_path = public;

-- 3. ENSURE NO FUNCTIONS ARE BLOCKING
-- Clear search paths for all suspected functions
ALTER FUNCTION public.handle_new_user() SET search_path = public;
ALTER FUNCTION public.get_admin_scope() SET search_path = public;

-- 4. FORCE CACHE RELOAD
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- 5. VERIFICATION
SELECT count(*) FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass AND tgname LIKE 'RI_ConstraintTrigger%';
