-- TRANSFORM.DEV.FACT_GREEN_STREET_MACRO_MARKET_TOP50_RAW — read-through of SOURCE_PROD.GREEN_STREET.GS_MACRO_MARKET_TOP50_RAW.
-- **Census CBSA:** pretium-ai-dbt joins ``ref('ref_gs_market_cbsa')`` on ``V:market_id`` (TRANSFORM_PROD.REF — not declared here).
-- Reuse that model in the EDW stack or add a TRANSFORM.REF mirror before enriching in this project.

{{ config(
    alias='fact_green_street_macro_market_top50_raw',
    materialized='view',
    tags=['transform', 'transform_dev', 'greenstreet', 'fact_green_street', 'macro', 'observe_only'],
) }}

SELECT * FROM {{ source('green_street', 'gs_macro_market_top50_raw') }}
