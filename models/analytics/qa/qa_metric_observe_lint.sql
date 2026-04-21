-- Slug: **metric_observe_lint** (10) — null / blank `metric_id_observe` and duplicate `(vendor_code, metric_id_observe)` across concept surfaces.
-- Target: ANALYTICS.DBT_DEV.QA_METRIC_OBSERVE_LINT
{{ config(
    materialized='view',
    alias='QA_METRIC_OBSERVE_LINT',
    tags=['analytics', 'qa', 'semantic_validation', 'metric_observe_lint'],
) }}

WITH obs AS (
    SELECT 'concept_rent_market_monthly' AS concept_object, vendor_code, TO_VARCHAR(metric_id_observe) AS metric_id_observe
    FROM {{ ref('concept_rent_market_monthly') }}
    UNION ALL
    SELECT 'concept_rent_property_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_rent_property_monthly') }}
    UNION ALL
    SELECT 'concept_occupancy_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_occupancy_market_monthly') }}
    UNION ALL
    SELECT 'concept_employment_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_employment_market_monthly') }}
    UNION ALL
    SELECT 'concept_unemployment_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_unemployment_market_monthly') }}
    UNION ALL
    SELECT 'concept_home_price_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_home_price_market_monthly') }}
    UNION ALL
    SELECT 'concept_listings_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_listings_market_monthly') }}
    UNION ALL
    SELECT 'concept_avm_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_avm_market_monthly') }}
    UNION ALL
    SELECT 'concept_valuation_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_valuation_market_monthly') }}
    UNION ALL
    SELECT 'concept_transactions_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_transactions_market_monthly') }}
    UNION ALL
    SELECT 'concept_delinquency_market_monthly', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_delinquency_market_monthly') }}
    UNION ALL
    SELECT 'concept_migration_market_annual', vendor_code, TO_VARCHAR(metric_id_observe)
    FROM {{ ref('concept_migration_market_annual') }}
),

blank AS (
    SELECT
        'BLANK_OR_NULL_METRIC_ID_OBSERVE' AS lint_category,
        concept_object,
        vendor_code,
        CAST(NULL AS VARCHAR(16777216)) AS metric_id_observe,
        COUNT(*)::BIGINT AS detail_value
    FROM obs
    WHERE metric_id_observe IS NULL OR TRIM(metric_id_observe) = ''
    GROUP BY concept_object, vendor_code
),

dup_across_objects AS (
    SELECT
        'DUPLICATE_VENDOR_METRIC_ID_OBSERVE_ACROSS_CONCEPTS' AS lint_category,
        CAST(NULL AS VARCHAR(128)) AS concept_object,
        vendor_code,
        metric_id_observe,
        COUNT(DISTINCT concept_object)::BIGINT AS detail_value
    FROM obs
    WHERE metric_id_observe IS NOT NULL AND TRIM(metric_id_observe) <> ''
    GROUP BY vendor_code, metric_id_observe
    HAVING COUNT(DISTINCT concept_object) > 1
)

SELECT lint_category, concept_object, vendor_code, metric_id_observe, detail_value
FROM blank
UNION ALL
SELECT lint_category, concept_object, vendor_code, metric_id_observe, detail_value
FROM dup_across_objects
