-- ──────────────────────────────────────────────────────────
-- GET THE EXACT KILL COMMANDS
-- ──────────────────────────────────────────────────────────

-- Run this script and it will output a list of SQL commands.
-- You need to copy those results and run them in a NEW query.

SELECT
    'ALTER TABLE ' || quote_ident(tc.table_schema) || '.' || quote_ident(tc.table_name) ||
    ' DROP CONSTRAINT ' || quote_ident(tc.constraint_name) || ';' AS kill_command
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
      AND ccu.table_schema = tc.table_schema
WHERE ccu.table_name = 'users'
  AND ccu.table_schema = 'auth'
  AND tc.constraint_type = 'FOREIGN KEY';
