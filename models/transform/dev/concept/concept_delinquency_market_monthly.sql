{{ config(
    materialized='table',
    alias='concept_delinquency_market_monthly',
    tags=['semantic', 'concept', 'delinquency', 'fhfa']
) }}

{% set _delinq_rx = var('concept_delinquency_market_fhfa_variable_regex', 'delinq|serious|foreclosure|noncurrent') | replace("'", "''") %}

WITH fhfa_cbsa AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_fhfa_mortgage_performance_cbsa_monthly') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _delinq_rx }}')
),

fhfa_county_to_cbsa AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(gl.cbsa_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        AVG(TRY_TO_DOUBLE(TO_VARCHAR(f.value))) AS metric_value
    FROM {{ ref('fact_fhfa_mortgage_performance_county_monthly') }} AS f
    INNER JOIN {{ ref('geography_latest') }} AS gl
        ON LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') = LPAD(TRIM(TO_VARCHAR(gl.geo_id)), 5, '0')
       AND LOWER(gl.geo_level_code) = 'county'
       AND gl.cbsa_id IS NOT NULL
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), '{{ _delinq_rx }}')
    GROUP BY
        DATE_TRUNC('month', f.date_reference)::DATE,
        LPAD(TRIM(TO_VARCHAR(gl.cbsa_id)), 5, '0'),
        TRIM(TO_VARCHAR(f.variable))
),

fhfa_union AS (
    SELECT 'FHFA_CBSA' AS vendor_code, * FROM fhfa_cbsa
    UNION ALL
    SELECT 'FHFA_COUNTY_ROLLUP' AS vendor_code, * FROM fhfa_county_to_cbsa
),

fhfa_pick AS (
    SELECT
        vendor_code,
        month_start,
        cbsa_id,
        metric_id_observe,
        metric_value
    FROM fhfa_union
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY vendor_code, month_start, cbsa_id
        ORDER BY metric_id_observe
    ) = 1
)

SELECT
    'delinquency' AS concept_code,
    p.vendor_code,
    p.month_start,
    'cbsa' AS geo_level_code,
    p.cbsa_id AS geo_id,
    p.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_fhfa_mortgage_performance_cbsa_county_rollup' AS census_geo_source,
    p.metric_id_observe,
    CAST(p.metric_value AS DOUBLE) AS {{ concept_metric_slot('delinquency', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('delinquency', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('delinquency', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM fhfa_pick AS p
LEFT JOIN fhfa_pick AS h
    ON p.vendor_code = h.vendor_code
   AND p.cbsa_id = h.cbsa_id
   AND p.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(p.month_start, -12)
