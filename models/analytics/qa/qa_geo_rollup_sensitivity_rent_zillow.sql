-- Slug: **geo_rollup_sensitivity** (11) — **ZILLOW** month alignment: ZIP `rent_current` vs CBSA `rent_current` where `concept_rent_market_monthly.cbsa_id` matches CBSA `geo_id` (spotlights rollup / weight mismatch).
-- Requires non-null `cbsa_id` on ZIP rows; sparse matches are expected in some accounts.
-- Target: ANALYTICS.DBT_DEV.QA_GEO_ROLLUP_SENSITIVITY_RENT_ZILLOW
{{ config(
    materialized='view',
    alias='QA_GEO_ROLLUP_SENSITIVITY_RENT_ZILLOW',
    tags=['analytics', 'qa', 'feature_development', 'geo_rollup_sensitivity'],
) }}

WITH zip AS (
    SELECT
        month_start,
        LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_join,
        rent_current::DOUBLE AS rent_zip
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND LOWER(TRIM(TO_VARCHAR(geo_level_code))) = 'zip'
      AND rent_current IS NOT NULL
      AND cbsa_id IS NOT NULL
),

cbsa AS (
    SELECT
        month_start,
        LPAD(TRIM(TO_VARCHAR(geo_id)), 5, '0') AS cbsa_join,
        rent_current::DOUBLE AS rent_cbsa
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND LOWER(TRIM(TO_VARCHAR(geo_level_code))) = 'cbsa'
      AND rent_current IS NOT NULL
),

paired AS (
    SELECT
        z.month_start,
        z.cbsa_join,
        z.rent_zip,
        c.rent_cbsa
    FROM zip AS z
    INNER JOIN cbsa AS c
        ON z.month_start = c.month_start
       AND z.cbsa_join = c.cbsa_join
)

SELECT
    month_start,
    CORR(rent_zip, rent_cbsa) AS pearson_zip_vs_cbsa_rent,
    AVG(ABS(rent_zip - rent_cbsa))::DOUBLE AS mae_zip_minus_cbsa,
    MAX(ABS(rent_zip - rent_cbsa))::DOUBLE AS max_abs_zip_minus_cbsa,
    COUNT(*)::BIGINT AS n_zip_cbsa_pairs
FROM paired
GROUP BY month_start
