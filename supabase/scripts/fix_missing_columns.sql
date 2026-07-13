-- ─────────────────────────────────────────────────────────────
-- MKMU SCHEMA REPAIR: Add Missing IPI Columns
-- Run this if you see "column frequency_count does not exist"
-- ─────────────────────────────────────────────────────────────

-- 1. Add IPI Metadata Columns to 'ripoti'
ALTER TABLE ripoti
ADD COLUMN IF NOT EXISTS frequency_count INT DEFAULT 1,
ADD COLUMN IF NOT EXISTS severity_weight DECIMAL(3, 2) DEFAULT 1.0,
ADD COLUMN IF NOT EXISTS priority_score DECIMAL(5, 2) DEFAULT 0.0;

-- 2. Ensure IPI Scoring Function exists
CREATE OR REPLACE FUNCTION calculate_ipi_score()
RETURNS TRIGGER AS $$
BEGIN
    NEW.priority_score := (0.40 * NEW.frequency_count) + (0.35 * NEW.severity_weight);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Ensure Trigger is attached
DROP TRIGGER IF EXISTS trigger_update_ipi ON ripoti;
CREATE TRIGGER trigger_update_ipi
BEFORE INSERT OR UPDATE ON ripoti
FOR EACH ROW EXECUTE FUNCTION calculate_ipi_score();

-- 4. Success Check
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'ripoti' AND column_name IN ('frequency_count', 'severity_weight', 'priority_score');
