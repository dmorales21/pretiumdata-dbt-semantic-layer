-- TRANSFORM.DEV.FACT_FHFA_MORTGAGE_PERFORMANCE_COUNTY — FHFA mortgage performance, county grain only.
{{ config(
    alias='fact_fhfa_mortgage_performance_county',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_fhfa_mortgage_performance') }}
WHERE lower(geo_level_code) = 'county'
