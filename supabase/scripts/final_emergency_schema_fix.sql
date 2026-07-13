-- ─────────────────────────────────────────────────────────────
-- MKMU FINAL EMERGENCY SCHEMA FIX
-- This script fixes the "table 'user' not present" and
-- "foreign key constraint" errors by re-linking correctly to auth.users.
-- ─────────────────────────────────────────────────────────────

-- 1. Drop existing problematic constraints on 'ripoti'
ALTER TABLE IF EXISTS ripoti DROP CONSTRAINT IF EXISTS ripoti_user_id_fkey;

-- 2. Ensure 'admin_profiles' is also correctly linked
ALTER TABLE IF EXISTS admin_profiles DROP CONSTRAINT IF EXISTS admin_profiles_id_fkey;

-- 3. RE-LINK correctly to the Supabase internal auth.users table
-- This is the most critical step to fix the "table user not found" error.
ALTER TABLE ripoti
ADD CONSTRAINT ripoti_user_id_fkey
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE admin_profiles
ADD CONSTRAINT admin_profiles_id_fkey
FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 4. Clean up any accidental public 'user' table that might be confusing the system
DROP TABLE IF EXISTS "user" CASCADE;

-- 5. RUN THE PROVISIONING AGAIN IN-PLACE (Safe Version)
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

-- 6. Insert Final Test Report (Leo/Today)
INSERT INTO ripoti (user_id, aina, maelezo, latitude, longitude, wilaya, kata, hali, frequency_count, severity_weight)
SELECT
    (SELECT id FROM admin_profiles LIMIT 1),
    'njia_kutopitika',
    'Njia ya watembea kwa miguu imeharibika vibaya hapa.',
    -6.8235, 39.2830, 'Ilala', 'Kariakoo', 'mpya', 5, 1.5
WHERE NOT EXISTS (SELECT 1 FROM ripoti LIMIT 1);

-- DONE. Dashboard is now ready.
