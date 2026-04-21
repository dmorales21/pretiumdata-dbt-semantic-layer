-- =============================================================================
-- Redfin (TRANSFORM.REDFIN + optional SOURCE_PROD / RAW) and Stanford SEDA
-- (SOURCE_PROD.STANFORD VARIANT + TRANSFORM.STANFORD + RAW.STANFORD)
--
-- snowsql -f (nested repo folder — same Errno 2 fix as other migration SQL):
--   Outer clone:  -f pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_stanford_redfin_for_dev_facts.sql
--   Inner project: -f scripts/sql/migration/inventory_stanford_redfin_for_dev_facts.sql
--
-- Operational: run **RF-A → RF-B** (then **ST-A → ST-B2**) first; export CSVs.
-- If RF-D / ST-G fail, fix identifiers from **RF-B** / **ST-B2** vs DESCRIBE.
--
-- Block index:
--   RF-A,B objects+columns TRANSFORM.REDFIN | RF-C counts | RF-D dup ZIP grain |
--   RF-E property/state splits | RF-F RAW.REDFIN | RF-I SOURCE_PROD.REDFIN
--   ST-A TRANSFORM.STANFORD | ST-B,B2 SOURCE_PROD objects+columns | ST-C RAW |
--   ST-D OBJECT_KEYS samples | ST-E counts | ST-F FILE_NAME mix | ST-G crosswalk dup
--
-- Related: docs/migration/MIGRATION_TASKS_STANFORD_REDFIN.md
-- Redfin cleaned: pretium-ai-dbt dbt/models/transform_prod/cleaned/cleaned_redfin_market_tracker_zipcode.sql
-- =============================================================================

-- ############################################################################
-- # REDFIN — TRANSFORM.REDFIN
-- ############################################################################

USE DATABASE TRANSFORM;

-- RF-A) Objects in TRANSFORM.REDFIN
SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'REDFIN'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- RF-B) Columns (export to CSV; compare to cleaned_redfin_market_tracker_*)
SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'REDFIN'
ORDER BY table_name, ordinal_position;

-- RF-C) Row counts — core latest tracker views (extend from RF-A)
SELECT 'REDFIN.REDFIN_ZIPCODE_MARKET_TRACKER_LATEST' AS object_id, COUNT(*) AS row_count
FROM REDFIN.REDFIN_ZIPCODE_MARKET_TRACKER_LATEST
UNION ALL
SELECT 'REDFIN.REDFIN_COUNTY_MARKET_TRACKER_LATEST', COUNT(*) FROM REDFIN.REDFIN_COUNTY_MARKET_TRACKER_LATEST
UNION ALL
SELECT 'REDFIN.REDFIN_METRO_MARKET_TRACKER_LATEST', COUNT(*) FROM REDFIN.REDFIN_METRO_MARKET_TRACKER_LATEST;

-- RF-D) ZIP tracker — duplicate grain (ZIP × month × property type) aligned with cleaned model filters
SELECT 'ZIP tracker dup grain' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT
        LPAD(LEFT(TRIM(COALESCE(TABLE_ID, REGION))::VARCHAR, 5), 5, '0') AS zip5,
        TRY_TO_DATE(TRIM(PERIOD_BEGIN)) AS period_begin,
        TRIM(PROPERTY_TYPE) AS property_type,
        COUNT(*) AS c
    FROM REDFIN.REDFIN_ZIPCODE_MARKET_TRACKER_LATEST
    WHERE PERIOD_BEGIN IS NOT NULL
      AND (TABLE_ID IS NOT NULL OR REGION IS NOT NULL)
      AND PROPERTY_TYPE IS NOT NULL
    GROUP BY zip5, period_begin, property_type
    HAVING c > 1
) s;

-- RF-E) Property type and state cardinality (ZIP view)
SELECT TRIM(PROPERTY_TYPE) AS property_type, COUNT(*) AS row_count
FROM REDFIN.REDFIN_ZIPCODE_MARKET_TRACKER_LATEST
WHERE PROPERTY_TYPE IS NOT NULL
GROUP BY TRIM(PROPERTY_TYPE)
ORDER BY row_count DESC
LIMIT 30;

SELECT TRIM(STATE_CODE) AS state_code, COUNT(*) AS row_count
FROM REDFIN.REDFIN_ZIPCODE_MARKET_TRACKER_LATEST
WHERE STATE_CODE IS NOT NULL
GROUP BY TRIM(STATE_CODE)
ORDER BY row_count DESC;

-- RF-F) Optional — RAW.REDFIN inventory
USE DATABASE RAW;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'RAW'
  AND UPPER(table_schema) = 'REDFIN'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- RF-I) Optional — SOURCE_PROD.REDFIN (canonical target; may be empty)
USE DATABASE SOURCE_PROD;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'SOURCE_PROD'
  AND UPPER(table_schema) = 'REDFIN'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- ############################################################################
-- # STANFORD — TRANSFORM.STANFORD, SOURCE_PROD.STANFORD, RAW.STANFORD
-- ############################################################################

USE DATABASE TRANSFORM;

-- ST-A) Objects in TRANSFORM.STANFORD
SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'STANFORD'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

USE DATABASE SOURCE_PROD;

-- ST-B) Objects in SOURCE_PROD.STANFORD
SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'SOURCE_PROD'
  AND UPPER(table_schema) = 'STANFORD'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- ST-B2) Columns on VARIANT parquet tables (typically V, FILE_NAME)
SELECT table_name, ordinal_position, column_name, data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'SOURCE_PROD'
  AND UPPER(table_schema) = 'STANFORD'
  AND UPPER(table_name) IN (
      'STANFORD_SEDA_ADMINDIST_PARQUET',
      'STANFORD_SEDA_CROSSWALK_PARQUET',
      'STANFORD_SEDA_COUNTY_PARQUET',
      'STANFORD_SEDA_FIELD_DICTIONARY'
  )
ORDER BY table_name, ordinal_position;

-- ST-C) RAW.STANFORD (legacy)
USE DATABASE RAW;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'RAW'
  AND UPPER(table_schema) = 'STANFORD'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;

-- ST-D) VARIANT — sample OBJECT_KEYS(V) (5 rows total across tables; adjust names from ST-B2)
USE DATABASE SOURCE_PROD;

SELECT 'STANFORD_SEDA_ADMINDIST_PARQUET' AS src_table, file_name, OBJECT_KEYS(v) AS variant_keys
FROM STANFORD.STANFORD_SEDA_ADMINDIST_PARQUET
WHERE v IS NOT NULL
ORDER BY file_name
LIMIT 2;

SELECT 'STANFORD_SEDA_CROSSWALK_PARQUET' AS src_table, file_name, OBJECT_KEYS(v) AS variant_keys
FROM STANFORD.STANFORD_SEDA_CROSSWALK_PARQUET
WHERE v IS NOT NULL
ORDER BY file_name
LIMIT 2;

SELECT 'STANFORD_SEDA_COUNTY_PARQUET' AS src_table, file_name, OBJECT_KEYS(v) AS variant_keys
FROM STANFORD.STANFORD_SEDA_COUNTY_PARQUET
WHERE v IS NOT NULL
ORDER BY file_name
LIMIT 1;

-- ST-E) Row counts — core parquet tables
SELECT 'STANFORD.STANFORD_SEDA_ADMINDIST_PARQUET' AS object_id, COUNT(*) AS row_count
FROM STANFORD.STANFORD_SEDA_ADMINDIST_PARQUET
UNION ALL
SELECT 'STANFORD.STANFORD_SEDA_CROSSWALK_PARQUET', COUNT(*) FROM STANFORD.STANFORD_SEDA_CROSSWALK_PARQUET
UNION ALL
SELECT 'STANFORD.STANFORD_SEDA_COUNTY_PARQUET', COUNT(*) FROM STANFORD.STANFORD_SEDA_COUNTY_PARQUET;

-- ST-F) FILE_NAME mix (pool / annual / long) — admindist
SELECT
    CASE
        WHEN LOWER(file_name) LIKE '%pool%' THEN 'pool'
        WHEN LOWER(file_name) LIKE '%annual%' THEN 'annual'
        WHEN LOWER(file_name) LIKE '%long%' THEN 'long'
        ELSE 'other'
    END AS file_class,
    COUNT(*) AS row_count
FROM STANFORD.STANFORD_SEDA_ADMINDIST_PARQUET
GROUP BY 1
ORDER BY row_count DESC;

-- ST-G) Crosswalk duplicate grain template (leaid × year) — comment out if columns missing; confirm via ST-B2
SELECT 'CROSSWALK dup leaid+year' AS check_name, COUNT(*) AS bad_rows
FROM (
    SELECT
        v:leaid::VARCHAR AS leaid,
        v:year::INTEGER AS yr,
        COUNT(*) AS c
    FROM STANFORD.STANFORD_SEDA_CROSSWALK_PARQUET
    WHERE v:leaid IS NOT NULL AND v:year IS NOT NULL
    GROUP BY leaid, yr
    HAVING c > 1
) s;
