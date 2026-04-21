-- Slug: **partition_rowcount_regression** (14) — **current** row counts by vendor × grain (baseline for %‑change alerts between runs).
-- Pair two Snowflake snapshots of this view (or export CSV) to detect join/filter regressions; dbt does not retain history here.
-- Target: ANALYTICS.DBT_DEV.QA_PARTITION_ROWCOUNT_REGRESSION
{{ config(
    materialized='view',
    alias='QA_PARTITION_ROWCOUNT_REGRESSION',
    tags=['analytics', 'qa', 'semantic_validation', 'partition_rowcount_regression'],
) }}

{% set parts = [
    'concept_rent_market_monthly',
    'concept_rent_property_monthly',
    'concept_occupancy_market_monthly',
    'concept_employment_market_monthly',
    'concept_unemployment_market_monthly',
    'concept_home_price_market_monthly',
    'concept_listings_market_monthly',
    'concept_avm_market_monthly',
    'concept_valuation_market_monthly',
    'concept_transactions_market_monthly',
    'concept_delinquency_market_monthly',
    'concept_migration_market_annual',
] %}

{% for model_name in parts %}
SELECT
    'CURRENT_SNAPSHOT' AS report_type,
    '{{ model_name }}' AS concept_object,
    vendor_code,
    LOWER(TRIM(TO_VARCHAR(geo_level_code))) AS analysis_grain,
    COUNT(*)::BIGINT AS row_count,
    COUNT(DISTINCT TO_VARCHAR(geo_id))::BIGINT AS n_geos,
    COUNT(DISTINCT TO_VARCHAR(metric_id_observe))::BIGINT AS n_metric_observe
FROM {{ ref(model_name) }}
WHERE vendor_code IS NOT NULL
GROUP BY 1, 2, 3, 4
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
