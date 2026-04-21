-- AIGE county automation index — long form (date_reference, geo_id, metric_id, value).
-- Builds from **SOURCE_PROD.AIGE.AIGE_COUNTIES** (VARIANT) when `aige_counties_enabled`; no TRANSFORM_PROD /
-- ANALYTICS_PROD / EDW_PROD reads. Unpivot contract matches legacy `FACT_AIGE_COUNTIES` long grain.
-- Governance: pretium-ai-dbt `AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md` §2.

{{ config(
    alias='FACT_AIGE_COUNTIES',
    materialized='view',
    tags=['transform', 'transform_dev', 'aige', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('aige_counties_enabled', false) %}

WITH source AS (
    SELECT
        v,
        _loaded_at
    FROM {{ source('source_prod_aige', 'aige_counties') }}
),

extracted AS (
    SELECT
        LPAD(TRIM(v:FIPS::varchar), 5, '0') AS geo_id,
        TRY_TO_DOUBLE(v:AIGE::varchar) AS aige,
        TRY_TO_DOUBLE(v['AIGE_plot']::varchar) AS aige_plot,
        COALESCE(DATE(_loaded_at), CURRENT_DATE()) AS date_reference
    FROM source
    WHERE v:FIPS IS NOT NULL
      AND TRIM(v:FIPS::varchar) <> ''
),

with_canonical AS (
    SELECT
        geo_id,
        'COUNTY_FIPS' AS geo_level_code,
        date_reference,
        aige,
        aige_plot
    FROM extracted
    WHERE LENGTH(geo_id) = 5
),

unpivoted AS (
    SELECT
        date_reference,
        geo_id,
        geo_level_code,
        'AIGE_SCORE' AS metric_id,
        aige::double AS value,
        'AIGE' AS vendor_name,
        'OK' AS quality_flag
    FROM with_canonical
    WHERE aige IS NOT NULL
    UNION ALL
    SELECT
        date_reference,
        geo_id,
        geo_level_code,
        'AIGE_PLOT',
        aige_plot::double,
        'AIGE',
        'OK'
    FROM with_canonical
    WHERE aige_plot IS NOT NULL
)

SELECT
    date_reference,
    geo_id,
    geo_level_code,
    metric_id,
    value,
    vendor_name,
    quality_flag
FROM unpivoted
WHERE value IS NOT NULL

{% else %}

SELECT
    CAST(NULL AS date) AS date_reference,
    CAST(NULL AS varchar) AS geo_id,
    CAST(NULL AS varchar) AS geo_level_code,
    CAST(NULL AS varchar) AS metric_id,
    CAST(NULL AS double) AS value,
    CAST(NULL AS varchar) AS vendor_name,
    CAST(NULL AS varchar) AS quality_flag
WHERE 1 = 0

{% endif %}
