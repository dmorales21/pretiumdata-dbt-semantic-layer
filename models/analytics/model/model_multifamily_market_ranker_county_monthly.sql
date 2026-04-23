-- MODEL: Multifamily Market Ranker — county × month read surface (purpose-named contract layer).
-- Pass-through of **FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY** until Pretium score / phase / flag MODEL_* logic lands.
{{ config(
    materialized='view',
    alias='model_multifamily_market_ranker_county_monthly',
    tags=['analytics', 'model', 'multifamily_market', 'mfr_ranker'],
) }}

SELECT
    concept_code,
    vendor_code,
    month_start,
    geo_level_code,
    geo_id,
    cbsa_id,
    state_fips,
    rent_mom_pct_change,
    avg_asking_rent,
    avg_concession_mom_pct_change,
    median_market_ppsf,
    market_phase,
    median_months_to_completion,
    units_garden,
    units_under_construction,
    total_households,
    pct_pre_1980,
    renter_share,
    pct_25_44,
    rent_burden_30_plus_share,
    unemployment_rate,
    pretium_score,
    custom_score,
    rent_trend_flag,
    dbt_updated_at
FROM {{ ref('feature_multifamily_market_ranker_monthly_spine') }}
