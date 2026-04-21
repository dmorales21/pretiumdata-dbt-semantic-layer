-- Slug: **autocorrelation** (1) — per‑geo lag‑1 Pearson on **ZILLOW** × **cbsa** × `rent_current` (materialized counterpart to `scripts/sql/validation/acf_lag1_concept_rent_zillow_cbsa.sql` slice B).
-- Target: ANALYTICS.DBT_DEV.QA_AUTOCORRELATION_RENT_ZILLOW_CBSA_SUMMARY
{{ config(
    materialized='view',
    alias='QA_AUTOCORRELATION_RENT_ZILLOW_CBSA_SUMMARY',
    tags=['analytics', 'qa', 'semantic_validation', 'autocorrelation'],
) }}

WITH base AS (
    SELECT
        vendor_code,
        LOWER(TRIM(TO_VARCHAR(geo_level_code))) AS analysis_grain,
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
        vendor_code,
        analysis_grain,
        geo_id,
        month_start,
        x,
        LAG(x) OVER (PARTITION BY vendor_code, analysis_grain, geo_id ORDER BY month_start) AS x_lag1
    FROM base
),

by_geo AS (
    SELECT
        vendor_code,
        analysis_grain,
        geo_id,
        CORR(x, x_lag1) AS acf_lag1_pearson,
        COUNT(*) AS n_pairs
    FROM lagged
    WHERE x_lag1 IS NOT NULL
    GROUP BY vendor_code, analysis_grain, geo_id
    HAVING COUNT(*) >= 24
)

SELECT
    vendor_code,
    analysis_grain,
    geo_id,
    acf_lag1_pearson,
    n_pairs
FROM by_geo
