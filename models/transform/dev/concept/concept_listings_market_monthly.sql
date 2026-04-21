{{ config(
    materialized='table',
    alias='concept_listings_market_monthly',
    tags=['semantic', 'concept', 'listings', 'realtor', 'zillow']
) }}

WITH
realtor_base AS (
    SELECT
        DATE_TRUNC('month', r.date_reference)::DATE AS month_start,
        COALESCE(
            NULLIF(LPAD(LEFT(REGEXP_REPLACE(TRIM(TO_VARCHAR(r.geo_id)), '[^0-9]', ''), 5), 5, '0'), '00000'),
            TRIM(TO_VARCHAR(r.geo_id))
        ) AS cbsa_id,
        TRIM(TO_VARCHAR(r.metric_id)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(r.value)) AS metric_value
    FROM {{ ref('fact_realtor_inventory_cbsa') }} AS r
    WHERE r.date_reference IS NOT NULL
      AND r.geo_id IS NOT NULL
      AND r.value IS NOT NULL
),

realtor_listings AS (
    SELECT
        'listings' AS concept_code,
        'REALTOR' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        (LENGTH(c.cbsa_id) = 5) AS has_census_geo,
        'fact_realtor_inventory_cbsa' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('listings', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('listings', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('listings', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM realtor_base AS c
    LEFT JOIN realtor_base AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zillow_dom_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_listings_market_zillow_dom_metric_pattern', var('concept_absorption_market_zillow_dom_metric_pattern', '%days_on_market%')) }}')
                        THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_days_on_market_and_price_cuts') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_dom_pick AS (
    SELECT *
    FROM zillow_dom_ranked
    WHERE metric_rn = 1
),

zillow_dom_listings AS (
    SELECT
        'listings' AS concept_code,
        'ZILLOW_DOM' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_days_on_market_and_price_cuts' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('listings', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('listings', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('listings', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_dom_pick AS c
    LEFT JOIN zillow_dom_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zillow_listings_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_listings_market_zillow_listings_metric_pattern', var('concept_absorption_market_zillow_listings_metric_pattern', '%for_sale%list%')) }}')
                        THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_for_sale_listings') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_listings_pick AS (
    SELECT *
    FROM zillow_listings_ranked
    WHERE metric_rn = 1
),

zillow_for_sale_listings AS (
    SELECT
        'listings' AS concept_code,
        'ZILLOW_LISTINGS' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_for_sale_listings' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('listings', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('listings', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('listings', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_listings_pick AS c
    LEFT JOIN zillow_listings_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
)

SELECT * FROM realtor_listings
UNION ALL
SELECT * FROM zillow_dom_listings
UNION ALL
SELECT * FROM zillow_for_sale_listings
