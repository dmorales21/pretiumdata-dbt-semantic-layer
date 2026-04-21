{{ config(
    materialized='table',
    alias='concept_absorption_market_monthly',
    tags=['semantic', 'concept', 'absorption', 'costar']
) }}

{#-
  Market **absorption** (net demand vs supply / clearing dynamics) — distinct from **listings** (inventory, DOM, for-sale counts)
  and **transactions** (closed sales events). Primary vendor: CoStar MF DataExport ``ABSORPTION_UNITS`` on
  ``fact_costar_mf_market_cbsa_monthly`` (observe rows only; Multifamily slice via var).
-#}
{% set _cpt = var('concept_absorption_market_costar_property_type_pattern', '%Multifamily%') | replace("'", "''") %}

WITH costar_absorption AS (
    SELECT
        DATE_TRUNC('month', f.PERIOD::DATE)::DATE AS month_start,
        LPAD(TRIM(f.CBSA_ID::VARCHAR), 5, '0') AS cbsa_id,
        'costar_cbsa_monthly_absorption_units' AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.ABSORPTION_UNITS)) AS absorption_value
    FROM {{ ref('fact_costar_mf_market_cbsa_monthly') }} AS f
    WHERE f.CBSA_ID IS NOT NULL
      AND f.PERIOD IS NOT NULL
      AND f.IS_FORECAST IS DISTINCT FROM TRUE
      AND TRIM(COALESCE(f.PROPERTY_TYPE::VARCHAR, '')) ILIKE '{{ _cpt }}'
      AND f.ABSORPTION_UNITS IS NOT NULL
)

SELECT
    'absorption' AS concept_code,
    'COSTAR_MF_MARKET' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_costar_mf_market_cbsa_monthly' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.absorption_value AS DOUBLE) AS {{ concept_metric_slot('absorption', 'current') }},
    CAST(h.absorption_value AS DOUBLE) AS {{ concept_metric_slot('absorption', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('absorption', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM costar_absorption AS c
LEFT JOIN costar_absorption AS h
    ON c.cbsa_id = h.cbsa_id
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
