-- TRANSFORM.DEV.FACT_GREEN_STREET_MARKET_FORECAST_BASE_TOP50_RAW — read-through of GS_MARKET_FORECAST_BASE_TOP50_RAW.
-- **Census CBSA:** see pretium-ai-dbt ``fact_green_street_market_forecast_base_top50_raw`` + ``ref_gs_market_cbsa``.

{{ config(
    alias='fact_green_street_market_forecast_base_top50_raw',
    materialized='view',
    tags=['transform', 'transform_dev', 'greenstreet', 'fact_green_street', 'forecast', 'observe_only'],
) }}

SELECT * FROM {{ source('green_street', 'gs_market_forecast_base_top50_raw') }}
