-- QA template — harmonized tract / ZCTA parquet inventory vs Snowflake stage
--
-- Source of truth for *expected* file names: REFERENCE.DRAFT seed
--   `qa_tract_zcta_harmonized_parquet_manifest` (dbt: seeds/reference/draft/qa_tract_zcta_harmonized_parquet_manifest.csv).
--
-- Operator steps:
-- 1) Create or identify an internal stage (e.g. @SOURCE_PROD.GEOGRAPHY.NHGIS_HARMONIZED_PARQUET_STAGE)
--    per SCHEMA_RULES: landed vendor/geo files belong SOURCE_PROD / RAW, not TRANSFORM.DEV.
-- 2) Replace @YOUR_STAGE below and run LIST / compare in a worksheet or pipeline.
--
-- Example (Snowflake — adjust database/schema/stage):
-- LIST @SOURCE_PROD.GEOGRAPHY.NHGIS_HARMONIZED_PARQUET_STAGE PATTERN='.*[.]parquet';
--
-- Compare to expected manifest:
SELECT m.file_name AS expected_file, m.geo_unit, m.schema_year, m.approx_size_mb
FROM REFERENCE.DRAFT.QA_TRACT_ZCTA_HARMONIZED_PARQUET_MANIFEST AS m
ORDER BY m.geo_unit, m.schema_year, m.file_name;

-- Anti-join template: files on stage not in manifest (fill @YOUR_STAGE and run LIST into a temp table first).
-- WITH stage_files AS ( SELECT "name" AS file_name FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) )
-- SELECT s.file_name
-- FROM stage_files AS s
-- LEFT JOIN REFERENCE.DRAFT.QA_TRACT_ZCTA_HARMONIZED_PARQUET_MANIFEST AS m
--   ON LOWER(s.file_name) = LOWER(m.file_name)
-- WHERE m.file_name IS NULL;
