-- ──────────────────────────────────────────────────────────
-- Fix admin status updates, and constrain `hali` to real values.
--
-- Run this in the Supabase SQL Editor for the project the dashboard
-- points at (mkmu-admin-web/.env).
--
-- Background: the only UPDATE policy on public.ripoti lives in
-- admin_provisioning.sql and requires role = 'admin' exactly. The admin
-- dashboard also admits 'superuser' accounts, which the policy then
-- silently refuses — Postgres reports zero affected rows rather than an
-- error, so the dashboard showed those writes as successful. This widens
-- the policy to cover superusers and tightens WITH CHECK so an admin
-- cannot move a report outside their own scope.
--
-- Only UPDATE policies are touched here. The SELECT policies are left
-- alone deliberately: several files define overlapping ones
-- (select_reports_by_admin_tier, admin_isolation_policy, "Admins can view
-- scoped reports") and untangling them is a separate job.
-- ──────────────────────────────────────────────────────────

-- 1. Valid statuses ────────────────────────────────────────
-- These five are what lib/core/models/ripoti_model.dart renders. Without
-- this constraint a typo in either client writes a status that the mobile
-- app cannot label, and the citizen sees a raw database value.

-- Surface any existing rows that would violate the constraint before adding it.
DO $$
DECLARE
  bad_count INT;
BEGIN
  SELECT count(*) INTO bad_count
  FROM public.ripoti
  WHERE hali IS NULL
     OR hali NOT IN ('mpya', 'inaangaliwa', 'imepewa_mamlaka',
                     'inashughulikiwa', 'imekamilika');

  IF bad_count > 0 THEN
    RAISE EXCEPTION
      'ripoti has % row(s) with a status outside the five valid values. '
      'Inspect them before re-running: '
      'SELECT id, hali FROM public.ripoti WHERE hali NOT IN '
      '(''mpya'',''inaangaliwa'',''imepewa_mamlaka'',''inashughulikiwa'',''imekamilika'');',
      bad_count;
  END IF;
END $$;

ALTER TABLE public.ripoti DROP CONSTRAINT IF EXISTS ripoti_hali_valid;
ALTER TABLE public.ripoti ADD CONSTRAINT ripoti_hali_valid
  CHECK (hali IN ('mpya', 'inaangaliwa', 'imepewa_mamlaka',
                  'inashughulikiwa', 'imekamilika'));

-- 2. Who may update a report ───────────────────────────────
-- Kept as a function so USING and WITH CHECK cannot drift apart, and so
-- the profiles lookup happens once per statement rather than per row.

CREATE OR REPLACE FUNCTION public.can_manage_ripoti(target_mkoa TEXT, target_wilaya TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND (
        -- Superuser: every district.
        p.role = 'superuser'
        OR (
          p.role = 'admin'
          AND (
            -- Region admin (managed_wilaya IS NULL) covers the whole region.
            (p.managed_wilaya IS NULL AND p.managed_mkoa IS NOT NULL
                                     AND p.managed_mkoa = target_mkoa)
            -- District admin covers one district.
            OR p.managed_wilaya = target_wilaya
          )
        )
      )
  );
$$;

REVOKE ALL ON FUNCTION public.can_manage_ripoti(TEXT, TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.can_manage_ripoti(TEXT, TEXT) TO authenticated;

DROP POLICY IF EXISTS "Admins can update scoped reports" ON public.ripoti;

CREATE POLICY "Admins can update scoped reports" ON public.ripoti
FOR UPDATE TO authenticated
USING (public.can_manage_ripoti(mkoa, wilaya))
-- WITH CHECK mirrors USING so a report cannot be edited into a district the
-- admin does not manage. The previous version checked only the role, which
-- let a district admin reassign a report out of their own scope.
WITH CHECK (public.can_manage_ripoti(mkoa, wilaya));

NOTIFY pgrst, 'reload schema';
