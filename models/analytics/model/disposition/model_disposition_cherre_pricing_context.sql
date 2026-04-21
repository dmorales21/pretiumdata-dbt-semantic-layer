-- ANALYTICS.DBT_DEV.MODEL_DISPOSITION_CHERRE_PRICING_CONTEXT
-- Replaces pretium-ai-dbt **ANALYTICS_PROD.MODELS** object of the same purpose: disposition × Cherre bridge ×
-- latest county SFR AVM (read from pretium-ai-dbt **ANALYTICS.FACTS** until that fact is ported here).
-- Upstream: **TRANSFORM.DEV** `concept_disposition_yield_property` + `ref_disposition_cherre_subject_bridge`.
-- Gated: **`transform_dev_enable_disposition_yield_stack`**.
{{ config(
    materialized='table',
    tags=['analytics', 'model', 'disposition', 'cherre', 'pricing', 'replaces_analytics_prod'],
    cluster_by=['disposition_id'],
    enabled=var('transform_dev_enable_disposition_yield_stack', false),
) }}

WITH county_latest AS (
    SELECT
        county_fips,
        median_avm,
        median_confidence_score,
        avm_month
    FROM {{ source('analytics_facts_pretium_ai_dbt', 'fact_housing_valuation_cherre_county_monthly') }}
    WHERE UPPER(TRIM(TO_VARCHAR(property_use_standardized_code))) = '1001'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY county_fips
        ORDER BY avm_month DESC NULLS LAST
    ) = 1
)

SELECT
    d.*,
    b.tax_assessor_id,
    b.cherre_parcel_id,
    b.cherre_match_confidence_score,
    b.cherre_latitude,
    b.cherre_longitude,
    b.bridge_method,
    cl.median_avm              AS county_median_avm_sfr_latest,
    cl.median_confidence_score AS county_median_confidence_latest,
    cl.avm_month               AS county_median_avm_month,
    CURRENT_TIMESTAMP()        AS dbt_updated_at
FROM {{ ref('concept_disposition_yield_property') }} AS d
LEFT JOIN {{ ref('ref_disposition_cherre_subject_bridge') }} AS b
    ON d.disposition_id = b.disposition_id
LEFT JOIN county_latest AS cl
    ON LPAD(TRIM(TO_VARCHAR(d.county_fips)), 5, '0') = LPAD(TRIM(TO_VARCHAR(cl.county_fips)), 5, '0')
