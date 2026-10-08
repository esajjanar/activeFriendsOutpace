-- ============================================================
-- import_diagnostics
-- ============================================================
-- Captures a per-import breakdown of the Health Connect / HealthKit read
-- (SDK status, per-type permission state, raw read counts, dedup skips, a
-- broad 365-day "can we read any workout" probe, and a sample) so that a
-- "0 activities imported" result is debuggable off-device — the corporate
-- Pixel 9 has no ADB. The app writes one row per import; RLS restricts each
-- user to their own rows.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.import_diagnostics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  platform text,
  payload jsonb NOT NULL
);

CREATE INDEX IF NOT EXISTS import_diagnostics_user_time_idx
  ON public.import_diagnostics (user_id, created_at DESC);

ALTER TABLE public.import_diagnostics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "insert own import diagnostics"
  ON public.import_diagnostics FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "read own import diagnostics"
  ON public.import_diagnostics FOR SELECT TO authenticated
  USING (user_id = auth.uid());
