-- =============================================================================
-- ACS5 + LODES OD_BG — metadata-only inventory (no full-table scans)
--
-- Use when XL warehouse / off-hours window is **not** available for:
--   inventory_transform_bps_census_bls_lodes.sql (ACS-D/E/F, LODES-D, LODES-E, etc.)
--
-- Run from inner project root:
--   snowsql -c pretium -f scripts/sql/migration/inventory_transform_acs5_lodes_metadata_only.sql
--
-- Checklist: docs/migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md Parts B, E
-- =============================================================================

USE DATABASE TRANSFORM;

DESCRIBE TABLE CENSUS.ACS5;

DESCRIBE TABLE LODES.OD_BG;
