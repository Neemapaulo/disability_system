-- ─────────────────────────────────────────────────────────────
-- MKMU FINAL PRODUCTION PROVISIONING & LIVE DATA
-- Run this to ensure the dashboard has REAL data to show
-- ─────────────────────────────────────────────────────────────

-- 1. Ensure Admins are Provisioned (Safe Method)
DO $$
DECLARE
    v_password TEXT := 'MkmuAdmin2024!';
    v_emails TEXT[] := ARRAY[
        'mkmudaradmi@mkmu.com',
        'mkmuilalaadmin@mkmu.com',
        'mkmuadminkinondoni@mkmu.com',
        'mkmuadmintemeke@mkmu.com',
        'mkmuadminubungo@mkmu.com',
        'mkmuadminkigamboni@mkmu.com'
    ];
    v_names TEXT[] := ARRAY[
        'Mratibu wa Mkoa',
        'Mhandisi wa Ilala',
        'Mhandisi wa Kinondoni',
        'Mhandisi wa Temeke',
        'Mhandisi wa Ubungo',
        'Mhandisi wa Kigamboni'
    ];
    v_districts TEXT[] := ARRAY[NULL, 'Ilala', 'Kinondoni', 'Temeke', 'Ubungo', 'Kigamboni'];
    v_temp_id UUID;
BEGIN
    FOR i IN 1..6 LOOP
        -- Check if Auth User exists
        SELECT id INTO v_temp_id FROM auth.users WHERE email = v_emails[i];

        IF v_temp_id IS NULL THEN
            INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
            VALUES (
                '00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
                v_emails[i], crypt(v_password, gen_salt('bf')), now(),
                '{"provider":"email","providers":["email"]}',
                jsonb_build_object('full_name', v_names[i]),
                now(), now()
            ) RETURNING id INTO v_temp_id;
        END IF;

        -- Link to Admin Profile
        INSERT INTO admin_profiles (id, majina_kamili, role, assigned_district, idara_taasisi)
        VALUES (
            v_temp_id, v_names[i],
            CASE WHEN i=1 THEN 'regional'::admin_role ELSE 'district'::admin_role END,
            v_districts[i]::dsm_district,
            CASE WHEN i=1 THEN 'RC Office' ELSE 'TARURA' END
        ) ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, assigned_district = EXCLUDED.assigned_district;
    END LOOP;
END $$;

-- 2. Insert Sample REAL Reports (To verify Dashboard loading)
-- If table is empty, add some data
INSERT INTO ripoti (user_id, aina, maelezo, latitude, longitude, wilaya, kata, hali, frequency_count, severity_weight)
SELECT
    (SELECT id FROM admin_profiles LIMIT 1), -- Assign to first admin for testing
    'njia_kutopitika',
    'Njia ya watembea kwa miguu imeharibika vibaya hapa.',
    -6.8235 + (random() * 0.05),
    39.2830 + (random() * 0.05),
    'Ilala',
    'Kariakoo',
    'mpya',
    5,
    1.5
WHERE NOT EXISTS (SELECT 1 FROM ripoti LIMIT 1);

-- 3. Verify
SELECT * FROM admin_profiles;
SELECT count(*) as total_reports FROM ripoti;
