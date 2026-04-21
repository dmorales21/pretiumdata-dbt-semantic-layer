-- =============================================================================
-- Operator: copy ZIP ↔ H3 R8 polyfill into canonical REFERENCE.GEOGRAPHY
--
-- Use when dbt defaults (`h3_polyfill_bridge_database` = REFERENCE,
-- `h3_polyfill_bridge_schema` = GEOGRAPHY) fail with **42S02** on
-- `REFERENCE.GEOGRAPHY.BRIDGE_ZIP_H3_R8_POLYFILL` but a mirror already exists under
-- **ANALYTICS.REFERENCE** (common in Pretium accounts).
--
-- After this, prefer keeping the canonical copy in REFERENCE.GEOGRAPHY so corridor
-- models do not need dbt var overrides. Heavy rebuild from ZCTA polygons instead:
-- pretium-ai-dbt `scripts/sql/analytics/h3_polyfill_load_wh/05_bridge_zip_h3_r8_polyfill.sql`.
-- =============================================================================

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.BRIDGE_ZIP_H3_R8_POLYFILL
  CLUSTER BY (ZIP_CODE)
  AS
SELECT * FROM ANALYTICS.REFERENCE.BRIDGE_ZIP_H3_R8_POLYFILL;

-- Match grants on sibling REFERENCE.GEOGRAPHY tables (e.g. ZCTA).
GRANT SELECT ON TABLE REFERENCE.GEOGRAPHY.BRIDGE_ZIP_H3_R8_POLYFILL TO ROLE STRATA_ADMIN_APP;
