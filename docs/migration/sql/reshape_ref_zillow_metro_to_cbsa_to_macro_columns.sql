-- =============================================================================
-- Normalize TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA → Jon-style column names
--
-- Use when DESCRIBE TABLE TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA shows
--   ZILLOW_REGION_ID, CBSA_ID, ZILLOW_METRO_NAME, …
-- but dbt macro `zillow_research_fact_enriched` is configured for
--   `zillow_metro_to_cbsa_xwalk_profile: legacy_jon` (expects zillow_6_digit + census_5_digit).
--
-- After this reshape, set `zillow_metro_to_cbsa_xwalk_profile: legacy_jon` in dbt_project.yml
-- (or keep `alex_metro_ref` and skip this script — both are valid).
--
-- Run: snowsql -c pretium -f docs/migration/sql/reshape_ref_zillow_metro_to_cbsa_to_macro_columns.sql
-- =============================================================================

USE DATABASE TRANSFORM;
USE SCHEMA DEV;

CREATE OR REPLACE TABLE REF_ZILLOW_METRO_TO_CBSA__RESHAPE_STAGING CLONE REF_ZILLOW_METRO_TO_CBSA;

CREATE OR REPLACE TABLE REF_ZILLOW_METRO_TO_CBSA AS
SELECT
    LPAD(TRIM(s.ZILLOW_REGION_ID::VARCHAR), 6, '0')     AS zillow_6_digit,
    LPAD(TRIM(s.CBSA_ID::VARCHAR), 5, '0')              AS census_5_digit,
    TRIM(s.ZILLOW_METRO_NAME)                           AS zillow_name,
    TRIM(s.CBSA_NAME)                                   AS census_name,
    TRIM(s.MATCHED_ON_CITY)                             AS matched_on_city,
    TRIM(s.MATCH_METHOD)                                AS match_method
FROM REF_ZILLOW_METRO_TO_CBSA__RESHAPE_STAGING AS s
WHERE s.ZILLOW_REGION_ID IS NOT NULL
  AND s.CBSA_ID IS NOT NULL;

DROP TABLE IF EXISTS REF_ZILLOW_METRO_TO_CBSA__RESHAPE_STAGING;
