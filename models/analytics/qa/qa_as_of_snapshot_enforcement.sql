-- Slug: **as_of_snapshot_enforcement** (4) — **no future `month_start`** on key market FEATURE / CONCEPT surfaces (hard guard for time-travel bugs).
-- Does **not** prove immutability under late-arriving facts (needs versioned facts + audit); extend with `dbt_updated_at` audits separately.
-- Target: ANALYTICS.DBT_DEV.QA_AS_OF_SNAPSHOT_ENFORCEMENT
{{ config(
    materialized='view',
    alias='QA_AS_OF_SNAPSHOT_ENFORCEMENT',
    tags=['analytics', 'qa', 'feature_development', 'as_of_snapshot_enforcement'],
) }}

{% set checks = [
    ('concept_rent_market_monthly', 'CONCEPT_RENT_MARKET_MONTHLY'),
    ('feature_rent_market_monthly_spine', 'FEATURE_RENT_MARKET_MONTHLY_SPINE'),
    ('concept_employment_market_monthly', 'CONCEPT_EMPLOYMENT_MARKET_MONTHLY'),
    ('concept_unemployment_market_monthly', 'CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY'),
    ('concept_listings_market_monthly', 'CONCEPT_LISTINGS_MARKET_MONTHLY'),
    ('concept_home_price_market_monthly', 'CONCEPT_HOME_PRICE_MARKET_MONTHLY'),
] %}

{% for ref_model, label in checks %}
SELECT
    '{{ label }}' AS object_label,
    '{{ ref_model }}' AS dbt_model,
    COUNT_IF(month_start > DATE_TRUNC('month', CURRENT_TIMESTAMP())::DATE)::BIGINT AS n_future_month_start_rows,
    COUNT(*)::BIGINT AS n_total_rows
FROM {{ ref(ref_model) }}
{% if not loop.last %}
UNION ALL
{% endif %}
{% endfor %}
