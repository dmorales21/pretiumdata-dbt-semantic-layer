-- Slug: **series_collision_detection** (7) — rows where the natural panel key is duplicated (bad lag / double counts).
-- Target: ANALYTICS.DBT_DEV.QA_SERIES_COLLISION_DETECTION
{{ config(
    materialized='view',
    alias='QA_SERIES_COLLISION_DETECTION',
    tags=['analytics', 'qa', 'semantic_validation', 'series_collision_detection'],
) }}

{% set checks = [
    'concept_rent_market_monthly',
    'concept_listings_market_monthly',
    'concept_home_price_market_monthly',
    'concept_valuation_market_monthly',
    'concept_unemployment_market_monthly',
    'concept_delinquency_market_monthly',
] %}

{% for model_name in checks %}
SELECT
    '{{ model_name }}' AS concept_object,
    vendor_code,
    TO_VARCHAR(metric_id_observe) AS metric_id_observe,
    LOWER(TRIM(TO_VARCHAR(geo_level_code))) AS analysis_grain,
    TO_VARCHAR(geo_id) AS geo_id,
    month_start,
    COUNT(*)::BIGINT AS duplicate_row_count
FROM {{ ref(model_name) }}
WHERE vendor_code IS NOT NULL
GROUP BY
    vendor_code,
    metric_id_observe,
    LOWER(TRIM(TO_VARCHAR(geo_level_code))),
    TO_VARCHAR(geo_id),
    month_start
HAVING COUNT(*) > 1
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
