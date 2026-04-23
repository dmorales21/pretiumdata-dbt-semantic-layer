-- catalog_tall_metric_code_coverage.sql
-- Purpose: once a tall TRANSFORM.DEV concept observation table exists, verify that every
--   distinct (metric_code, dataset_code) on that table resolves to REFERENCE.CATALOG seeds.
--
-- Replace placeholders:
--   <TALL_CONCEPT_SCHEMA> — e.g. DEV
--   <TALL_CONCEPT_TABLE>  — e.g. CONCEPT_OBSERVATION_TALL
--
-- Usage (Snowflake):
--   snowsql -f scripts/sql/validation/catalog_tall_metric_code_coverage.sql

WITH tall AS (
    SELECT DISTINCT
        metric_code,
        dataset_code
    FROM TRANSFORM.<TALL_CONCEPT_SCHEMA>.<TALL_CONCEPT_TABLE>
    WHERE metric_code IS NOT NULL
),
bad_metric AS (
    SELECT t.metric_code
    FROM tall t
    WHERE NOT EXISTS (
        SELECT 1
        FROM REFERENCE.CATALOG.METRIC m
        WHERE m.metric_code = t.metric_code
          AND m.is_active = TRUE
    )
),
bad_dataset AS (
    SELECT t.dataset_code
    FROM tall t
    WHERE t.dataset_code IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM REFERENCE.CATALOG.DATASET d
        WHERE d.dataset_code = t.dataset_code
      )
)
SELECT 'orphan_metric_code' AS violation_type, metric_code AS code, NULL AS dataset_code
FROM bad_metric
UNION ALL
SELECT 'orphan_dataset_code', NULL, dataset_code
FROM bad_dataset
;
