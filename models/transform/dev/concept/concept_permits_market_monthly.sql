{#-
  **Permits** — monthly CBSA, Census BPS long-form on ``fact_bps_permits_county`` (silver is CBSA grain).

  **MET_001 alignment (default):** ``vars.concept_permits_met_001_canonical`` = ``true`` narrows rows with
  ``concept_permits_met_001_*_ilike`` filters (IC overrides after ``DESCRIBE`` / prod slice), dedupes on the silver grain
  + ``FILE_TYPE`` (latest ``LOAD_TIMESTAMP``), then **sums** ``VALUE`` to one row per ``month_start`` × ``cbsa_id`` with
  ``metric_id_observe = 'bps_permits_measure_value'`` (matches ``metric.csv`` **MET_001** ``metric_code``).

  **Exploration mode:** set ``concept_permits_met_001_canonical: false`` to emit composite ``metric_id_observe`` keys
  ``bps|MEASURE|BUILDING_USE|ESTIMATE_TYPE`` and use the ``concept_permits_market_bps_*_ilike`` filters (default ``'%'``).
-#}

{{ config(
    materialized='table',
    alias='concept_permits_market_monthly',
    tags=['semantic', 'concept', 'permits', 'bps', 'census'],
) }}

{% set _canonical = var('concept_permits_met_001_canonical', true) %}
{% if _canonical %}
{% set _m = var('concept_permits_met_001_measure_ilike', '%') | replace("'", "''") %}
{% set _e = var('concept_permits_met_001_estimate_type_ilike', '%') | replace("'", "''") %}
{% set _b = var('concept_permits_met_001_building_use_ilike', '%') | replace("'", "''") %}
{% else %}
{% set _m = var('concept_permits_market_bps_measure_ilike', '%') | replace("'", "''") %}
{% set _e = var('concept_permits_market_bps_estimate_type_ilike', '%') | replace("'", "''") %}
{% set _b = var('concept_permits_market_bps_building_use_ilike', '%') | replace("'", "''") %}
{% endif %}

WITH bps_ranked AS (
    SELECT
        DATE_TRUNC('month', p.DATE_REFERENCE)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(p.CBSA_CODE_OMB)), 5, '0') AS cbsa_id,
        CONCAT(
            'bps|',
            COALESCE(NULLIF(UPPER(TRIM(TO_VARCHAR(p.MEASURE))), ''), 'UNKNOWN'),
            '|',
            COALESCE(NULLIF(UPPER(TRIM(TO_VARCHAR(p.BUILDING_USE))), ''), 'UNKNOWN'),
            '|',
            COALESCE(NULLIF(UPPER(TRIM(TO_VARCHAR(p.ESTIMATE_TYPE))), ''), 'UNKNOWN')
        ) AS series_key,
        TRY_TO_DOUBLE(TO_VARCHAR(p.VALUE)) AS row_value,
        ROW_NUMBER() OVER (
            PARTITION BY
                DATE_TRUNC('month', p.DATE_REFERENCE)::DATE,
                LPAD(TRIM(TO_VARCHAR(p.CBSA_CODE_OMB)), 5, '0'),
                UPPER(TRIM(TO_VARCHAR(p.MEASURE))),
                UPPER(TRIM(TO_VARCHAR(p.BUILDING_USE))),
                UPPER(TRIM(TO_VARCHAR(p.ESTIMATE_TYPE))),
                COALESCE(TO_VARCHAR(p.YEAR_REFERENCE), ''),
                COALESCE(TO_VARCHAR(p.MONTH_REFERENCE), ''),
                COALESCE(UPPER(TRIM(TO_VARCHAR(p.FILE_TYPE))), '')
            ORDER BY p.LOAD_TIMESTAMP DESC NULLS LAST
        ) AS rn
    FROM {{ ref('fact_bps_permits_county') }} AS p
    WHERE p.DATE_REFERENCE IS NOT NULL
      AND p.CBSA_CODE_OMB IS NOT NULL
      AND TRIM(TO_VARCHAR(p.CBSA_CODE_OMB)) <> ''
      AND p.VALUE IS NOT NULL
      AND TRIM(TO_VARCHAR(p.MEASURE)) ILIKE '{{ _m }}'
      AND TRIM(TO_VARCHAR(p.ESTIMATE_TYPE)) ILIKE '{{ _e }}'
      AND TRIM(TO_VARCHAR(p.BUILDING_USE)) ILIKE '{{ _b }}'
),

bps_dedup AS (
    SELECT
        month_start,
        cbsa_id,
        series_key,
        row_value
    FROM bps_ranked
    WHERE rn = 1
),

{% if _canonical %}
bps_agg AS (
    SELECT
        month_start,
        cbsa_id,
        'bps_permits_measure_value'::VARCHAR(256) AS metric_id_observe,
        SUM(row_value) AS metric_value
    FROM bps_dedup
    GROUP BY 1, 2
)
{% else %}
bps_agg AS (
    SELECT
        month_start,
        cbsa_id,
        series_key AS metric_id_observe,
        SUM(row_value) AS metric_value
    FROM bps_dedup
    GROUP BY 1, 2, 3
)
{% endif %}

SELECT
    'permits' AS concept_code,
    'CENSUS_BPS' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_bps_permits_county' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('permits', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('permits', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('permits', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM bps_agg AS c
LEFT JOIN bps_agg AS h
    ON c.cbsa_id = h.cbsa_id
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
