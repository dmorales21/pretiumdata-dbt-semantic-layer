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

laus_cbsa_long AS (
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
),

laus_county_base AS (
    SELECT
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(l.date_reference)))::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(l.county_fips)), 5, '0') AS county_fips,
        TRY_TO_NUMBER(TO_VARCHAR(l.measure_code)) AS measure_code,
        TRY_TO_DOUBLE(TO_VARCHAR(l.value)) AS metric_value
    FROM {{ ref('fact_bls_laus_county') }} AS l
    WHERE l.date_reference IS NOT NULL
      AND l.county_fips IS NOT NULL
      AND TRY_TO_NUMBER(TO_VARCHAR(l.measure_code)) IN (3, 4)
      AND l.value IS NOT NULL
),

laus_county_long AS (
    SELECT
        month_start,
        county_fips,
        'bls_laus_county_unemployment_rate' AS metric_id_observe,
        metric_value
    FROM laus_county_base
    WHERE measure_code = 3
    UNION ALL
    SELECT
        month_start,
        county_fips,
        'bls_laus_county_unemployed_persons' AS metric_id_observe,
        metric_value
    FROM laus_county_base
    WHERE measure_code = 4
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
FROM laus_cbsa_long AS c
LEFT JOIN laus_cbsa_long AS h
    ON c.area_code = h.area_code
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)

UNION ALL

SELECT
    'unemployment' AS concept_code,
    'BLS_LAUS_COUNTY' AS vendor_code,
    c.month_start,
    'county' AS geo_level_code,
    c.county_fips AS geo_id,
    CAST(NULL AS VARCHAR(5)) AS cbsa_id,
    c.county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_bls_laus_county_measures_3_4' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('unemployment', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('unemployment', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('unemployment', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM laus_county_long AS c
LEFT JOIN laus_county_long AS h
    ON c.county_fips = h.county_fips
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
