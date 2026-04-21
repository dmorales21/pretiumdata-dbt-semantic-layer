-- TRANSFORM.DEV.FACT_FREDDIE_MAC_HOUSING_NATIONAL_WEEKLY — Freddie Mac PMMS / housing (national, weekly-dominant).
-- Canonical: GEO_LEVEL_CODE (national when geography missing for country/USA), FREQUENCY_CODE from attributes (defaults weekly-friendly).
-- Grain: **GEO_ID × DATE × VARIABLE** per Cybersyn `FREDDIE_MAC_HOUSING_TIMESERIES`. `FREDDIE_MAC_HOUSING_ATTRIBUTES`
-- can ship multiple rows per VARIABLE; dedupe before join so we do not fan out timeseries rows.
{{ config(
    alias='fact_freddie_mac_housing_national_weekly',
    tags=['transform', 'transform_dev', 'freddie_mac', 'fact_freddie_mac'],
) }}

WITH attributes_dedup AS (
    SELECT
        TRIM(a.variable) AS variable_key,
        TRIM(a.variable_name) AS variable_name,
        TRIM(a.unit) AS unit,
        a.{{ adapter.quote('FREQUENCY') }}
    FROM {{ source('source_snow_us_real_estate', 'freddie_mac_housing_attributes') }} AS a
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRIM(a.variable)
        ORDER BY TRIM(a.variable_name), TRIM(a.unit), TRIM(COALESCE(TO_VARCHAR(a.{{ adapter.quote('FREQUENCY') }}), ''))
    ) = 1
)

SELECT
    TRIM(ts.geo_id) AS SOURCE_GEO_ID,
    {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} AS GEO_ID,
    gi.geo_name AS GEO_NAME,
    gi.source_level AS SOURCE_LEVEL,
    coalesce(gi.geo_level_code, 'national') AS GEO_LEVEL_CODE,
    {{ normalize_cybersyn_frequency_col('a', 'FREQUENCY') }} AS FREQUENCY_CODE,
    ts.date AS DATE_REFERENCE,
    TRIM(ts.variable) AS VARIABLE,
    a.variable_name AS VARIABLE_NAME,
    a.unit AS UNIT,
    ts.value::FLOAT AS VALUE
FROM {{ source('source_snow_us_real_estate', 'freddie_mac_housing_timeseries') }} AS ts
INNER JOIN attributes_dedup AS a
    ON TRIM(ts.variable) = a.variable_key
LEFT JOIN {{ ref('geography_index') }} AS gi
    ON {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} = gi.geo_id
