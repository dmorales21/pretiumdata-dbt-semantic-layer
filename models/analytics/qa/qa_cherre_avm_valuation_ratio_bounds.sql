-- Slug: **cherre_avm_valuation_ratio_bounds** — Cherre **median** (`concept_avm_market_monthly.avm_current`) vs
-- **average** (`concept_valuation_market_monthly.valuation_current`) on same `(month_start, geo_id)` when both exist.
-- Wide-band sanity: count pairs where median/avg is outside **[0.25, 4.0]** (tunable in consumer queries, not enforced as dbt test here).
-- Target: ANALYTICS.DBT_DEV.QA_CHERRE_AVM_VALUATION_RATIO_BOUNDS
-- See **docs/reference/CONTRACT_RENT_AVM_VALUATION.md** (Cherre overlap contract).
{{ config(
    materialized='view',
    alias='QA_CHERRE_AVM_VALUATION_RATIO_BOUNDS',
    tags=['analytics', 'qa', 'feature_development', 'cherre_avm_valuation_ratio'],
) }}

WITH pair AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(a.geo_id)), 5, '0') AS geo_id,
        a.month_start,
        a.avm_current::DOUBLE AS median_avm,
        v.valuation_current::DOUBLE AS avg_valuation
    FROM {{ ref('concept_avm_market_monthly') }} AS a
    INNER JOIN {{ ref('concept_valuation_market_monthly') }} AS v
        ON LPAD(TRIM(TO_VARCHAR(a.geo_id)), 5, '0') = LPAD(TRIM(TO_VARCHAR(v.geo_id)), 5, '0')
       AND a.month_start = v.month_start
    WHERE a.vendor_code = 'CHERRE'
      AND v.vendor_code = 'CHERRE'
      AND a.avm_current IS NOT NULL
      AND v.valuation_current IS NOT NULL
      AND v.valuation_current > 0
),

ratioed AS (
    SELECT
        *,
        median_avm / avg_valuation AS median_over_avg
    FROM pair
)

SELECT
    DATE_TRUNC('month', CURRENT_TIMESTAMP())::DATE AS report_month_start,
    COUNT(*)::BIGINT AS n_cbsa_pairs,
    MIN(median_over_avg) AS min_median_over_avg,
    MAX(median_over_avg) AS max_median_over_avg,
    MEDIAN(median_over_avg) AS median_median_over_avg,
    COUNT_IF(median_over_avg < 0.25 OR median_over_avg > 4.0)::BIGINT AS n_outside_wide_plausible_band
FROM ratioed
