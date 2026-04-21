-- TRANSFORM.DEV.FACT_HUD_HOUSING_SERIES — HUD long-form series (GLOBAL_GOVERNMENT.CYBERSYN).
-- Canonical: GEO_LEVEL_CODE (REFERENCE.GEOGRAPHY or unmapped), FREQUENCY_CODE from attributes.FREQUENCY.
{{ config(
    alias='fact_hud_housing_series',
    tags=['transform', 'transform_dev', 'hud', 'fact_hud', 'cybersyn'],
) }}

SELECT
    TRIM(ts.geo_id) AS SOURCE_GEO_ID,
    {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} AS GEO_ID,
    gi.geo_name AS GEO_NAME,
    gi.source_level AS SOURCE_LEVEL,
    coalesce(gi.geo_level_code, 'unmapped') AS GEO_LEVEL_CODE,
    {{ normalize_cybersyn_frequency_col('a', 'FREQUENCY') }} AS FREQUENCY_CODE,
    ts.date AS DATE_REFERENCE,
    TRIM(ts.variable) AS VARIABLE,
    TRIM(a.variable_name) AS VARIABLE_NAME,
    TRIM(a.unit) AS UNIT,
    ts.value::FLOAT AS VALUE
FROM {{ source('global_government_cybersyn', 'housing_urban_development_timeseries') }} AS ts
INNER JOIN {{ source('global_government_cybersyn', 'housing_urban_development_attributes') }} AS a
    ON TRIM(ts.variable) = TRIM(a.variable)
LEFT JOIN {{ ref('geography_index') }} AS gi
    ON {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} = gi.geo_id
