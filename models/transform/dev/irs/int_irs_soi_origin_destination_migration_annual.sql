-- Ephemeral base for IRS SOI county OD flows (annual). Consumed by *_county and *_cbsa FACT views.
{{ config(
    materialized='ephemeral',
    tags=['transform', 'transform_dev', 'irs', 'internal'],
) }}

SELECT
    TRIM(ts.from_geo_id) AS SOURCE_FROM_GEO_ID,
    TRIM(ts.to_geo_id) AS SOURCE_TO_GEO_ID,
    {{ normalize_cybersyn_geo_id('trim(ts.from_geo_id)') }} AS FROM_GEO_ID,
    {{ normalize_cybersyn_geo_id('trim(ts.to_geo_id)') }} AS TO_GEO_ID,
    gi_from.geo_name AS FROM_GEO_NAME,
    gi_to.geo_name AS TO_GEO_NAME,
    gi_from.source_level AS FROM_SOURCE_LEVEL,
    gi_to.source_level AS TO_SOURCE_LEVEL,
    coalesce(gi_from.geo_level_code, 'county') AS FROM_GEO_LEVEL_CODE,
    coalesce(gi_to.geo_level_code, 'county') AS TO_GEO_LEVEL_CODE,
    'annual' AS FREQUENCY_CODE,
    ts.date AS DATE_REFERENCE,
    TRIM(ts.variable_name) AS VARIABLE_NAME,
    ts.value::FLOAT AS VALUE,
    coalesce(ts.suppressed, 0)::NUMBER(38, 0) AS SUPPRESSED
FROM {{ source('source_snow_us_real_estate', 'irs_origin_destination_migration_timeseries') }} AS ts
LEFT JOIN {{ ref('geography_index') }} AS gi_from
    ON {{ normalize_cybersyn_geo_id('trim(ts.from_geo_id)') }} = gi_from.geo_id
LEFT JOIN {{ ref('geography_index') }} AS gi_to
    ON {{ normalize_cybersyn_geo_id('trim(ts.to_geo_id)') }} = gi_to.geo_id
