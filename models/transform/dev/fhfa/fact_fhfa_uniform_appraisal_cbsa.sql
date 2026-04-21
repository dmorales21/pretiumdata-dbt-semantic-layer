-- TRANSFORM.DEV.FACT_FHFA_UNIFORM_APPRAISAL_CBSA — FHFA UAD, CBSA grain only.
{{ config(
    alias='fact_fhfa_uniform_appraisal_cbsa',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_fhfa_uniform_appraisal') }}
WHERE lower(geo_level_code) = 'cbsa'
