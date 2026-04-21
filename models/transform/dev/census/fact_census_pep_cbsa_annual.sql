-- TRANSFORM.DEV.FACT_CENSUS_PEP_CBSA_ANNUAL — read-through of Jon PEP CBSA annual (silver FQN via **`census_pep_source`**).
-- Grain: CBSA × vintage (per Jon table). **OMB CBSA** semantics per Jon build; verify joins vs LAUS BLS metro codes.
{{ config(
    alias='fact_census_pep_cbsa_annual',
    enabled=var('census_pep_readthrough_enabled', false),
    tags=['transform', 'transform_dev', 'census', 'pep', 'population', 'cbsa', 'labor_demographics_geography_spine'],
) }}

SELECT *
FROM {{ census_pep_source('cbsa') }}
