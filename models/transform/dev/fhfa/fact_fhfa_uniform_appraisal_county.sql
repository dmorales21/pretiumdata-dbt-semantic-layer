-- TRANSFORM.DEV.FACT_FHFA_UNIFORM_APPRAISAL_COUNTY — FHFA UAD, county grain only.
{{ config(
    alias='fact_fhfa_uniform_appraisal_county',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_fhfa_uniform_appraisal') }}
WHERE lower(geo_level_code) = 'county'
