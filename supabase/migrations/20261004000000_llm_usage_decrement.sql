-- ============================================================
-- decrement_llm_usage
-- ============================================================
-- Rolls back a claimed LLM budget slot when a Gemini call does not
-- actually succeed (HTTP error, timeout, or rejected output). The
-- Edge Functions claim a slot atomically via increment_llm_usage()
-- BEFORE calling Gemini (to prevent overspend races), then call this
-- to release the slot on failure — so failed/404 calls never
-- permanently burn the daily budget.
-- ============================================================

CREATE OR REPLACE FUNCTION public.decrement_llm_usage()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.llm_usage
    SET call_count = GREATEST(call_count - 1, 0)
    WHERE date = CURRENT_DATE;
END; $$;
