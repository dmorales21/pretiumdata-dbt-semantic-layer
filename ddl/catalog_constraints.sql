-- =============================================================================
-- REFERENCE.CATALOG — optional NOT NULL / PK / FK hardening (Snowflake DDL spec)
-- =============================================================================
-- **Do not** run from dbt post-hooks. A human with an appropriate role (e.g. SYSADMIN)
-- reviews and applies fragments in a controlled window after coordinating loads.
--
-- dbt **seeds** validate row-level contracts in CI; they do **not** change warehouse
-- nullability. Keeping DDL here avoids silent drift when `dbt seed --full-refresh`
-- reloads CSVs without re-applying constraints.
--
-- Runbook: add your org’s change ticket, backup, and apply in a transaction.
-- =============================================================================

-- Example pattern (commented — adjust identifiers to match physical REFERENCE.CATALOG):

-- alter table reference.catalog.concept modify column concept_code set not null;
-- alter table reference.catalog.metric modify column vendor_code set not null;

-- Add FKs only after verifying no orphan rows:

-- alter table reference.catalog.metric
--   add constraint fk_metric_concept foreign key (concept_code) references reference.catalog.concept (concept_code);

-- =============================================================================
-- End of spec stub — extend table-by-table with your platform DBA checklist.
-- =============================================================================
