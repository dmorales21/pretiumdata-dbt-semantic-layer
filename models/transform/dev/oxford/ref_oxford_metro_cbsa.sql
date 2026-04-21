-- TRANSFORM.DEV.REF_OXFORD_METRO_CBSA — versioned dbt build of Oxford metro → Pretium CBSA (302 rows).
-- Replaces ad-hoc CTAS from pretium-ai-dbt `scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql`.
-- Source: **TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK** only (`source('transform_dev_oxford_ref','oxford_cbsa_crosswalk')`).
--   Land the table first: `docs/migration/sql/land_oxford_cbsa_crosswalk_transform_dev.sql`.
-- Join contract: OXFORD_SOURCE_ENTITY_PROFILE_AND_CROSSWALK_JOIN.md §3–4.
{{ config(
    alias='ref_oxford_metro_cbsa',
    materialized='table',
    enabled=var('transform_dev_enable_oxford_cbsa_crosswalk', true),
    tags=['transform', 'transform_dev', 'oxford_economics', 'ref_oxford'],
) }}

SELECT
    TRIM(LOCATION_CODE_OXFORD) AS oxford_location_code,
    TRIM(LOCATION_NAME_OXFORD) AS oxford_location_name,
    TRIM(REGION_TYPE_OXFORD) AS oxford_region_type,
    TRIM(ID_CBSA) AS id_cbsa,
    TRIM(NAME_CBSA) AS name_cbsa,
    TRIM(MATCH_METHOD) AS match_method,
    TRIM(MATCH_CONFIDENCE) AS match_confidence,
    TRIM(MATCH_NOTES) AS match_notes,
    CREATED_AT AS source_created_at,
    UPDATED_AT AS source_updated_at
FROM {{ source('transform_dev_oxford_ref', 'oxford_cbsa_crosswalk') }}
