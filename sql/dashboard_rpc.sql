/*
Project: SecurityLog-Cleaning
Purpose: Create RPC functions for the Honeypot Dashboard
Version: 1.0
Date: 2026-02-07
*/

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
    SELECT * FROM honeypot_logs
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
  FROM honeypot_logs
  WHERE event_time >= start_ts
    AND event_time <= end_ts
  GROUP BY country_code
  ORDER BY attack_count DESC;
$$;