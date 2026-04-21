-- Slug: **cold_start_geo_report** (14) — months of history since **first non-null** `rent_current` for **ZILLOW** (tunable) on `concept_rent_market_monthly` (parent of rent FEATURE spine).
-- Target: ANALYTICS.DBT_DEV.QA_COLD_START_GEO_REPORT
{{ config(
    materialized='view',
    alias='QA_COLD_START_GEO_REPORT',
    tags=['analytics', 'qa', 'feature_development', 'cold_start_geo_report'],
) }}

WITH first_obs AS (
    SELECT
        vendor_code,
        LOWER(TRIM(TO_VARCHAR(geo_level_code))) AS geo_level_code,
        TO_VARCHAR(geo_id) AS geo_id,
        MIN(month_start) AS first_month_with_rent
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
    GROUP BY vendor_code, LOWER(TRIM(TO_VARCHAR(geo_level_code))), TO_VARCHAR(geo_id)
),

last_obs AS (
    SELECT
        vendor_code,
        LOWER(TRIM(TO_VARCHAR(geo_level_code))) AS geo_level_code,
        TO_VARCHAR(geo_id) AS geo_id,
        MAX(month_start) AS last_month_with_rent
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
    GROUP BY vendor_code, LOWER(TRIM(TO_VARCHAR(geo_level_code))), TO_VARCHAR(geo_id)
)

SELECT
    f.vendor_code,
    f.geo_level_code,
    f.geo_id,
    f.first_month_with_rent,
    l.last_month_with_rent,
    DATEDIFF('month', f.first_month_with_rent, l.last_month_with_rent)::INTEGER AS months_of_history_inclusive,
    (DATEDIFF('month', f.first_month_with_rent, l.last_month_with_rent) < 24) AS is_cold_start_lt_24m
FROM first_obs AS f
INNER JOIN last_obs AS l
    ON f.vendor_code = l.vendor_code
   AND f.geo_level_code = l.geo_level_code
   AND f.geo_id = l.geo_id
