-- TRANSFORM.DEV.FACT_FHFA_HOUSE_PRICE_CBSA — FHFA HPI rows at CBSA grain only.
{{ config(
    alias='fact_fhfa_house_price_cbsa',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_fhfa_house_price') }}
WHERE lower(geo_level_code) = 'cbsa'
