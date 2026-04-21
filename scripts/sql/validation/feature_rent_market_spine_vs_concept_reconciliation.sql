-- Pilot A reconciliation (Q): pass-through FEATURE spine vs MART semantic CONCEPT row counts and key grain.
-- Tolerance T: default 0 row-count delta when feature is SELECT * from concept (same grain).
--
-- Run (adjust database/schema for your Snowflake env):
--   snowsql -c pretium -f scripts/sql/validation/feature_rent_market_spine_vs_concept_reconciliation.sql
--
-- Canonical FQNs (this repo): TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY, ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY.
-- Override literals if your profile resolves different database names.

-- ---------------------------------------------------------------------------
-- 1) Row counts (failure = ABS(delta) > T; T = 0 for identical pass-through)
-- ---------------------------------------------------------------------------
WITH c AS (
    SELECT COUNT(*) AS n FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
),
f AS (
    SELECT COUNT(*) AS n FROM ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY
)
SELECT
    'PILOT_A:rowcount_concept_vs_feature' AS check_name,
    c.n AS concept_rows,
    f.n AS feature_rows,
    ABS(c.n - f.n) AS abs_delta,
    CASE WHEN ABS(c.n - f.n) = 0 THEN 'PASS' ELSE 'FAIL' END AS vs_tolerance_t0
FROM c CROSS JOIN f;

-- ---------------------------------------------------------------------------
-- 2) Grain key overlap (sample: should be 0 missing keys if pass-through)
-- ---------------------------------------------------------------------------
SELECT
    'PILOT_A:keys_in_concept_not_in_feature' AS check_name,
    COUNT(*) AS failure_rows
FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY c
WHERE NOT EXISTS (
    SELECT 1
    FROM ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY f
    WHERE f.vendor_code = c.vendor_code
      AND f.month_start = c.month_start
      AND f.geo_level_code = c.geo_level_code
      AND f.geo_id = c.geo_id
);
