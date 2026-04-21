{#-
  **Transactions** — monthly **CBSA** spine.

  - **Zillow** — ``ref('fact_zillow_sales')`` (existing primary series via ``concept_transactions_market_zillow_metric_pattern``).
  - **Cherre Recorder** — SFR + MF H3 monthly facts rolled to CBSA × month (**sale_count** sum) from
    ``source('transform_dev_corridor_transaction_facts', …)`` (**TRANSFORM.DEV** tables).
  - **RCA** — MF closed-sale H3 monthly → CBSA × month (**sale_count** sum).
  - **Zonda** — deeds H3 monthly → CBSA × month (**sale_count** sum); branch is empty until the fact is populated.
  - **Zonda SFR** — ``FACT_ZONDA_SFR_H3_R8_MONTHLY`` → CBSA × month (**sfr_annual_closings_wavg** sum across H3 rows).

  Disable non-Zillow branches: ``vars.concept_transactions_include_cherre_rca_zonda: false``.
  Disable Zonda SFR only: ``vars.concept_transactions_include_zonda_sfr: false``.
-#}

{{ config(
    materialized='table',
    alias='concept_transactions_market_monthly',
    tags=['semantic', 'concept', 'transactions', 'zillow', 'cherre', 'rca', 'zonda'],
) }}

{% set _ext = var('concept_transactions_include_cherre_rca_zonda', true) %}
{% set _zsf = var('concept_transactions_include_zonda_sfr', true) %}

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
),

zillow_out AS (
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
),

cherre_sfr_cbsa AS (
    SELECT
        DATE_TRUNC('month', s.recorded_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(s.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(s.sale_count)::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_cherre_recorder_sfr_h3_r8_monthly') }} AS s
    WHERE s.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(s.cbsa_id)) != ''
      AND s.recorded_month IS NOT NULL
    GROUP BY 1, 2
),

cherre_sfr_out AS (
    SELECT
        'transactions' AS concept_code,
        'CHERRE_RECORDER_SFR' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_cherre_recorder_sfr_h3_r8_monthly' AS census_geo_source,
        'concept_transactions_cherre_recorder_sfr_sale_count_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('transactions', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM cherre_sfr_cbsa AS c
    LEFT JOIN cherre_sfr_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

cherre_mf_cbsa AS (
    SELECT
        DATE_TRUNC('month', s.recorded_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(s.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(s.sale_count)::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_cherre_recorder_mf_h3_r8_monthly') }} AS s
    WHERE s.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(s.cbsa_id)) != ''
      AND s.recorded_month IS NOT NULL
    GROUP BY 1, 2
),

cherre_mf_out AS (
    SELECT
        'transactions' AS concept_code,
        'CHERRE_RECORDER_MF' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_cherre_recorder_mf_h3_r8_monthly' AS census_geo_source,
        'concept_transactions_cherre_recorder_mf_sale_count_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('transactions', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM cherre_mf_cbsa AS c
    LEFT JOIN cherre_mf_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

rca_mf_tx_cbsa AS (
    SELECT
        DATE_TRUNC('month', r.as_of_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(r.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(r.sale_count)::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_rca_mf_transactions_h3_r8_monthly') }} AS r
    WHERE r.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(r.cbsa_id)) != ''
      AND r.as_of_month IS NOT NULL
    GROUP BY 1, 2
),

rca_mf_tx_out AS (
    SELECT
        'transactions' AS concept_code,
        'RCA_MF_TRANSACTIONS' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_rca_mf_transactions_h3_r8_monthly' AS census_geo_source,
        'concept_transactions_rca_mf_sale_count_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('transactions', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM rca_mf_tx_cbsa AS c
    LEFT JOIN rca_mf_tx_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zonda_deeds_cbsa AS (
    SELECT
        DATE_TRUNC('month', z.as_of_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(z.sale_count)::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_zonda_deeds_h3_r8_monthly') }} AS z
    WHERE z.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(z.cbsa_id)) != ''
      AND z.as_of_month IS NOT NULL
    GROUP BY 1, 2
),

zonda_deeds_out AS (
    SELECT
        'transactions' AS concept_code,
        'ZONDA_DEEDS' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zonda_deeds_h3_r8_monthly' AS census_geo_source,
        'concept_transactions_zonda_deeds_sale_count_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('transactions', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zonda_deeds_cbsa AS c
    LEFT JOIN zonda_deeds_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zonda_sfr_cbsa AS (
    SELECT
        DATE_TRUNC('month', s.as_of_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(s.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(COALESCE(TRY_TO_DOUBLE(TO_VARCHAR(s.sfr_annual_closings_wavg)), 0::DOUBLE))::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_zonda_sfr_h3_r8_monthly') }} AS s
    WHERE s.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(s.cbsa_id)) != ''
      AND s.as_of_month IS NOT NULL
    GROUP BY 1, 2
),

zonda_sfr_out AS (
    SELECT
        'transactions' AS concept_code,
        'ZONDA_SFR' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zonda_sfr_h3_r8_monthly' AS census_geo_source,
        'concept_transactions_zonda_sfr_annual_closings_wsum_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('transactions', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('transactions', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zonda_sfr_cbsa AS c
    LEFT JOIN zonda_sfr_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
)

SELECT * FROM zillow_out
{% if _ext %}
UNION ALL
SELECT * FROM cherre_sfr_out
UNION ALL
SELECT * FROM cherre_mf_out
UNION ALL
SELECT * FROM rca_mf_tx_out
UNION ALL
SELECT * FROM zonda_deeds_out
{% endif %}
{% if _zsf %}
UNION ALL
SELECT * FROM zonda_sfr_out
{% endif %}
