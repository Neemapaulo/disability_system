-- ──────────────────────────────────────────────────────────
-- Why is the dashboard's status update being refused?
--
-- Run this in the Supabase SQL Editor while logged in as yourself
-- (the SQL Editor runs as the postgres role, so auth.uid() is NULL here —
-- that is expected; section 2 asks you to paste your admin's email instead).
--
-- Send back all four result sets.
-- ──────────────────────────────────────────────────────────

-- 1. Has migration 0003 actually been applied? ─────────────
-- Expect: one row, can_manage_ripoti. No rows = 0003 was never run,
-- which on its own explains the refusal.
SELECT p.proname AS function_found
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'can_manage_ripoti';


-- 2. What does the admin's profile actually say? ───────────
-- >>> Replace the email below with the account you log in as. <<<
-- Expect: role 'admin' or 'superuser', and either
--   managed_wilaya = 'Kinondoni'  (district admin), or
--   managed_wilaya NULL + managed_mkoa = 'Dar es Salaam'  (regional admin).
-- A missing row here is decisive: the policy looks the account up in
-- public.profiles, so no row means no permission, whatever the dashboard shows.
SELECT
  u.email,
  p.id IS NOT NULL AS has_profile_row,
  p.role,
  p.managed_mkoa,
  p.managed_wilaya
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email = 'mkmudaradmin@mkmu.com';   -- <<< EDIT THIS


-- 3. Which UPDATE policies exist on ripoti right now? ──────
-- Expect after 0003: "Admins can update scoped reports", permissive,
-- qual and with_check both calling can_manage_ripoti.
-- A policy with permissive = 'RESTRICTIVE' would AND against the others
-- and could block on its own.
SELECT policyname, permissive, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'ripoti'
ORDER BY cmd, policyname;


-- 4. Would the policy pass for that admin on that report? ──
-- Evaluates the same condition the policy uses, but with the admin named
-- explicitly rather than via auth.uid(). This is the direct answer:
-- if can_update is false, the profile/report pairing is the problem;
-- if true, the block is elsewhere (stale JWT, wrong account in the browser).
SELECT
  r.id,
  r.wilaya,
  r.mkoa,
  r.hali,
  EXISTS (
    SELECT 1 FROM public.profiles p
    JOIN auth.users u ON u.id = p.id
    WHERE u.email = 'mkmudaradmin@mkmu.com'   -- <<< EDIT THIS TOO
      AND (
        p.role = 'superuser'
        OR (
          p.role = 'admin'
          AND (
            (p.managed_wilaya IS NULL AND p.managed_mkoa IS NOT NULL
                                     AND p.managed_mkoa = r.mkoa)
            OR p.managed_wilaya = r.wilaya
          )
        )
      )
  ) AS can_update
FROM public.ripoti r
WHERE r.wilaya = 'Kinondoni'
LIMIT 5;
