-- Singular test: active MET_* rows whose table_path registers a CONCEPT_* must pass §1f lineage.
-- Prerequisites:
--   dbt seed --select path:seeds/reference/catalog
--   dbt run --select qa_catalog_metric_transform_dev_lineage
-- Expect: 0 rows. Requires Snowflake + TRANSFORM.DEV + INFORMATION_SCHEMA access.
-- Scope: **data_status_code = active** only.

{{ config(tags=['catalog_registration', 'qa']) }}

SELECT
    l.metric_id,
    l.metric_code,
    l.table_path,
    l.qa_status
FROM {{ ref('qa_catalog_metric_transform_dev_lineage') }} AS l
INNER JOIN {{ ref('metric') }} AS m
    ON l.metric_id = m.metric_id
WHERE l.qa_status <> 'OK'
  AND UPPER(SPLIT_PART(TRIM(l.table_path), '.', 3)) LIKE 'CONCEPT%'
  AND LOWER(TRIM(m.data_status_code)) = 'active'
