-- TRANSFORM.DEV.FACT_JBREC_BTR_RENT_OCCUPANCY_CLEANED — **SOURCE_PROD.JBREC.BTR_RENT_AND_OCCUPANCY** with JBREC parsing.
-- Logic aligned with **pretium-ai-dbt** ``cleaned_jbrec_btr_rent_and_occupancy.sql`` (CBSA remap, DFW average, % → 0–1).
{{ config(
    alias='fact_jbrec_btr_rent_occupancy_cleaned',
    materialized='view',
    tags=['transform', 'transform_dev', 'jbrec', 'fact_jbrec', 'rent'],
) }}

WITH source AS (

    SELECT * FROM {{ source('jbrec', 'btr_rent_and_occupancy') }}

),

parsed AS (

    SELECT
        TRIM(s.METRO_CODE)                                                          AS metro_code_raw,
        TRIM(s.METRO_NAME)                                                          AS metro_name_raw,

        TO_DATE('01-' || TRIM(s."DATE"), 'DD-Mon-YY')                               AS date_reference,

        TRY_TO_DECIMAL(
            REPLACE(REPLACE(TRIM(s.BBTRI_RENT), '$', ''), ',', ''),
            10, 2
        )                                                                           AS btr_avg_rent,

        TRY_TO_DECIMAL(
            REPLACE(TRIM(s.BBTRI_OCCUPANCY), '%', ''),
            6, 3
        ) / 100.0                                                                   AS btr_occupancy_pct,

        TRY_TO_DECIMAL(
            REPLACE(TRIM(s.BBTRI_RENT_GROWTH_YOY), '%', ''),
            6, 3
        ) / 100.0                                                                   AS btr_rent_growth_yoy_pct

    FROM source AS s
    WHERE TRIM(s.METRO_CODE) != '10000'

),

cbsa_mapped AS (

    SELECT
        LPAD(
            CASE metro_code_raw
                WHEN '16981' THEN '16980'
                WHEN '19124' THEN '19100'
                WHEN '23104' THEN '19100'
                WHEN '19804' THEN '19820'
                WHEN '39581' THEN '39580'
                WHEN '11245' THEN '11244'
                ELSE metro_code_raw
            END,
        5, '0')                                                                     AS cbsa_code,

        metro_name_raw,
        date_reference,
        btr_avg_rent,
        btr_occupancy_pct,
        btr_rent_growth_yoy_pct

    FROM parsed
    WHERE date_reference IS NOT NULL

),

deduped AS (

    SELECT
        cbsa_code,
        date_reference,
        MAX(metro_name_raw)                         AS metro_name,
        ROUND(AVG(btr_avg_rent), 2)                 AS btr_avg_rent,
        ROUND(AVG(btr_occupancy_pct), 5)            AS btr_occupancy_pct,
        ROUND(AVG(btr_rent_growth_yoy_pct), 5)      AS btr_rent_growth_yoy_pct,
        COUNT(*)                                    AS _source_row_count

    FROM cbsa_mapped
    GROUP BY cbsa_code, date_reference

)

SELECT
    cbsa_code,
    date_reference,
    metro_name,
    btr_avg_rent,
    btr_occupancy_pct,
    ROUND(1.0 - btr_occupancy_pct, 5)              AS btr_vacancy_pct,
    btr_rent_growth_yoy_pct,
    CASE WHEN _source_row_count > 1
         THEN TRUE ELSE FALSE
    END                                             AS is_mdivision_average,
    'JBREC'                                         AS data_source,
    CURRENT_TIMESTAMP()                             AS _loaded_at

FROM deduped
WHERE btr_avg_rent IS NOT NULL
