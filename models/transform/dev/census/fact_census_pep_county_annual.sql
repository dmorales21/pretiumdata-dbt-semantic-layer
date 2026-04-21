-- TRANSFORM.DEV.FACT_CENSUS_PEP_COUNTY_ANNUAL — read-through of Jon PEP county annual (silver FQN via **`census_pep_source`**).
-- Grain: county × vintage (per Jon table). Feeds population spine at **county** alongside ACS rollups.
{{ config(
    alias='fact_census_pep_county_annual',
    enabled=var('census_pep_readthrough_enabled', false),
    tags=['transform', 'transform_dev', 'census', 'pep', 'population', 'county', 'labor_demographics_geography_spine'],
) }}

SELECT *
FROM {{ census_pep_source('county') }}
