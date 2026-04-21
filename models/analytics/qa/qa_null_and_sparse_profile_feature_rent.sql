-- Slug: **null_and_sparse_profile** (6) — per **(vendor_code, geo_level_code, geo_id)** panel density on `FEATURE_RENT_MARKET_MONTHLY`: months present, null rate on `rent_current`, zero-variance flag.
-- Extend the same pattern to other FEATURE families as they stabilize.
-- Target: ANALYTICS.DBT_DEV.QA_NULL_AND_SPARSE_PROFILE_FEATURE_RENT
{{ config(
    materialized='view',
    alias='QA_NULL_AND_SPARSE_PROFILE_FEATURE_RENT',
    tags=['analytics', 'qa', 'feature_development', 'null_and_sparse_profile'],
) }}

WITH g AS (
    SELECT
        vendor_code,
        geo_level_code,
        geo_id,
        COUNT(*)::BIGINT AS n_months,
        COUNT_IF(rent_current IS NULL)::BIGINT AS n_null_rent_current,
        VAR_POP(rent_current::DOUBLE) AS var_pop_rent_current
    FROM {{ ref('feature_rent_market_monthly_spine') }}
    GROUP BY vendor_code, geo_level_code, geo_id
)

SELECT
    vendor_code,
    geo_level_code,
    geo_id,
    n_months,
    n_null_rent_current,
    (n_null_rent_current::DOUBLE / NULLIF(n_months, 0)) AS null_rent_current_rate,
    (var_pop_rent_current IS NULL OR var_pop_rent_current = 0) AS zero_variance_rent_current,
    (n_months < 24) AS cold_start_lt_24_months
FROM g
