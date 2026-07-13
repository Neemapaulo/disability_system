-- ──────────────────────────────────────────────────────────
-- DIAGNOSTIC CHECK SCRIPT
-- Run this and tell me the results (if any errors occur)
-- ──────────────────────────────────────────────────────────

-- Check 1: Does profiles table exist and have the right columns?
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles';

-- Check 2: Are there any broken triggers on auth.users?
SELECT tgname, tgenabled, tgtype
FROM pg_trigger
WHERE tgrelid = 'auth.users'::regclass;

-- Check 3: Can we manually insert into profiles without error?
-- (This tests the 'handle_new_user' function logic)
DO $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES ('00000000-0000-0000-0000-000000000000', 'test@test.com', 'citizen')
    ON CONFLICT (id) DO NOTHING;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Insert failed: %', SQLERRM;
END $$;

-- Check 4: Check search path again
SHOW search_path;
