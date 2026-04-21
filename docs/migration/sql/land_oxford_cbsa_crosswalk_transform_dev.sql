-- =============================================================================
-- Operator one-time (or refresh): land Oxford metro → Pretium CBSA crosswalk on TRANSFORM.DEV
--
-- Purpose: `ref_oxford_metro_cbsa` reads **only** `TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK` via dbt source
-- `transform_dev_oxford_ref` — no **TRANSFORM_PROD** dependency in the semantic-layer dbt graph.
--
-- Option A — copy from legacy Jon ref (read once; dbt never points at TRANSFORM_PROD):
--   Run with a role that can SELECT TRANSFORM_PROD.REF and CREATE TABLE on TRANSFORM.DEV.
--
-- Option B — load from governed export / seed pipeline (same column names as Jon table).
-- =============================================================================

CREATE OR REPLACE TABLE TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK AS
SELECT *
FROM TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK;

-- Optional: grant app read (same pattern as REFERENCE.GEOGRAPHY.ZCTA). Run separately if desired:
--   snowsql -c pretium -f docs/migration/sql/grant_select_transform_dev_oxford_cbsa_crosswalk.sql
