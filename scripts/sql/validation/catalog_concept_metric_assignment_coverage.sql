-- catalog_concept_metric_assignment_coverage.sql
-- Purpose:
--   1) Show active concept -> active metric assignment coverage
--   2) Flag concepts with no active metrics assigned
--   3) Flag active metrics assigned to unknown concepts
--
-- Usage (Snowflake):
--   snowsql -f scripts/sql/validation/catalog_concept_metric_assignment_coverage.sql

WITH active_concepts AS (
    SELECT
        concept_code,
        concept_label
    FROM REFERENCE.CATALOG.CONCEPT
    WHERE is_active = TRUE
),
active_metrics AS (
    SELECT
        metric_id,
        metric_code,
        concept_code,
        table_path,
        snowflake_column
    FROM REFERENCE.CATALOG.METRIC
    WHERE is_active = TRUE
),
coverage AS (
    SELECT
        c.concept_code,
        c.concept_label,
        COUNT(m.metric_id) AS active_metric_count,
        COUNT(DISTINCT m.table_path) AS active_table_path_count,
        COUNT(DISTINCT m.snowflake_column) AS active_column_count
    FROM active_concepts c
    LEFT JOIN active_metrics m
      ON m.concept_code = c.concept_code
    GROUP BY 1, 2
),
unknown_metric_concepts AS (
    SELECT
        m.metric_id,
        m.metric_code,
        m.concept_code,
        m.table_path,
        m.snowflake_column
    FROM active_metrics m
    LEFT JOIN active_concepts c
      ON c.concept_code = m.concept_code
    WHERE c.concept_code IS NULL
),
coverage_scored AS (
    SELECT
        concept_code,
        concept_label,
        active_metric_count,
        active_table_path_count,
        active_column_count,
        CASE
            WHEN active_metric_count = 0 THEN 'NO_METRIC_ASSIGNMENT'
            WHEN active_metric_count < 2 THEN 'LOW_COVERAGE'
            ELSE 'OK'
        END AS assignment_status
    FROM coverage
)
SELECT
    'coverage' AS section,
    concept_code,
    concept_label,
    assignment_status,
    active_metric_count,
    active_table_path_count,
    active_column_count,
    NULL AS metric_id,
    NULL AS metric_code,
    NULL AS table_path,
    NULL AS snowflake_column
FROM coverage_scored

UNION ALL

SELECT
    'unknown_metric_concepts' AS section,
    umc.concept_code,
    NULL AS concept_label,
    'UNKNOWN_CONCEPT_CODE' AS assignment_status,
    NULL AS active_metric_count,
    NULL AS active_table_path_count,
    NULL AS active_column_count,
    umc.metric_id,
    umc.metric_code,
    umc.table_path,
    umc.snowflake_column
FROM unknown_metric_concepts umc

ORDER BY
    section,
    assignment_status DESC,
    concept_code,
    metric_id;
