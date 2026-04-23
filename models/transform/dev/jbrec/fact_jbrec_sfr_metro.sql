-- TRANSFORM.DEV.FACT_JBREC_SFR_METRO — legacy SFR_METRO + **REFERENCE.GEOGRAPHY.CBSA** when METRO_CODE is OMB GEOID.

{{ config(
    alias='fact_jbrec_sfr_metro',
    materialized='view',
    tags=['transform', 'transform_dev', 'jbrec', 'fact_jbrec', 'sfr', 'observe_only'],
) }}

SELECT
    s.*,
    LPAD(TRIM(TO_VARCHAR(s.METRO_CODE)), 5, '0')                                         AS census_cbsa_code_resolved,
    c.NAME                                                                               AS census_geo_cbsa_name,
    {{ var('reference_geography_year', 2024) }}                                          AS census_geography_vintage_year,
    CASE WHEN c.GEOID IS NOT NULL THEN TRUE ELSE FALSE END                               AS has_census_cbsa,
    CASE WHEN c.GEOID IS NOT NULL THEN TRUE ELSE FALSE END                               AS has_census_geo_cbsa_lookup
FROM {{ source('jbrec', 'sfr_metro') }} AS s
LEFT JOIN {{ source('reference_geography', 'cbsa') }} AS c
    ON LPAD(TRIM(TO_VARCHAR(s.METRO_CODE)), 5, '0') = LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0')
   AND c.YEAR = {{ var('reference_geography_year', 2024) }}
