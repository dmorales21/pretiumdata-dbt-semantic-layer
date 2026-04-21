-- TRANSFORM.DEV.FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL — IRS SOI migration by characteristic (annual).
-- FREQUENCY_CODE fixed annual; GEO_LEVEL_CODE from REFERENCE.GEOGRAPHY or unmapped.
{{ config(
    alias='fact_irs_soi_migration_by_characteristic_annual',
    tags=['transform', 'transform_dev', 'irs', 'fact_irs', 'cybersyn'],
) }}

SELECT
    TRIM(ts.geo_id) AS SOURCE_GEO_ID,
    {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} AS GEO_ID,
    gi.geo_name AS GEO_NAME,
    gi.source_level AS SOURCE_LEVEL,
    coalesce(gi.geo_level_code, 'unmapped') AS GEO_LEVEL_CODE,
    'annual' AS FREQUENCY_CODE,
    ts.date AS DATE_REFERENCE,
    TRIM(ts.variable) AS VARIABLE,
    TRIM(a.variable_name) AS VARIABLE_NAME,
    TRIM(a.return_group) AS RETURN_GROUP,
    TRIM(a.income_bracket) AS INCOME_BRACKET,
    TRIM(a.age_group) AS AGE_GROUP,
    TRIM(a.unit) AS UNIT,
    ts.value::FLOAT AS VALUE
FROM {{ source('source_snow_us_real_estate', 'irs_migration_by_characteristic_timeseries') }} AS ts
INNER JOIN {{ source('source_snow_us_real_estate', 'irs_migration_by_characteristic_attributes') }} AS a
    ON TRIM(ts.variable) = TRIM(a.variable)
LEFT JOIN {{ ref('geography_index') }} AS gi
    ON {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} = gi.geo_id
