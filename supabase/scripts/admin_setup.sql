-- ─────────────────────────────────────────────────────────────
-- MKMU FINAL ADMIN PROVISIONING SCRIPT (STABLE)
-- ─────────────────────────────────────────────────────────────

DO $$
DECLARE
    v_password TEXT := 'MkmuAdmin2024!';

    v_regional_id UUID;
    v_ilala_id UUID;
    v_kigamboni_id UUID;
    v_ubungo_id UUID;
    v_kinondoni_id UUID;
    v_temeke_id UUID;

    v_emails TEXT[] := ARRAY[
        'mkmudaradmi@mkmu.com',
        'mkmuilalaadmin@mkmu.com',
        'mkmuadminkigamboni@mkmu.com',
        'mkmuadminubungo@mkmu.com',
        'mkmuadminkinondoni@mkmu.com',
        'mkmuadmintemeke@mkmu.com'
    ];
    v_names TEXT[] := ARRAY[
        'Mratibu wa Mkoa',
        'Mhandisi wa Wilaya - Ilala',
        'Mhandisi wa Wilaya - Kigamboni',
        'Mhandisi wa Wilaya - Ubungo',
        'Mhandisi wa Wilaya - Kinondoni',
        'Mhandisi wa Wilaya - Temeke'
    ];
    v_temp_id UUID;
BEGIN

    -- 1. Create Users (Safe approach without ON CONFLICT)
    FOR i IN 1..6 LOOP
        -- Check if exists
        SELECT id INTO v_temp_id FROM auth.users WHERE email = v_emails[i];

        -- Insert only if missing
        IF v_temp_id IS NULL THEN
            INSERT INTO auth.users (
                instance_id, id, aud, role, email, encrypted_password,
                email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
                created_at, updated_at, confirmation_token, email_change,
                email_change_token_new, recovery_token
            )
            VALUES (
                '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
                v_emails[i], crypt(v_password, gen_salt('bf')), now(),
                '{"provider":"email","providers":["email"]}',
                jsonb_build_object('full_name', v_names[i]),
                now(), now(), '', '', '', ''
            ) RETURNING id INTO v_temp_id;
        END IF;

        -- Store IDs for Step 2
        IF i = 1 THEN v_regional_id := v_temp_id;
        ELSIF i = 2 THEN v_ilala_id := v_temp_id;
        ELSIF i = 3 THEN v_kigamboni_id := v_temp_id;
        ELSIF i = 4 THEN v_ubungo_id := v_temp_id;
        ELSIF i = 5 THEN v_kinondoni_id := v_temp_id;
        ELSIF i = 6 THEN v_temeke_id := v_temp_id;
        END IF;
    END LOOP;

    -- 2. Link Admin Profiles
    INSERT INTO admin_profiles (id, majina_kamili, role, assigned_district, idara_taasisi)
    VALUES
        (v_regional_id, 'Mratibu wa Mkoa', 'regional', NULL, 'Ofisi ya Mkuu wa Mkoa (RC)'),
        (v_ilala_id, 'Mhandisi wa Wilaya - Ilala', 'district', 'Ilala', 'TARURA Ilala'),
        (v_kigamboni_id, 'Mhandisi wa Wilaya - Kigamboni', 'district', 'Kigamboni', 'TARURA Kigamboni'),
        (v_ubungo_id, 'Mhandisi wa Wilaya - Ubungo', 'district', 'Ubungo', 'TARURA Ubungo'),
        (v_kinondoni_id, 'Mhandisi wa Wilaya - Kinondoni', 'district', 'Kinondoni', 'TARURA Kinondoni'),
        (v_temeke_id, 'Mhandisi wa Wilaya - Temeke', 'district', 'Temeke', 'TARURA Temeke')
    ON CONFLICT (id) DO UPDATE SET
        role = EXCLUDED.role,
        assigned_district = EXCLUDED.assigned_district;

END $$;

-- 3. Verification
SELECT p.majina_kamili, p.role, p.assigned_district, u.email
FROM admin_profiles p
JOIN auth.users u ON p.id = u.id;
