-- Vet P1 catalog surfaces: objects that enable **new MET_* / activate** (BLS LAUS county + CBSA,
-- QCEW + county SOC + AI risk, O*NET landings, national rates/inflation fact, Cherre/Zonda/RCA
-- transaction paths where named in metric.csv).
--
-- **Last Pretium run (2026-04-21, snowsql -c pretium):** All section **B** probes **except**
-- `TRANSFORM.DEV.FACT_RATES_MACRO_NATIONAL_DAILY` returned `object_exists = TRUE`. **D** rowcounts
-- all non-zero (LAUS / QCEW / SOC / AI risk / SOURCE_PROD QCEW & rates raw). **FACT_RATES** is
-- defined in **pretium-ai-dbt** `dbt/models/transform/dev/fact_rates_macro_national_daily.sql`
-- (target `transform.dev`) — materialize with a profile that supplies `SNOWFLAKE_*` (or port) before
-- activating **RATES_*** / macro **MET_*** rows on that `table_path`. Pair **MET_132** parent:
-- `FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY` is included in **B** below. **Zonda** rollup rowcounts
-- remain **0** in `vet_concept_cherre_rca_zonda_rollups_pretium.sql` — keep **MET_130** `under_review`.
--
-- Run:
--   snowsql -c pretium -f scripts/sql/migration/vet_p1_met_enabling_sources_pretium.sql
--
-- Output: one row per **wanted** table — `object_exists` from INFORMATION_SCHEMA; optional
-- `approx_row_count` only when the table exists (bounded COUNT(*) on recent slice for large FACTs).

-- ---------------------------------------------------------------------------
-- A) Catalog + session context
-- ---------------------------------------------------------------------------
SELECT 'A_session' AS check_id,
       CURRENT_ACCOUNT() AS account,
       CURRENT_USER() AS sf_user,
       CURRENT_ROLE() AS role,
       CURRENT_WAREHOUSE() AS warehouse;

-- ---------------------------------------------------------------------------
-- B) TRANSFORM — silver BLS + TRANSFORM.DEV FACT_* (existence only)
-- ---------------------------------------------------------------------------
WITH want AS (
    SELECT * FROM VALUES
        ('TRANSFORM', 'BLS', 'LAUS_COUNTY'),
        ('TRANSFORM', 'BLS', 'LAUS_CBSA'),
        ('TRANSFORM', 'DEV', 'FACT_BLS_LAUS_COUNTY'),
        ('TRANSFORM', 'DEV', 'FACT_BLS_LAUS_COUNTY_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_BLS_LAUS_CBSA_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY'),
        ('TRANSFORM', 'DEV', 'FACT_COUNTY_SOC_EMPLOYMENT'),
        ('TRANSFORM', 'DEV', 'FACT_COUNTY_AI_REPLACEMENT_RISK'),
        ('TRANSFORM', 'DEV', 'REF_ONET_SOC_TO_NAICS'),
        ('TRANSFORM', 'DEV', 'FACT_RATES_MACRO_NATIONAL_DAILY'),
        ('TRANSFORM', 'DEV', 'FACT_ZILLOW_SALES'),
        ('TRANSFORM', 'DEV', 'FACT_CHERRE_RECORDER_SFR_H3_R8_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_CHERRE_RECORDER_MF_H3_R8_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_RCA_MF_TRANSACTIONS_H3_R8_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_RCA_MF_TRANSACTIONS_COUNTY_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_ZONDA_DEEDS_H3_R8_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY'),
        ('TRANSFORM', 'DEV', 'FACT_CHERRE_VACANT_H3_R8_SNAPSHOT'),
        ('TRANSFORM', 'DEV', 'FACT_CHERRE_VACANT_COUNTY_SNAPSHOT')
    AS t(table_catalog, table_schema, table_name)
)
SELECT
    'B_transform_object' AS check_id,
    w.table_catalog AS db,
    w.table_schema AS sc,
    w.table_name AS tbl,
    IFF(t.table_name IS NOT NULL, TRUE, FALSE) AS object_exists,
    t.table_type
FROM want AS w
LEFT JOIN TRANSFORM.INFORMATION_SCHEMA.TABLES AS t
    ON t.table_catalog = w.table_catalog
   AND t.table_schema = w.table_schema
   AND t.table_name = w.table_name
ORDER BY object_exists DESC, w.table_catalog, w.table_schema, w.table_name;

-- ---------------------------------------------------------------------------
-- C) SOURCE_PROD — QCEW / O*NET / RATES landings (existence)
-- ---------------------------------------------------------------------------
WITH want AS (
    SELECT * FROM VALUES
        ('SOURCE_PROD', 'BLS', 'QCEW_COUNTY_RAW'),
        ('SOURCE_PROD', 'ONET', 'OCCUPATION_BASE'),
        ('SOURCE_PROD', 'ONET', 'WORK_ACTIVITIES_GENERAL'),
        ('SOURCE_PROD', 'ONET', 'WORK_CONTEXT'),
        ('SOURCE_PROD', 'RATES', 'RATES_DAILY_RAW')
    AS t(table_catalog, table_schema, table_name)
)
SELECT
    'C_source_prod_object' AS check_id,
    w.table_catalog AS db,
    w.table_schema AS sc,
    w.table_name AS tbl,
    IFF(t.table_name IS NOT NULL, TRUE, FALSE) AS object_exists,
    t.table_type
FROM want AS w
LEFT JOIN SOURCE_PROD.INFORMATION_SCHEMA.TABLES AS t
    ON t.table_catalog = w.table_catalog
   AND t.table_schema = w.table_schema
   AND t.table_name = w.table_name
ORDER BY object_exists DESC, w.table_catalog, w.table_schema, w.table_name;

-- ---------------------------------------------------------------------------
-- D) Row samples (core paths — **fails if object missing**; run after B shows TRUE)
-- ---------------------------------------------------------------------------
SELECT 'D_bls_laus_county_recent' AS check_id, COUNT(*) AS row_count
FROM TRANSFORM.BLS.LAUS_COUNTY
WHERE DATE_REFERENCE >= DATEADD(year, -3, CURRENT_DATE());

SELECT 'D_fact_bls_laus_county_recent' AS check_id, COUNT(*) AS row_count
FROM TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY
WHERE DATE_REFERENCE >= DATEADD(year, -3, CURRENT_DATE());

SELECT 'D_fact_bls_laus_cbsa_monthly_recent' AS check_id, COUNT(*) AS row_count
FROM TRANSFORM.DEV.FACT_BLS_LAUS_CBSA_MONTHLY
WHERE DATE_REFERENCE >= DATEADD(year, -3, CURRENT_DATE());

SELECT 'D_fact_bls_qcew_county_naics_recent' AS check_id, COUNT(*) AS row_count
FROM TRANSFORM.DEV.FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY
WHERE YEAR >= YEAR(CURRENT_DATE()) - 3;

SELECT 'D_fact_county_soc_employment' AS check_id, COUNT(*) AS row_count
FROM TRANSFORM.DEV.FACT_COUNTY_SOC_EMPLOYMENT;

SELECT 'D_fact_county_ai_replacement_risk' AS check_id, COUNT(*) AS row_count
FROM TRANSFORM.DEV.FACT_COUNTY_AI_REPLACEMENT_RISK;

SELECT 'D_source_prod_qcew_raw_recent' AS check_id, COUNT(*) AS row_count
FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW
WHERE TRY_TO_NUMBER(v:year::varchar) >= YEAR(CURRENT_DATE()) - 3;

SELECT 'D_source_prod_rates_daily_recent' AS check_id, COUNT(*) AS row_count
FROM SOURCE_PROD.RATES.RATES_DAILY_RAW
WHERE ASOF_DATE_ET >= DATEADD(year, -2, CURRENT_DATE());

-- ---------------------------------------------------------------------------
-- E) metric.csv drift: FACT_BLS_LAUS_COUNTY_MONTHLY — column probe if object exists
-- ---------------------------------------------------------------------------
SELECT 'E_laus_county_monthly_columns' AS check_id,
       LISTAGG(column_name, ', ') WITHIN GROUP (ORDER BY ordinal_position) AS columns
FROM TRANSFORM.INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND table_schema = 'DEV'
  AND table_name = 'FACT_BLS_LAUS_COUNTY_MONTHLY';
