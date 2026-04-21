-- KPI + gap inventory: REFERENCE.CATALOG.METRIC vs TRANSFORM.DEV physical objects.
--
-- Scale note: **~67K “metrics”** in a vendor catalog usually means **time-series rows** or
-- **variable / series codes** (e.g. long VALUE grain), not **MET_* definition rows**. This repo’s
-- governed registry is **one MET_* per registered observable / FACT column contract** in
-- `seeds/reference/catalog/metric.csv` — keep bulk universes in **dataset** / vendor tables, not
-- as 67K duplicate `metric` rows unless IC explicitly adopts that model.
--
-- Run (example):
--   snowsql -c pretium -f scripts/sql/validation/catalog_metric_registration_coverage.sql
--
-- Prerequisites: session can read REFERENCE.CATALOG.METRIC and TRANSFORM.INFORMATION_SCHEMA.

-- ---------------------------------------------------------------------------
-- A) KPIs — catalog registration volume
-- ---------------------------------------------------------------------------
SELECT
    'KPI:metric_rows_total' AS kpi_name,
    COUNT(*) AS kpi_value
FROM reference.catalog.metric;

SELECT
    'KPI:metric_rows_active_is_true' AS kpi_name,
    COUNT(*) AS kpi_value
FROM reference.catalog.metric AS m
WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T');

SELECT
    'KPI:metric_rows_active_transform_dev_table_path' AS kpi_name,
    COUNT(*) AS kpi_value
FROM reference.catalog.metric AS m
WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
  AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%';

SELECT
    'KPI:metric_distinct_transform_dev_table_path_active' AS kpi_name,
    COUNT(DISTINCT UPPER(TRIM(m.table_path))) AS kpi_value
FROM reference.catalog.metric AS m
WHERE UPPER(TRIM(TO_VARCHAR(m.is_active))) IN ('TRUE', '1', 'T')
  AND UPPER(TRIM(m.table_path)) LIKE 'TRANSFORM.DEV.%';

-- ---------------------------------------------------------------------------
-- B) GAP — TRANSFORM.DEV FACT_/CONCEPT_/REF_ tables with no MET row on that table_path
-- (exact FQN match: TRANSFORM.DEV.<OBJECT> uppercased). Excludes QA_* helpers.
-- ---------------------------------------------------------------------------
WITH dev_objects AS (
    SELECT UPPER(t.table_name) AS obj
    FROM TRANSFORM.information_schema.tables AS t
    WHERE UPPER(t.table_catalog) = 'TRANSFORM'
      AND UPPER(t.table_schema) = 'DEV'
      AND t.table_type IN ('BASE TABLE', 'VIEW', 'MATERIALIZED VIEW')
      AND NOT STARTSWITH(UPPER(t.table_name), 'QA_')
      AND (
          STARTSWITH(UPPER(t.table_name), 'FACT_')
          OR STARTSWITH(UPPER(t.table_name), 'CONCEPT_')
          OR STARTSWITH(UPPER(t.table_name), 'REF_')
      )
),
registered_paths AS (
    SELECT DISTINCT UPPER(TRIM(m.table_path)) AS table_path
    FROM reference.catalog.metric AS m
    WHERE m.table_path IS NOT NULL
      AND TRIM(m.table_path) <> ''
)
SELECT
    'GAP:transform_dev_object_without_metric_table_path' AS check_name,
    d.obj AS suggested_table_path,
    'TRANSFORM.DEV.' || d.obj AS full_table_path_for_metric_seed
FROM dev_objects AS d
WHERE NOT EXISTS (
    SELECT 1
    FROM registered_paths AS r
    WHERE r.table_path = 'TRANSFORM.DEV.' || d.obj
)
ORDER BY d.obj;
