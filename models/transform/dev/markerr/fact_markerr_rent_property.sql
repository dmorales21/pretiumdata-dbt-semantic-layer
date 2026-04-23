-- TRANSFORM.DEV.FACT_MARKERR_RENT_PROPERTY — **TRANSFORM.MARKERR.RENT_PROPERTY** with typed columns + QC flags.
-- Enriches vendor ZIP with **REFERENCE.GEOGRAPHY** HUD postal spine (county + primary CBSA) and dominant **H3 R6/R8**
-- from **BRIDGE_ZIP_H3_R8_POLYFILL** (same contract as ``fact_markerr_rent_listings``).
{{ config(
    alias='fact_markerr_rent_property',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'fact_markerr', 'rent'],
) }}

WITH {{ reference_geo_zip_to_cbsa_and_h3_ctes() }},

src AS (
    SELECT
        TRIM(CAST(PROPERTY_ID AS VARCHAR)) AS property_id,
        AS_OF_DATE::DATE AS as_of_date,
        TRIM(CAST(BEDROOM_CATEGORY AS VARCHAR)) AS bedroom_category,
        TRIM(CAST(CLASS_CATEGORY AS VARCHAR)) AS class_category,
        TRY_TO_DOUBLE(
            REPLACE(TRIM(TO_VARCHAR(COALESCE(RENT_ASKING, ''))), ' ', '')
        ) AS rent_asking,
        TRY_TO_DOUBLE(TO_VARCHAR(VACANCY)) / 100.0 AS vacancy_rate,
        TRY_TO_DOUBLE(TO_VARCHAR(OCCUPANCY)) / 100.0 AS occupancy_rate,
        LPAD(TRIM(CAST(ZIPCODE AS VARCHAR)), 5, '0') AS zip_code,
        TRY_CAST(MSA_ID AS NUMBER) AS msa_id,
        INGESTED_AT::TIMESTAMP_NTZ AS ingested_at
    FROM {{ source('transform_markerr', 'rent_property') }}
    WHERE AS_OF_DATE IS NOT NULL
      AND TRIM(CAST(PROPERTY_ID AS VARCHAR)) != ''
)

SELECT
    s.property_id,
    s.as_of_date,
    s.bedroom_category,
    s.class_category,
    s.rent_asking,
    s.vacancy_rate,
    s.occupancy_rate,
    s.zip_code,
    s.msa_id,
    ze.county_fips AS reference_county_fips,
    ze.cbsa_id AS reference_cbsa_id,
    CASE WHEN ze.county_fips IS NOT NULL THEN LEFT(ze.county_fips, 2) ELSE NULL END AS reference_state_fips,
    h.h3_6_hex AS zip_to_h3_r6_hex,
    h.h3_8_hex AS zip_to_h3_r8_hex,
    h.id_cbsa AS zip_to_cbsa_id,
    s.ingested_at,
    CASE
        WHEN s.rent_asking IS NULL THEN 'null_rent_asking'
        WHEN s.vacancy_rate IS NOT NULL AND s.vacancy_rate < 0 THEN 'negative_vacancy'
        ELSE NULL
    END AS quality_flag,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM src AS s
LEFT JOIN zip_enriched AS ze
    ON s.zip_code = ze.id_zip
LEFT JOIN h3_zip AS h
    ON s.zip_code = h.id_zip
