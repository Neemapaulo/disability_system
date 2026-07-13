-- ─────────────────────────────────────────────────────────────
-- MKMU SUPABASE SCHEMA SETUP (CLEAN VERSION)
-- Use this if you see "relation ripoti is already member of publication"
-- ─────────────────────────────────────────────────────────────

-- 1. Define Custom Types
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'admin_role') THEN
        CREATE TYPE admin_role AS ENUM ('regional', 'district');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'dsm_district') THEN
        CREATE TYPE dsm_district AS ENUM ('Ilala', 'Kinondoni', 'Temeke', 'Ubungo', 'Kigamboni');
    END IF;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Admin Profiles Table
CREATE TABLE IF NOT EXISTS admin_profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    majina_kamili VARCHAR(255) NOT NULL,
    role admin_role NOT NULL,
    assigned_district dsm_district,
    idara_taasisi VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Wards Lookup Table
CREATE TABLE IF NOT EXISTS mtaa_kata (
    id SERIAL PRIMARY KEY,
    district dsm_district NOT NULL,
    ward_name VARCHAR(100) NOT NULL,
    UNIQUE(district, ward_name)
);

-- 4. Main Reports Table (Ripoti)
CREATE TABLE IF NOT EXISTS ripoti (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id),
    aina VARCHAR(50) NOT NULL,
    maelezo TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    mkoa VARCHAR(50) DEFAULT 'Dar es Salaam',
    wilaya dsm_district NOT NULL,
    kata VARCHAR(100),
    eneo_jina VARCHAR(255),
    picha_url TEXT,
    hali VARCHAR(30) DEFAULT 'mpya',
    maoni_ya_admin TEXT,
    frequency_count INT DEFAULT 1,
    severity_weight DECIMAL(3, 2) DEFAULT 1.0,
    priority_score DECIMAL(5, 2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    admin_updated_at TIMESTAMP WITH TIME ZONE
);

-- 5. Enable RLS
ALTER TABLE ripoti ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;

-- 6. Isolation Policy
DROP POLICY IF EXISTS admin_isolation_policy ON ripoti;
CREATE POLICY admin_isolation_policy ON ripoti
AS PERMISSIVE FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM admin_profiles
        WHERE admin_profiles.id::text = (auth.uid())::text
          AND admin_profiles.role::text = 'regional'
    )
    OR
    EXISTS (
        SELECT 1 FROM admin_profiles
        WHERE admin_profiles.id::text = (auth.uid())::text
          AND admin_profiles.role::text = 'district'
          AND ripoti.wilaya::text = admin_profiles.assigned_district::text
    )
    OR
    ((auth.uid())::text = user_id::text)
);

-- 7. IPI Scoring Function
CREATE OR REPLACE FUNCTION calculate_ipi_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.priority_score := (0.40 * NEW.frequency_count) + (0.35 * NEW.severity_weight);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_ipi ON ripoti;
CREATE TRIGGER trigger_update_ipi
BEFORE INSERT OR UPDATE ON ripoti
FOR EACH ROW EXECUTE FUNCTION calculate_ipi_score();

-- 8. Matangazo & Logs
CREATE TABLE IF NOT EXISTS matangazo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kichwa VARCHAR(255) NOT NULL,
    maudhui TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES auth.users(id),
    action VARCHAR(100) NOT NULL,
    target_id UUID,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 9. Insert Wards Data
INSERT INTO mtaa_kata (district, ward_name) VALUES
('Ilala', 'Bonyokwa'), ('Ilala', 'Buguruni'), ('Ilala', 'Buyuni'), ('Ilala', 'Chanika'),
('Ilala', 'Gerezani'), ('Ilala', 'Gongolamboto'), ('Ilala', 'Ilala'), ('Ilala', 'Jangwani'),
('Ilala', 'Kariakoo'), ('Ilala', 'Kimanga'), ('Ilala', 'Kinyerezi'), ('Ilala', 'Kipawa'),
('Ilala', 'Kipunguni'), ('Ilala', 'Kisukuru'), ('Ilala', 'Kitunda'), ('Ilala', 'Kisutu'),
('Ilala', 'Kivukoni'), ('Ilala', 'Kivule'), ('Ilala', 'Kiwalani'), ('Ilala', 'Majohe'),
('Ilala', 'Mchafukoge'), ('Ilala', 'Mchikichini'), ('Ilala', 'Minazi Mirefu'), ('Ilala', 'Mnyamani'),
('Ilala', 'Msongola'), ('Ilala', 'Mzinga'), ('Ilala', 'Pugu'), ('Ilala', 'Pugu Station'),
('Ilala', 'Segerea'), ('Ilala', 'Tabata'), ('Ilala', 'Ukonga'), ('Ilala', 'Upanga East'),
('Ilala', 'Upanga West'), ('Ilala', 'Vingunguti'), ('Ilala', 'Zingiziwa'),
('Kinondoni', 'Bunju'), ('Kinondoni', 'Goba'), ('Kinondoni', 'Hananasif'), ('Kinondoni', 'Kawe'),
('Kinondoni', 'Kijitonyama'), ('Kinondoni', 'Kimara'), ('Kinondoni', 'Kinondoni'), ('Kinondoni', 'Kunduchi'),
('Kinondoni', 'Mabwepande'), ('Kinondoni', 'Magomeni'), ('Kinondoni', 'Makongo'), ('Kinondoni', 'Makumbusho'),
('Kinondoni', 'Mbezi Juu'), ('Kinondoni', 'Mikocheni'), ('Kinondoni', 'Mlalakuwa'), ('Kinondoni', 'Msasani'),
('Kinondoni', 'Mwananyamala'), ('Kinondoni', 'Ununio'), ('Kinondoni', 'Wazo'),
('Temeke', 'Azimio'), ('Temeke', 'Buza'), ('Temeke', 'Chamazi'), ('Temeke', 'Chang''ombe'),
('Temeke', 'Charambe'), ('Temeke', 'Keko'), ('Temeke', 'Kiburugwa'), ('Temeke', 'Kijichi'),
('Temeke', 'Kilakala'), ('Temeke', 'Kurasini'), ('Temeke', 'Makangarawe'), ('Temeke', 'Mbagala'),
('Temeke', 'Mbagala Kuu'), ('Temeke', 'Mianzini'), ('Temeke', 'Miburani'), ('Temeke', 'Mtoni'),
('Temeke', 'Sandali'), ('Temeke', 'Tandika'), ('Temeke', 'Temeke'), ('Temeke', 'Toangoma'),
('Temeke', 'Yombo Vituka'),
('Ubungo', 'Goba'), ('Ubungo', 'Kibamba'), ('Ubungo', 'Kimara'), ('Ubungo', 'Kwembe'),
('Ubungo', 'Mabibo'), ('Ubungo', 'Makuburi'), ('Ubungo', 'Makurumla'), ('Ubungo', 'Manzese'),
('Ubungo', 'Mbezi'), ('Ubungo', 'Mburahati'), ('Ubungo', 'Msigani'), ('Ubungo', 'Saranga'),
('Ubungo', 'Sinza'),
('Kigamboni', 'Kigamboni'), ('Kigamboni', 'Kibada'), ('Kigamboni', 'Kimbiji'), ('Kigamboni', 'Kisarawe II'),
('Kigamboni', 'Mjimwema'), ('Kigamboni', 'Pembamnazi'), ('Kigamboni', 'Somangila'), ('Kigamboni', 'Tungi')
ON CONFLICT (district, ward_name) DO NOTHING;
