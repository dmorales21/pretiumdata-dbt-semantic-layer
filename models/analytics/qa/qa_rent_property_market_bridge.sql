-- Slug: **rent_property_market_bridge** — APARTMENTIQ property rows vs CBSA market rows on shared `(month_start, cbsa_id)`.
-- Flags **orphans** (no market row) and **fan-out** (more than one market row for the same key — unexpected for CBSA market slice).
-- Target: ANALYTICS.DBT_DEV.QA_RENT_PROPERTY_MARKET_BRIDGE
-- See **docs/reference/CONTRACT_RENT_AVM_VALUATION.md**.
{{ config(
    materialized='view',
    alias='QA_RENT_PROPERTY_MARKET_BRIDGE',
    tags=['analytics', 'qa', 'feature_development', 'rent_property_market_bridge'],
) }}

WITH prop AS (
    SELECT DISTINCT
        p.month_start,
        LPAD(TRIM(TO_VARCHAR(p.cbsa_id)), 5, '0') AS cbsa_id,
        TO_VARCHAR(p.property_natural_key) AS property_natural_key
    FROM {{ ref('concept_rent_property_monthly') }} AS p
    WHERE p.vendor_code = 'APARTMENTIQ'
      AND p.cbsa_id IS NOT NULL
      AND p.month_start IS NOT NULL
),

mkt AS (
    SELECT
        m.month_start,
        LPAD(TRIM(TO_VARCHAR(m.geo_id)), 5, '0') AS cbsa_id,
        m.vendor_code
    FROM {{ ref('concept_rent_market_monthly') }} AS m
    WHERE m.vendor_code = 'APARTMENTIQ'
      AND LOWER(TRIM(TO_VARCHAR(m.geo_level_code))) = 'cbsa'
),

joined AS (
    SELECT
        p.property_natural_key,
        p.month_start,
        p.cbsa_id,
        COUNT(m.cbsa_id) AS n_market_rows
    FROM prop AS p
    LEFT JOIN mkt AS m
        ON p.month_start = m.month_start
       AND p.cbsa_id = m.cbsa_id
    GROUP BY 1, 2, 3
)

SELECT
    COUNT(*)::BIGINT AS n_property_month_rows,
    COUNT_IF(n_market_rows = 0)::BIGINT AS n_no_market_match,
    COUNT_IF(n_market_rows > 1)::BIGINT AS n_fanout_gt_one,
    COUNT_IF(n_market_rows = 1)::BIGINT AS n_exactly_one_market_row
FROM joined
