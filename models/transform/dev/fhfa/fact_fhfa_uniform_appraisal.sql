-- TRANSFORM.DEV.FACT_FHFA_UNIFORM_APPRAISAL — FHFA Uniform Appraisal Dataset long-form series (SOURCE_SNOW.US_REAL_ESTATE).
{{ config(
    alias='fact_fhfa_uniform_appraisal',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn'],
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
FROM {{ source('source_snow_us_real_estate', 'fhfa_uniform_appraisal_timeseries') }} AS ts
INNER JOIN {{ source('source_snow_us_real_estate', 'fhfa_uniform_appraisal_attributes') }} AS a
    ON TRIM(ts.variable) = TRIM(a.variable)
LEFT JOIN {{ ref('geography_index') }} AS gi
    ON {{ normalize_cybersyn_geo_id('trim(ts.geo_id)') }} = gi.geo_id
