-- TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY — county-to-county OD rows (both endpoints county).
{{ config(
    alias='fact_irs_soi_origin_destination_migration_annual_county',
    tags=['transform', 'transform_dev', 'irs', 'fact_irs', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('int_irs_soi_origin_destination_migration_annual') }}
WHERE lower(coalesce(FROM_GEO_LEVEL_CODE, 'county')) = 'county'
  AND lower(coalesce(TO_GEO_LEVEL_CODE, 'county')) = 'county'
