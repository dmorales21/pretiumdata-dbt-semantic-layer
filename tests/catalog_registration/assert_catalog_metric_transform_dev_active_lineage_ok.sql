-- Singular test: active MET_* rows with table_path on TRANSFORM.DEV must pass §1f lineage
-- (object exists + optional column check in qa_catalog_metric_transform_dev_lineage).
-- Covers FACT_*, CONCEPT_*, REF_*, and other DEV objects — not only FACT/CONCEPT name prefixes.
-- Prerequisites:
--   dbt build --select path:seeds/reference/catalog qa_catalog_metric_transform_dev_lineage
-- Expect: 0 rows. Requires Snowflake + TRANSFORM.DEV + INFORMATION_SCHEMA access.
-- Scope: **data_status_code = active** only.

{{ config(tags=['catalog_registration', 'qa', 'metric_transform_dev_lineage']) }}

SELECT
    l.metric_id,
    l.metric_code,
    l.table_path,
    l.qa_status
FROM {{ ref('qa_catalog_metric_transform_dev_lineage') }} AS l
INNER JOIN {{ ref('metric') }} AS m
    ON l.metric_id = m.metric_id
WHERE l.qa_status <> 'OK'
  AND LOWER(TRIM(m.data_status_code)) = 'active'
