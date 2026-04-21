-- ANALYTICS.DBT_* — ZIP home price YoY from **TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES** (ZHVI-style series).
--
-- **Lineage note (Phase B):** ZIP-only YoY transform; ``concept_home_price_market_monthly`` is CBSA-first multi-vendor.
-- **TODO:** optional refactor to read from a ZIP-level concept slice when one exists — ``QA_CONCEPT_PREFLIGHT_CHECKLIST.md`` §C.
-- Port of pretium-ai-dbt ``feature_price_momentum_zip`` intent: ``metric_id`` in this fact is filename-derived;
-- filter uses ``%zhvi%`` (case-insensitive) plus legacy ``ZILLOW_ZHVI_MEDIAN`` id when present.
{{ config(
    materialized='view',
    alias='feature_home_price_delta_zip_monthly',
    tags=['analytics', 'feature', 'homeprice', 'zillow', 'zip'],
) }}

{% set _zhvi_pat = var('feature_home_price_delta_metric_id_pattern', '%zhvi%') | replace("'", "''") %}

WITH z AS (
    SELECT
        geo_id,
        metric_id,
        date_reference,
        metric_value::DOUBLE AS price_level
    FROM {{ ref('fact_zillow_home_values') }}
    WHERE geo_level_code = 'zip'
      AND geo_id IS NOT NULL
      AND date_reference IS NOT NULL
      AND metric_value IS NOT NULL
      AND (
        LOWER(metric_id::VARCHAR) LIKE LOWER('{{ _zhvi_pat }}')
        OR UPPER(TRIM(metric_id::VARCHAR)) = 'ZILLOW_ZHVI_MEDIAN'
      )
),

with_lag AS (
    SELECT
        geo_id,
        'zip' AS geo_level_code,
        metric_id,
        date_reference,
        price_level,
        LAG(price_level, 12) OVER (
            PARTITION BY geo_id, metric_id
            ORDER BY date_reference
        ) AS price_level_12m_ago
    FROM z
)

SELECT
    geo_id,
    geo_level_code,
    metric_id,
    date_reference,
    price_level AS home_price_level,
    price_level_12m_ago AS home_price_level_12m_ago,
    CASE
        WHEN price_level_12m_ago > 0
        THEN ROUND((price_level - price_level_12m_ago) / price_level_12m_ago * 100.0, 4)
    END AS home_price_yoy_pct,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM with_lag
WHERE price_level_12m_ago IS NOT NULL
