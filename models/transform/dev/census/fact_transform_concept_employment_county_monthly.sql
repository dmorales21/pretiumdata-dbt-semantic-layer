-- TRANSFORM.DEV.FACT_TRANSFORM_CONCEPT_EMPLOYMENT_COUNTY_MONTHLY — read-through of **TRANSFORM.CONCEPT.EMPLOYMENT_COUNTY_MONTHLY**.
-- Vendor-agnostic **county** employment time series (Jon concept layer). Use for **jobs / employment** at county
-- when LODES OD is not the right grain. Pair with **`fact_bls_laus_county`** for unemployment / labor force where needed.
{{ config(
    alias='fact_transform_concept_employment_county_monthly',
    tags=['transform', 'transform_dev', 'transform_concept', 'employment', 'county', 'labor_demographics_geography_spine'],
) }}

SELECT *
FROM {{ source('transform_concept', 'employment_county_monthly') }}
