-- Vet REFERENCE.GEOGRAPHY + TRANSFORM.DEV vendor ref for labor / automation stack.
-- Run from inner repo root:
--   snowsql -c pretium -f scripts/sql/migration/vet_labor_stack_reference_geography_and_vendor_ref.sql
-- Pairing: docs/runbooks/RUN_LABOR_AUTOMATION_RISK_STACK_DBT.md
--
-- **Last Pretium run (2026-04-21):** COUNTY ~42k, STATE 56, COUNTY_CBSA_XWALK YEAR=2024 ~5.1k,
-- REF_ONET_SOC_TO_NAICS ~6.5k rows (non-zero).

-- ---------------------------------------------------------------------------
-- G) REFERENCE.GEOGRAPHY — county / state / county_cbsa_xwalk (YEAR = 2024 default)
-- ---------------------------------------------------------------------------
SELECT 'G_ref_geo_county_rows' AS check_id, TO_VARCHAR(COUNT(*)) AS result
FROM REFERENCE.GEOGRAPHY.COUNTY;

SELECT 'G_ref_geo_state_rows' AS check_id, TO_VARCHAR(COUNT(*)) AS result
FROM REFERENCE.GEOGRAPHY.STATE;

SELECT 'G_ref_geo_county_cbsa_xwalk_y2024' AS check_id, TO_VARCHAR(COUNT(*)) AS result
FROM REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK
WHERE YEAR = 2024;

-- ---------------------------------------------------------------------------
-- H) TRANSFORM.DEV — O*NET SOC × NAICS bridge (landed, not dbt-built)
-- ---------------------------------------------------------------------------
SELECT 'H_transform_dev_ref_onet_soc_to_naics_rows' AS check_id, TO_VARCHAR(COUNT(*)) AS result
FROM TRANSFORM.DEV.REF_ONET_SOC_TO_NAICS;
