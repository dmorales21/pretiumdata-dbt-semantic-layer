-- Slug: **uad_isolation_validation** (11) — **FHFA_UAD** volume on home price / valuation (isolated from global ACF sweep).
-- Target: ANALYTICS.DBT_DEV.QA_UAD_ISOLATION_VALIDATION
{{ config(
    materialized='view',
    alias='QA_UAD_ISOLATION_VALIDATION',
    tags=['analytics', 'qa', 'semantic_validation', 'uad_isolation_validation'],
) }}

SELECT
    'CONCEPT_HOME_PRICE_MARKET_MONTHLY' AS concept_object,
    COUNT(*)::BIGINT AS uad_row_count,
    COUNT(DISTINCT TO_VARCHAR(metric_id_observe))::BIGINT AS n_distinct_metric_id_observe,
    COUNT(DISTINCT TO_VARCHAR(geo_id))::BIGINT AS n_distinct_geo_id,
    MIN(month_start) AS min_month_start,
    MAX(month_start) AS max_month_start
FROM {{ ref('concept_home_price_market_monthly') }}
WHERE vendor_code = 'FHFA_UAD'

UNION ALL

SELECT
    'CONCEPT_VALUATION_MARKET_MONTHLY',
    COUNT(*)::BIGINT,
    COUNT(DISTINCT TO_VARCHAR(metric_id_observe))::BIGINT,
    COUNT(DISTINCT TO_VARCHAR(geo_id))::BIGINT,
    MIN(month_start),
    MAX(month_start)
FROM {{ ref('concept_valuation_market_monthly') }}
WHERE vendor_code = 'FHFA_UAD'
