-- TRANSFORM.DEV.FACT_MARKERR_RENT_LISTINGS — **TRANSFORM.MARKERR.RENT_LISTINGS** listing-level clean + ZIP→H3/CBSA via **REFERENCE.GEOGRAPHY** (HUD ZIP spine + **BRIDGE_ZIP_H3_R8_POLYFILL**), not **TRANSFORM.REF**.
-- ``cbsa_name`` from **REFERENCE.GEOGRAPHY.CBSA** on resolved CBSA (bridge **CBSA_ID** when present, else HUD ZIP→county→primary CBSA).
{{ config(
    alias='fact_markerr_rent_listings',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'fact_markerr', 'rent'],
) }}

WITH {{ reference_geo_zip_to_cbsa_and_h3_ctes() }},

source AS (

    SELECT *
    FROM {{ source('transform_markerr', 'rent_listings') }}

),

cbsa_dim AS (

    SELECT
        LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0') AS id_cbsa,
        MAX(TRIM(TO_VARCHAR(c.NAME))) AS name_cbsa
    FROM {{ source('reference_geography', 'cbsa') }} AS c
    WHERE c.YEAR = {{ reference_geography_year() }}
      AND c.GEOID IS NOT NULL
    GROUP BY 1

),

cleaned AS (

    SELECT
        s.ID                                                        AS id,
        s.SCRAPED_TIMESTAMP                                         AS scraped_timestamp,
        DATE(s.SCRAPED_TIMESTAMP)                                   AS scraped_date,
        DATE_TRUNC('MONTH', DATE(s.SCRAPED_TIMESTAMP))              AS scraped_month,

        MD5(
            CONCAT_WS(
                '|',
                UPPER(TRIM(COALESCE(s.ADDRESS, ''))),
                LPAD(TRIM(COALESCE(s.ZIPCODE, '')), 5, '0'),
                COALESCE(CAST(s.BEDS AS VARCHAR), ''),
                COALESCE(CAST(s.BATHS AS VARCHAR), ''),
                COALESCE(CAST(s.SQFT AS VARCHAR), '')
            )
        )                                                           AS property_fingerprint,

        s.AVAILABILITY_STATUS                                       AS availability_status_raw,
        CASE
            WHEN LOWER(TRIM(s.AVAILABILITY_STATUS)) = 'available'     THEN 'AVAILABLE'
            WHEN LOWER(TRIM(s.AVAILABILITY_STATUS)) = 'unavailable'   THEN 'UNAVAILABLE'
            WHEN LOWER(TRIM(s.AVAILABILITY_STATUS)) LIKE 'coming%'    THEN 'COMING_SOON'
            WHEN s.AVAILABILITY_STATUS IS NULL                        THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END                                                         AS availability_status,

        s.ADDRESS                                                   AS address,
        s.CITY                                                      AS city,
        s.STATE                                                     AS state,
        LPAD(TRIM(COALESCE(s.ZIPCODE, '')), 5, '0')                 AS zipcode,
        s.COUNTY                                                    AS county,
        s.COUNTY_ID                                                 AS county_id,
        s.MSA                                                       AS msa,
        s.MSA_ID                                                    AS msa_id,
        s.LATITUDE                                                  AS latitude,
        s.LONGITUDE                                                 AS longitude,

        ze.county_fips                                              AS reference_county_fips,
        ze.cbsa_id                                                  AS reference_cbsa_id,
        CASE WHEN ze.county_fips IS NOT NULL THEN LEFT(ze.county_fips, 2) ELSE NULL END AS reference_state_fips,

        h.h3_6_hex,
        h.h3_8_hex,
        h.id_cbsa                                                   AS cbsa_code,
        cb.name_cbsa                                                AS cbsa_name,

        s.BUILDING_TYPE                                             AS building_type,
        s.BEDS                                                      AS beds,
        s.BATHS                                                     AS baths,
        s.FULL_BATHS                                                AS full_baths,
        s.PARTIAL_BATHS                                             AS partial_baths,
        s.SQFT                                                      AS sqft,

        CASE
            WHEN s.BEDS = 0 OR LOWER(TRIM(s.AVAILABILITY_STATUS)) LIKE '%studio%'
                THEN '0BR'
            WHEN s.BEDS = 1                                        THEN '1BR'
            WHEN s.BEDS = 2                                        THEN '2BR'
            WHEN s.BEDS = 3                                        THEN '3BR'
            WHEN s.BEDS >= 4                                       THEN '4BR_PLUS'
            ELSE 'UNKNOWN'
        END                                                         AS beds_bucket,

        TRY_TO_DOUBLE(
            REPLACE(TRIM(TO_VARCHAR(COALESCE(s.RENT, ''))), ' ', '')
        )                                                           AS rent,

        s.HAS_GRANITE_COUNTERTOP                                    AS has_granite_countertop,
        s.HAS_STAINLESS_STEEL_APPLIANCES                            AS has_stainless_steel_appliances,
        s.HAS_POOL                                                  AS has_pool,
        s.HAS_GYM                                                   AS has_gym,
        s.HAS_DOORMAN                                               AS has_doorman,
        s.IS_FURNISHED                                              AS is_furnished,
        s.HAS_LAUNDRY                                               AS has_laundry,
        s.HAS_GARAGE                                                AS has_garage,
        s.HAS_CLUBHOUSE                                             AS has_clubhouse,

        s.HOST_NAME                                                 AS host_name,
        s.COMPANY                                                   AS company,
        s.UNIT_NAME                                                 AS unit_name,
        s.DATE_POSTED                                               AS date_posted,
        s.AVAILABILITY_DATE                                         AS availability_date,
        s.YEAR_BUILT                                                AS year_built,

        s.INGESTED_AT                                               AS ingested_at,
        CURRENT_TIMESTAMP()                                         AS dbt_updated_at

    FROM source AS s
    LEFT JOIN h3_zip AS h
        ON LPAD(TRIM(COALESCE(s.ZIPCODE, '')), 5, '0') = h.id_zip
    LEFT JOIN zip_enriched AS ze
        ON LPAD(TRIM(COALESCE(s.ZIPCODE, '')), 5, '0') = ze.id_zip
    LEFT JOIN cbsa_dim AS cb
        ON COALESCE(h.id_cbsa, ze.cbsa_id) = cb.id_cbsa

)

SELECT *
FROM cleaned
