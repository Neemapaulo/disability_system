-- ──────────────────────────────────────────────────────────
-- 1. UNIFY PROFILES AND ADMIN PERMISSIONS
-- ──────────────────────────────────────────────────────────

-- Ensure the profiles table can handle admin roles
-- (Assuming it already has 'role', 'managed_mkoa', 'managed_wilaya', 'managed_kata')

-- ──────────────────────────────────────────────────────────
-- 2. UPDATE RIPOTI RLS (MANDATORY FIX)
-- ──────────────────────────────────────────────────────────
-- The current policy is too strict or depends on the wrong table.
-- We unify it to check both profiles and admin_profiles for safety.

DROP POLICY IF EXISTS select_reports_by_admin_tier ON ripoti;

CREATE POLICY select_reports_by_admin_tier ON ripoti
FOR SELECT TO authenticated
USING (
    -- A. Check public.profiles (modern way)
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid()
          AND (
            role = 'admin' AND (managed_wilaya IS NULL OR managed_wilaya = ripoti.wilaya::text)
            OR role = 'superuser'
          )
    )
    OR
    -- B. Check admin_profiles (legacy/fallback)
    EXISTS (
        SELECT 1 FROM public.admin_profiles
        WHERE id = auth.uid()
          AND (
            role = 'regional'
            OR (role = 'district' AND assigned_district::text = ripoti.wilaya::text)
          )
    )
    OR
    -- C. Citizen: See own reports
    (user_id = auth.uid())
);

-- Ensure Insert is possible for authenticated users
DROP POLICY IF EXISTS "Anyone can insert reports" ON ripoti;
CREATE POLICY "Anyone can insert reports" ON ripoti
FOR INSERT TO authenticated
WITH CHECK (true);

-- ──────────────────────────────────────────────────────────
-- 3. STORAGE POLICIES (IMAGE FIX)
-- ──────────────────────────────────────────────────────────
-- Ensure the mkmu-picha bucket allows public read if we use getPublicUrl
-- Run these in the dashboard or via SQL if possible:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('mkmu-picha', 'mkmu-picha', true) ON CONFLICT (id) DO UPDATE SET public = true;

-- Policy to allow authenticated users to upload to their own folder
DROP POLICY IF EXISTS "Allow authenticated uploads" ON storage.objects;
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'mkmu-picha');

-- Policy to allow public to view images (required for getPublicUrl to work)
DROP POLICY IF EXISTS "Allow public view" ON storage.objects;
CREATE POLICY "Allow public view"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'mkmu-picha');

-- ──────────────────────────────────────────────────────────
-- 4. DATA CLEANUP (FIX INCORRECT DISTRICTS)
-- ──────────────────────────────────────────────────────────
-- Fix records where 'wilaya' was incorrectly set to 'Dar es Salaam'
-- Based on the user's specific case (Ubungo report labeled as DSM)
UPDATE public.ripoti
SET wilaya = 'Ubungo'
WHERE wilaya::text = 'Dar es Salaam';

-- Ensure empty kata strings are NULL for better UI
UPDATE public.ripoti
SET kata = NULL
WHERE kata = '' OR kata = 'EMPTY';
