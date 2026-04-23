-- TRANSFORM.DEV.CLEANED_DEEPHAVEN_PROPERTIES — OpCo footprint row shape (property × CBSA × ZIP).
-- Parity with pretium-ai-dbt **cleaned_deephaven_properties**; feeds **fact_footprint_deephaven_properties**.

{{ config(
    alias='cleaned_deephaven_properties',
    materialized='view',
    tags=['transform', 'transform_dev', 'deephaven', 'cleaned', 'opco'],
) }}

WITH raw AS (
    SELECT
        CAST(d.PROPERTY_ID AS VARCHAR) AS property_id,
        d.CBSA_CODE AS raw_cbsa,
        TRIM(d.CBSA_TITLE) AS cbsa_title_src,
        LEFT(TRIM(CAST(COALESCE(d.ZIP_CODE, d.PROPERTY_ZIPCODE) AS VARCHAR)), 5) AS zip_code
    FROM {{ source('source_entity_deephaven', 'deephaven_properties') }} AS d
    WHERE d.ZIP_CODE IS NOT NULL OR d.PROPERTY_ZIPCODE IS NOT NULL
       OR d.LATITUDE IS NOT NULL OR d.LONGITUDE IS NOT NULL
),

xwalk AS (
    SELECT DISTINCT
        LEFT(TRIM(CAST(id_zip AS VARCHAR)), 5) AS zip_code,
        LPAD(TRIM(SPLIT_PART(CAST(id_cbsa AS VARCHAR), '.', 1)), 5, '0') AS cbsa_code
    FROM {{ source('transform_ref', 'h3_xwalk_6810_canon') }}
    WHERE id_zip IS NOT NULL AND id_cbsa IS NOT NULL
),

enriched AS (
    SELECT
        r.property_id,
        COALESCE(
            NULLIF(LPAD(TRIM(SPLIT_PART(CAST(r.raw_cbsa AS VARCHAR), '.', 1)), 5, '0'), ''),
            x.cbsa_code
        ) AS cbsa_code,
        r.cbsa_title_src,
        r.zip_code
    FROM raw AS r
    LEFT JOIN xwalk AS x ON r.zip_code = x.zip_code
    WHERE r.raw_cbsa IS NOT NULL OR x.cbsa_code IS NOT NULL
)

SELECT
    e.property_id,
    'DEEPHAVEN_MORTGAGE' AS opco_id,
    e.cbsa_code,
    COALESCE(NULLIF(e.cbsa_title_src, ''), TRIM(TO_VARCHAR(c.NAME))) AS cbsa_title,
    e.zip_code,
    TRUE AS is_active
FROM enriched AS e
LEFT JOIN {{ source('reference_geography', 'cbsa') }} AS c
    ON LPAD(TRIM(e.cbsa_code), 5, '0') = LPAD(TRIM(TO_VARCHAR(c.GEOID)), 5, '0')
   AND c.YEAR = {{ reference_geography_year() }}
