# Migration artifacts (dated exports)

## Why `snowsql` fails with `Errno 2: No such file or directory`

The git repo has **two** directories named `pretiumdata-dbt-semantic-layer` (parent clone folder + inner dbt project). The SQL files live in the **inner** one.

| Your shell prompt / `pwd` | Use this `-f` argument |
|---------------------------|-------------------------|
| **Outer** clone (you see `pretiumdata-dbt-semantic-layer` and *inside* it another `pretiumdata-dbt-semantic-layer/` with `dbt_project.yml`) | `pretiumdata-dbt-semantic-layer/scripts/sql/migration/<script>.sql` |
| **Inner** dbt project (same folder that contains `dbt_project.yml`) | `scripts/sql/migration/<script>.sql` — **do not** prefix another `pretiumdata-dbt-semantic-layer/` |

If you run `-f pretiumdata-dbt-semantic-layer/scripts/...` **from the inner project**, Snowflake looks for a **non-existent** nested path and returns Errno 2. Fix: `cd` up or down once, or pass an **absolute** path.

---

Store **dated** CSV or worksheet exports here (e.g. `2026-04-20_apartmentiq_yardi_inventory_A.csv`) from:

- `scripts/sql/migration/inventory_apartmentiq_yardi_matrix_for_dev_facts.sql`
- `scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql`
- `scripts/sql/migration/inventory_costar_for_dev_facts.sql`
- `scripts/sql/migration/inventory_first_street_rca_for_dev_facts.sql`
- `scripts/sql/migration/inventory_stanford_redfin_for_dev_facts.sql`
- `scripts/sql/migration/inventory_transform_bps_census_bls_lodes.sql`
- `scripts/sql/migration/inventory_transform_bps_census_bls_lodes_phase1_fast.sql` (cheap counts + metadata; use before full workbook)
- `scripts/sql/migration/inventory_transform_acs5_lodes_metadata_only.sql` (`DESCRIBE` **ACS5** + **OD_BG** only — no table scans)
- `scripts/sql/migration/inventory_corridor_pipeline_critical.sql`
- `scripts/sql/migration/inventory_zillow_source_prod_raw.sql`

Example column inventories: `2026-04-19_batch003_bps_permits_county_describe.csv` (`TRANSFORM.BPS.PERMITS_COUNTY`); `2026-04-19_batch004_bls_laus_county_describe.csv` (`TRANSFORM.BLS.LAUS_COUNTY`); `2026-04-19_batch005_acs5_describe.csv` (`TRANSFORM.CENSUS.ACS5`); `2026-04-19_batch005_lodes_od_bg_describe.csv` (`TRANSFORM.LODES.OD_BG`).

Link each batch from **`MIGRATION_LOG.md`** (short row) and **`MIGRATION_BATCH_INDEX.md`** (verbose notes + dated files here); check off **§1.5** deliverables in `MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`, `MIGRATION_TASKS_YARDI_BH_PROGRESS.md`, `MIGRATION_TASKS_COSTAR.md`, `MIGRATION_TASKS_FIRST_STREET_RCA.md`, `MIGRATION_TASKS_STANFORD_REDFIN.md`, `MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md`, `MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md`, `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`, or `MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md` as applicable.

**Vendor → catalog index:** [../CATALOG_NEEDS_VENDOR_INVENTORY_INDEX.md](../CATALOG_NEEDS_VENDOR_INVENTORY_INDEX.md)

**Catalog / CI quality evidence:** [2026-04-19_semantic_layer_quality_gate_results.md](./2026-04-19_semantic_layer_quality_gate_results.md) (batch 021 — `dbt test` on `path:seeds/reference/catalog` + dimensional SQL).
