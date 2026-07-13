-- ──────────────────────────────────────────────────────────
-- FIND AND KILL BLOCKING CONSTRAINTS
-- ──────────────────────────────────────────────────────────

-- 1. Identify which tables are "holding onto" auth.users
-- This will list every table that has a link (Foreign Key) to your users.
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
      AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND ccu.table_name = 'users'
AND ccu.table_schema = 'auth';

-- 2. NUCLEAR OPTION: Drop the known suspect constraints
-- We start with the ones we know about.
-- If the query above shows more, we will add them.
ALTER TABLE IF EXISTS public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE IF EXISTS public.profiles DROP CONSTRAINT IF EXISTS profiles_user_id_fkey;
ALTER TABLE IF EXISTS public.ripoti DROP CONSTRAINT IF EXISTS ripoti_user_id_fkey;
ALTER TABLE IF EXISTS public.active_map_reports DROP CONSTRAINT IF EXISTS active_map_reports_user_id_fkey;

-- 3. REFRESH API
NOTIFY pgrst, 'reload schema';
