-- TRANSFORM.DEV.FACT_FHFA_MORTGAGE_PERFORMANCE_CBSA — FHFA mortgage performance, CBSA grain only.
{{ config(
    alias='fact_fhfa_mortgage_performance_cbsa',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_fhfa_mortgage_performance') }}
WHERE lower(geo_level_code) = 'cbsa'
