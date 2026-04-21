-- =============================================================================
-- Snowflake workbook: ApartmentIQ + Yardi Matrix — inventory, uniques, grains
-- =============================================================================
-- Purpose: Query every object, capture uniques, and prove grains BEFORE
--          designing or registering TRANSFORM.DEV.FACT_* for these vendors.
--
-- Database: USE DATABASE TRANSFORM; (change to TRANSFORM_PROD only if your
--          account’s vendor silver lives there — do not mix contracts.)
--
-- Operational order (mandatory):
--   1) Run **A** then **B** first. Save both result sets (CSV).
--   2) If any identifier in **G** or **H** fails to compile, fix names from **B**
--      (ordinal + column_name) before treating results as authoritative.
--   3) Run **C**–**H**; archive all outputs with run date under
--      docs/migration/artifacts/ and link from MIGRATION_LOG.md (see
--      MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md §1.5).
--
-- Section index:
-- | Block | Purpose |
-- |-------|---------|
-- | **A** | All tables/views in TRANSFORM.APARTMENTIQ and TRANSFORM.YARDI_MATRIX |
-- | **B** | All columns (ordinal, type, nullable) for both schemas |
-- | **C** | COUNT(*) for each known silver table (+ extend from **A** if extra) |
-- | **D** | Duplicate-grain checks: (PROPERTYID, MONTHDATE), (UNITID, MONTHDATE), PROPERTY_BH.ID, UNIT_BH.ID |
-- | **E** | ApartmentIQ time spine + distinct property/unit/month + geo cardinality + BHCOMP join density |
-- | **F** | Non-null counts on wide KPI columns (basis for which metrics become FACT_* columns) |
-- | **G** | Yardi Matrix: distinct DATATYPE, ASSETCLASS, ASSETCLASS×DATATYPE, period bounds, dimension counts, EAV duplicate grain |
-- | **H** | SUBMARKETMATCHZIPZCTA_BH: row count + distinct ZIPCODE, ZCTA, MARKETID, SUBMARKET, market–submarket pairs |
--
-- Related docs:
--   docs/migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md §1.5
--   pretium-ai-dbt/scripts/sql/admin/catalog/export_yardi_matrix_datatype_catalog.sql
--
-- snowsql -f path (repo has one nested `pretiumdata-dbt-semantic-layer/` folder):
--   From parent of that folder:  -f pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_apartmentiq_yardi_matrix_for_dev_facts.sql
--   From inside that folder:     -f scripts/sql/migration/inventory_apartmentiq_yardi_matrix_for_dev_facts.sql
-- =============================================================================

USE DATABASE TRANSFORM;  -- comment out if session context already set

-- =============================================================================
-- A) All tables/views in TRANSFORM.APARTMENTIQ and TRANSFORM.YARDI_MATRIX
-- =============================================================================
SELECT
    table_catalog,
    table_schema,
    table_name,
    table_type
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND table_schema IN ('APARTMENTIQ', 'YARDI_MATRIX')
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_schema, table_name;

-- =============================================================================
-- B) All columns (ordinal, type, nullable) for both schemas
-- =============================================================================
SELECT
    table_schema,
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM TRANSFORM.INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND table_schema IN ('APARTMENTIQ', 'YARDI_MATRIX')
ORDER BY table_schema, table_name, ordinal_position;

-- =============================================================================
-- C) Row counts — full table scan per object (run off-hours if large)
--     Extend: for every BASE TABLE from §A not listed below, add:
--       UNION ALL SELECT 'SCHEMA.TABLE', COUNT(*) FROM SCHEMA.TABLE
-- =============================================================================
SELECT 'APARTMENTIQ.PROPERTYKPI_BH' AS object_id, COUNT(*) AS row_count
FROM TRANSFORM.APARTMENTIQ.PROPERTYKPI_BH
UNION ALL
SELECT 'APARTMENTIQ.UNITKPI_BH', COUNT(*) FROM TRANSFORM.APARTMENTIQ.UNITKPI_BH
UNION ALL
SELECT 'APARTMENTIQ.PROPERTY_BH', COUNT(*) FROM TRANSFORM.APARTMENTIQ.PROPERTY_BH
UNION ALL
SELECT 'APARTMENTIQ.UNIT_BH', COUNT(*) FROM TRANSFORM.APARTMENTIQ.UNIT_BH
UNION ALL
SELECT 'APARTMENTIQ.BHCOMP_BH', COUNT(*) FROM TRANSFORM.APARTMENTIQ.BHCOMP_BH
UNION ALL
SELECT 'YARDI_MATRIX.MARKETPERFORMANCE_BH', COUNT(*) FROM TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH
UNION ALL
SELECT 'YARDI_MATRIX.SUBMARKETMATCHZIPZCTA_BH', COUNT(*) FROM TRANSFORM.YARDI_MATRIX.SUBMARKETMATCHZIPZCTA_BH;

-- If §A returns a third YARDI_MATRIX table (or extra APARTMENTIQ tables), append UNION ALL lines here.

-- =============================================================================
-- D) ApartmentIQ — duplicate-grain checks (bad_rows must be 0 for declared keys)
-- =============================================================================
SELECT 'PROPERTYKPI_BH duplicate (PROPERTYID, MONTHDATE)' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT PROPERTYID, MONTHDATE, COUNT(*) AS c
    FROM TRANSFORM.APARTMENTIQ.PROPERTYKPI_BH
    WHERE MONTHDATE IS NOT NULL
    GROUP BY PROPERTYID, MONTHDATE
    HAVING COUNT(*) > 1
) s;

SELECT 'UNITKPI_BH duplicate (UNITID, MONTHDATE)' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT UNITID, MONTHDATE, COUNT(*) AS c
    FROM TRANSFORM.APARTMENTIQ.UNITKPI_BH
    WHERE MONTHDATE IS NOT NULL
    GROUP BY UNITID, MONTHDATE
    HAVING COUNT(*) > 1
) s;

SELECT 'PROPERTY_BH duplicate ID' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT ID, COUNT(*) AS c
    FROM TRANSFORM.APARTMENTIQ.PROPERTY_BH
    GROUP BY ID
    HAVING COUNT(*) > 1
) s;

SELECT 'UNIT_BH duplicate ID' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT ID, COUNT(*) AS c
    FROM TRANSFORM.APARTMENTIQ.UNIT_BH
    GROUP BY ID
    HAVING COUNT(*) > 1
) s;

-- =============================================================================
-- E) ApartmentIQ — time spine + grain cardinality + geo + BHCOMP density
-- =============================================================================
SELECT
    MIN(MONTHDATE) AS property_kpi_month_min,
    MAX(MONTHDATE) AS property_kpi_month_max,
    COUNT(DISTINCT PROPERTYID) AS distinct_property_id,
    COUNT(DISTINCT DATE_TRUNC('month', MONTHDATE)) AS distinct_calendar_months,
    COUNT(DISTINCT CONCAT(COALESCE(PROPERTYID::VARCHAR, ''), '|', COALESCE(TO_VARCHAR(DATE_TRUNC('month', MONTHDATE)), '')))
        AS distinct_property_month_pairs
FROM TRANSFORM.APARTMENTIQ.PROPERTYKPI_BH
WHERE MONTHDATE IS NOT NULL;

SELECT
    MIN(MONTHDATE) AS unit_kpi_month_min,
    MAX(MONTHDATE) AS unit_kpi_month_max,
    COUNT(DISTINCT UNITID) AS distinct_unit_id,
    COUNT(DISTINCT DATE_TRUNC('month', MONTHDATE)) AS distinct_calendar_months,
    COUNT(DISTINCT CONCAT(COALESCE(UNITID::VARCHAR, ''), '|', COALESCE(TO_VARCHAR(DATE_TRUNC('month', MONTHDATE)), '')))
        AS distinct_unit_month_pairs
FROM TRANSFORM.APARTMENTIQ.UNITKPI_BH
WHERE MONTHDATE IS NOT NULL;

SELECT
    COUNT(DISTINCT STATE) AS distinct_state,
    COUNT(DISTINCT ZIPCODE) AS distinct_zipcode
FROM TRANSFORM.APARTMENTIQ.PROPERTY_BH;

SELECT
    COUNT(*) AS bhcomp_rows,
    COUNT(DISTINCT PROPERTYID) AS distinct_property,
    COUNT(DISTINCT MARKETID) AS distinct_market,
    ROUND(COUNT(*) / NULLIF(COUNT(DISTINCT PROPERTYID), 0), 4) AS avg_markets_per_property
FROM TRANSFORM.APARTMENTIQ.BHCOMP_BH;

-- =============================================================================
-- F) ApartmentIQ — non-null counts on wide KPI columns (FACT column candidates)
--     Extend SELECT list after PROPERTYKPI_BH / UNITKPI_BH DESCRIBE if new measures appear.
-- =============================================================================
SELECT
    COUNT(*) FILTER (WHERE OCCUPANCYADVERTISEDPERCENT IS NOT NULL) AS n_occ_pct,
    COUNT(*) FILTER (WHERE RENTAVERAGE IS NOT NULL) AS n_rent_avg,
    COUNT(*) FILTER (WHERE RENTNETEFFECTIVEAVERAGE IS NOT NULL) AS n_rent_nef_avg,
    COUNT(*) FILTER (WHERE SQUAREFOOTAVERAGE IS NOT NULL) AS n_sqft_avg,
    COUNT(*) FILTER (WHERE GOOGLERATING IS NOT NULL) AS n_google_rating,
    COUNT(*) FILTER (WHERE GOOGLEREVIEWCOUNT IS NOT NULL) AS n_google_reviews
FROM TRANSFORM.APARTMENTIQ.PROPERTYKPI_BH;

SELECT
    COUNT(*) FILTER (WHERE DAYSONMARKET IS NOT NULL) AS n_days_on_market
FROM TRANSFORM.APARTMENTIQ.UNITKPI_BH;

-- =============================================================================
-- G) Yardi Matrix — authoritative metric / dimension universe for long-form FACT
--     §G is the authoritative metric list for Matrix (DATATYPE + ASSETCLASS context).
--     Pair with SOURCE_ENTITY export: export_yardi_matrix_datatype_catalog.sql — diff TRIM(DATATYPE) sets.
-- =============================================================================
-- G1) Distinct DATATYPE (trimmed)
SELECT TRIM(DATATYPE) AS datatype, COUNT(*) AS row_count
FROM TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH
WHERE DATATYPE IS NOT NULL
GROUP BY TRIM(DATATYPE)
ORDER BY row_count DESC;

-- G2) Distinct ASSETCLASS (trimmed)
SELECT TRIM(ASSETCLASS) AS assetclass, COUNT(*) AS row_count
FROM TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH
WHERE ASSETCLASS IS NOT NULL
GROUP BY TRIM(ASSETCLASS)
ORDER BY row_count DESC;

-- G3) ASSETCLASS × DATATYPE (trimmed) — pivot / registration grain
SELECT
    TRIM(ASSETCLASS) AS assetclass,
    TRIM(DATATYPE) AS datatype,
    COUNT(*) AS row_count
FROM TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH
WHERE ASSETCLASS IS NOT NULL AND DATATYPE IS NOT NULL
GROUP BY TRIM(ASSETCLASS), TRIM(DATATYPE)
ORDER BY row_count DESC;

-- G4) Period bounds + G5) distinct dimension counts
SELECT
    MIN(PERIOD) AS period_min,
    MAX(PERIOD) AS period_max,
    COUNT(DISTINCT MARKET) AS distinct_market,
    COUNT(DISTINCT SUBMARKET) AS distinct_submarket,
    COUNT(DISTINCT PERIOD) AS distinct_period,
    COUNT(DISTINCT TRIM(DATATYPE)) AS distinct_datatype,
    COUNT(DISTINCT TRIM(ASSETCLASS)) AS distinct_assetclass
FROM TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH;

-- G6) EAV duplicate-grain — (MARKET, SUBMARKET, PERIOD, ASSETCLASS, DATATYPE)
SELECT 'MARKETPERFORMANCE_BH duplicate EAV grain' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT
        MARKET,
        SUBMARKET,
        PERIOD,
        ASSETCLASS,
        TRIM(DATATYPE) AS datatype_trimmed,
        COUNT(*) AS c
    FROM TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH
    GROUP BY MARKET, SUBMARKET, PERIOD, ASSETCLASS, TRIM(DATATYPE)
    HAVING COUNT(*) > 1
) s;

-- =============================================================================
-- H) Yardi Matrix — SUBMARKETMATCHZIPZCTA_BH bridge (geo join coverage inputs)
--     If MARKETID / ZIPCODE / ZCTA differ from §B, align identifiers to INFORMATION_SCHEMA.
-- =============================================================================
SELECT
    COUNT(*) AS bridge_rows,
    COUNT(DISTINCT ZIPCODE) AS distinct_zipcode,
    COUNT(DISTINCT ZCTA) AS distinct_zcta,
    COUNT(DISTINCT MARKETID) AS distinct_market_id,
    COUNT(DISTINCT SUBMARKET) AS distinct_submarket_label,
    COUNT(DISTINCT CONCAT(COALESCE(MARKETID::VARCHAR, ''), '|', COALESCE(SUBMARKET, ''))) AS distinct_market_submarket_pairs
FROM TRANSFORM.YARDI_MATRIX.SUBMARKETMATCHZIPZCTA_BH;
