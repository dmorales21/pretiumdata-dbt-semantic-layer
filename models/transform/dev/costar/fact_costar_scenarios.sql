-- TRANSFORM.DEV.FACT_COSTAR_SCENARIOS — read-through of Jon **TRANSFORM.COSTAR.SCENARIOS** (wide MF scenario rent).
-- Used by ``concept_rent_market_monthly`` today via ``source('transform_costar','scenarios')``; this alias centralizes
-- the physical name under **FACT_** for catalog **table_path** alignment (WL_020).
{{ config(
    alias='fact_costar_scenarios',
    materialized='view',
    tags=['transform', 'transform_dev', 'costar', 'fact_costar'],
) }}

SELECT *
FROM {{ source('transform_costar', 'scenarios') }}
