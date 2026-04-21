-- vet_catalog_only_vendors_pretium.sql
-- Purpose: Reproducible Snowflake checks for **catalog-only vendors** (no rows in
--   seeds/reference/catalog/dataset.csv for that vendor_code): bea, cfpb, cybersyn,
--   fbi, fdic, nws, salesforce, usps.
-- Run: snowsql -c pretium -f vet_catalog_only_vendors_pretium.sql
-- Notes:
--   * Grants on GLOBAL_GOVERNMENT.CYBERSYN vary by role — some views exist in
--     INFORMATION_SCHEMA but return "does not exist or not authorized" on SELECT.
--   * RAW database in pretium dev may **not** include RAW.BEA-style schemas; many
--     landings live under SOURCE_PROD instead.

-- Optional: USE ROLE <role_name>;  -- set explicitly if your default role lacks CYBERSYN SELECTs

-- 1) RAW: schemas (expect no BEA/CFPB/FBI/USPS/NOAA dedicated schema in many dev accounts)
SELECT 'RAW_SCHEMAS' AS probe, SCHEMA_NAME
FROM RAW.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME NOT IN ('INFORMATION_SCHEMA')
ORDER BY 1;

-- 2) SOURCE_PROD: vendor-shaped schemas (FDIC exists; BEA/CFPB/FBI may be absent)
SELECT 'SOURCE_PROD_SCHEMAS' AS probe, SCHEMA_NAME
FROM SOURCE_PROD.INFORMATION_SCHEMA.SCHEMATA
WHERE SCHEMA_NAME IN ('FDIC','BEA','CFPB','FBI','USPS','NOAA','HMDA')
ORDER BY 1;

-- 3) GLOBAL_GOVERNMENT.CYBERSYN: object count (metadata only)
SELECT 'CYBERSYN_OBJECT_COUNT' AS probe, COUNT(*) AS n
FROM GLOBAL_GOVERNMENT.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'CYBERSYN'
  AND TABLE_TYPE IN ('BASE TABLE', 'VIEW');

-- 4) Cybersyn: catalog entries for skipped-vendor domains
SELECT 'CYBERSYN_CATALOG_FBI_FDIC_USPS_CFPB_NOAA' AS probe, TABLE_NAME, TABLE_NAME_PROPER
FROM GLOBAL_GOVERNMENT.CYBERSYN.CYBERSYN_DATA_CATALOG
WHERE TABLE_NAME IN (
    'fbi_crime_timeseries',
    'fbi_crime_attributes',
    'fdic_summary_of_deposits_timeseries',
    'fdic_summary_of_deposits_attributes',
    'fdic_branch_locations_index',
    'usps_address_change_timeseries',
    'usps_address_change_attributes',
    'financial_cfpb_complaint',
    'financial_cfpb_complaint_pit'
)
   OR TABLE_NAME LIKE 'noaa_%'
ORDER BY TABLE_NAME;

-- 5) FBI (typically SELECT-authorized when Cybersyn share is partially granted)
SELECT 'FBI_CRIME_TIMESERIES_STATS' AS probe,
       COUNT(*) AS row_cnt,
       COUNT(DISTINCT geo_id) AS distinct_geo,
       COUNT(DISTINCT variable) AS distinct_variable,
       MIN(date) AS min_date,
       MAX(date) AS max_date,
       SUM(CASE WHEN value IS NULL THEN 1 ELSE 0 END) AS null_value_rows
FROM GLOBAL_GOVERNMENT.CYBERSYN.FBI_CRIME_TIMESERIES;

-- 6) SOURCE_PROD.FDIC landing (may be empty VARIANT ingest)
SELECT 'SOURCE_PROD_FDIC_CONSTRUCTION' AS probe, COUNT(*) AS row_cnt
FROM SOURCE_PROD.FDIC.CONSTRUCTION_LOANS_RAW;

-- 7) SOURCE_ENTITY.PROGRESS (Salesforce-adjacent per vendor.csv) — table visibility
SHOW TABLES IN SCHEMA SOURCE_ENTITY.PROGRESS;
