-- Slug: **partial_autocorrelation** (2) — per‑geo Pearson **(x_t, x_{t-2})** on ZILLOW CBSA `rent_current` (lag‑2 persistence vs AR(1)); pool summary row only.
-- Not true PACF(2); use with **autocorrelation** view for “AR vs longer memory” triage.
-- Target: ANALYTICS.DBT_DEV.QA_PARTIAL_AUTOCORRELATION_RENT_ZILLOW_CBSA
{{ config(
    materialized='view',
    alias='QA_PARTIAL_AUTOCORRELATION_RENT_ZILLOW_CBSA',
    tags=['analytics', 'qa', 'semantic_validation', 'partial_autocorrelation'],
) }}

WITH base AS (
    SELECT
        TO_VARCHAR(geo_id) AS geo_id,
        month_start,
        rent_current::DOUBLE AS x
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
      AND LOWER(TRIM(TO_VARCHAR(geo_level_code))) = 'cbsa'
),

lagged AS (
    SELECT
        geo_id,
        month_start,
        x,
        LAG(x, 2) OVER (PARTITION BY geo_id ORDER BY month_start) AS x_lag2
    FROM base
),

by_geo AS (
    SELECT
        geo_id,
        CORR(x, x_lag2) AS lag2_pearson,
        COUNT(*) AS n_pairs
    FROM lagged
    WHERE x_lag2 IS NOT NULL
    GROUP BY geo_id
    HAVING COUNT(*) >= 24
)

SELECT
    'ZILLOW' AS vendor_code,
    'cbsa' AS analysis_grain,
    COUNT(*)::BIGINT AS n_geos,
    MEDIAN(lag2_pearson) AS median_lag2_pearson,
    MIN(lag2_pearson) AS min_lag2_pearson,
    MAX(lag2_pearson) AS max_lag2_pearson
FROM by_geo
