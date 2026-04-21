-- Slug: **serving_crosswalk_assertions** (16) — null-key counts on **demo_ref_*** seeds-as-views (`models/serving/demo/`) after they are built in your warehouse.
-- **Default off:** set `vars.analytics_qa_serving_crosswalk_enabled: true` (CLI or `dbt_project.yml`) after `dbt run -s path:models/serving/demo` so `DEMO_REF_*` relations exist under **ANALYTICS.DBT_DEV**.
-- Target: ANALYTICS.DBT_DEV.QA_SERVING_CROSSWALK_ASSERTIONS
{{ config(
    materialized='view',
    alias='QA_SERVING_CROSSWALK_ASSERTIONS',
    enabled=var('analytics_qa_serving_crosswalk_enabled', false),
    tags=['analytics', 'qa', 'semantic_validation', 'serving_crosswalk_assertions'],
) }}

SELECT
    'demo_ref_metric' AS demo_object,
    COUNT(*)::BIGINT AS n_rows,
    COUNT_IF(metric_id IS NULL)::BIGINT AS null_metric_id_rows
FROM {{ ref('demo_ref_metric') }}

UNION ALL

SELECT
    'demo_ref_concept',
    COUNT(*)::BIGINT,
    COUNT_IF(concept_code IS NULL OR TRIM(TO_VARCHAR(concept_code)) = '')::BIGINT
FROM {{ ref('demo_ref_concept') }}

UNION ALL

SELECT
    'demo_ref_bridge_product_type_metric',
    COUNT(*)::BIGINT,
    COUNT_IF(metric_code IS NULL OR TRIM(TO_VARCHAR(metric_code)) = '' OR product_type_code IS NULL OR TRIM(TO_VARCHAR(product_type_code)) = '')::BIGINT
FROM {{ ref('demo_ref_bridge_product_type_metric') }}

UNION ALL

SELECT
    'demo_ref_product_type',
    COUNT(*)::BIGINT,
    COUNT_IF(product_type_id IS NULL OR TRIM(TO_VARCHAR(product_type_id)) = '')::BIGINT
FROM {{ ref('demo_ref_product_type') }}
