-- TRANSFORM.DEV.FACT_FHFA_HOUSE_PRICE_COUNTY — FHFA HPI rows at county grain only.
{{ config(
    alias='fact_fhfa_house_price_county',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_fhfa_house_price') }}
WHERE lower(geo_level_code) = 'county'
