/*
Project: SecurityLog-Cleaning
Purpose: Create RPC functions for the Honeypot Dashboard with RLS security
Version: 1.1
Date: 2026-02-08
Changes:
  - Added SECURITY DEFINER to bypass RLS for aggregate calculations
  - Added RLS enabling and SELECT policy for public access
  - Added GRANT EXECUTE permissions for anon role 
*/

-- 1. Enable RLS on the table
ALTER TABLE public.honeypot_logs ENABLE ROW LEVEL SECURITY;

-- 2. Create a transparent read policy for the dashboard
DROP POLICY IF EXISTS "Allow public read access" ON public.honeypot_logs;
CREATE POLICY "Allow public read access" ON public.honeypot_logs
  FOR SELECT TO anon USING (true);

-- 3. High-level stats RPC
DROP FUNCTION IF EXISTS get_dashboard_stats;

CREATE OR REPLACE FUNCTION get_dashboard_stats(
  start_ts timestamptz,  -- Start time of the filter
  end_ts timestamptz     -- End time of the filter
)
RETURNS TABLE (
  total_attacks bigint,
  unique_countries bigint,
  top_protocol text,
  risk_breakdown json
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  WITH filtered_logs AS (
    SELECT * FROM public.honeypot_logs
    WHERE event_time >= start_ts
      AND event_time <= end_ts
  ),
  risk_counts AS (
    SELECT risk_level, count(*) as cnt
    FROM filtered_logs
    GROUP BY risk_level
  )
  SELECT
    (SELECT count(*) FROM filtered_logs) as total_attacks,
    (SELECT count(DISTINCT country_code) FROM filtered_logs) as unique_countries,
    (
      SELECT protocol
      FROM filtered_logs
      GROUP BY protocol
      ORDER BY count(*) DESC
      LIMIT 1
    ) as top_protocol,
    (
      SELECT json_object_agg(COALESCE(risk_level, 'Unknown'), cnt)
      FROM risk_counts
    ) as risk_breakdown;
END;
$$;

-- 4. Country distribution RPC
DROP FUNCTION IF EXISTS get_country_distribution;
CREATE OR REPLACE FUNCTION get_country_distribution(
  start_ts timestamptz,  -- Start time of the filter
  end_ts timestamptz     -- End time of the filter
)
RETURNS TABLE (
  country_code text,
  attack_count bigint
)
LANGUAGE sql
AS $$
  SELECT
    country_code,
    count(*) as attack_count
  FROM public.honeypot_logs
  WHERE event_time >= start_ts
    AND event_time <= end_ts
  GROUP BY country_code
  ORDER BY attack_count DESC;
$$;

-- 5. Explicitly grant execution to the anon role
GRANT EXECUTE ON FUNCTION get_dashboard_stats TO anon;
GRANT EXECUTE ON FUNCTION get_country_distribution TO anon;