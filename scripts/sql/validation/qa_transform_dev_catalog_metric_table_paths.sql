-- QA: REFERENCE.CATALOG.METRIC rows that register TRANSFORM.DEV objects (FACT_ / CONCEPT_ / REF_*).
-- Metrics whose table_path is ANALYTICS.* (e.g. MF ranker MET_146–MET_162 on FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY) are intentionally out of scope here.
-- Prerequisites: seeds deployed to REFERENCE.CATALOG (e.g. dbt seed --select path:seeds/reference/catalog).
--
-- This is NOT the same as ANALYTICS.DBT_STAGE.QA_* promotion-gate tables (see SCHEMA_RULES.md /
-- README.md). Those hold row-level ERROR/WARN results before DBT_PROD writes.
--
-- Run (example):
--   snowsql -c pretium -f scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql
--
-- IMPORTANT: This file queries **TRANSFORM.INFORMATION_SCHEMA** (fully qualified). If you use
-- unqualified `information_schema` while the session `database` is REFERENCE or ANALYTICS, Snowflake
-- only lists objects in that database — every TRANSFORM.DEV registration looks "missing".
--
-- Expect failure_rows = 0 for each summary check. Non-zero: fix catalog table_path / snowflake_column
-- or build the missing TRANSFORM.DEV relation (semantic-layer dbt under models/transform/dev/).
-- One-shot surface (models only):  dbt run --selector catalog_metric_transform_dev_surface
-- (see selectors.yml). If a model fails on missing refs, build its vendor subtree first (FHFA/HUD/IRS
-- depend on SOURCE_SNOW parents; BPS/BLS on transform sources).

-- ---------------------------------------------------------------------------
-- 1) table_path must parse as TRANSFORM.DEV.<OBJECT>
-- ---------------------------------------------------------------------------
WITH reg AS (
    SELECT
        m.metric_id,
        m.metric_code,
        TRIM(m.table_path) AS table_path,
        TRIM(m.snowflake_column) AS snowflake_column
    FROM reference.catalog.metric AS m
    WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
      AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%'
),
parsed AS (
    SELECT
        r.*,
        SPLIT_PART(UPPER(TRIM(r.table_path)), '.', 1) AS db,
        SPLIT_PART(UPPER(TRIM(r.table_path)), '.', 2) AS sch,
        SPLIT_PART(UPPER(TRIM(r.table_path)), '.', 3) AS obj
    FROM reg AS r
)
SELECT
    'CATALOG:metric TRANSFORM.DEV table_path malformed (expect DB.SCHEMA.OBJECT)' AS check_name,
    COUNT(*) AS failure_rows
FROM parsed AS p
WHERE p.db IS NULL
   OR p.sch IS NULL
   OR p.obj IS NULL
   OR TRIM(p.obj) = ''
   OR p.db <> 'TRANSFORM'
   OR p.sch <> 'DEV';

-- ---------------------------------------------------------------------------
-- 2) Registered relation exists in Snowflake (BASE TABLE / VIEW / MATERIALIZED VIEW)
-- ---------------------------------------------------------------------------
WITH reg AS (
    SELECT DISTINCT
        TRIM(m.table_path) AS table_path,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 1) AS db,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 2) AS sch,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 3) AS obj
    FROM reference.catalog.metric AS m
    WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
      AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%'
),
ist AS (
    SELECT
        table_catalog,
        table_schema,
        table_name,
        table_type
    FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
    WHERE UPPER(table_catalog) = 'TRANSFORM'
      AND UPPER(table_schema) = 'DEV'
      AND table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')
)
SELECT
    'SNOWFLAKE:registered TRANSFORM.DEV table_path missing (TRANSFORM.INFORMATION_SCHEMA.TABLES)' AS check_name,
    COUNT(*) AS failure_rows
FROM reg AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM ist AS i
    WHERE UPPER(i.table_catalog) = r.db
      AND UPPER(i.table_schema) = r.sch
      AND UPPER(i.table_name) = r.obj
);

-- ---------------------------------------------------------------------------
-- 3) snowflake_column exists on the relation (active metrics with non-blank column only)
-- ---------------------------------------------------------------------------
WITH reg AS (
    SELECT
        m.metric_id,
        m.metric_code,
        TRIM(m.table_path) AS table_path,
        TRIM(m.snowflake_column) AS snowflake_column,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 1) AS db,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 2) AS sch,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 3) AS obj
    FROM reference.catalog.metric AS m
    WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
      AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%'
      AND m.snowflake_column IS NOT NULL
      AND TRIM(m.snowflake_column) <> ''
),
ist AS (
    SELECT
        table_catalog,
        table_schema,
        table_name,
        column_name
    FROM TRANSFORM.INFORMATION_SCHEMA.COLUMNS
    WHERE UPPER(table_catalog) = 'TRANSFORM'
      AND UPPER(table_schema) = 'DEV'
)
SELECT
    'SNOWFLAKE:metric snowflake_column missing on registered TRANSFORM.DEV relation' AS check_name,
    COUNT(*) AS failure_rows
FROM reg AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM ist AS i
    WHERE UPPER(i.table_catalog) = r.db
      AND UPPER(i.table_schema) = r.sch
      AND UPPER(i.table_name) = r.obj
      AND UPPER(TRIM(i.column_name)) = UPPER(TRIM(r.snowflake_column))
);

-- ---------------------------------------------------------------------------
-- 4) Operator detail — missing objects (run when check 2 > 0)
-- ---------------------------------------------------------------------------
WITH reg AS (
    SELECT
        TRIM(m.table_path) AS table_path,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 1) AS db,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 2) AS sch,
        SPLIT_PART(UPPER(TRIM(m.table_path)), '.', 3) AS obj,
        LISTAGG(m.metric_code, ', ') WITHIN GROUP (ORDER BY m.metric_code) AS metric_codes
    FROM reference.catalog.metric AS m
    WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
      AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%'
    GROUP BY table_path, db, sch, obj
),
ist AS (
    SELECT
        UPPER(table_catalog) AS table_catalog,
        UPPER(table_schema) AS table_schema,
        UPPER(table_name) AS table_name
    FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
    WHERE UPPER(table_catalog) = 'TRANSFORM'
      AND UPPER(table_schema) = 'DEV'
      AND table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')
)
SELECT
    'DETAIL:missing_TRANSFORM_DEV_object' AS check_name,
    r.table_path,
    r.metric_codes
FROM reg AS r
WHERE NOT EXISTS (
    SELECT 1
    FROM ist AS i
    WHERE i.table_catalog = r.db
      AND i.table_schema = r.sch
      AND i.table_name = r.obj
)
ORDER BY r.table_path;
