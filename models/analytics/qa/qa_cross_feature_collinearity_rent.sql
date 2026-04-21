-- Slug: **cross_feature_collinearity** (8) — distribution of **within-geo** Pearson **rent_current** vs **rent_historical** (FEATURE spine), then pooled summary by `vendor_code` × `geo_level_code`.
-- Target: ANALYTICS.DBT_DEV.QA_CROSS_FEATURE_COLLINEARITY_RENT
{{ config(
    materialized='view',
    alias='QA_CROSS_FEATURE_COLLINEARITY_RENT',
    tags=['analytics', 'qa', 'feature_development', 'cross_feature_collinearity'],
) }}

WITH by_geo AS (
    SELECT
        vendor_code,
        geo_level_code,
        geo_id,
        CORR(rent_current::DOUBLE, rent_historical::DOUBLE) AS pearson_current_vs_historical,
        COUNT(*)::BIGINT AS n_months
    FROM {{ ref('feature_rent_market_monthly_spine') }}
    WHERE rent_current IS NOT NULL
      AND rent_historical IS NOT NULL
    GROUP BY vendor_code, geo_level_code, geo_id
    HAVING COUNT(*) >= 24
)

SELECT
    vendor_code,
    geo_level_code,
    COUNT(*)::BIGINT AS n_geos,
    MEDIAN(pearson_current_vs_historical) AS median_pearson,
    MIN(pearson_current_vs_historical) AS min_pearson,
    MAX(pearson_current_vs_historical) AS max_pearson
FROM by_geo
GROUP BY vendor_code, geo_level_code
