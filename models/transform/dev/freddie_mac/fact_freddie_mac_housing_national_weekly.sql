-- TRANSFORM.DEV.FACT_FREDDIE_MAC_HOUSING_NATIONAL_WEEKLY — Freddie Mac PMMS / housing (national, weekly-dominant).
-- Canonical: GEO_LEVEL_CODE (national when geography missing for country/USA), FREQUENCY_CODE from attributes (defaults weekly-friendly).
{{ config(
    alias='fact_freddie_mac_housing_national_weekly',
    tags=['transform', 'transform_dev', 'freddie_mac', 'fact_freddie_mac'],
) }}

SELECT
    TRIM(ts.geo_id) AS SOURCE_GEO_ID,
    {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} AS GEO_ID,
    gi.geo_name AS GEO_NAME,
    gi.source_level AS SOURCE_LEVEL,
    coalesce(gi.geo_level_code, 'national') AS GEO_LEVEL_CODE,
    {{ normalize_cybersyn_frequency_col('a', 'FREQUENCY') }} AS FREQUENCY_CODE,
    ts.date AS DATE_REFERENCE,
    TRIM(ts.variable) AS VARIABLE,
    TRIM(a.variable_name) AS VARIABLE_NAME,
    TRIM(a.unit) AS UNIT,
    ts.value::FLOAT AS VALUE
FROM {{ source('source_snow_us_real_estate', 'freddie_mac_housing_timeseries') }} AS ts
INNER JOIN {{ source('source_snow_us_real_estate', 'freddie_mac_housing_attributes') }} AS a
    ON TRIM(ts.variable) = TRIM(a.variable)
LEFT JOIN {{ ref('geography_index') }} AS gi
    ON {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} = gi.geo_id
