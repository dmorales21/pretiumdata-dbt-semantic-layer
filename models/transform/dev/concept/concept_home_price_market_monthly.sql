{{ config(
    materialized='table',
    alias='concept_home_price_market_monthly',
    tags=['semantic', 'concept', 'homeprice', 'zillow', 'fhfa']
) }}

WITH zillow_home_values_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_home_price_market_zillow_home_values_metric_pattern', '%zhvi%') }}')
                        THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_home_values') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_home_values_pick AS (
    SELECT *
    FROM zillow_home_values_ranked
    WHERE metric_rn = 1
),

zillow_home_values_fcst_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_home_price_market_zillow_home_values_metric_pattern', '%zhvi%') }}')
                        THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_home_values_forecasts') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_home_values_fcst_pick AS (
    SELECT *
    FROM zillow_home_values_fcst_ranked
    WHERE metric_rn = 1
),

zillow_home_values_concept AS (
    SELECT
        'homeprice' AS concept_code,
        'ZILLOW_HOME_VALUES' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_home_values' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'historical') }},
        CAST(f.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'forecast') }},
        f.metric_id_observe AS metric_id_forecast,
        f.month_start AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_home_values_pick AS c
    LEFT JOIN zillow_home_values_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
    LEFT JOIN zillow_home_values_fcst_pick AS f
        ON c.cbsa_id = f.cbsa_id
       AND c.metric_id_observe = f.metric_id_observe
       AND c.month_start = f.month_start
),

fhfa_house_price_cbsa AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_fhfa_house_price_cbsa_monthly') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
),

fhfa_house_price_concept AS (
    SELECT
        'homeprice' AS concept_code,
        'FHFA_HPI' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_fhfa_house_price_cbsa' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM fhfa_house_price_cbsa AS c
    LEFT JOIN fhfa_house_price_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

fhfa_uniform_appraisal_cbsa AS (
    SELECT
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.geo_id)), 5, '0') AS cbsa_id,
        TRIM(TO_VARCHAR(f.variable)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(f.value)) AS metric_value
    FROM {{ ref('fact_fhfa_uniform_appraisal_cbsa_monthly') }} AS f
    WHERE f.date_reference IS NOT NULL
      AND f.geo_id IS NOT NULL
      AND f.value IS NOT NULL
),

fhfa_uniform_appraisal_concept AS (
    SELECT
        'homeprice' AS concept_code,
        'FHFA_UAD' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_fhfa_uniform_appraisal_cbsa' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM fhfa_uniform_appraisal_cbsa AS c
    LEFT JOIN fhfa_uniform_appraisal_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zillow_affordability_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_home_price_market_zillow_affordability_metric_pattern', '%afford%') }}')
                        THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_affordability') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_affordability_pick AS (
    SELECT *
    FROM zillow_affordability_ranked
    WHERE metric_rn = 1
),

zillow_affordability_concept AS (
    SELECT
        'homeprice' AS concept_code,
        'ZILLOW_AFFORDABILITY' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_affordability' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_affordability_pick AS c
    LEFT JOIN zillow_affordability_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zillow_for_sale_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_home_price_market_zillow_for_sale_metric_pattern', '%for_sale%list%') }}')
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

zillow_for_sale_pick AS (
    SELECT *
    FROM zillow_for_sale_ranked
    WHERE metric_rn = 1
),

zillow_for_sale_concept AS (
    SELECT
        'homeprice' AS concept_code,
        'ZILLOW_FOR_SALE_LISTINGS' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_for_sale_listings' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('homeprice', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_for_sale_pick AS c
    LEFT JOIN zillow_for_sale_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
)

SELECT * FROM zillow_home_values_concept
UNION ALL
SELECT * FROM fhfa_house_price_concept
UNION ALL
SELECT * FROM fhfa_uniform_appraisal_concept
UNION ALL
SELECT * FROM zillow_affordability_concept
UNION ALL
SELECT * FROM zillow_for_sale_concept
