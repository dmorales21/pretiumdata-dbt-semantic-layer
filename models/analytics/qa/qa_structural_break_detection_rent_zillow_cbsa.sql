-- Slug: **structural_break_detection** (4) — first‑half vs second‑half **mean level** split by geo (NTILE 2 on time) for ZILLOW CBSA `rent_current`; large |Δ| suggests level shift / vendor mix change.
-- Target: ANALYTICS.DBT_DEV.QA_STRUCTURAL_BREAK_DETECTION_RENT_ZILLOW_CBSA
{{ config(
    materialized='view',
    alias='QA_STRUCTURAL_BREAK_DETECTION_RENT_ZILLOW_CBSA',
    tags=['analytics', 'qa', 'semantic_validation', 'structural_break_detection'],
) }}

WITH base AS (
    SELECT
        TO_VARCHAR(geo_id) AS geo_id,
        month_start,
        rent_current::DOUBLE AS x,
        NTILE(2) OVER (PARTITION BY geo_id ORDER BY month_start) AS time_half
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
      AND LOWER(TRIM(TO_VARCHAR(geo_level_code))) = 'cbsa'
),

half_means AS (
    SELECT
        geo_id,
        time_half,
        AVG(x) AS half_mean
    FROM base
    GROUP BY geo_id, time_half
),

spread AS (
    SELECT
        geo_id,
        MAX(IFF(time_half = 1, half_mean, NULL)) AS mean_first_half,
        MAX(IFF(time_half = 2, half_mean, NULL)) AS mean_second_half
    FROM half_means
    GROUP BY geo_id
)

SELECT
    geo_id,
    mean_first_half,
    mean_second_half,
    (mean_second_half - mean_first_half) AS level_shift_second_minus_first,
    ABS(mean_second_half - mean_first_half) / NULLIF(mean_first_half, 0) AS abs_relative_shift
FROM spread
WHERE mean_first_half IS NOT NULL
  AND mean_second_half IS NOT NULL
