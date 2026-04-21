-- Slug: **cross_series_coherence** (5) — BLS LAUS **employment** vs **unemployment** on the same `geo_id` / `month_start` (rate should be in (0,1) for sane metros).
-- Target: ANALYTICS.DBT_DEV.QA_CROSS_SERIES_COHERENCE
{{ config(
    materialized='view',
    alias='QA_CROSS_SERIES_COHERENCE',
    tags=['analytics', 'qa', 'semantic_validation', 'cross_series_coherence'],
) }}

WITH e AS (
    SELECT
        month_start,
        geo_id,
        employment_current::DOUBLE AS employment_current
    FROM {{ ref('concept_employment_market_monthly') }}
    WHERE vendor_code = 'BLS_LAUS'
      AND employment_current IS NOT NULL
),

u AS (
    SELECT
        month_start,
        geo_id,
        metric_id_observe,
        unemployment_current::DOUBLE AS unemployment_current
    FROM {{ ref('concept_unemployment_market_monthly') }}
    WHERE vendor_code = 'BLS_LAUS'
      AND unemployment_current IS NOT NULL
      AND LOWER(TO_VARCHAR(metric_id_observe)) LIKE '%unemployment_rate%'
)

SELECT
    e.month_start,
    e.geo_id,
    e.employment_current,
    u.unemployment_current AS unemployment_rate,
    (u.unemployment_current > 0 AND u.unemployment_current < 100) AS unemployment_rate_plausible_percent_scale,
    (e.employment_current > 0) AS employment_positive
FROM e
INNER JOIN u
    ON e.month_start = u.month_start
   AND e.geo_id = u.geo_id
