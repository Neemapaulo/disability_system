-- ──────────────────────────────────────────────────────────
-- 1. PROFILES TABLE
-- Extends Supabase Auth users with custom fields
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
    id                 UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email              TEXT UNIQUE NOT NULL,
    full_name          TEXT,
    phone_number       TEXT,
    mkoa               TEXT DEFAULT 'Dar es Salaam',
    wilaya             TEXT,
    secret_question    TEXT,
    secret_answer      TEXT,
    role               TEXT DEFAULT 'citizen', -- 'citizen', 'admin'
    managed_mkoa       TEXT,
    managed_wilaya      TEXT,
    managed_kata        TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW(),
    updated_at         TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ──────────────────────────────────────────────────────────
-- 2. RIPOTI TABLE ENHANCEMENTS
-- ──────────────────────────────────────────────────────────
-- Assuming ripoti table already exists, we ensure these columns are present
ALTER TABLE public.ripoti ADD COLUMN IF NOT EXISTS kata TEXT;
ALTER TABLE public.ripoti ADD COLUMN IF NOT EXISTS eneo_jina TEXT;
ALTER TABLE public.ripoti ADD COLUMN IF NOT EXISTS solved_at TIMESTAMPTZ;

-- ──────────────────────────────────────────────────────────
-- 3. MAP VIEW (Filtering Solved Reports)
-- ──────────────────────────────────────────────────────────
-- Solved reports stay for 1 month
CREATE OR REPLACE VIEW active_map_reports AS
SELECT *
FROM public.ripoti
WHERE hali != 'imekamilika'
   OR (hali = 'imekamilika' AND solved_at > NOW() - INTERVAL '1 month');

-- ──────────────────────────────────────────────────────────
-- 4. AUTOMATIC PROFILE CREATION
-- ──────────────────────────────────────────────────────────
-- Trigger to create profile record when a new user signs up via Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, phone_number, mkoa, wilaya, secret_question, secret_answer, role)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'phone_number',
        NEW.raw_user_meta_data->>'mkoa',
        NEW.raw_user_meta_data->>'wilaya',
        NEW.raw_user_meta_data->>'secret_question',
        NEW.raw_user_meta_data->>'secret_answer',
        COALESCE(NEW.raw_user_meta_data->>'role', 'citizen')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
