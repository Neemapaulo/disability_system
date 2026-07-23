-- ──────────────────────────────────────────────────────────
-- Notification tracking: when a report's status changes, mark
-- that the citizen should be notified.
--
-- This is the infrastructure for sending notifications. The
-- actual delivery (push via FCM, email, SMS, etc.) is handled
-- separately by a service that polls this table and sends.
-- ──────────────────────────────────────────────────────────

-- Track which citizens have been notified of which changes.
-- This allows resend logic and prevents duplicate notifications.
CREATE TABLE IF NOT EXISTS public.ripoti_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ripoti_id uuid NOT NULL REFERENCES public.ripoti(id) ON DELETE CASCADE,
  notification_type text NOT NULL, -- 'status_changed', 'comment_added'
  status_from text,
  status_to text,
  sent_at timestamptz,
  delivery_method text, -- 'realtime' (via supabase stream), 'push' (FCM), 'email', 'sms'
  delivery_status text DEFAULT 'pending', -- 'pending', 'sent', 'failed'
  error_message text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ripoti_notifications_ripoti_id_idx ON public.ripoti_notifications(ripoti_id);
CREATE INDEX ripoti_notifications_delivery_status_idx ON public.ripoti_notifications(delivery_status);
CREATE INDEX ripoti_notifications_created_at_idx ON public.ripoti_notifications(created_at DESC);

ALTER TABLE public.ripoti_notifications ENABLE ROW LEVEL SECURITY;

-- Citizens can see notifications for their own reports.
CREATE POLICY "Citizens see their own notifications" ON public.ripoti_notifications
FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.ripoti r
    WHERE r.id = ripoti_id AND r.user_id = auth.uid()
  )
);

-- Trigger: when a report's hali or maoni_ya_admin changes, log that the citizen
-- should be notified. Actual delivery is handled by a background service.
CREATE OR REPLACE FUNCTION public.queue_ripoti_notification()
RETURNS TRIGGER AS $$
BEGIN
  IF (OLD.hali IS DISTINCT FROM NEW.hali) THEN
    INSERT INTO public.ripoti_notifications
      (ripoti_id, notification_type, status_from, status_to)
    VALUES
      (NEW.id, 'status_changed', OLD.hali, NEW.hali);
  END IF;

  IF (OLD.maoni_ya_admin IS DISTINCT FROM NEW.maoni_ya_admin)
    AND NEW.maoni_ya_admin IS NOT NULL THEN
    INSERT INTO public.ripoti_notifications
      (ripoti_id, notification_type, status_from, status_to)
    VALUES
      (NEW.id, 'comment_added', NULL, NULL);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS queue_citizen_notification ON public.ripoti;
CREATE TRIGGER queue_citizen_notification
AFTER UPDATE ON public.ripoti
FOR EACH ROW
EXECUTE FUNCTION public.queue_ripoti_notification();

NOTIFY pgrst, 'reload schema';
