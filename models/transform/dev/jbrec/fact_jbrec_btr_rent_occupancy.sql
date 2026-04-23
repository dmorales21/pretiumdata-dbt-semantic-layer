-- TRANSFORM.DEV.FACT_JBREC_BTR_RENT_OCCUPANCY — raw JBREC BTR + **REFERENCE.GEOGRAPHY.CBSA** (TIGER title + vintage).
-- METRO_CODE remaps match pretium-ai-dbt ``cleaned_jbrec_btr_rent_and_occupancy``; national 10000 → NULL CBSA.

{{ config(
    alias='fact_jbrec_btr_rent_occupancy',
    materialized='view',
    tags=['transform', 'transform_dev', 'jbrec', 'fact_jbrec', 'rent', 'observe_only'],
) }}

WITH raw AS (

    SELECT * FROM {{ source('jbrec', 'btr_rent_and_occupancy') }}

),

remapped AS (

    SELECT
        r.*,
        CASE
            WHEN TRIM(r.METRO_CODE) = '10000' THEN NULL
            ELSE LPAD(
                CASE TRIM(r.METRO_CODE)
                    WHEN '16981' THEN '16980'
                    WHEN '19124' THEN '19100'
                    WHEN '23104' THEN '19100'
                    WHEN '19804' THEN '19820'
                    WHEN '39581' THEN '39580'
                    WHEN '11245' THEN '11244'
                    ELSE TRIM(r.METRO_CODE)
                END,
            5, '0')
        END AS census_cbsa_code
    FROM raw AS r

)

SELECT
    r.*,
    c.NAME                                                                               AS census_cbsa_name,
    c.NAME                                                                               AS census_geo_cbsa_name,
    {{ var('reference_geography_year', 2024) }}                                          AS census_geography_vintage_year,
    CASE WHEN r.census_cbsa_code IS NOT NULL AND c.GEOID IS NOT NULL THEN TRUE ELSE FALSE END AS has_census_cbsa,
    CASE WHEN c.GEOID IS NOT NULL THEN TRUE ELSE FALSE END                               AS has_census_geo_cbsa_lookup
FROM remapped AS r
LEFT JOIN {{ source('reference_geography', 'cbsa') }} AS c
    ON r.census_cbsa_code = LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0')
   AND c.YEAR = {{ var('reference_geography_year', 2024) }}
