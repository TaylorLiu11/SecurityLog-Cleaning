/*
Project: SecurityLog-Cleaning
Purpose: Setup core table for the project.
Version: 1.0
Date: 2026-02-06
*/

-- 1. Create table
CREATE TABLE public.honeypot_logs (
  id SERIAL PRIMARY KEY,                -- Unique identifier
  event_time TIMESTAMPTZ NOT NULL,      -- Timestamp (UTC) of the attack
  source_ip TEXT NOT NULL,              -- Masked source IP (PII masking)
  protocol TEXT,                        -- Protocol (TCP/UDP)
  target_port INTEGER,                  -- Destination port of the attack
  country_code CHAR(2),                 -- ISO country code (2 chars)
  risk_level TEXT,                      -- Categorized risk level (High/Low/Unknown)
  created_at TIMESTAMPTZ DEFAULT NOW()  -- When insert into DB
);

-- 2. Query optimization to prevent full table scan
-- Create index: time-based queries
CREATE INDEX idx_risk_level ON public.honeypot_logs(risk_level);
-- Create index: risk-level filtering
CREATE INDEX idx_event_time ON public.honeypot_logs(event_time);