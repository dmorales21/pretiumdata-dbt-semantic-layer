-- TRANSFORM.DEV.FACT_APARTMENTIQ_PROPERTYKPI_BH — PROPERTYKPI_BH × PROPERTY_BH + HUD ZIP spine + **REFERENCE.GEOGRAPHY** TIGER.
-- ``zip_enriched`` (HUD postal → county → CBSA) plus CBSA / COUNTY / STATE polygon tables at ``reference_geography_year()``.

{{ config(
    alias='fact_apartmentiq_propertykpi_bh',
    materialized='view',
    tags=['transform', 'transform_dev', 'apartmentiq', 'fact_apartmentiq', 'rent', 'observe_only'],
) }}

WITH {{ reference_geo_zip_to_cbsa_ctes() }}

SELECT
    k.*,
    LPAD(TRIM(TO_VARCHAR(p.ZIPCODE)), 5, '0')                                           AS census_zcta5,
    ze.cbsa_id                                                                           AS census_cbsa_code,
    ze.county_fips                                                                       AS census_county_fips,
    LPAD(TRIM(TO_VARCHAR(co_geo.STATEFP)), 2, '0')                                       AS census_state_fips,
    cbsa_geo.NAME                                                                        AS census_geo_cbsa_name,
    co_geo.NAME                                                                          AS census_geo_county_name,
    st_geo.NAME                                                                          AS census_geo_state_name,
    {{ var('reference_geography_year', 2024) }}                                          AS census_geography_vintage_year,
    CASE WHEN ze.cbsa_id IS NOT NULL THEN TRUE ELSE FALSE END                            AS has_census_cbsa,
    CASE WHEN ze.county_fips IS NOT NULL THEN TRUE ELSE FALSE END                       AS has_census_county,
    CASE WHEN cbsa_geo.GEOID IS NOT NULL THEN TRUE ELSE FALSE END                        AS has_census_geo_cbsa_lookup,
    CASE WHEN co_geo.GEOID IS NOT NULL THEN TRUE ELSE FALSE END                         AS has_census_geo_county_lookup,
    CASE WHEN st_geo.GEOID IS NOT NULL THEN TRUE ELSE FALSE END                         AS has_census_geo_state_lookup
FROM {{ source('transform_apartmentiq', 'propertykpi_bh') }} AS k
LEFT JOIN {{ source('transform_apartmentiq', 'property_bh') }} AS p
    ON k.PROPERTYID = p.ID
LEFT JOIN zip_enriched AS ze
    ON LPAD(TRIM(TO_VARCHAR(p.ZIPCODE)), 5, '0') = ze.id_zip
LEFT JOIN {{ source('reference_geography', 'cbsa') }} AS cbsa_geo
    ON LPAD(TRIM(TO_VARCHAR(ze.cbsa_id)), 5, '0') = LPAD(TRIM(TO_VARCHAR(cbsa_geo.GEOID)), 5, '0')
   AND cbsa_geo.YEAR = {{ var('reference_geography_year', 2024) }}
LEFT JOIN {{ source('reference_geography', 'county') }} AS co_geo
    ON ze.county_fips = LPAD(TRIM(TO_VARCHAR(co_geo.GEOID)), 5, '0')
   AND co_geo.YEAR = {{ var('reference_geography_year', 2024) }}
LEFT JOIN {{ source('reference_geography', 'state') }} AS st_geo
    ON LPAD(TRIM(TO_VARCHAR(co_geo.STATEFP)), 2, '0') = LPAD(TRIM(TO_VARCHAR(st_geo.GEOID)), 2, '0')
   AND st_geo.YEAR = {{ var('reference_geography_year', 2024) }}
