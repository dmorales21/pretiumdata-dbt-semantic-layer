-- =============================================================================
-- Land **TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS** (O*NET SOC × NAICS staffing bridge).
--
-- Semantic-layer dbt reads this table only via
-- `source('transform_dev_vendor_ref', 'ref_onet_soc_to_naics')` — no **TRANSFORM_PROD**
-- or pretium-ai-dbt **dbt graph** dependency once this table exists in **TRANSFORM.DEV**.
--
-- **Run** with a role that can **CREATE TABLE** in **TRANSFORM.DEV** and **SELECT** your chosen
-- upstream snapshot (export, stage, or a one-time readable clone).
-- =============================================================================

-- Example A — you have a same-schema copy under a different name (adjust source name):
-- CREATE OR REPLACE TABLE TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS COPY GRANTS AS
-- SELECT * FROM TRANSFORM.DEV.BRIDGE_ONET_SOC_TO_NAICS_STAGING;

-- Example B — read from Jon **TRANSFORM.REF** after grants exist (dbt still must not depend on it):
-- CREATE OR REPLACE TABLE TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS COPY GRANTS AS
-- SELECT * FROM TRANSFORM.REF.ONET_SOC_TO_NAICS;

-- Example C — bootstrap from a governed Parquet / stage (column list must match pretium-ai-dbt
-- `ref_onet_soc_to_naics` / `fact_county_soc_employment` expectations: at minimum
-- `ONET_SOC_CODE`, `OCCUPATION_TITLE`, `NAICS_CODE`, `EMPLOYMENT_SHARE`, `NAICS_LEVEL`).
