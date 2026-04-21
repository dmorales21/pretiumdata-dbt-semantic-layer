{#-
  **Labor** — CBSA labor-force participation proxy from ACS5 H3 R8 snapshot (B23025 roll-up), population-weighted across hexes.

  See ``int_acs5_h3_r8_cbsa_demographics_rollups``. ``month_start`` = Dec 31 of ``vars.concept_acs5_cbsa_reference_year``.
-#}

{{ config(
    materialized='table',
    alias='concept_labor_market_annual',
    tags=['semantic', 'concept', 'labor', 'census', 'acs'],
) }}

{% set _yr = var('concept_acs5_cbsa_reference_year', 2024) | int %}

WITH acs AS (
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        r.cbsa_id,
        r.labor_force_participation_rate_wavg AS metric_value
    FROM {{ ref('int_acs5_h3_r8_cbsa_demographics_rollups') }} AS r
    WHERE r.labor_force_participation_rate_wavg IS NOT NULL
)

SELECT
    'labor' AS concept_code,
    'CENSUS_ACS5_H3_CBSA' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'int_acs5_h3_r8_cbsa_demographics_rollups' AS census_geo_source,
    'census_acs5_h3_r8_labor_force_participation_rate_wavg_cbsa' AS metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('labor', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('labor', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('labor', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM acs AS c
LEFT JOIN acs AS h
    ON c.cbsa_id = h.cbsa_id
   AND h.month_start = DATEADD('year', -1, c.month_start)
