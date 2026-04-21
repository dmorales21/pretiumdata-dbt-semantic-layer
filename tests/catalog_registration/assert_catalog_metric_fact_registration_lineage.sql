-- Singular test: active MET_* rows whose table_path registers a FACT_* must pass §1f lineage.
-- Prerequisites:
--   dbt seed --select path:seeds/reference/catalog
--   dbt run --select qa_catalog_metric_transform_dev_lineage
-- Expect: 0 rows (any row = test failure). Requires Snowflake + TRANSFORM.DEV objects + INFORMATION_SCHEMA access.
-- Scope: **data_status_code = active** only (under_review / planned placeholders stay out of this gate).

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
  AND UPPER(SPLIT_PART(TRIM(l.table_path), '.', 3)) LIKE 'FACT%'
  AND LOWER(TRIM(m.data_status_code)) = 'active'
