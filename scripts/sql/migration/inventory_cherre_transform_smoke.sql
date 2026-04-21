-- Cherre — TRANSFORM.CHERRE smoke inventory (run in Snowflake worksheet; adjust role/warehouse).
-- Purpose: confirm promoted vendor objects exist before dbt source() cutover or corridor stock builds.
-- Baseline count note: ~14 tables in TRANSFORM.CHERRE (see MIGRATION_BASELINE_RAW_TRANSFORM.md); account may differ.

SHOW TABLES IN SCHEMA TRANSFORM.CHERRE;

-- Row presence smokes (comment in/out; large tables use LIMIT / SAMPLE in separate worksheet if needed).
-- SELECT 'TAX_ASSESSOR_V2' AS t, COUNT(*) AS c FROM TRANSFORM.CHERRE.TAX_ASSESSOR_V2 SAMPLE (100000 ROWS);
-- SELECT 'USA_AVM_V2' AS t, COUNT(*) AS c FROM TRANSFORM.CHERRE.USA_AVM_V2 SAMPLE (100000 ROWS);
-- SELECT 'MLS_LISTING_EVENTS' AS t, COUNT(*) AS c FROM TRANSFORM.CHERRE.MLS_LISTING_EVENTS SAMPLE (100000 ROWS);
