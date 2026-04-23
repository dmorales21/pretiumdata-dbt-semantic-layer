-- TRANSFORM.DEV.FACT_PARCLLABS_RENT_LISTINGS_CLEANED — **SOURCE_PROD.PARCLLABS.RENT_LISTINGS** normalized.
-- Vendor grain is **ZIP** (``geo_level_code = 'ZIP'``). Adds **REFERENCE.GEOGRAPHY** HUD ZIP→county→CBSA and dominant
-- **H3 R6/R8** via ``reference_geo_zip_to_cbsa_and_h3_ctes()`` (same contract as Markerr ZIP-native rent facts).
{{ config(
    alias='fact_parcllabs_rent_listings_cleaned',
    materialized='view',
    tags=['transform', 'transform_dev', 'parcllabs', 'fact_parcllabs', 'rent'],
) }}

WITH {{ reference_geo_zip_to_cbsa_and_h3_ctes() }},

base AS (

    SELECT
        CAST(s.date_reference AS DATE) AS date_reference,
        YEAR(CAST(s.date_reference AS DATE)) AS year,
        LPAD(TRIM(TO_VARCHAR(s.zip_code)), 5, '0') AS geo_id,
        'ZIP' AS geo_level_code,
        TRY_TO_NUMBER(TO_VARCHAR(s.parcl_property_id)) AS parcl_property_id,
        TRY_TO_NUMBER(TO_VARCHAR(s.parcl_id)) AS parcl_id,
        TRY_TO_DOUBLE(REPLACE(TO_VARCHAR(s.rent), ' ', '')) AS rent,
        TRY_TO_DOUBLE(REPLACE(TO_VARCHAR(s.rent_per_sqft), ' ', '')) AS rent_per_sqft,
        TRY_TO_NUMBER(TO_VARCHAR(s.bedrooms)) AS bedrooms,
        TRY_TO_NUMBER(TO_VARCHAR(s.bathrooms)) AS bathrooms,
        TRY_TO_DOUBLE(REPLACE(TO_VARCHAR(s.sqft), ' ', '')) AS sqft,
        TRIM(TO_VARCHAR(s.owner_name))::VARCHAR(500) AS owner_name,
        TRIM(TO_VARCHAR(s.owner_type))::VARCHAR(100) AS owner_type,
        'PARCLLABS' AS vendor_name,
        'rent_listings' AS source_dataset,
        CURRENT_TIMESTAMP() AS cleaned_at
    FROM {{ source('parcllabs', 'rent_listings') }} AS s
    WHERE s.date_reference IS NOT NULL
      AND s.zip_code IS NOT NULL
      AND LENGTH(LPAD(TRIM(TO_VARCHAR(s.zip_code)), 5, '0')) = 5
      AND TRY_TO_DOUBLE(REPLACE(TO_VARCHAR(s.rent), ' ', '')) IS NOT NULL
      AND TRY_TO_DOUBLE(REPLACE(TO_VARCHAR(s.rent), ' ', '')) > 0

)

SELECT
    b.date_reference,
    b.year,
    b.geo_id,
    b.geo_level_code,
    b.parcl_property_id,
    b.parcl_id,
    b.rent,
    b.rent_per_sqft,
    b.bedrooms,
    b.bathrooms,
    b.sqft,
    b.owner_name,
    b.owner_type,
    b.vendor_name,
    b.source_dataset,
    ze.county_fips AS reference_county_fips,
    ze.cbsa_id AS reference_cbsa_id,
    CASE WHEN ze.county_fips IS NOT NULL THEN LEFT(ze.county_fips, 2) ELSE NULL END AS reference_state_fips,
    h.h3_6_hex AS zip_to_h3_r6_hex,
    h.h3_8_hex AS zip_to_h3_r8_hex,
    h.id_cbsa AS zip_to_cbsa_id,
    b.cleaned_at
FROM base AS b
LEFT JOIN zip_enriched AS ze
    ON b.geo_id = ze.id_zip
LEFT JOIN h3_zip AS h
    ON b.geo_id = h.id_zip
