-- Fund IV comps / pricing API — **data presence** smoke checks (tables/views with rows or empty-but-existing).
-- Edit FQNs if your warehouse uses different database/schema names.
-- Run: snowsql -c pretium -f scripts/sql/validation/fund4_pricing_api_data_presence.sql
--
-- Related: docs/migration/FUND4_COMPS_PRICING_DATA_UNDERPINNING.md

-- ---------------------------------------------------------------------------
-- A) TRANSFORM.DEV — already wired in this repo’s dbt graph (adjust if missing)
-- ---------------------------------------------------------------------------

SELECT 'A1_fact_cherre_avm_county_monthly_rowcount' AS check_name, COUNT(*) AS n
FROM TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY;

SELECT 'A2_cherre_avm_geo_stats_rowcount' AS check_name, COUNT(*) AS n
FROM TRANSFORM.DEV.CHERRE_AVM_GEO_STATS;

SELECT 'A3_fact_markerr_rent_property_cbsa_monthly_rowcount' AS check_name, COUNT(*) AS n
FROM TRANSFORM.DEV.FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY;

SELECT 'A4_fact_markerr_rent_sfr_rowcount' AS check_name, COUNT(*) AS n
FROM TRANSFORM.DEV.FACT_MARKERR_RENT_SFR;

-- ---------------------------------------------------------------------------
-- B) EDW delivery (spec defaults) — uncomment when role has SELECT on EDW_PROD.DELIVERY
-- ---------------------------------------------------------------------------

-- SELECT 'B1_v_ic_disposition_yield_property_rowcount' AS check_name, COUNT(*) AS n
-- FROM EDW_PROD.DELIVERY.V_IC_DISPOSITION_YIELD_PROPERTY;

-- SELECT 'B2_v_cherre_ihpm_property_rowcount' AS check_name, COUNT(*) AS n
-- FROM EDW_PROD.DELIVERY.V_CHERRE_IHPM_PROPERTY;

-- ---------------------------------------------------------------------------
-- C) Spec alternate FQN for county AVM (ANALYTICS.FACTS) — uncomment if used in your org
-- ---------------------------------------------------------------------------

-- SELECT 'C1_analytics_facts_cherre_avm_county_monthly_rowcount' AS check_name, COUNT(*) AS n
-- FROM ANALYTICS.FACTS.CHERRE_AVM_COUNTY_MONTHLY;
