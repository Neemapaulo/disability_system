-- ─────────────────────────────────────────────────────────────
-- MKMU ULTIMATE DATA TYPE FIX
-- This script fixes the "text vs uuid" incompatible types error.
-- ─────────────────────────────────────────────────────────────

-- 1. Drop the problematic foreign key if it exists
ALTER TABLE IF EXISTS ripoti DROP CONSTRAINT IF EXISTS ripoti_user_id_fkey;

-- 2. SURGICAL CONVERSION: Convert user_id column from TEXT to UUID
-- We use USING clause to force the cast correctly.
ALTER TABLE ripoti
ALTER COLUMN user_id TYPE UUID USING user_id::uuid;

-- 3. RE-ESTABLISH THE RELATIONSHIP
-- Now that both sides are UUID, this will succeed.
ALTER TABLE ripoti
ADD CONSTRAINT ripoti_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. FINAL PROVISIONING (The 6 Admins)
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

-- 5. SUCCESS CHECK
SELECT 'SUCCESS' as Status, count(*) as AdminCount FROM admin_profiles;
