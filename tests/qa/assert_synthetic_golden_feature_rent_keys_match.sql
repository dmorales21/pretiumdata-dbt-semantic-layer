-- Slug: **synthetic_fixture_replay** (16) — fails when any seed row has `use_in_test=true` and FEATURE rent spine ≠ `expected_rent` (join on full grain).
-- Populate `seeds/analytics/qa/synthetic_golden_feature_rent_keys.csv` with known-good rows after `dbt run` + spot-check in Snowflake.
{{ config(severity='error') }}

WITH k AS (
    SELECT
        TRIM(TO_VARCHAR(use_in_test)) AS use_in_test,
        TRIM(TO_VARCHAR(vendor_code)) AS vendor_code,
        TRY_TO_DATE(TO_VARCHAR(month_start)) AS month_start,
        TRIM(TO_VARCHAR(geo_level_code)) AS geo_level_code,
        TRIM(TO_VARCHAR(geo_id)) AS geo_id,
        TRIM(TO_VARCHAR(metric_id_observe)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(expected_rent)) AS expected_rent
    FROM {{ ref('synthetic_golden_feature_rent_keys') }}
    WHERE UPPER(TRIM(TO_VARCHAR(use_in_test))) IN ('TRUE', '1', 'T')
)

SELECT
    k.*,
    f.rent_current AS actual_rent_current
FROM k
LEFT JOIN {{ ref('feature_rent_market_monthly_spine') }} AS f
    ON f.vendor_code = k.vendor_code
   AND f.month_start = k.month_start
   AND f.geo_level_code = k.geo_level_code
   AND f.geo_id = k.geo_id
   AND COALESCE(TO_VARCHAR(f.metric_id_observe), '') = COALESCE(k.metric_id_observe, '')
WHERE k.expected_rent IS NOT NULL
  AND (
      f.rent_current IS NULL
      OR ABS(f.rent_current::DOUBLE - k.expected_rent::DOUBLE) > 0.000001
  )
