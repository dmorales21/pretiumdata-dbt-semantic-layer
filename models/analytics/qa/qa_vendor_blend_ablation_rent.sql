-- Slug: **vendor_blend_ablation** (12) — per **`month_start` × `geo_level_code` × `geo_id`**, list **mean `rent_current` by `vendor_code`** (leave-one-vendor-out deltas are a manual second step from this grain).
-- Intended input for “drop vendor V and re-score cohort” workflows; not a full combinatorial ablation.
-- Target: ANALYTICS.DBT_DEV.QA_VENDOR_BLEND_ABLATION_RENT
{{ config(
    materialized='view',
    alias='QA_VENDOR_BLEND_ABLATION_RENT',
    tags=['analytics', 'qa', 'feature_development', 'vendor_blend_ablation'],
) }}

SELECT
    month_start,
    geo_level_code,
    geo_id,
    vendor_code,
    AVG(rent_current::DOUBLE) AS mean_rent_current,
    COUNT(*)::BIGINT AS n_rows
FROM {{ ref('concept_rent_market_monthly') }}
WHERE rent_current IS NOT NULL
GROUP BY month_start, geo_level_code, geo_id, vendor_code
