-- =============================================================================
-- Legacy Zillow objects — DROP VIEW candidates (TRANSFORM_PROD / EDW_PROD)
-- =============================================================================
-- Generated for migration off broken wide cleaned / joined / tools surfaces onto
-- pretiumdata-dbt-semantic-layer TRANSFORM.DEV.FACT_ZILLOW_* long-form facts.
--
-- BEFORE RUNNING:
-- 1) Run lineage: no remaining ref() / workbook / app may SELECT these objects.
-- 2) Prefer repointing consumers to TRANSFORM.DEV.FACT_* or SOURCE_PROD.ZILLOW.RAW_*.
-- 3) Use a role authorized on each database/schema.
-- 4) This repo standard runbook targets TRANSFORM.DEV only; this file is
--    intentionally separate for production cleanup when you choose to execute it.
-- 5) FACT_ZILLOW_CBSA_METRICS: not recreated 1:1 in DEV — replace with queries
--    over FACT_ZILLOW_* at cbsa grain + metric_id filters (or a future CONCEPT).
-- =============================================================================
-- Optional: empty dbt audit artifacts (TRANSFORM_PROD.DBT_TEST__AUDIT) — only
-- if your org treats these as disposable. Uncomment after confirming.
-- =============================================================================
-- DROP TABLE IF EXISTS TRANSFORM_PROD.DBT_TEST__AUDIT.NOT_NULL_CLEANED_ZILLOW_ZORI_MFR_CBSA_CBSA_CODE;
-- DROP TABLE IF EXISTS TRANSFORM_PROD.DBT_TEST__AUDIT.NOT_NULL_CLEANED_ZILLOW_ZORI_MFR_CBSA_DATE_REFERENCE;
-- DROP TABLE IF EXISTS TRANSFORM_PROD.DBT_TEST__AUDIT.NOT_NULL_CLEANED_ZILLOW_ZORI_MFR_CBSA_ZORI_MFR;
-- DROP TABLE IF EXISTS TRANSFORM_PROD.DBT_TEST__AUDIT.NOT_NULL_CLEANED_ZILLOW_ZORI_SFR_CBSA_CBSA_CODE;
-- DROP TABLE IF EXISTS TRANSFORM_PROD.DBT_TEST__AUDIT.NOT_NULL_CLEANED_ZILLOW_ZORI_SFR_CBSA_DATE_REFERENCE;
-- DROP TABLE IF EXISTS TRANSFORM_PROD.DBT_TEST__AUDIT.NOT_NULL_CLEANED_ZILLOW_ZORI_SFR_CBSA_ZORI_SFR;

-- ---------------------------------------------------------------------------
-- TRANSFORM_PROD.CLEANED — per-series / wide Zillow views (stale or empty)
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.CLEANED_ZILLOW_ZHVI_ZIP;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.CLEANED_ZILLOW_SHARE_HOUSEHOLD_INCOME;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_LISTINGS_SFRCONDO_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_LISTINGS_SFR_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_PENDING_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZHVF_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_CBSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_STATE;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_ZIP;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_ZIP_TEST;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZODRI_CBSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZORDI_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.CLEANED.ZILLOW_ZORI_CBSA;

-- ---------------------------------------------------------------------------
-- TRANSFORM_PROD.FACT — legacy “fixed” ZIP / CBSA Zillow facts
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZHVI_ZIP_FIXED;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZHVI_COUNTY_FIXED;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZHVI_STATE_FIXED;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZHVI_PRICING;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZORI_ZIP_FIXED;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZORI_CBSA_FIXED;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_ZIP_TS_DEDUPED;
DROP VIEW IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_CITY_TS_DEDUPED;
-- BASE TABLE (not a view) in smoke audit — do NOT use DROP VIEW; explicit approval only:
-- DROP TABLE IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_MSA_TS_CLEAN;
-- DROP TABLE IF EXISTS TRANSFORM_PROD.FACT.FACT_ZILLOW_STATE_TS;

-- ---------------------------------------------------------------------------
-- TRANSFORM_PROD.JOINED — rollups (often broken upstream in smoke audit)
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS TRANSFORM_PROD.JOINED.FACT_ZILLOW_CBSA_METRICS;
DROP VIEW IF EXISTS TRANSFORM_PROD.JOINED.ZILLOW_ALL_METRICS_MSA;
DROP VIEW IF EXISTS TRANSFORM_PROD.JOINED.ZILLOW_ALL_METRICS_ZIP;

-- ---------------------------------------------------------------------------
-- EDW_PROD.TOOLS — app / intel views (drop only after consumer migration)
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS EDW_PROD.TOOLS.ZILLOW_MSA_APP_VIEW;
DROP VIEW IF EXISTS EDW_PROD.TOOLS.ZILLOW_ZIP_APP_VIEW;
DROP VIEW IF EXISTS EDW_PROD.TOOLS.ZILLOW_ZHVI_CBSA_TOOLS_MIN;
DROP VIEW IF EXISTS EDW_PROD.TOOLS.ZILLOW_ZHVF_ZIP_TOOLS_MIN;
DROP VIEW IF EXISTS EDW_PROD.TOOLS.MARKET_INTELLIGENCE_ZIP;
