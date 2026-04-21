-- =============================================================================
-- One-time (or refresh): copy Zillow metro RegionID → Census CBSA xwalk into
-- **TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA** (Alex-owned; dbt reads via
-- `source('transform_dev_vendor_ref', 'ref_zillow_metro_to_cbsa')`).
--
-- **Do not** use **TRANSFORM_PROD** as the long-term source (deprecated Alex legacy).
-- Read from **Jon’s** published table (typically **TRANSFORM.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING**)
-- or from a governed export Jon provides — then land the copy in **TRANSFORM.DEV** only.
--
-- Run in Snowflake with a role that can **SELECT** the Jon xwalk and **CREATE TABLE** in TRANSFORM.DEV.
-- =============================================================================

-- Prefer explicit column names matching `zillow_research_fact_enriched` + `legacy_jon` profile
-- (zillow_6_digit, census_5_digit, …). `SELECT *` only when Jon physical columns match exactly.
CREATE OR REPLACE TABLE TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA AS
SELECT
    LPAD(TRIM(ZILLOW_6_DIGIT::VARCHAR), 6, '0')     AS zillow_6_digit,
    LPAD(TRIM(CENSUS_5_DIGIT::VARCHAR), 5, '0')     AS census_5_digit,
    TRIM(ZILLOW_NAME)                               AS zillow_name,
    TRIM(CENSUS_NAME)                               AS census_name,
    TRIM(MATCHED_ON_CITY)                           AS matched_on_city,
    TRIM(MATCH_METHOD)                              AS match_method
FROM TRANSFORM.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING;

-- If your DEV table already has bridge-style names (ZILLOW_REGION_ID / CBSA_ID), either:
--   (a) set dbt var `zillow_metro_to_cbsa_xwalk_profile: alex_metro_ref`, or
--   (b) run `reshape_ref_zillow_metro_to_cbsa_to_macro_columns.sql` then use `legacy_jon`.
