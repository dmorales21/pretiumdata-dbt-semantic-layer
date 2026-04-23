-- TRANSFORM.DEV.FACT_MARKERR_RENT_PROPERTY_MONTHLY — **TRANSFORM.MARKERR.RENT_PROPERTY_MONTHLY** with MSA→CBSA + class canonicalization.
-- MSA name join: **REFERENCE.GEOGRAPHY.CBSA** (``name`` × ``geoid``) for ``reference_geography_year()`` — replaces **EDW_PROD.TOOLS.MSA_LOOKUP** in pretium-ai-dbt.
-- Class map: ``ref('ref_markerr_class_to_canonical')`` (seed parity with pretium-ai-dbt).
{{ config(
    alias='fact_markerr_rent_property_monthly',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'fact_markerr', 'rent'],
) }}

WITH source AS (

    SELECT *
    FROM {{ source('transform_markerr', 'rent_property_monthly') }}

),

msa_lookup AS (

    SELECT
        UPPER(TRIM(TO_VARCHAR(c.NAME))) AS name_cbsa_upper,
        LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0') AS id_cbsa,
        TRIM(TO_VARCHAR(c.NAME)) AS name_cbsa
    FROM {{ source('reference_geography', 'cbsa') }} AS c
    WHERE c.YEAR = {{ reference_geography_year() }}
      AND c.GEOID IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY UPPER(TRIM(TO_VARCHAR(c.NAME)))
        ORDER BY LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0')
    ) = 1

),

class_lookup AS (

    SELECT
        TRIM(source_value) AS source_value,
        class_code
    FROM {{ ref('ref_markerr_class_to_canonical') }}

),

cleaned AS (

    SELECT
        DATE_TRUNC('MONTH', s.MONTH)::DATE                                AS date_reference,
        s.MONTH                                                         AS month_raw,

        s.MSA                                                           AS msa,
        ml.id_cbsa                                                      AS cbsa_code,
        ml.name_cbsa                                                    AS cbsa_name,

        s.BEDROOM_CATEGORY                                              AS bedroom_category_raw,
        CASE
            WHEN LOWER(TRIM(s.BEDROOM_CATEGORY)) IN ('studio', '0br', '0-bedroom', 'efficiency')
                THEN '0BR'
            WHEN LOWER(TRIM(s.BEDROOM_CATEGORY)) IN ('1br', '1-bedroom', '1 bedroom', '1 br')
                THEN '1BR'
            WHEN LOWER(TRIM(s.BEDROOM_CATEGORY)) IN ('2br', '2-bedroom', '2 bedroom', '2 br')
                THEN '2BR'
            WHEN LOWER(TRIM(s.BEDROOM_CATEGORY)) IN ('3br', '3-bedroom', '3 bedroom', '3 br')
                THEN '3BR'
            WHEN LOWER(TRIM(s.BEDROOM_CATEGORY)) IN (
                '4br', '4-bedroom', '4 bedroom', '4 br', '4br+', '4+ br', '4+ bedroom'
            )
                THEN '4BR_PLUS'
            WHEN LOWER(TRIM(s.BEDROOM_CATEGORY)) IN ('any', 'all', 'overall', 'total')
                THEN 'ALL'
            ELSE TRIM(s.BEDROOM_CATEGORY)
        END                                                             AS bedroom_category,

        s.CLASS_CATEGORY                                                AS class_category_raw,
        CASE
            WHEN cl.source_value IS NOT NULL AND cl.class_code IS NULL THEN NULL
            ELSE COALESCE(cl.class_code, TRIM(s.CLASS_CATEGORY))
        END                                                             AS class_code,

        TRY_TO_DOUBLE(
            REPLACE(TRIM(TO_VARCHAR(COALESCE(s.AVG_EFFECTIVE_RENT, ''))), ' ', '')
        )                                                               AS avg_effective_rent,
        TRY_TO_DOUBLE(
            REPLACE(TRIM(TO_VARCHAR(COALESCE(s.AVG_ASKING_RENT, ''))), ' ', '')
        )                                                               AS avg_asking_rent,

        TRY_TO_DOUBLE(
            REPLACE(TRIM(TO_VARCHAR(COALESCE(s.AVG_ASKING_RENT, ''))), ' ', '')
        )
        - TRY_TO_DOUBLE(
            REPLACE(TRIM(TO_VARCHAR(COALESCE(s.AVG_EFFECTIVE_RENT, ''))), ' ', '')
        )                                                               AS concession_spread,

        TRY_TO_DOUBLE(TO_VARCHAR(s.AVG_VACANCY)) / 100.0                 AS avg_vacancy_rate,
        1.0 - (TRY_TO_DOUBLE(TO_VARCHAR(s.AVG_VACANCY)) / 100.0)       AS avg_occupancy_rate,

        s.OBS_COUNT                                                     AS obs_count,

        'MARKERR'                                                       AS vendor_name,
        CURRENT_TIMESTAMP()                                             AS dbt_updated_at

    FROM source AS s
    LEFT JOIN msa_lookup AS ml
        ON UPPER(TRIM(s.MSA)) = ml.name_cbsa_upper
    LEFT JOIN class_lookup AS cl
        ON TRIM(NULLIF(s.CLASS_CATEGORY, '')) = cl.source_value

)

SELECT *
FROM cleaned
