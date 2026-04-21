{#-
  **Market AVM** — monthly slots ``avm_current`` / ``avm_historical`` / ``avm_forecast`` (``concept_metric_slot('avm', …)``).

  **Cherre** — ``ref('cherre_avm_geo_stats')`` → ``TRANSFORM.CHERRE.USA_AVM_GEO_STATS``. Rows are **as-of snapshot**
  (no native period column); ``month_start`` is ``DATE_TRUNC('month', CURRENT_TIMESTAMP())`` for all rows so CBSA
  keys align with other concepts on **``GEOGRAPHY_TYPE = 'MA'``** (5-digit CBSA code in ``GEOGRAPHY_CODE``).

  Historical / forecast slots reserved (NULL) until time-series AVM facts (ZIP/CBSA monthly) are promoted.

  **Contract (snapshot time truth, QA exclusions):** ``docs/reference/CONTRACT_RENT_AVM_VALUATION.md``.
-#}

{{ config(
    materialized='table',
    alias='concept_avm_market_monthly',
    tags=['semantic', 'concept', 'avm', 'avm_market', 'cherre']
) }}

WITH snapshot_month AS (
    SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP())::DATE AS month_start
),

cherre_ma AS (
    SELECT
        'avm_market' AS concept_code,
        'CHERRE' AS vendor_code,
        sm.month_start,
        'cbsa' AS geo_level_code,
        LPAD(TRIM(REGEXP_REPLACE(TO_VARCHAR(g.GEOGRAPHY_CODE), '[^0-9]', '')), 5, '0') AS geo_id,
        LPAD(TRIM(REGEXP_REPLACE(TO_VARCHAR(g.GEOGRAPHY_CODE), '[^0-9]', '')), 5, '0') AS cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'cherre_usa_avm_geo_stats_ma_snapshot' AS census_geo_source,
        'cherre_median_estimated_value' AS metric_id_observe,
        CAST(g.MEDIAN_ESTIMATED_VALUE AS DOUBLE) AS {{ concept_metric_slot('avm', 'current') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('avm', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('avm', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM {{ ref('cherre_avm_geo_stats') }} AS g
    CROSS JOIN snapshot_month AS sm
    WHERE TRIM(TO_VARCHAR(g.GEOGRAPHY_TYPE)) = 'MA'
      AND g.GEOGRAPHY_CODE IS NOT NULL
      AND g.MEDIAN_ESTIMATED_VALUE IS NOT NULL
),

redfin_stub AS (
    SELECT
        CAST('avm_market' AS VARCHAR(64)) AS concept_code,
        CAST('REDFIN' AS VARCHAR(32)) AS vendor_code,
        CAST(NULL AS DATE) AS month_start,
        CAST(NULL AS VARCHAR(32)) AS geo_level_code,
        CAST(NULL AS VARCHAR(64)) AS geo_id,
        CAST(NULL AS VARCHAR(8)) AS cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        CAST(NULL AS BOOLEAN) AS has_census_geo,
        CAST(NULL AS VARCHAR(128)) AS census_geo_source,
        CAST(NULL AS VARCHAR(512)) AS metric_id_observe,
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('avm', 'current') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('avm', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('avm', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM (SELECT 1 AS stub_one) AS stub_from
    WHERE 1 = 0
)

SELECT * FROM cherre_ma
UNION ALL
SELECT * FROM redfin_stub
