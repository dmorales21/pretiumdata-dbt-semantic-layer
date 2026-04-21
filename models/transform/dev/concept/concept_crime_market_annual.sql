{#-
  **Crime** — annual **CBSA** spine from Markerr H3 R8 crime snapshot.

  ``source('transform_dev', 'fact_markerr_crime_h3_r8_snapshot')`` is static hex grain; this mart **averages** vendor
  indices across hex rows within each ``cbsa_id``. ``month_start`` = Dec 31 of ``vars.concept_acs5_cbsa_reference_year``
  (same anchor as other annual market concepts).

  Emits one output row per ``(cbsa_id, metric_id_observe)`` for overall / violent / property indices (vendor scale and 0–100 transforms).
-#}

{{ config(
    materialized='table',
    alias='concept_crime_market_annual',
    tags=['semantic', 'concept', 'crime', 'markerr'],
) }}

{% set _yr = var('concept_acs5_cbsa_reference_year', 2024) | int %}

WITH markerr_hex AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(f.cbsa_id)), 5, '0') AS cbsa_id,
        TRY_TO_DOUBLE(TO_VARCHAR(f.crime_index_wavg)) AS crime_index_wavg,
        TRY_TO_DOUBLE(TO_VARCHAR(f.violent_crime_index_wavg)) AS violent_crime_index_wavg,
        TRY_TO_DOUBLE(TO_VARCHAR(f.property_crime_index_wavg)) AS property_crime_index_wavg,
        TRY_TO_DOUBLE(TO_VARCHAR(f.crime_index_wavg_0_100)) AS crime_index_wavg_0_100,
        TRY_TO_DOUBLE(TO_VARCHAR(f.violent_crime_index_wavg_0_100)) AS violent_crime_index_wavg_0_100,
        TRY_TO_DOUBLE(TO_VARCHAR(f.property_crime_index_wavg_0_100)) AS property_crime_index_wavg_0_100
    FROM {{ source('transform_dev', 'fact_markerr_crime_h3_r8_snapshot') }} AS f
    WHERE f.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(f.cbsa_id)) <> ''
),

markerr_cbsa AS (
    SELECT
        cbsa_id,
        AVG(crime_index_wavg) AS crime_index_wavg,
        AVG(violent_crime_index_wavg) AS violent_crime_index_wavg,
        AVG(property_crime_index_wavg) AS property_crime_index_wavg,
        AVG(crime_index_wavg_0_100) AS crime_index_wavg_0_100,
        AVG(violent_crime_index_wavg_0_100) AS violent_crime_index_wavg_0_100,
        AVG(property_crime_index_wavg_0_100) AS property_crime_index_wavg_0_100
    FROM markerr_hex
    GROUP BY 1
),

markerr_long AS (
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'markerr_crime_overall_index_wavg_cbsa' AS metric_id_observe,
        crime_index_wavg AS metric_value
    FROM markerr_cbsa
    WHERE crime_index_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'markerr_crime_violent_index_wavg_cbsa' AS metric_id_observe,
        violent_crime_index_wavg AS metric_value
    FROM markerr_cbsa
    WHERE violent_crime_index_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'markerr_crime_property_index_wavg_cbsa' AS metric_id_observe,
        property_crime_index_wavg AS metric_value
    FROM markerr_cbsa
    WHERE property_crime_index_wavg IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'markerr_crime_overall_index_wavg_0_100_cbsa' AS metric_id_observe,
        crime_index_wavg_0_100 AS metric_value
    FROM markerr_cbsa
    WHERE crime_index_wavg_0_100 IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'markerr_crime_violent_index_wavg_0_100_cbsa' AS metric_id_observe,
        violent_crime_index_wavg_0_100 AS metric_value
    FROM markerr_cbsa
    WHERE violent_crime_index_wavg_0_100 IS NOT NULL
    UNION ALL
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        cbsa_id,
        'markerr_crime_property_index_wavg_0_100_cbsa' AS metric_id_observe,
        property_crime_index_wavg_0_100 AS metric_value
    FROM markerr_cbsa
    WHERE property_crime_index_wavg_0_100 IS NOT NULL
)

SELECT
    'crime' AS concept_code,
    'MARKERR_CRIME' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_markerr_crime_h3_r8_snapshot' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('crime', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('crime', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('crime', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM markerr_long AS c
LEFT JOIN markerr_long AS h
    ON c.cbsa_id = h.cbsa_id
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = DATEADD('year', -1, c.month_start)
