-- ──────────────────────────────────────────────────────────
-- FRESH ADMIN REFRESH (CLEAN START) - VERSION 2
-- Run this in your Supabase SQL Editor
-- This will reset ALL admin passwords to: MKMU-Admin-2026!
-- ──────────────────────────────────────────────────────────

DO $$
DECLARE
    v_emails TEXT[] := ARRAY[
        'mkmudaradmin@mkmu.com',
        'mkmudaradmi@mkmu.com',
        'mkmuilalaadmin@mkmu.com',
        'mkmuadminkigamboni@mkmu.com',
        'mkmuadminubungo@mkmu.com',
        'mkmuadminkinondoni@mkmu.com',
        'mkmuadmintemeke@mkmu.com'
    ];
    v_names TEXT[] := ARRAY[
        'DSM Regional Admin',
        'DSM Regional Admin (Alt)',
        'Ilala District Admin',
        'Kigamboni District Admin',
        'Ubungo District Admin',
        'Kinondoni District Admin',
        'Temeke District Admin'
    ];
    v_districts TEXT[] := ARRAY[
        NULL,
        NULL,
        'Ilala',
        'Kigamboni',
        'Ubungo',
        'Kinondoni',
        'Temeke'
    ];
    v_temp_id UUID;
    v_new_password_hash TEXT := crypt('MKMU-Admin-2026!', gen_salt('bf'));
BEGIN
    -- 1. CLEANUP: Force remove old records to prevent constraint conflicts
    -- We use a more aggressive cleanup to ensure everything tied to these emails is gone
    DELETE FROM public.profiles WHERE email = ANY(v_emails);
    DELETE FROM auth.users WHERE email = ANY(v_emails);

    -- 2. PROVISION: Create fresh users and profiles
    FOR i IN 1..cardinality(v_emails) LOOP
        -- Generate a guaranteed unique ID
        v_temp_id := gen_random_uuid();

        -- Create Auth User
        INSERT INTO auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, recovery_sent_at, last_sign_in_at,
            raw_app_meta_data, raw_user_meta_data, is_super_admin,
            created_at, updated_at, confirmation_token, email_change,
            email_change_token_new, recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000', v_temp_id, 'authenticated', 'authenticated',
            v_emails[i], v_new_password_hash,
            NOW(), NULL, NOW(),
            '{"provider":"email","providers":["email"]}',
            jsonb_build_object('full_name', v_names[i], 'role', 'admin'),
            FALSE, NOW(), NOW(), '', '', '', ''
        );

        -- Create Public Profile
        -- Added ON CONFLICT clause as a safety measure
        INSERT INTO public.profiles (
            id, email, full_name, role, managed_wilaya, managed_mkoa
        ) VALUES (
            v_temp_id, v_emails[i], v_names[i], 'admin', v_districts[i], 'Dar es Salaam'
        )
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            full_name = EXCLUDED.full_name,
            role = EXCLUDED.role,
            managed_wilaya = EXCLUDED.managed_wilaya,
            managed_mkoa = EXCLUDED.managed_mkoa;

    END LOOP;

    -- 3. SYNC: Refresh API Cache
    NOTIFY pgrst, 'reload schema';
END $$;
