-- ──────────────────────────────────────────────────────────
-- Audit trail: track all changes to report status and admin comments.
--
-- Run this in the Supabase SQL Editor to create the history table and
-- automatic logging trigger. Writes one row per status or comment change,
-- with the admin who made the change, the new status, and a timestamp.
-- Helps answer "who closed this report and when" and gives the mobile
-- timeline screen a real history instead of just a current state.
-- ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.ripoti_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ripoti_id uuid NOT NULL REFERENCES public.ripoti(id) ON DELETE CASCADE,
  changed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  hali_old text,
  hali_new text,
  maoni_ya_admin_old text,
  maoni_ya_admin_new text,
  changed_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT at_least_one_change CHECK (
    hali_old IS DISTINCT FROM hali_new
    OR maoni_ya_admin_old IS DISTINCT FROM maoni_ya_admin_new
  )
);

CREATE INDEX ripoti_history_ripoti_id_idx ON public.ripoti_history(ripoti_id);
CREATE INDEX ripoti_history_changed_at_idx ON public.ripoti_history(changed_at DESC);
CREATE INDEX ripoti_history_changed_by_idx ON public.ripoti_history(changed_by);

ALTER TABLE public.ripoti_history ENABLE ROW LEVEL SECURITY;

-- History is append-only and anyone who can see a report can see its history.
CREATE POLICY "Anyone can view report history" ON public.ripoti_history
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.ripoti r WHERE r.id = ripoti_id
    AND (
      r.user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superuser')
      )
    )
  )
);

-- Trigger: log status or comment changes.
CREATE OR REPLACE FUNCTION public.log_ripoti_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Only log if something actually changed that matters.
  IF (OLD.hali IS DISTINCT FROM NEW.hali)
    OR (OLD.maoni_ya_admin IS DISTINCT FROM NEW.maoni_ya_admin) THEN
    INSERT INTO public.ripoti_history
      (ripoti_id, changed_by, hali_old, hali_new, maoni_ya_admin_old, maoni_ya_admin_new)
    VALUES
      (NEW.id, auth.uid(), OLD.hali, NEW.hali, OLD.maoni_ya_admin, NEW.maoni_ya_admin);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS ripoti_change_log ON public.ripoti;
CREATE TRIGGER ripoti_change_log
AFTER UPDATE ON public.ripoti
FOR EACH ROW
EXECUTE FUNCTION public.log_ripoti_change();

NOTIFY pgrst, 'reload schema';
