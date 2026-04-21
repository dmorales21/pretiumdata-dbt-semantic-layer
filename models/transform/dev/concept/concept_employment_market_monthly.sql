{{ config(
    materialized='table',
    alias='concept_employment_market_monthly',
    tags=['semantic', 'concept', 'employment', 'bls', 'laus']
) }}

WITH laus_cbsa AS (
    SELECT
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(l.DATE_REFERENCE)))::DATE AS month_start,
        TRIM(TO_VARCHAR(l.AREA_CODE)) AS area_code,
        TRY_TO_DOUBLE(TO_VARCHAR(l.EMPLOYMENT)) AS employment_value
    FROM {{ ref('fact_bls_laus_cbsa_monthly') }} AS l
    WHERE l.DATE_REFERENCE IS NOT NULL
      AND l.AREA_CODE IS NOT NULL
      AND l.EMPLOYMENT IS NOT NULL
),

laus_county AS (
    SELECT
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(l.date_reference)))::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(l.county_fips)), 5, '0') AS county_fips,
        TRY_TO_DOUBLE(TO_VARCHAR(l.value)) AS employment_value
    FROM {{ ref('fact_bls_laus_county') }} AS l
    WHERE l.date_reference IS NOT NULL
      AND l.county_fips IS NOT NULL
      AND TRY_TO_NUMBER(TO_VARCHAR(l.measure_code)) = 5
      AND l.value IS NOT NULL
)

SELECT
    'employment' AS concept_code,
    'BLS_LAUS' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.area_code AS geo_id,
    c.area_code AS cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    FALSE AS has_census_geo,
    'fact_bls_laus_cbsa_monthly_area_code_observe_only' AS census_geo_source,
    'bls_laus_cbsa_employment' AS metric_id_observe,
    CAST(c.employment_value AS DOUBLE) AS {{ concept_metric_slot('employment', 'current') }},
    CAST(h.employment_value AS DOUBLE) AS {{ concept_metric_slot('employment', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('employment', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM laus_cbsa AS c
LEFT JOIN laus_cbsa AS h
    ON c.area_code = h.area_code
   AND h.month_start = ADD_MONTHS(c.month_start, -12)

UNION ALL

SELECT
    'employment' AS concept_code,
    'BLS_LAUS_COUNTY' AS vendor_code,
    c.month_start,
    'county' AS geo_level_code,
    c.county_fips AS geo_id,
    CAST(NULL AS VARCHAR(5)) AS cbsa_id,
    c.county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_bls_laus_county_measure_5' AS census_geo_source,
    'bls_laus_county_employment' AS metric_id_observe,
    CAST(c.employment_value AS DOUBLE) AS {{ concept_metric_slot('employment', 'current') }},
    CAST(h.employment_value AS DOUBLE) AS {{ concept_metric_slot('employment', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('employment', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM laus_county AS c
LEFT JOIN laus_county AS h
    ON c.county_fips = h.county_fips
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
