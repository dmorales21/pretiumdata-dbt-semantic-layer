-- Singular test: active FEATURE-layer metric_derived rows must map to a physical ANALYTICS.DBT_DEV object.
-- Prerequisites:
--   dbt seed --select path:seeds/reference/catalog
--   dbt run --select path:models/analytics/feature
--   dbt run --select qa_catalog_metric_derived_feature_lineage
-- When adding a new active MDV_* feature: extend feature_physical_map in
--   models/transform/dev/catalog_qa/qa_catalog_metric_derived_feature_lineage.sql
-- Expect: 0 rows. Requires Snowflake + ANALYTICS.DBT_DEV + INFORMATION_SCHEMA access.

{{ config(tags=['catalog_registration', 'qa']) }}

SELECT
    f.metric_derived_id,
    f.metric_derived_code,
    f.expected_table_name,
    f.qa_status
FROM {{ ref('qa_catalog_metric_derived_feature_lineage') }} AS f
WHERE f.qa_status <> 'OK'
