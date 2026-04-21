-- =============================================================================
-- TRANSFORM.BPS.PERMITS_COUNTY, TRANSFORM.CENSUS.ACS5, TRANSFORM.BLS.LAUS_*,
-- TRANSFORM.LODES.OD_BG — column inventory, row counts, grain probes
--
-- Related: docs/migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md
-- Snapshot row counts (2026-04-19, pretium): BPS ~3.05M; ACS5 ~619.1M;
--   LAUS_CBSA ~168k; LAUS_COUNTY ~5.55M; OD_BG ~64.1M
-- =============================================================================

USE DATABASE TRANSFORM;

-- ############################################################################
-- # BPS — PERMITS_COUNTY
-- ############################################################################

-- BPS-A) Columns
SELECT table_catalog, table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'BPS'
  AND UPPER(table_name) = 'PERMITS_COUNTY'
ORDER BY ordinal_position;

-- BPS-B) Row count
SELECT COUNT(*) AS row_count FROM BPS.PERMITS_COUNTY;

-- BPS-C) Sample
SELECT * FROM BPS.PERMITS_COUNTY LIMIT 20;

-- BPS-D) Duplicate grain probe (adjust keys if DE changes DDL)
SELECT COUNT(*) AS dup_rows
FROM (
    SELECT
        DATE_REFERENCE,
        ID_CBSA,
        BUILDING_USE,
        MEASURE,
        ESTIMATE_TYPE,
        YEAR_REFERENCE,
        MONTH_REFERENCE,
        COUNT(*) AS c
    FROM BPS.PERMITS_COUNTY
    GROUP BY 1, 2, 3, 4, 5, 6, 7
    HAVING c > 1
) s;

-- BPS-E) Cardinality helpers
SELECT BUILDING_USE, COUNT(*) AS n FROM BPS.PERMITS_COUNTY GROUP BY 1 ORDER BY n DESC LIMIT 30;
SELECT MEASURE, COUNT(*) AS n FROM BPS.PERMITS_COUNTY GROUP BY 1 ORDER BY n DESC LIMIT 30;

-- ############################################################################
-- # CENSUS — ACS5
-- ############################################################################

-- ACS-A) Columns
SELECT table_catalog, table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'CENSUS'
  AND UPPER(table_name) = 'ACS5'
ORDER BY ordinal_position;

-- ACS-B) Row count (expensive — run off-hours)
-- SELECT COUNT(*) AS row_count FROM CENSUS.ACS5;

-- ACS-D) LEVEL distribution — **full table scan** (~619M rows); run in XL warehouse or skip
SELECT LEVEL, COUNT(*) AS n
FROM CENSUS.ACS5
GROUP BY 1
ORDER BY n DESC;

-- ACS-E) YEAR counts for block_group only (bounded; still heavy — add YEAR filter if needed)
SELECT YEAR, COUNT(*) AS n
FROM CENSUS.ACS5
WHERE LEVEL = 'block_group'
  AND YEAR IN (2014, 2019, 2024)
GROUP BY 1
ORDER BY 1;

-- ACS-F) Duplicate probe — block_group + vintages used by fact_acs_demographics_county — **large scan**
SELECT COUNT(*) AS dup_rows
FROM (
    SELECT GEO_ID, VARIABLE_ID, YEAR, COUNT(*) AS c
    FROM CENSUS.ACS5
    WHERE LEVEL = 'block_group'
      AND YEAR IN (2014, 2019, 2024)
      AND GEO_ID IS NOT NULL
    GROUP BY 1, 2, 3
    HAVING c > 1
) s;

-- ############################################################################
-- # BLS — LAUS_CBSA
-- ############################################################################

-- LAUS-CBSA-A) Columns
SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'BLS'
  AND UPPER(table_name) = 'LAUS_CBSA'
ORDER BY ordinal_position;

-- LAUS-CBSA-B) Row count
SELECT COUNT(*) AS row_count FROM BLS.LAUS_CBSA;

-- LAUS-CBSA-D) Date range
SELECT MIN(DATE_REFERENCE) AS d_min, MAX(DATE_REFERENCE) AS d_max FROM BLS.LAUS_CBSA;

-- LAUS-CBSA-E) AREA_CODE sample (do not assume OMB CBSA — see fact_bls_laus_cbsa_monthly.sql)
SELECT AREA_CODE, COUNT(*) AS n
FROM BLS.LAUS_CBSA
GROUP BY 1
ORDER BY n DESC
LIMIT 20;

-- ############################################################################
-- # BLS — LAUS_COUNTY
-- ############################################################################

-- LAUS-CNTY-A) Columns
SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'BLS'
  AND UPPER(table_name) = 'LAUS_COUNTY'
ORDER BY ordinal_position;

-- LAUS-CNTY-B) Row count
SELECT COUNT(*) AS row_count FROM BLS.LAUS_COUNTY;

-- LAUS-CNTY-D) MEASURE_CODE distribution
SELECT MEASURE_CODE, METRIC_NAME, COUNT(*) AS n
FROM BLS.LAUS_COUNTY
GROUP BY 1, 2
ORDER BY n DESC;

-- LAUS-CNTY-E) Duplicate grain
SELECT COUNT(*) AS dup_rows
FROM (
    SELECT DATE_REFERENCE, COUNTY_FIPS, MEASURE_CODE, COUNT(*) AS c
    FROM BLS.LAUS_COUNTY
    GROUP BY 1, 2, 3
    HAVING c > 1
) s;

-- ############################################################################
-- # LODES — OD_BG
-- ############################################################################

-- LODES-A) Columns
SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'LODES'
  AND UPPER(table_name) = 'OD_BG'
ORDER BY ordinal_position;

-- LODES-B) Row count
SELECT COUNT(*) AS row_count FROM LODES.OD_BG;

-- LODES-D) Vintage years
SELECT VINTAGE_YEAR, COUNT(*) AS n
FROM LODES.OD_BG
GROUP BY 1
ORDER BY 1;

-- LODES-E) Duplicate grain probe (single vintage to bound cost — change year as needed)
SELECT COUNT(*) AS dup_rows
FROM (
    SELECT
        VINTAGE_YEAR,
        GEO_ID_RESIDENCE_BLOCK_GROUP,
        GEO_ID_WORKPLACE_BLOCK_GROUP,
        LODES_JOB_TYPE_CODE,
        COUNT(*) AS c
    FROM LODES.OD_BG
    WHERE VINTAGE_YEAR = (SELECT MAX(VINTAGE_YEAR) FROM LODES.OD_BG)
    GROUP BY 1, 2, 3, 4
    HAVING c > 1
) s;
