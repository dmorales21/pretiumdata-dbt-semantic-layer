-- Slug: **feature_concept_parity_diff** (13) — time-aligned **mean absolute % error** (and level MAE) of FEATURE rent spine vs parent `CONCEPT_*` by `month_start` × vendor × grain.
-- Complements `QA_FEATURE_CONCEPT_ALIGNMENT` (row-level). Pass-through spine should drive **mape_pct** ≈ 0.
-- Target: ANALYTICS.DBT_DEV.QA_FEATURE_CONCEPT_PARITY_DIFF
{{ config(
    materialized='view',
    alias='QA_FEATURE_CONCEPT_PARITY_DIFF',
    tags=['analytics', 'qa', 'feature_development', 'feature_concept_parity_diff'],
) }}

WITH aligned AS (
    SELECT
        c.vendor_code,
        c.month_start,
        c.geo_level_code,
        c.rent_current::DOUBLE AS c_rent,
        f.rent_current::DOUBLE AS f_rent
    FROM {{ ref('concept_rent_market_monthly') }} AS c
    INNER JOIN {{ ref('feature_rent_market_monthly_spine') }} AS f
        ON c.vendor_code = f.vendor_code
       AND c.month_start = f.month_start
       AND c.geo_level_code = f.geo_level_code
       AND c.geo_id = f.geo_id
       AND COALESCE(TO_VARCHAR(c.metric_id_observe), '') = COALESCE(TO_VARCHAR(f.metric_id_observe), '')
    WHERE c.rent_current IS NOT NULL
      AND f.rent_current IS NOT NULL
)

SELECT
    vendor_code,
    month_start,
    geo_level_code,
    COUNT(*)::BIGINT AS n_pairs,
    AVG(ABS(f_rent - c_rent))::DOUBLE AS mae_level,
    AVG(ABS(f_rent - c_rent) / NULLIF(ABS(c_rent), 0))::DOUBLE AS mape_ratio,
    AVG(ABS(f_rent - c_rent) / NULLIF(ABS(c_rent), 0)) * 100.0::DOUBLE AS mape_pct
FROM aligned
GROUP BY 1, 2, 3
