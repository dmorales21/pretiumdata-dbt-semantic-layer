-- ANALYTICS.DBT_* — typed read surface for market-rent cohort math (z-scores, vs-market ratio) on top of
-- TRANSFORM.DEV `concept_rent_market_monthly`. Extend here; do not duplicate vendor unions in FACT branches.
-- Consumer contract: **docs/reference/CONTRACT_RENT_AVM_VALUATION.md** (FEATURE = pass-through + cohort stats only).
-- Relation name: FEATURE_RENT_MARKET_MONTHLY (alias). Re-run `dbt run -s feature_rent_market_monthly_spine`
-- after changing alias; drop legacy FEATURE_RENT_MARKET_MONTHLY_SPINE in Snowflake if it still exists.
{{ config(
    materialized='view',
    alias='feature_rent_market_monthly',
    tags=['analytics', 'feature', 'rent', 'rent_market'],
) }}

SELECT
    concept_code,
    vendor_code,
    month_start,
    geo_level_code,
    geo_id,
    cbsa_id,
    county_fips,
    state_fips,
    rent_current,
    rent_historical,
    rent_forecast,
    metric_id_observe,
    metric_id_forecast,
    forecast_month_start
FROM {{ ref('concept_rent_market_monthly') }}
