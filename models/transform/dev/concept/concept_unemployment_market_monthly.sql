{{ config(
    materialized='table',
    alias='concept_unemployment_market_monthly',
    tags=['semantic', 'concept', 'unemployment', 'bls', 'laus']
) }}

WITH laus_cbsa_base AS (
    SELECT
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(l.DATE_REFERENCE)))::DATE AS month_start,
        TRIM(TO_VARCHAR(l.AREA_CODE)) AS area_code,
        TRY_TO_DOUBLE(TO_VARCHAR(l.UNEMPLOYMENT_RATE)) AS unemployment_rate,
        TRY_TO_DOUBLE(TO_VARCHAR(l.UNEMPLOYED_COUNT)) AS unemployed_count
    FROM {{ ref('fact_bls_laus_cbsa_monthly') }} AS l
    WHERE l.DATE_REFERENCE IS NOT NULL
      AND l.AREA_CODE IS NOT NULL
),

laus_unpivot AS (
    SELECT
        month_start,
        area_code,
        'bls_laus_cbsa_unemployment_rate' AS metric_id_observe,
        unemployment_rate AS metric_value
    FROM laus_cbsa_base
    WHERE unemployment_rate IS NOT NULL
    UNION ALL
    SELECT
        month_start,
        area_code,
        'bls_laus_cbsa_unemployed_count' AS metric_id_observe,
        unemployed_count AS metric_value
    FROM laus_cbsa_base
    WHERE unemployed_count IS NOT NULL
)

SELECT
    'unemployment' AS concept_code,
    'BLS_LAUS' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.area_code AS geo_id,
    c.area_code AS cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    FALSE AS has_census_geo,
    'fact_bls_laus_cbsa_monthly_area_code_observe_only' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('unemployment', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('unemployment', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('unemployment', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM laus_unpivot AS c
LEFT JOIN laus_unpivot AS h
    ON c.area_code = h.area_code
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
