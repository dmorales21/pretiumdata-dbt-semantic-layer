-- =============================================================================
-- CoStar — inventory + uniques across TRANSFORM.COSTAR, SOURCE_PROD.COSTAR,
--          RAW.COSTAR, and TRANSFORM.FACT / TRANSFORM.DEV (%COSTAR%)
--
-- Purpose: Query every object, capture uniques, and prove grains BEFORE
--          designing TRANSFORM.DEV.FACT_* or registry work on CoStar metrics.
--
-- Operational order:
--   1) Run **A → B** (TRANSFORM.COSTAR objects + columns), then **C → D**
--      (SOURCE_PROD.COSTAR objects + columns). Export all four.
--   2) If §G / §H identifiers fail, fix names from **D** (SOURCE_PROD columns)
--      or **B** (TRANSFORM columns) before locking FACT DDL.
--   3) Run **E**–**J**; archive with date under docs/migration/artifacts/.
--
-- snowsql -f path (repo has nested `pretiumdata-dbt-semantic-layer/` folder):
--   From parent:  -f pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_costar_for_dev_facts.sql
--   From inner:   -f scripts/sql/migration/inventory_costar_for_dev_facts.sql
--
-- USE DATABASE: script switches TRANSFORM / SOURCE_PROD / RAW as needed.
-- Adjust database names (e.g. TRANSFORM_PROD) if your account uses PROD-only vendor schemas.
--
-- Section index:
-- | Block | Purpose |
-- |-------|---------|
-- | **A** | All tables/views in **TRANSFORM.COSTAR** |
-- | **B** | All columns (ordinal, type, nullable) — **TRANSFORM.COSTAR** |
-- | **C** | All tables/views in **SOURCE_PROD.COSTAR** |
-- | **D** | All columns — **SOURCE_PROD.COSTAR** |
-- | **E** | Row counts: **SCENARIOS**, **SCENARIOS_METRICS**, **COSTAR_EXPORT_PARQUET**, **METRIC_CATALOG_*** (extend from **A/C** if names differ) |
-- | **F** | **SCENARIOS** time spine + **PROPERTY_TYPE** / **FORECAST_SCENARIO** / **IS_FORECAST** distributions |
-- | **G** | **SCENARIOS** duplicate grain (aligned with `fact_costar_cbsa_monthly`: CBSA × property_type × month × scenario × forecast flag) |
-- | **H** | **SCENARIOS** non-null counts on a representative wide metric subset |
-- | **I** | **SCENARIOS_METRICS** — scenario codes + geo-key presence + date range |
-- | **J** | **COSTAR_EXPORT_PARQUET** — sample **OBJECT_KEYS(v)** (5 rows) |
-- | **K** | **TRANSFORM.FACT** / **TRANSFORM.DEV** — objects matching **%COSTAR%** |
-- | **L** | **RAW.COSTAR** — object list (legacy; prefer TRANSFORM / SOURCE_PROD) |
--
-- Related: docs/migration/MIGRATION_TASKS_COSTAR.md §1.5
-- Registry pairing: pretium-ai-dbt/scripts/sql/admin/catalog/register_costar_mf_market_export_metrics.sql
-- =============================================================================

-- =============================================================================
-- A) TRANSFORM.COSTAR — all objects
-- =============================================================================
USE DATABASE TRANSFORM;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'COSTAR'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- =============================================================================
-- B) TRANSFORM.COSTAR — all columns
-- =============================================================================
SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'COSTAR'
ORDER BY table_name, ordinal_position;

-- =============================================================================
-- C) SOURCE_PROD.COSTAR — all objects
-- =============================================================================
USE DATABASE SOURCE_PROD;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'SOURCE_PROD'
  AND UPPER(table_schema) = 'COSTAR'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- =============================================================================
-- D) SOURCE_PROD.COSTAR — all columns
-- =============================================================================
SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'SOURCE_PROD'
  AND UPPER(table_schema) = 'COSTAR'
ORDER BY table_name, ordinal_position;

-- =============================================================================
-- E) Row counts — extend UNION if §A/C list additional tables
-- =============================================================================
USE DATABASE TRANSFORM;

SELECT 'TRANSFORM.COSTAR.SCENARIOS' AS object_id, COUNT(*) AS row_count
FROM TRANSFORM.COSTAR.SCENARIOS;

USE DATABASE SOURCE_PROD;

SELECT 'SOURCE_PROD.COSTAR.SCENARIOS_METRICS' AS object_id, COUNT(*) AS row_count
FROM COSTAR.SCENARIOS_METRICS
UNION ALL
SELECT 'SOURCE_PROD.COSTAR.COSTAR_EXPORT_PARQUET', COUNT(*) FROM COSTAR.COSTAR_EXPORT_PARQUET
UNION ALL
SELECT 'SOURCE_PROD.COSTAR.METRIC_CATALOG_COSTAR_MF_MARKET_EXPORT', COUNT(*) FROM COSTAR.METRIC_CATALOG_COSTAR_MF_MARKET_EXPORT;

-- =============================================================================
-- F) TRANSFORM.COSTAR.SCENARIOS — time spine + scenario / type cardinalities
--     Grain reference: pretium-ai-dbt dbt/models/analytics/facts/fact_costar_cbsa_monthly.sql
-- =============================================================================
USE DATABASE TRANSFORM;

SELECT
    MIN(PERIOD) AS period_min,
    MAX(PERIOD) AS period_max,
    COUNT(DISTINCT LPAD(TRIM(CBSA_CODE), 5, '0')) AS distinct_cbsa,
    COUNT(DISTINCT PROPERTY_TYPE) AS distinct_property_type,
    COUNT(DISTINCT FORECAST_SCENARIO) AS distinct_forecast_scenario,
    COUNT(DISTINCT IS_FORECAST) AS distinct_is_forecast_flag
FROM TRANSFORM.COSTAR.SCENARIOS
WHERE CBSA_CODE IS NOT NULL;

SELECT PROPERTY_TYPE, COUNT(*) AS row_count
FROM TRANSFORM.COSTAR.SCENARIOS
WHERE CBSA_CODE IS NOT NULL
GROUP BY PROPERTY_TYPE
ORDER BY row_count DESC;

SELECT COALESCE(FORECAST_SCENARIO, '(null)') AS forecast_scenario, COUNT(*) AS row_count
FROM TRANSFORM.COSTAR.SCENARIOS
WHERE CBSA_CODE IS NOT NULL
GROUP BY COALESCE(FORECAST_SCENARIO, '(null)')
ORDER BY row_count DESC;

SELECT IS_FORECAST, COUNT(*) AS row_count
FROM TRANSFORM.COSTAR.SCENARIOS
WHERE CBSA_CODE IS NOT NULL
GROUP BY IS_FORECAST;

-- =============================================================================
-- G) SCENARIOS — duplicate grain (must be 0 before locking FACT grain)
-- =============================================================================
SELECT 'SCENARIOS duplicate grain' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT
        LPAD(TRIM(CBSA_CODE), 5, '0') AS cbsa_id,
        PROPERTY_TYPE,
        DATE_TRUNC('month', PERIOD) AS period_m,
        COALESCE(FORECAST_SCENARIO, 'actual') AS fs,
        IS_FORECAST,
        COUNT(*) AS c
    FROM TRANSFORM.COSTAR.SCENARIOS
    WHERE CBSA_CODE IS NOT NULL
    GROUP BY cbsa_id, PROPERTY_TYPE, period_m, fs, IS_FORECAST
    HAVING COUNT(*) > 1
) s;

-- =============================================================================
-- H) SCENARIOS — non-null counts on representative wide metrics
-- =============================================================================
SELECT
    COUNT(*) FILTER (WHERE MARKET_EFFECTIVE_RENT_PER_SF IS NOT NULL) AS n_eff_rent_psf,
    COUNT(*) FILTER (WHERE OCCUPANCY_RATE IS NOT NULL) AS n_occ,
    COUNT(*) FILTER (WHERE UNDER_CONSTRUCTION_UNITS IS NOT NULL) AS n_uc_units,
    COUNT(*) FILTER (WHERE ABSORPTION_UNITS IS NOT NULL) AS n_absorption_units,
    COUNT(*) FILTER (WHERE CAP_RATE IS NOT NULL) AS n_cap_rate,
    COUNT(*) FILTER (WHERE MEDIAN_HOUSEHOLD_INCOME IS NOT NULL) AS n_median_hhi
FROM TRANSFORM.COSTAR.SCENARIOS
WHERE CBSA_CODE IS NOT NULL;

-- =============================================================================
-- I) SOURCE_PROD.COSTAR.SCENARIOS_METRICS — scenario + geo uniques
-- =============================================================================
USE DATABASE SOURCE_PROD;

SELECT TRIM(SCENARIO_CODE) AS scenario_code, COUNT(*) AS row_count
FROM COSTAR.SCENARIOS_METRICS
GROUP BY TRIM(SCENARIO_CODE)
ORDER BY row_count DESC;

SELECT
    MIN(DATE_REFERENCE) AS date_ref_min,
    MAX(DATE_REFERENCE) AS date_ref_max,
    COUNT(*) FILTER (WHERE ID_CBSA IS NOT NULL) AS rows_with_cbsa,
    COUNT(*) FILTER (WHERE ID_ZIP IS NOT NULL) AS rows_with_zip,
    COUNT(*) FILTER (WHERE ID_SUBMARKET IS NOT NULL) AS rows_with_submarket
FROM COSTAR.SCENARIOS_METRICS;

-- =============================================================================
-- J) VARIANT parquet — sample OBJECT_KEYS (5 rows)
-- =============================================================================
SELECT file_name, _loaded_at, OBJECT_KEYS(v) AS top_level_keys
FROM COSTAR.COSTAR_EXPORT_PARQUET
WHERE v IS NOT NULL
ORDER BY _loaded_at DESC
LIMIT 5;

-- =============================================================================
-- K) TRANSFORM.FACT / TRANSFORM.DEV — CoStar-related published objects
-- =============================================================================
USE DATABASE TRANSFORM;

SELECT table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND table_schema IN ('FACT', 'DEV')
  AND UPPER(table_name) LIKE '%COSTAR%'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_schema, table_name;

-- =============================================================================
-- L) RAW.COSTAR — object list (legacy mirror)
-- =============================================================================
USE DATABASE RAW;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'RAW'
  AND UPPER(table_schema) = 'COSTAR'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;
