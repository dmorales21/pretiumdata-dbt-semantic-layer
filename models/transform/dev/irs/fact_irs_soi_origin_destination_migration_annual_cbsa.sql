-- TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_CBSA — county OD flows where both endpoints map to a CBSA via REFERENCE.GEOGRAPHY_LATEST.
-- Grain remains county×county; FROM_CBSA_ID / TO_CBSA_ID support CBSA-scoped analytics and rollups.
{{ config(
    alias='fact_irs_soi_origin_destination_migration_annual_cbsa',
    tags=['transform', 'transform_dev', 'irs', 'fact_irs', 'cybersyn'],
) }}

SELECT
    od.SOURCE_FROM_GEO_ID,
    od.SOURCE_TO_GEO_ID,
    od.FROM_GEO_ID,
    od.TO_GEO_ID,
    od.FROM_GEO_NAME,
    od.TO_GEO_NAME,
    od.FROM_SOURCE_LEVEL,
    od.TO_SOURCE_LEVEL,
    od.FROM_GEO_LEVEL_CODE,
    od.TO_GEO_LEVEL_CODE,
    od.FREQUENCY_CODE,
    od.DATE_REFERENCE,
    od.VARIABLE_NAME,
    od.VALUE,
    od.SUPPRESSED,
    gl_from.cbsa_id AS FROM_CBSA_ID,
    gl_from.cbsa_name AS FROM_CBSA_NAME,
    gl_to.cbsa_id AS TO_CBSA_ID,
    gl_to.cbsa_name AS TO_CBSA_NAME
FROM {{ ref('int_irs_soi_origin_destination_migration_annual') }} AS od
LEFT JOIN {{ ref('geography_latest') }} AS gl_from
    ON od.FROM_GEO_ID = gl_from.geo_id
    AND lower(gl_from.geo_level_code) = 'county'
LEFT JOIN {{ ref('geography_latest') }} AS gl_to
    ON od.TO_GEO_ID = gl_to.geo_id
    AND lower(gl_to.geo_level_code) = 'county'
WHERE gl_from.cbsa_id IS NOT NULL
  AND gl_to.cbsa_id IS NOT NULL
