-- TRANSFORM.DEV.FACT_MARKERR_RENT_SFR — read-through of **TRANSFORM.MARKERR.MARKERR_RENT_SFR**.
-- Feeds ``concept_rent_market_monthly`` Markerr SFR ZIP branch (WL_020 / graph edge).
{{ config(
    alias='fact_markerr_rent_sfr',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'fact_markerr'],
) }}

SELECT *
FROM {{ source('transform_markerr', 'markerr_rent_sfr') }}
