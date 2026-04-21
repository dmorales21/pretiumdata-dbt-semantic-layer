-- TRANSFORM.DEV.FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY — read-through of **TRANSFORM.MARKERR.RENT_PROPERTY_CBSA_MONTHLY**.
-- Feeds ``concept_rent_market_monthly`` Markerr MF branch (AVG_RENT_EFFECTIVE / AVG_RENT_ASKING); WL_020 catalog **MET_044–MET_045**.
{{ config(
    alias='fact_markerr_rent_property_cbsa_monthly',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'fact_markerr'],
) }}

SELECT *
FROM {{ source('transform_markerr', 'rent_property_cbsa_monthly') }}
