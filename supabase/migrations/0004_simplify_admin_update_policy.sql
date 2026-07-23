-- ──────────────────────────────────────────────────────────
-- Any admin may update any report.
--
-- Run this in the Supabase SQL Editor. It supersedes the scoping half of
-- 0003 — run 0003 first if you have not, since this reuses its function
-- and keeps its `hali` CHECK constraint.
--
-- Why not simply "TO authenticated USING (true)": the mobile app's users
-- are authenticated against this same project, and the publishable key
-- ships inside the APK. `authenticated` therefore means "anyone who
-- installed the app", not "an admin" — a citizen could mark their own
-- report solved by calling the REST API directly. Requiring an admin role
-- keeps the check to one column while excluding app users.
--
-- District scoping is deliberately dropped: an Ilala admin can now edit a
-- Kinondoni report. That is the intended simplification. Reinstate 0003's
-- version of can_manage_ripoti if that ever needs tightening again.
-- ──────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.can_manage_ripoti(target_mkoa TEXT, target_wilaya TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  -- Arguments are ignored: kept so the existing policy on ripoti, which
  -- passes (mkoa, wilaya), continues to resolve without being recreated.
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.role IN ('admin', 'superuser')
  );
$$;

REVOKE ALL ON FUNCTION public.can_manage_ripoti(TEXT, TEXT) FROM public;
GRANT EXECUTE ON FUNCTION public.can_manage_ripoti(TEXT, TEXT) TO authenticated;

DROP POLICY IF EXISTS "Admins can update scoped reports" ON public.ripoti;

CREATE POLICY "Admins can update reports" ON public.ripoti
FOR UPDATE TO authenticated
USING (public.can_manage_ripoti(mkoa, wilaya))
WITH CHECK (public.can_manage_ripoti(mkoa, wilaya));

-- Note: admin_isolation_policy (defined in scripts/setup_schema_v2_CLEAN.sql)
-- is FOR ALL, so if it exists on this project it also grants UPDATE and ORs
-- with the policy above. It is left in place on purpose — it grants SELECT
-- too, and dropping it here to tidy up UPDATE would silently take reads away
-- with it. Query 3 of scripts/diagnose_update_block.sql lists what is
-- actually on the table if you want to see.

NOTIFY pgrst, 'reload schema';

-- ──────────────────────────────────────────────────────────
-- Check it worked: run as the admin account, not in the SQL Editor.
-- Change a status in the dashboard. If the red "Hairuhusiwi" box still
-- appears, the account has no row in public.profiles with an admin role —
-- confirm with:
--   SELECT u.email, p.role
--   FROM auth.users u LEFT JOIN public.profiles p ON p.id = u.id
--   WHERE u.email = 'your-admin@mkmu.com';
-- ──────────────────────────────────────────────────────────
