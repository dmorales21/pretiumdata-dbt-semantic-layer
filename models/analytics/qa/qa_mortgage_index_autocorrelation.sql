-- Slug: **mortgage_index_autocorrelation** (17) — placeholder until `concept_mortgage_rate_index_*` exists; run **autocorrelation** pattern on national weekly series with product-type partitions.
-- Target: ANALYTICS.DBT_DEV.QA_MORTGAGE_INDEX_AUTOCORRELATION
{{ config(
    materialized='view',
    alias='QA_MORTGAGE_INDEX_AUTOCORRELATION',
    tags=['analytics', 'qa', 'semantic_validation', 'mortgage_index_autocorrelation'],
) }}

SELECT
    'NOT_IMPLEMENTED' AS implementation_status,
    'Awaiting concept_mortgage_rate_index_* model — partition by product_type (30y, 15y, ARM) vs geo_id when national only.' AS note
