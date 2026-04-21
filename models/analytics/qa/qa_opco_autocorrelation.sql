-- Slug: **opco_autocorrelation** (12) — lag‑1 panel on **Progress rent** (`concept_progress_rent`): partition `property_natural_key`, order `month_start` from `rent_market_effective_date`.
-- Gated with `transform_dev_enable_source_entity_progress_facts` (same as fund_opco concepts); **disabled** by default so CI parse graphs stay small.
-- Target: ANALYTICS.DBT_DEV.QA_OPCO_AUTOCORRELATION
{{ config(
    materialized='view',
    alias='QA_OPCO_AUTOCORRELATION',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=['analytics', 'qa', 'semantic_validation', 'opco_autocorrelation'],
) }}

WITH base AS (
    SELECT
        property_natural_key,
        DATE_TRUNC('month', rent_market_effective_date)::DATE AS month_start,
        rent_current::DOUBLE AS x
    FROM {{ ref('concept_progress_rent') }}
    WHERE rent_market_effective_date IS NOT NULL
      AND rent_current IS NOT NULL
      AND property_natural_key IS NOT NULL
),

lagged AS (
    SELECT
        property_natural_key,
        month_start,
        x,
        LAG(x) OVER (PARTITION BY property_natural_key ORDER BY month_start) AS x_lag1
    FROM base
),

by_entity AS (
    SELECT
        property_natural_key,
        CORR(x, x_lag1) AS acf_lag1_pearson,
        COUNT(*) AS n_pairs
    FROM lagged
    WHERE x_lag1 IS NOT NULL
    GROUP BY property_natural_key
    HAVING COUNT(*) >= 6
)

SELECT
    property_natural_key,
    acf_lag1_pearson,
    n_pairs
FROM by_entity
