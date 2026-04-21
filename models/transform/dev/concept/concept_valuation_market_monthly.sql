{#-
  **Market valuation** — slots ``valuation_current`` / ``valuation_historical`` / ``valuation_forecast``.

  **Cherre** — ``cherre_avm_geo_stats`` MA snapshot (CBSA).
  **Zillow** — ``fact_zillow_home_values`` + ``fact_zillow_home_values_forecasts`` at CBSA grain.
  **FHFA** — ``fact_fhfa_house_price_cbsa`` + ``fact_fhfa_uniform_appraisal_cbsa``.

  This is intentionally a mixed vendor concept layer so downstream feature/model surfaces can consume
  a single valuation concept object while preserving ``metric_id_observe`` / ``vendor_code`` lineage.

  **Contract + consumer routing:** ``docs/reference/CONTRACT_RENT_AVM_VALUATION.md``.
  **FHFA UAD:** optional ``vars.concept_valuation_fhfa_uad_variable_regex`` (empty = no extra filter) to keep only
  month-comparable variables in this concept; see contract doc.
-#}

{{ config(
    materialized='table',
    alias='concept_valuation_market_monthly',
    tags=['semantic', 'concept', 'valuation', 'valuation_market', 'cherre']
) }}

{% set _valuation_uad_rx = var('concept_valuation_fhfa_uad_variable_regex', '') | replace("'", "''") %}

WITH snapshot_month AS (
    SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP())::DATE AS month_start
),

cherre_ma_valuation AS (
    SELECT
        'valuation_market' AS concept_code,
        'CHERRE' AS vendor_code,
        sm.month_start,
        'cbsa' AS geo_level_code,
        LPAD(TRIM(REGEXP_REPLACE(TO_VARCHAR(g.GEOGRAPHY_CODE), '[^0-9]', '')), 5, '0') AS geo_id,
        LPAD(TRIM(REGEXP_REPLACE(TO_VARCHAR(g.GEOGRAPHY_CODE), '[^0-9]', '')), 5, '0') AS cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'cherre_usa_avm_geo_stats_ma_snapshot' AS census_geo_source,
        'cherre_avg_estimated_value' AS metric_id_observe,
        CAST(g.AVG_ESTIMATED_VALUE AS DOUBLE) AS {{ concept_metric_slot('valuation', 'current') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('valuation', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('valuation', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM {{ ref('cherre_avm_geo_stats') }} AS g
    CROSS JOIN snapshot_month AS sm
    WHERE TRIM(TO_VARCHAR(g.GEOGRAPHY_TYPE)) = 'MA'
      AND g.GEOGRAPHY_CODE IS NOT NULL
      AND g.AVG_ESTIMATED_VALUE IS NOT NULL
),

zillow_home_values_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_valuation_market_zillow_metric_pattern', '%zhvi%') }}')
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
        z.metric_id,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN LOWER(z.metric_id) LIKE LOWER('{{ var('concept_valuation_market_zillow_metric_pattern', '%zhvi%') }}')
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

zillow_valuation AS (
    SELECT
        'valuation_market' AS concept_code,
        'ZILLOW' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_home_values_cbsa' AS census_geo_source,
        c.metric_id AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'historical') }},
        CAST(f.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'forecast') }},
        f.metric_id AS metric_id_forecast,
        f.month_start AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_home_values_pick AS c
    LEFT JOIN zillow_home_values_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
       AND h.metric_id = c.metric_id
    LEFT JOIN zillow_home_values_fcst_pick AS f
        ON c.cbsa_id = f.cbsa_id
       AND c.month_start = f.month_start
       AND c.metric_id = f.metric_id
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

fhfa_house_price_valuation AS (
    SELECT
        'valuation_market' AS concept_code,
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
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('valuation', 'forecast') }},
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
    {% if _valuation_uad_rx | trim != '' %}
      AND REGEXP_LIKE(LOWER(TRIM(TO_VARCHAR(f.variable))), LOWER('{{ _valuation_uad_rx }}'))
    {% endif %}
),

fhfa_uniform_appraisal_valuation AS (
    SELECT
        'valuation_market' AS concept_code,
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
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('valuation', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('valuation', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM fhfa_uniform_appraisal_cbsa AS c
    LEFT JOIN fhfa_uniform_appraisal_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
)

SELECT * FROM cherre_ma_valuation
UNION ALL
SELECT * FROM zillow_valuation
UNION ALL
SELECT * FROM fhfa_house_price_valuation
UNION ALL
SELECT * FROM fhfa_uniform_appraisal_valuation
