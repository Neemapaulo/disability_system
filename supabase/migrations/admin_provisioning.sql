-- ──────────────────────────────────────────────────────────
-- ADMIN PROVISIONING & SECURITY POLICIES
-- ──────────────────────────────────────────────────────────

-- 1. CLEANUP PREVIOUS ADMIN POLICIES (if any)
DROP POLICY IF EXISTS "Admins can view scoped reports" ON public.ripoti;
DROP POLICY IF EXISTS "Admins can update scoped reports" ON public.ripoti;

-- 2. ENHANCED RLS POLICIES FOR HIERARCHICAL ACCESS
-- Region Admin: managed_mkoa = 'Dar es Salaam', managed_wilaya = NULL
-- District Admin: managed_wilaya = 'Ilala', etc.

CREATE POLICY "Admins can view scoped reports" ON public.ripoti
FOR SELECT TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  AND (
    -- Region Admin check
    (SELECT managed_mkoa FROM public.profiles WHERE id = auth.uid()) = ripoti.mkoa
    OR
    -- District Admin check
    (SELECT managed_wilaya FROM public.profiles WHERE id = auth.uid()) = ripoti.wilaya
  )
);

CREATE POLICY "Admins can update scoped reports" ON public.ripoti
FOR UPDATE TO authenticated
USING (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
  AND (
    (SELECT managed_mkoa FROM public.profiles WHERE id = auth.uid()) = ripoti.mkoa
    OR
    (SELECT managed_wilaya FROM public.profiles WHERE id = auth.uid()) = ripoti.wilaya
  )
)
WITH CHECK (
  (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
);

-- 3. HELPER FUNCTION TO GET SCOPED DATA (Optional for performance)
CREATE OR REPLACE FUNCTION get_admin_scope()
RETURNS TABLE (mkoa TEXT, wilaya TEXT) AS $$
BEGIN
  RETURN QUERY SELECT p.managed_mkoa, p.managed_wilaya
               FROM profiles p WHERE p.id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. INSERTING SYSTEM ADMINS (Metadata only - actual Auth users must be created in Supabase Dashboard)
-- Since I cannot create Auth users via SQL (requires auth schema access usually restricted),
-- these inserts will populate the profiles table once the users are created via Dashboard/API.

/*
INSTRUCTIONS FOR USER:
Create users in Supabase Auth with these emails and password 'MkmuAdmin2024'.
The 'on_auth_user_created' trigger will handle the initial profile creation.
Then run these updates to set their admin privileges.
*/

-- Example Update Script for Admin Privileges:
/*
-- DAR ES SALAAM (REGION)
UPDATE public.profiles SET role = 'admin', managed_mkoa = 'Dar es Salaam' WHERE email = 'mkmudaradmi@mkmu.com';

-- ILALA
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Ilala' WHERE email = 'mkmuilalaadmin@mkmu.com';

-- KIGAMBONI
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Kigamboni' WHERE email = 'mkmuadminkigamboni@mkmu.com';

-- UBUNGO
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Ubungo' WHERE email = 'mkmuadminubungo@mkmu.com';

-- KINONDONI
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Kinondoni' WHERE email = 'mkmuadminkinondoni@mkmu.com';

-- TEMEKE
UPDATE public.profiles SET role = 'admin', managed_wilaya = 'Temeke' WHERE email = 'mkmuadmintemeke@mkmu.com';
*/
