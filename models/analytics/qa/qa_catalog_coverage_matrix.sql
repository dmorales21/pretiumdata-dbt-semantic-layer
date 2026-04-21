-- Slug: **catalog_coverage_matrix** (9) — active `ref('concept')` rows vs **implemented** market `CONCEPT_*` row presence (green / yellow / red heuristic).
-- Mapping is explicit (catalog `rent` ↔ emitted `rent_market`); extend the `impl` CTE when new market concepts ship.
-- Target: ANALYTICS.DBT_DEV.QA_CATALOG_COVERAGE_MATRIX
{{ config(
    materialized='view',
    alias='QA_CATALOG_COVERAGE_MATRIX',
    tags=['analytics', 'qa', 'semantic_validation', 'catalog_coverage_matrix'],
) }}

WITH cat AS (
    SELECT
        concept_id,
        concept_code,
        concept_label,
        UPPER(TRIM(TO_VARCHAR(is_active))) AS is_active_flag
    FROM {{ ref('concept') }}
    WHERE UPPER(TRIM(TO_VARCHAR(is_active))) IN ('TRUE', '1', 'T')
),

impl AS (
    SELECT 'rent' AS catalog_concept_code, (SELECT COUNT(*) FROM {{ ref('concept_rent_market_monthly') }}) AS n_rows
    UNION ALL SELECT 'occupancy', (SELECT COUNT(*) FROM {{ ref('concept_occupancy_market_monthly') }})
    UNION ALL SELECT 'employment', (SELECT COUNT(*) FROM {{ ref('concept_employment_market_monthly') }})
    UNION ALL SELECT 'unemployment', (SELECT COUNT(*) FROM {{ ref('concept_unemployment_market_monthly') }})
    UNION ALL SELECT 'migration', (SELECT COUNT(*) FROM {{ ref('concept_migration_market_annual') }})
    UNION ALL SELECT 'homeprice', (SELECT COUNT(*) FROM {{ ref('concept_home_price_market_monthly') }})
    UNION ALL SELECT 'listings', (SELECT COUNT(*) FROM {{ ref('concept_listings_market_monthly') }})
    UNION ALL SELECT 'transactions', (SELECT COUNT(*) FROM {{ ref('concept_transactions_market_monthly') }})
    UNION ALL SELECT 'delinquency', (SELECT COUNT(*) FROM {{ ref('concept_delinquency_market_monthly') }})
)

SELECT
    c.concept_id,
    c.concept_code,
    c.concept_label,
    i.n_rows AS implemented_row_count,
    CASE
        WHEN i.catalog_concept_code IS NULL THEN 'RED'
        WHEN COALESCE(i.n_rows, 0) = 0 THEN 'YELLOW'
        ELSE 'GREEN'
    END AS coverage_status,
    CASE c.concept_code
        WHEN 'rent' THEN 'CONCEPT_RENT_MARKET_MONTHLY (emits concept_code=rent_market)'
        WHEN 'occupancy' THEN 'CONCEPT_OCCUPANCY_MARKET_MONTHLY'
        WHEN 'employment' THEN 'CONCEPT_EMPLOYMENT_MARKET_MONTHLY'
        WHEN 'unemployment' THEN 'CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY'
        WHEN 'migration' THEN 'CONCEPT_MIGRATION_MARKET_ANNUAL'
        WHEN 'homeprice' THEN 'CONCEPT_HOME_PRICE_MARKET_MONTHLY'
        WHEN 'listings' THEN 'CONCEPT_LISTINGS_MARKET_MONTHLY'
        WHEN 'transactions' THEN 'CONCEPT_TRANSACTIONS_MARKET_MONTHLY'
        WHEN 'delinquency' THEN 'CONCEPT_DELINQUENCY_MARKET_MONTHLY'
        ELSE NULL
    END AS primary_market_object_hint
FROM cat AS c
LEFT JOIN impl AS i
    ON i.catalog_concept_code = c.concept_code
