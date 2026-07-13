-- ──────────────────────────────────────────────────────────
-- UNLOCK LOGIN: FINAL CONSTRAINT KILLER
-- ──────────────────────────────────────────────────────────

-- 1. FIND THE REAL TABLES
-- Run this first to see exactly which REAL tables are causing the triggers.
-- Look for 'BASE TABLE' in the table_type column.
SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    t.table_type
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
    JOIN information_schema.tables AS t
      ON t.table_name = tc.table_name
      AND t.table_schema = tc.table_schema
WHERE ccu.table_name = 'users'
  AND ccu.table_schema = 'auth'
  AND tc.constraint_type = 'FOREIGN KEY';

-- 2. THE KILL LIST (Tables only)
-- We drop the constraints from the tables we suspect.
-- If the query above shows others, add them here.
ALTER TABLE IF EXISTS public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE IF EXISTS public.profiles DROP CONSTRAINT IF EXISTS profiles_user_id_fkey;
ALTER TABLE IF EXISTS public.ripoti DROP CONSTRAINT IF EXISTS ripoti_user_id_fkey;
ALTER TABLE IF EXISTS public.admin_audit_logs DROP CONSTRAINT IF EXISTS admin_audit_logs_admin_id_fkey;

-- 3. RESET API
NOTIFY pgrst, 'reload schema';

-- 4. VERIFY TRIGGERS ARE GONE
-- This should be 0 or very low now.
SELECT count(*) FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass AND tgname LIKE 'RI_ConstraintTrigger%';
