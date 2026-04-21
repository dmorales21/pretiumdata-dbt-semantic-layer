-- TRANSFORM.DEV.FACT_TRANSFORM_CONCEPT_EMPLOYMENT_CBSA_MONTHLY — read-through of **TRANSFORM.CONCEPT.EMPLOYMENT_CBSA_MONTHLY**.
-- **CBSA**-grain employment (Jon concept). Prefer OMB-aligned CBSA ids when joining to **`fact_bls_laus_county`** rollups.
{{ config(
    alias='fact_transform_concept_employment_cbsa_monthly',
    tags=['transform', 'transform_dev', 'transform_concept', 'employment', 'cbsa', 'labor_demographics_geography_spine'],
) }}

SELECT *
FROM {{ source('transform_concept', 'employment_cbsa_monthly') }}
