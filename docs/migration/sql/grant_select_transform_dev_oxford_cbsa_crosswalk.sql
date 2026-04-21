-- =============================================================================
-- Optional grant after `land_oxford_cbsa_crosswalk_transform_dev.sql`
-- Aligns with REFERENCE.GEOGRAPHY.ZCTA pattern (SELECT for STRATA_ADMIN_APP).
-- Adjust ROLE name if your consumer role differs.
-- =============================================================================

GRANT SELECT ON TABLE TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK TO ROLE STRATA_ADMIN_APP;
