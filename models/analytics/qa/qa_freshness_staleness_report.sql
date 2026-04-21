-- Slug: **freshness_staleness_report** (13) — max period end by vendor × concept surface.
-- **Excluded:** `concept_avm_market_monthly` (Cherre) — `month_start` is snapshot-aligned, not an observation period;
-- staleness months-behind would be misleading. See **docs/reference/CONTRACT_RENT_AVM_VALUATION.md**.
-- Target: ANALYTICS.DBT_DEV.QA_FRESHNESS_STALENESS_REPORT
{{ config(
    materialized='view',
    alias='QA_FRESHNESS_STALENESS_REPORT',
    tags=['analytics', 'qa', 'semantic_validation', 'freshness_staleness_report'],
) }}

{% set market_concepts = [
    ('concept_rent_market_monthly', 'month_start'),
    ('concept_rent_property_monthly', 'month_start'),
    ('concept_occupancy_market_monthly', 'month_start'),
    ('concept_employment_market_monthly', 'month_start'),
    ('concept_unemployment_market_monthly', 'month_start'),
    ('concept_home_price_market_monthly', 'month_start'),
    ('concept_listings_market_monthly', 'month_start'),
    ('concept_valuation_market_monthly', 'month_start'),
    ('concept_transactions_market_monthly', 'month_start'),
    ('concept_delinquency_market_monthly', 'month_start'),
    ('concept_migration_market_annual', 'month_start'),
] %}

{% for model_name, time_col in market_concepts %}
SELECT
    '{{ model_name }}' AS concept_object,
    vendor_code,
    MAX({{ time_col }}) AS max_period_start,
    DATEDIFF(
        'month',
        MAX({{ time_col }}),
        DATE_TRUNC('month', CURRENT_DATE())::DATE
    )::INTEGER AS months_behind_period_month,
    DATEDIFF('day', MAX({{ time_col }}), CURRENT_DATE())::INTEGER AS days_behind_calendar
FROM {{ ref(model_name) }}
WHERE vendor_code IS NOT NULL
GROUP BY 1, 2
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
