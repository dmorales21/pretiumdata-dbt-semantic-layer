# Catalog needs — vendor inventory index

**Repo:** pretiumdata-dbt-semantic-layer (this file).  
**Purpose:** Map **vendor / cluster** → **Snowflake inventory SQL** in this repo → **catalog follow-ups** (`seeds/reference/catalog/`, admin catalog seeds, `register_*.sql` in pretium-ai-dbt where registration still runs).

**Canonical task register:** [MIGRATION_TASKS.md](./MIGRATION_TASKS.md)

---

## Transform cluster: BPS, Census ACS, BLS LAUS, LODES

| Cluster | Inventory SQL (this repo) | Checklist | pretium-ai-dbt `sources.yml` |
|---------|---------------------------|-----------|-------------------------------|
| BPS + ACS + LAUS + LODES | `inventory_transform_bps_census_bls_lodes.sql` (full) · `inventory_transform_bps_census_bls_lodes_phase1_fast.sql` · **`inventory_transform_acs5_lodes_metadata_only.sql`** (`DESCRIBE` ACS5 + OD_BG only) | [MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md](./MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md) §1.5 | `transform_bps`, `bls_transform`, `transform_census`, `transform_lodes`, `lehd` banner |

**Catalog work:** Extend REFERENCE.CATALOG seeds and/or pretium-ai-dbt admin seeds for BPS metrics, ACS variable families, LAUS measures (prefer county-first), LODES OD segments — after inventory exit criteria pass.

---

## Inventory workbooks (this repo)

| Vendor / topic | Inventory SQL |
|----------------|---------------|
| CoStar MF market export | `scripts/sql/migration/inventory_costar_for_dev_facts.sql` |
| ApartmentIQ + Yardi Matrix | `scripts/sql/migration/inventory_apartmentiq_yardi_matrix_for_dev_facts.sql` |
| Stanford + Redfin | `scripts/sql/migration/inventory_stanford_redfin_for_dev_facts.sql` |
| First Street + RCA | `scripts/sql/migration/inventory_first_street_rca_for_dev_facts.sql` |
| Yardi BH / Progress | `scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql` |
| Corridor pipeline | `scripts/sql/migration/inventory_corridor_pipeline_critical.sql` |

---

## pretium-ai-dbt–only references (legacy until ported)

These stay in **pretium-ai-dbt** until models and registration move here:

| Vendor | Location in pretium-ai-dbt |
|--------|----------------------------|
| Zillow (SOURCE_PROD + research docs) | `docs/data_dictionaries/raw/zillow/zillow_metrics.md`, `dbt/seeds/admin/catalog/dim_dataset.csv`, `dim_metric_raw.csv` / `dim_metric_facts.csv` |
| ApartmentIQ validation | `scripts/validation/validate_apartmentsiq_source.sql` |
| Yardi Matrix datatype export | `scripts/sql/admin/catalog/export_yardi_matrix_datatype_catalog.sql` |
| Oxford ref materialize | `scripts/sql/source_entity/materialize_ref_oxford_metro_cbsa_dev.sql`, `docs/vendors/amreg/OXFORD_SOURCE_ENTITY_PROFILE_AND_CROSSWALK_JOIN.md` |
| Admin catalog registration scripts | `scripts/sql/admin/catalog/register_*.sql` |

---

## Suggested order for new REFERENCE.CATALOG rows

1. **Dataset** grain in `seeds/reference/catalog/dataset.csv`.
2. **Metric** rows in `seeds/reference/catalog/metric.csv`.
3. **DIM_METRIC** (or equivalent) via pretium-ai-dbt `register_*.sql` until registration is relocated.

---

*Hub: [docs/README.md](../README.md)*
