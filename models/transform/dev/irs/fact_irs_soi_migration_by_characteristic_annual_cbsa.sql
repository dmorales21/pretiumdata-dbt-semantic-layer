-- TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL_CBSA — IRS by-characteristic, CBSA grain only.
{{ config(
    alias='fact_irs_soi_migration_by_characteristic_annual_cbsa',
    tags=['transform', 'transform_dev', 'irs', 'fact_irs', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_irs_soi_migration_by_characteristic_annual') }}
WHERE lower(geo_level_code) = 'cbsa'
