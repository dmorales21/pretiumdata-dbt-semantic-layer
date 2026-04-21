-- ============================================================================
-- QA — TRANSFORM.DEV: catalog METRIC registrations vs Snowflake reality
-- Purpose: Materialize row-level results in TRANSFORM.DEV (SCHEMA_RULES.md
--          Alex / DEV / QA quality-check row) so operators can SELECT from
--          QA_CATALOG_METRIC_TRANSFORM_DEV_LINEAGE instead of only ad hoc SQL.
-- Source of truth: this repo + REFERENCE.CATALOG.metric (dbt seed `metric`).
-- Related: scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql
-- Grain: one row per active METRIC row whose table_path is TRANSFORM.DEV.*.
-- ============================================================================

{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    tags=['transform', 'transform_dev', 'qa', 'catalog', 'catalog_registration', 'T-QA-CATALOG-TRANSFORM-DEV'],
) }}

WITH reg AS (
    SELECT
        m.metric_id,
        m.metric_code,
        TRIM(m.table_path) AS table_path,
        TRIM(m.snowflake_column) AS snowflake_column,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 1) AS db_part,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 2) AS schema_part,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 3) AS object_part
    FROM {{ ref('metric') }} AS m
    WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
      AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%'
),

parsed_ok AS (
    SELECT
        r.*,
        r.db_part = 'TRANSFORM'
            AND r.schema_part = 'DEV'
            AND r.object_part IS NOT NULL
            AND TRIM(r.object_part) <> '' AS path_parse_ok
    FROM reg AS r
),

ist AS (
    SELECT
        UPPER(table_catalog) AS table_catalog,
        UPPER(table_schema) AS table_schema,
        UPPER(table_name) AS table_name,
        table_type
    FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
    WHERE UPPER(table_catalog) = 'TRANSFORM'
      AND UPPER(table_schema) = 'DEV'
      AND table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')
),

obj_exists AS (
    SELECT
        p.*,
        EXISTS (
            SELECT 1
            FROM ist AS i
            WHERE i.table_catalog = p.db_part
              AND i.table_schema = p.schema_part
              AND i.table_name = p.object_part
        ) AS snowflake_object_exists
    FROM parsed_ok AS p
),

col_chk AS (
    SELECT
        e.*,
        CASE
            WHEN e.snowflake_column IS NULL OR TRIM(e.snowflake_column) = '' THEN NULL
            ELSE EXISTS (
                SELECT 1
                FROM TRANSFORM.INFORMATION_SCHEMA.COLUMNS AS c
                WHERE UPPER(c.table_catalog) = e.db_part
                  AND UPPER(c.table_schema) = e.schema_part
                  AND UPPER(c.table_name) = e.object_part
                  AND UPPER(TRIM(c.column_name)) = UPPER(TRIM(e.snowflake_column))
            )
        END AS snowflake_column_ok
    FROM obj_exists AS e
)

SELECT
    metric_id,
    metric_code,
    table_path,
    snowflake_column,
    path_parse_ok,
    snowflake_object_exists,
    snowflake_column_ok,
    CASE
        WHEN NOT path_parse_ok THEN 'BAD_PATH'
        WHEN NOT snowflake_object_exists THEN 'MISSING_OBJECT'
        WHEN snowflake_column IS NOT NULL
            AND TRIM(snowflake_column) <> ''
            AND snowflake_column_ok = FALSE THEN 'MISSING_COLUMN'
        ELSE 'OK'
    END AS qa_status,
    CURRENT_TIMESTAMP() AS qa_built_at
FROM col_chk
