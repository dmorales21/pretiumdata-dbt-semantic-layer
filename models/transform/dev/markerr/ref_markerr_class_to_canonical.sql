-- TRANSFORM.DEV.REF_MARKERR_CLASS_TO_CANONICAL — Markerr ``CLASS_CATEGORY`` → canonical class_code (seed-driven).
-- Same contract as **pretium-ai-dbt** ``ref_markerr_class_to_canonical.sql``.
{{ config(
    alias='ref_markerr_class_to_canonical',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'ref', 'xwalk'],
) }}

SELECT
    TRIM(source_value) AS source_value,
    NULLIF(TRIM(class_code), '') AS class_code,
    description
FROM {{ ref('ref_markerr_class_to_canonical_seed') }}
WHERE source_value IS NOT NULL
