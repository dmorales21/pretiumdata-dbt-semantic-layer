-- Slug: **seasonal_decomposition** (3) — **month‑of‑year** between‑metro dispersion of ZILLOW CBSA `rent_current` (STL substitute: “how strong is calendar seasonality across markets this month?”).
-- Target: ANALYTICS.DBT_DEV.QA_SEASONAL_DECOMPOSITION_RENT_ZILLOW_CBSA
{{ config(
    materialized='view',
    alias='QA_SEASONAL_DECOMPOSITION_RENT_ZILLOW_CBSA',
    tags=['analytics', 'qa', 'semantic_validation', 'seasonal_decomposition'],
) }}

WITH base AS (
    SELECT
        EXTRACT(MONTH FROM month_start)::INTEGER AS calendar_month,
        month_start,
        TO_VARCHAR(geo_id) AS geo_id,
        rent_current::DOUBLE AS x
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
      AND LOWER(TRIM(TO_VARCHAR(geo_level_code))) = 'cbsa'
)

SELECT
    calendar_month,
    COUNT(DISTINCT geo_id)::BIGINT AS n_cbsa_geos,
    COUNT(*)::BIGINT AS n_obs,
    AVG(x) AS mean_rent_across_geos,
    STDDEV_SAMP(x) AS stddev_rent_across_geos_this_month,
    MEDIAN(x) AS median_rent_across_geos
FROM base
GROUP BY calendar_month
ORDER BY calendar_month
