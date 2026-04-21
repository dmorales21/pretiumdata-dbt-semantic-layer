{{ config(
    materialized='table',
    alias='concept_transactions_market_monthly',
    tags=['semantic', 'concept', 'transactions', 'zillow']
) }}

WITH zillow_sales_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_transactions_market_zillow_metric_pattern', '%sales%') }}')
                        THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_sales') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_sales_pick AS (
    SELECT *
    FROM zillow_sales_ranked
    WHERE metric_rn = 1
)

SELECT
    'transactions' AS concept_code,
    'ZILLOW' AS vendor_code,
    c.month_start,
    'cbsa' AS geo_level_code,
    c.cbsa_id AS geo_id,
    c.cbsa_id,
    CAST(NULL AS VARCHAR(8)) AS county_fips,
    CAST(NULL AS VARCHAR(4)) AS state_fips,
    TRUE AS has_census_geo,
    'fact_zillow_sales' AS census_geo_source,
    c.metric_id_observe,
    CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'current') }},
    CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('transactions', 'forecast') }},
    CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
    CAST(NULL AS DATE) AS forecast_month_start,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM zillow_sales_pick AS c
LEFT JOIN zillow_sales_pick AS h
    ON c.cbsa_id = h.cbsa_id
   AND c.metric_id_observe = h.metric_id_observe
   AND h.month_start = ADD_MONTHS(c.month_start, -12)
