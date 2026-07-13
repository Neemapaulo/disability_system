-- ──────────────────────────────────────────────────────────
-- MKMU ADMIN SCOPING AND DATA REPAIR SCRIPT
-- ──────────────────────────────────────────────────────────

-- 1. REINFORCE SECURITY: Admins ONLY see their assigned district
-- This ensures that reports for 'Kinondoni' are not visible to 'Ubungo' admins
-- even if they try to bypass the UI filters.

DROP POLICY IF EXISTS select_reports_by_admin_tier ON public.ripoti;

CREATE POLICY select_reports_by_admin_tier ON public.ripoti
FOR SELECT TO authenticated
USING (
    -- A. Admins see only their managed district
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND (
            role::text = 'superuser'
            OR (role::text = 'admin' AND managed_wilaya = ripoti.wilaya::text)
          )
    )
    OR
    -- B. Legacy admin profile check
    EXISTS (
        SELECT 1 FROM public.admin_profiles
        WHERE id = auth.uid()
          AND (
            role::text = 'superuser'
            OR role::text = 'regional'
            OR (role::text = 'district' AND assigned_district::text = ripoti.wilaya::text)
          )
    )
    OR
    -- C. Citizen: See own reports
    (user_id = auth.uid())
);

-- ──────────────────────────────────────────────────────────
-- 2. DATA REPAIR: Correct any reports that defaulted to 'Ubungo'
-- ──────────────────────────────────────────────────────────

-- Fix records that were incorrectly tagged as Ubungo based on text in description or location
UPDATE public.ripoti
SET wilaya = 'Kinondoni'
WHERE wilaya = 'Ubungo'
  AND (maelezo ILIKE '%kinondoni%' OR eneo_jina ILIKE '%kinondoni%' OR kata ILIKE '%kinondoni%');

UPDATE public.ripoti
SET wilaya = 'Ilala'
WHERE wilaya = 'Ubungo'
  AND (maelezo ILIKE '%ilala%' OR eneo_jina ILIKE '%ilala%' OR kata ILIKE '%ilala%');

UPDATE public.ripoti
SET wilaya = 'Temeke'
WHERE wilaya = 'Ubungo'
  AND (maelezo ILIKE '%temeke%' OR eneo_jina ILIKE '%temeke%' OR kata ILIKE '%temeke%');

UPDATE public.ripoti
SET wilaya = 'Kigamboni'
WHERE wilaya = 'Ubungo'
  AND (maelezo ILIKE '%kigamboni%' OR eneo_jina ILIKE '%kigamboni%' OR kata ILIKE '%kigamboni%');

-- ──────────────────────────────────────────────────────────
-- 3. BUCKET PERMISSIONS: Allow public viewing of images
-- ──────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Allow public view" ON storage.objects;

CREATE POLICY "Allow public view"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'mkmu-picha');
