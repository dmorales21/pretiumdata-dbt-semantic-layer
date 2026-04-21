-- Slug: **distribution_shift_monitor** (7) — **lightweight** MoM shift on `rent_current` (median + mean) by `vendor_code` × `geo_level_code` on the rent FEATURE spine (PSI/KS can be layered later).
-- Target: ANALYTICS.DBT_DEV.QA_DISTRIBUTION_SHIFT_MONITOR_RENT
{{ config(
    materialized='view',
    alias='QA_DISTRIBUTION_SHIFT_MONITOR_RENT',
    tags=['analytics', 'qa', 'feature_development', 'distribution_shift_monitor'],
) }}

WITH m AS (
    SELECT
        vendor_code,
        geo_level_code,
        month_start,
        MEDIAN(rent_current::DOUBLE) AS median_rent,
        AVG(rent_current::DOUBLE) AS mean_rent
    FROM {{ ref('feature_rent_market_monthly_spine') }}
    WHERE rent_current IS NOT NULL
    GROUP BY vendor_code, geo_level_code, month_start
),

ordered AS (
    SELECT
        *,
        LAG(median_rent) OVER (PARTITION BY vendor_code, geo_level_code ORDER BY month_start) AS prev_median_rent,
        LAG(mean_rent) OVER (PARTITION BY vendor_code, geo_level_code ORDER BY month_start) AS prev_mean_rent
    FROM m
)

SELECT
    vendor_code,
    geo_level_code,
    month_start,
    median_rent,
    prev_median_rent,
    (median_rent - prev_median_rent) / NULLIF(ABS(prev_median_rent), 0) AS mom_median_rel_change,
    mean_rent,
    prev_mean_rent,
    (mean_rent - prev_mean_rent) / NULLIF(ABS(prev_mean_rent), 0) AS mom_mean_rel_change
FROM ordered
WHERE prev_median_rent IS NOT NULL
