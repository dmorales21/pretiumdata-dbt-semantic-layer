-- ANALYTICS.DBT_DEV.ESTIMATE_MULTIFAMILY_MARKET_RANKER_SCORE_POINT_COUNTY — point read surface (placeholder intervals until forecast contracts exist). Reads **MODEL_MULTIFAMILY_MARKET_RANKER_COUNTY_MONTHLY**.
{{ config(
    materialized='view',
    alias='estimate_multifamily_market_ranker_score_point_county',
    tags=['analytics', 'estimate', 'multifamily_market', 'mfr_ranker'],
) }}

SELECT
    concept_code,
    vendor_code,
    month_start,
    geo_level_code,
    geo_id,
    cbsa_id,
    state_fips,
    pretium_score AS pretium_score_point,
    custom_score AS custom_score_point,
    CAST(NULL AS DOUBLE) AS pretium_score_interval_lower,
    CAST(NULL AS DOUBLE) AS pretium_score_interval_upper,
    CAST(NULL AS DOUBLE) AS custom_score_interval_lower,
    CAST(NULL AS DOUBLE) AS custom_score_interval_upper,
    dbt_updated_at
FROM {{ ref('model_multifamily_market_ranker_county_monthly') }}
