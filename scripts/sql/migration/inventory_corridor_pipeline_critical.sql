-- =============================================================================
-- Corridor development pipeline — critical REFERENCE, LODES, TRANSFORM.DEV
-- Ward inputs (see docs/migration/MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md)
--
-- Run with a role that can read REFERENCE, ANALYTICS, TRANSFORM (pretium profile).
-- =============================================================================

-- ############################################################################
-- # REFERENCE — CBSA × H3 R8 polyfill spine
-- ############################################################################

USE DATABASE REFERENCE;

-- CORR-REF-A) CBSA_H3_R8_POLYFILL (physical: REFERENCE.GEOGRAPHY — verify; legacy code may say reference.reference)
SELECT column_name, data_type, ordinal_position
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'REFERENCE'
  AND table_schema = 'GEOGRAPHY'
  AND UPPER(table_name) = 'CBSA_H3_R8_POLYFILL'
ORDER BY ordinal_position;

SELECT COUNT(*) AS row_count FROM REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL;

SELECT COUNT(DISTINCT cbsa_id) AS distinct_cbsa, COUNT(DISTINCT h3_r8_hex) AS distinct_hex
FROM REFERENCE.GEOGRAPHY.CBSA_H3_R8_POLYFILL;

-- ############################################################################
-- # REFERENCE.GEOGRAPHY — BG ↔ H3 bridge + TIGER blockgroups
-- ############################################################################

USE DATABASE REFERENCE;

-- CORR-REF-B) blockgroup_h3_r8_polyfill (canonical table) + optional BRIDGE_BG_* view
SELECT table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'REFERENCE'
  AND table_schema = 'GEOGRAPHY'
  AND UPPER(table_name) IN ('BLOCKGROUP_H3_R8_POLYFILL', 'BRIDGE_BG_H3_R8_POLYFILL')
ORDER BY table_name;

SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'REFERENCE'
  AND table_schema = 'GEOGRAPHY'
  AND UPPER(table_name) = 'BLOCKGROUP_H3_R8_POLYFILL'
ORDER BY ordinal_position;

SELECT COUNT(*) AS row_count FROM REFERENCE.GEOGRAPHY.BLOCKGROUP_H3_R8_POLYFILL;

-- CORR-REF-C) BLOCKGROUPS (land/water columns for water-hex filter)
SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'REFERENCE'
  AND table_schema = 'GEOGRAPHY'
  AND UPPER(table_name) = 'BLOCKGROUPS'
ORDER BY ordinal_position;

SELECT COUNT(*) AS row_count FROM REFERENCE.GEOGRAPHY.BLOCKGROUPS;

-- ############################################################################
-- # ANALYTICS.REFERENCE — fallback bridges (if REFERENCE.GEOGRAPHY not granted)
-- ############################################################################

USE DATABASE ANALYTICS;

SELECT table_name
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'ANALYTICS'
  AND table_schema = 'REFERENCE'
  AND UPPER(table_name) IN (
      'BLOCKGROUP_H3_R8_POLYFILL',
      'BRIDGE_BG_H3_R8_POLYFILL',
      'BRIDGE_ZIP_H3_R8_POLYFILL',
      'BRIDGE_PLACE_H3_R8_POLYFILL',
      'BRIDGE_PLACE_ZIP'
  )
ORDER BY table_name;

-- If present, repeat DESCRIBE pattern for each.

-- ############################################################################
-- # TRANSFORM.LODES — OD_H3_R8 (hex-pair annual; feeds fact_lodes_od_h3_r8_annual)
-- ############################################################################

USE DATABASE TRANSFORM;

SELECT column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND table_schema = 'LODES'
  AND UPPER(table_name) = 'OD_H3_R8'
ORDER BY ordinal_position;

SELECT COUNT(*) AS row_count FROM TRANSFORM.LODES.OD_H3_R8;

SELECT VINTAGE_YEAR, COUNT(*) AS n
FROM TRANSFORM.LODES.OD_H3_R8
GROUP BY 1
ORDER BY 1;

-- Dup grain (latest vintage only)
SELECT COUNT(*) AS dup_rows
FROM (
    SELECT VINTAGE_YEAR, H3_R8_RESIDENCE, H3_R8_WORKPLACE, COUNT(*) AS c
    FROM TRANSFORM.LODES.OD_H3_R8
    WHERE VINTAGE_YEAR = (SELECT MAX(VINTAGE_YEAR) FROM TRANSFORM.LODES.OD_H3_R8)
    GROUP BY 1, 2, 3
    HAVING c > 1
) s;

-- ############################################################################
-- # TRANSFORM.DEV — Ward default spine fact smoke (corridor_pipeline.py)
-- ############################################################################

USE DATABASE TRANSFORM;

-- CORR-DEV-SMOKE) fingerprint queries (match corridor_pipeline.py _fingerprint_queries)
SELECT 'fact_census_acs5_h3_r8_snapshot' AS obj, TO_VARCHAR(MAX(dbt_updated_at)) AS v
FROM TRANSFORM.DEV.FACT_CENSUS_ACS5_H3_R8_SNAPSHOT
UNION ALL
SELECT 'fact_cherre_stock_h3_r8', TO_VARCHAR(MAX(dbt_updated_at)) FROM TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8
UNION ALL
SELECT 'fact_stanford_seda_h3_r8_snapshot', TO_VARCHAR(MAX(dbt_updated_at)) FROM TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT
UNION ALL
SELECT 'lodes_h3r8_workplace_gravity.vintage_year', MAX(vintage_year)::VARCHAR FROM TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY
UNION ALL
SELECT 'lodes_nearest_center_h3_r8_annual.vintage_year', MAX(vintage_year)::VARCHAR FROM TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL;
