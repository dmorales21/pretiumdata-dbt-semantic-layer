-- TRANSFORM.DEV.FACT_FOOTPRINT_DEEPHAVEN_PROPERTIES — OpCo footprint (presence metric).
-- Migrated from pretium-ai-dbt **fact_footprint_deephaven_properties**; reads **cleaned_deephaven_properties**.

{{ config(
    alias='fact_footprint_deephaven_properties',
    materialized='view',
    tags=['transform', 'transform_dev', 'deephaven', 'footprint', 'opco', 'fact_deephaven'],
) }}

WITH base AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY property_id) AS _row_id
    FROM {{ ref('cleaned_deephaven_properties') }}
)

SELECT
    CURRENT_DATE() AS date_reference,
    CASE
        WHEN cbsa_code IS NOT NULL AND TRIM(cbsa_code) != '' THEN TRIM(cbsa_code)
        ELSE LPAD(TRIM(zip_code), 5, '0')
    END AS geo_id,
    CASE
        WHEN cbsa_code IS NOT NULL AND TRIM(cbsa_code) != '' THEN 'CBSA'
        ELSE 'ZIP'
    END AS geo_level_code,
    'DEEPHAVEN_PROPERTY_FOOTPRINT' AS metric_id,
    1.0::FLOAT AS value,
    'DEEPHAVEN' AS vendor_name,
    'VALID' AS quality_flag,
    _row_id AS row_id
FROM base
WHERE (cbsa_code IS NOT NULL AND TRIM(cbsa_code) != '')
   OR (zip_code IS NOT NULL AND TRIM(zip_code) != '')
