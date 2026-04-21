-- =============================================================================
-- TRANSFORM.YARDI — inventory + uniques (BH *_BH vs Progress *_PROGRESS)
--
-- Purpose: Record all objects, primary-key candidates, status/ledger uniques
--          before modeling FACT_* in TRANSFORM.DEV.
--
-- Operational order: run **A → B** first; if **H** / **I** fail, fix identifiers
-- from **B** before treating duplicate-grain checks as authoritative.
--
-- snowsql -f path (nested `pretiumdata-dbt-semantic-layer/` folder):
--   From parent:  -f pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql
--   From inner:   -f scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql
--
-- Run in Snowflake (TRANSFORM → TRANSFORM_PROD if your account uses PROD).
-- Archive outputs per MIGRATION_TASKS_YARDI_BH_PROGRESS.md §1.5 under
--   docs/migration/artifacts/batch012_yardi/ (see RUNBOOK.md there; §A–B split scripts
--   inventory_yardi_batch012_section_a_tables.sql / _section_b_columns.sql).
--
-- Related: docs/migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md
-- Pair with: MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md (YARDI_MATRIX only)
--
-- Section index: A objects, B columns, C row counts, D–F PK-ish duplicates
-- (PROPERTY/UNIT/TENANT), G SSTATUS on UNIT_*, H UNIT_STATUS spine + dup grain,
-- I TRANS_* ledger spine + transaction HMY uniqueness, J PROPERTY geo cardinalities.
-- =============================================================================

USE DATABASE TRANSFORM;

-- -----------------------------------------------------------------------------
-- A) All objects in TRANSFORM.YARDI
-- -----------------------------------------------------------------------------
SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'YARDI'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- -----------------------------------------------------------------------------
-- B) All columns (full schema — large result; export to CSV)
-- -----------------------------------------------------------------------------
SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'YARDI'
ORDER BY table_name, ordinal_position;

-- -----------------------------------------------------------------------------
-- C) Row counts — core silver + ledgers (extend from §A if tables are missing)
-- -----------------------------------------------------------------------------
SELECT 'YARDI.PROPERTY_BH' AS object_id, COUNT(*) AS row_count FROM YARDI.PROPERTY_BH
UNION ALL SELECT 'YARDI.PROPERTY_PROGRESS', COUNT(*) FROM YARDI.PROPERTY_PROGRESS
UNION ALL SELECT 'YARDI.TENANT_BH', COUNT(*) FROM YARDI.TENANT_BH
UNION ALL SELECT 'YARDI.TENANT_PROGRESS', COUNT(*) FROM YARDI.TENANT_PROGRESS
UNION ALL SELECT 'YARDI.UNIT_BH', COUNT(*) FROM YARDI.UNIT_BH
UNION ALL SELECT 'YARDI.UNIT_PROGRESS', COUNT(*) FROM YARDI.UNIT_PROGRESS
UNION ALL SELECT 'YARDI.UNIT_STATUS_BH', COUNT(*) FROM YARDI.UNIT_STATUS_BH
UNION ALL SELECT 'YARDI.UNIT_STATUS_PROGRESS', COUNT(*) FROM YARDI.UNIT_STATUS_PROGRESS
UNION ALL SELECT 'YARDI.UNITTYPE_PROGRESS', COUNT(*) FROM YARDI.UNITTYPE_PROGRESS
UNION ALL SELECT 'YARDI.TRANS_BH', COUNT(*) FROM YARDI.TRANS_BH
UNION ALL SELECT 'YARDI.TRANS_PROGRESS', COUNT(*) FROM YARDI.TRANS_PROGRESS;

-- -----------------------------------------------------------------------------
-- D) PROPERTY_* — duplicate HMY (property surrogate)
-- -----------------------------------------------------------------------------
SELECT 'PROPERTY_BH duplicate HMY' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMY, COUNT(*) AS c FROM YARDI.PROPERTY_BH WHERE HMY IS NOT NULL GROUP BY HMY HAVING c > 1) s;

SELECT 'PROPERTY_PROGRESS duplicate HMY' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMY, COUNT(*) AS c FROM YARDI.PROPERTY_PROGRESS WHERE HMY IS NOT NULL GROUP BY HMY HAVING c > 1) s;

-- -----------------------------------------------------------------------------
-- E) UNIT_* — duplicate HMY (unit surrogate)
-- -----------------------------------------------------------------------------
SELECT 'UNIT_BH duplicate HMY' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMY, COUNT(*) AS c FROM YARDI.UNIT_BH WHERE HMY IS NOT NULL GROUP BY HMY HAVING c > 1) s;

SELECT 'UNIT_PROGRESS duplicate HMY' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMY, COUNT(*) AS c FROM YARDI.UNIT_PROGRESS WHERE HMY IS NOT NULL GROUP BY HMY HAVING c > 1) s;

-- -----------------------------------------------------------------------------
-- F) TENANT_* — duplicate HMYPERSON (confirm column name via §B if different)
-- -----------------------------------------------------------------------------
SELECT 'TENANT_BH duplicate HMYPERSON' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMYPERSON, COUNT(*) AS c FROM YARDI.TENANT_BH WHERE HMYPERSON IS NOT NULL GROUP BY HMYPERSON HAVING c > 1) s;

SELECT 'TENANT_PROGRESS duplicate HMYPERSON' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMYPERSON, COUNT(*) AS c FROM YARDI.TENANT_PROGRESS WHERE HMYPERSON IS NOT NULL GROUP BY HMYPERSON HAVING c > 1) s;

-- -----------------------------------------------------------------------------
-- G) UNIT_* — distinct unit status (column SSTATUS per cleaned_yardi_unit_bh pattern)
-- -----------------------------------------------------------------------------
SELECT 'UNIT_BH' AS tbl, SSTATUS, COUNT(*) AS row_count
FROM YARDI.UNIT_BH
WHERE SSTATUS IS NOT NULL
GROUP BY SSTATUS
ORDER BY row_count DESC;

SELECT 'UNIT_PROGRESS' AS tbl, SSTATUS, COUNT(*) AS row_count
FROM YARDI.UNIT_PROGRESS
WHERE SSTATUS IS NOT NULL
GROUP BY SSTATUS
ORDER BY row_count DESC;

-- -----------------------------------------------------------------------------
-- H) UNIT_STATUS_* — time spine + duplicate-grain template
--     Adjust column names from §B (common Yardi: HUNIT, DTSTART, DTEND, SSTATUS).
-- -----------------------------------------------------------------------------
SELECT
    'UNIT_STATUS_BH' AS tbl,
    MIN(DTSTART) AS dt_start_min,
    MAX(COALESCE(DTEND, DTSTART)) AS dt_end_or_start_max,
    COUNT(DISTINCT HUNIT) AS distinct_unit
FROM YARDI.UNIT_STATUS_BH;

SELECT
    'UNIT_STATUS_PROGRESS' AS tbl,
    MIN(DTSTART) AS dt_start_min,
    MAX(COALESCE(DTEND, DTSTART)) AS dt_end_or_start_max,
    COUNT(DISTINCT HUNIT) AS distinct_unit
FROM YARDI.UNIT_STATUS_PROGRESS;

-- Grain duplicate: one row per (HUNIT, DTSTART, SSTATUS) — comment out if columns differ.
SELECT 'UNIT_STATUS_BH duplicate grain' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT HUNIT, DTSTART, SSTATUS, COUNT(*) AS c
    FROM YARDI.UNIT_STATUS_BH
    WHERE HUNIT IS NOT NULL AND DTSTART IS NOT NULL
    GROUP BY HUNIT, DTSTART, SSTATUS
    HAVING c > 1
) s;

SELECT 'UNIT_STATUS_PROGRESS duplicate grain' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT HUNIT, DTSTART, SSTATUS, COUNT(*) AS c
    FROM YARDI.UNIT_STATUS_PROGRESS
    WHERE HUNIT IS NOT NULL AND DTSTART IS NOT NULL
    GROUP BY HUNIT, DTSTART, SSTATUS
    HAVING c > 1
) s;

-- -----------------------------------------------------------------------------
-- I) TRANS_BH / TRANS_PROGRESS — ledger spine for financial / delinquency facts
--     BH: COALESCE(SDATEOCCURRED, UPOSTDATE). Progress: UPOSTDATE (see fact_* comments).
-- -----------------------------------------------------------------------------
SELECT
    'TRANS_BH' AS tbl,
    MIN(COALESCE(SDATEOCCURRED, UPOSTDATE)) AS post_ts_min,
    MAX(COALESCE(SDATEOCCURRED, UPOSTDATE)) AS post_ts_max,
    COUNT(*) AS row_count,
    COUNT(*) FILTER (WHERE VOID = 0) AS n_non_void,
    COUNT(DISTINCT ITYPE) AS distinct_itype
FROM YARDI.TRANS_BH;

SELECT
    'TRANS_PROGRESS' AS tbl,
    MIN(UPOSTDATE) AS post_ts_min,
    MAX(UPOSTDATE) AS post_ts_max,
    COUNT(*) AS row_count,
    COUNT(*) FILTER (WHERE VOID = 0) AS n_non_void,
    COUNT(DISTINCT ITYPE) AS distinct_itype
FROM YARDI.TRANS_PROGRESS;

-- HMY on TRANS_* is the transaction surrogate (see fact_bh_financials_monthly); duplicates = bad.
SELECT 'TRANS_BH duplicate transaction HMY' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMY, COUNT(*) AS c FROM YARDI.TRANS_BH WHERE HMY IS NOT NULL GROUP BY HMY HAVING c > 1) s;

SELECT 'TRANS_PROGRESS duplicate transaction HMY' AS check_name, COUNT(*) AS bad_rows
FROM (SELECT HMY, COUNT(*) AS c FROM YARDI.TRANS_PROGRESS WHERE HMY IS NOT NULL GROUP BY HMY HAVING c > 1) s;

-- -----------------------------------------------------------------------------
-- J) PROPERTY_* — geographic cardinality (ZIP/state for CBSA bridges)
-- -----------------------------------------------------------------------------
SELECT
    'PROPERTY_BH' AS tbl,
    COUNT(DISTINCT SSTATE) AS distinct_state,
    COUNT(DISTINCT LEFT(TRIM(SZIPCODE), 5)) AS distinct_zip5
FROM YARDI.PROPERTY_BH
WHERE HMY IS NOT NULL;

SELECT
    'PROPERTY_PROGRESS' AS tbl,
    COUNT(DISTINCT SSTATE) AS distinct_state,
    COUNT(DISTINCT LEFT(TRIM(SZIPCODE), 5)) AS distinct_zip5
FROM YARDI.PROPERTY_PROGRESS
WHERE HMY IS NOT NULL;
