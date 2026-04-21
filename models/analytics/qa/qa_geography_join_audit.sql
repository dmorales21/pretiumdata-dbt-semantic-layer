-- Slug: **geography_join_audit** (8) — LAUS `AREA_CODE` vs **CBSA** row in `geography_latest` (join on `geo_id` **and** `geo_level_code = cbsa` only).
-- Target: ANALYTICS.DBT_DEV.QA_GEOGRAPHY_JOIN_AUDIT
{{ config(
    materialized='view',
    alias='QA_GEOGRAPHY_JOIN_AUDIT',
    tags=['analytics', 'qa', 'semantic_validation', 'geography_join_audit'],
) }}

WITH laus_keys AS (
    SELECT DISTINCT TRIM(TO_VARCHAR(geo_id)) AS laus_area_code
    FROM {{ ref('concept_unemployment_market_monthly') }}
    WHERE vendor_code = 'BLS_LAUS'
      AND geo_id IS NOT NULL
)

SELECT
    'concept_unemployment_market_monthly' AS concept_object,
    COUNT(*)::BIGINT AS n_distinct_laus_area_codes,
    COUNT_IF(gl.geo_id IS NULL)::BIGINT AS laus_area_missing_cbsa_geography_row,
    COUNT_IF(gl.geo_id IS NOT NULL)::BIGINT AS laus_area_matches_cbsa_geography_row
FROM laus_keys AS k
LEFT JOIN {{ ref('geography_latest') }} AS gl
    ON TRIM(TO_VARCHAR(gl.geo_id)) = k.laus_area_code
   AND LOWER(TRIM(TO_VARCHAR(gl.geo_level_code))) = 'cbsa'
