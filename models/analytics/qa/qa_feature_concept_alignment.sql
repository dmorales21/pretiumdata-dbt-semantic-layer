-- Slug: **feature_concept_alignment** (15) — row-level join **FEATURE** rent spine vs **CONCEPT** rent for overlap keys; exposes `abs_delta` on `rent_current`.
-- Target: ANALYTICS.DBT_DEV.QA_FEATURE_CONCEPT_ALIGNMENT
{{ config(
    materialized='view',
    alias='QA_FEATURE_CONCEPT_ALIGNMENT',
    tags=['analytics', 'qa', 'semantic_validation', 'feature_concept_alignment'],
) }}

SELECT
    c.vendor_code,
    c.month_start,
    c.geo_level_code,
    c.geo_id,
    c.metric_id_observe,
    c.rent_current AS concept_rent_current,
    f.rent_current AS feature_rent_current,
    ABS(COALESCE(f.rent_current, 0) - COALESCE(c.rent_current, 0))::DOUBLE AS abs_delta
FROM {{ ref('concept_rent_market_monthly') }} AS c
INNER JOIN {{ ref('feature_rent_market_monthly_spine') }} AS f
    ON c.vendor_code = f.vendor_code
   AND c.month_start = f.month_start
   AND c.geo_level_code = f.geo_level_code
   AND c.geo_id = f.geo_id
   AND COALESCE(TO_VARCHAR(c.metric_id_observe), '') = COALESCE(TO_VARCHAR(f.metric_id_observe), '')
