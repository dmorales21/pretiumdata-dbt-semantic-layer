{#-
  **Income** — annual CBSA anchor from ACS5 H3 R8 snapshot rollups (``int_acs5_h3_r8_cbsa_demographics_rollups``).

  ``month_start`` is **Dec 31** of ``vars.concept_acs5_cbsa_reference_year`` (ACS5 vintage anchor; aligns with other annual concepts using ``month_start`` as period key).

  Historical slot: prior calendar year same anchor via ``DATEADD(year, -1, month_start)``.
-#}

{{ config(
    materialized='table',
    alias='concept_income_market_annual',
    tags=['semantic', 'concept', 'income', 'census', 'acs'],
) }}

{% set _yr = var('concept_acs5_cbsa_reference_year', 2024) | int %}

WITH acs AS (
    SELECT
        DATE_FROM_PARTS({{ _yr }}, 12, 31)::DATE AS month_start,
        r.cbsa_id,
        r.median_hhi_wavg AS metric_value
    FROM {{ ref('int_acs5_h3_r8_cbsa_demographics_rollups') }} AS r
    WHERE r.median_hhi_wavg IS NOT NULL
)

SELECT
    'income' AS concept_code,
    'CENSUS_ACS5_H3_CBSA' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'int_acs5_h3_r8_cbsa_demographics_rollups' AS census_geo_source,
    'census_acs5_h3_r8_median_hhi_wavg_cbsa' AS metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('income', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('income', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('income', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM acs AS c
LEFT JOIN acs AS h
    ON c.cbsa_id = h.cbsa_id
   AND h.month_start = DATEADD('year', -1, c.month_start)
