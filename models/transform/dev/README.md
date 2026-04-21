# `models/transform/dev` — TRANSFORM.DEV facts (canonical)

**Rules of the road:** repository **`docs/`** — start at [docs/README.md](../../docs/README.md) (migration rules, operating model, schema rules).

This folder holds **dbt models** that compile to **`TRANSFORM.DEV`** (and related dev targets per `dbt_project.yml`). Examples:

- **`zillow/`** — `FACT_ZILLOW_*` long facts from Zillow research parquet.
- **`bps/`** — `FACT_BPS_PERMITS_COUNTY` view over **`TRANSFORM.BPS.PERMITS_COUNTY`** (Jon silver; CBSA grain).
- **`bls/`** — `FACT_BLS_LAUS_COUNTY` view over **`TRANSFORM.BLS.LAUS_COUNTY`** (county LAUS; preferred base for CBSA rollups).
- **`lodes/`** — `FACT_LODES_OD_BG` view over **`TRANSFORM.LODES.OD_BG`** (block OD; ~64M rows — view only).
- **`hud/`** — **`FACT_HUD_HOUSING_SERIES`** (all grains) plus **`FACT_HUD_HOUSING_SERIES_COUNTY`** / **`FACT_HUD_HOUSING_SERIES_CBSA`** over **`GLOBAL_GOVERNMENT.CYBERSYN.HOUSING_URBAN_DEVELOPMENT_*`** (Cybersyn HUD-aligned long series + REFERENCE.GEOGRAPHY join).
- **`irs/`** — **`FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL`** (+ **`_COUNTY`** / **`_CBSA`** slices) and **`FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY`** / **`_ANNUAL_CBSA`** over **`SOURCE_SNOW.US_REAL_ESTATE.IRS_*`** (Cybersyn IRS SOI migration; not `GLOBAL_GOVERNMENT.CYBERSYN` on typical accounts).
- **`oxford/`** — `REF_OXFORD_METRO_CBSA` (table from **`TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK`**), **`FACT_OXFORD_AMREG_QUARTERLY`**, **`FACT_OXFORD_WDMARCO_QUARTERLY`** from **`SOURCE_ENTITY.PRETIUM`** (`MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md`).
- **`fhfa/`** — **`FACT_FHFA_HOUSE_PRICE`** (+ **`_COUNTY`** / **`_CBSA`**), **`FACT_FHFA_MORTGAGE_PERFORMANCE`** (+ slices), **`FACT_FHFA_UNIFORM_APPRAISAL`** (+ slices) over **`SOURCE_SNOW.US_REAL_ESTATE`** FHFA Cybersyn tables (not `GLOBAL_GOVERNMENT.CYBERSYN` on typical accounts).
- **`freddie_mac/`** — **`FACT_FREDDIE_MAC_HOUSING_NATIONAL_WEEKLY`** over **`SOURCE_SNOW.US_REAL_ESTATE.FREDDIE_MAC_HOUSING_*`**.
- **`cherre/`** — passthrough views (`CHERRE_*`) over **`TRANSFORM.CHERRE`** Dynamic Tables / tables (`source('cherre_transform', …)`); Jon-owned silver — dbt read surface only.
- **`fund_opco/`** — **`FACT_PROGRESS_YARDI_PROPERTY`**, **`FACT_BH_YARDI_PROPERTY`**, **`FACT_*_YARDI_UNIT`**, **`FACT_PROGRESS_YARDI_LEDGER`**, **`FACT_BH_YARDI_LEDGER`** over **`source('transform_yardi', …)`** (silver) and legacy **`yardi_bh.TRANS`** for BH ledger when **`yardi_bh_available`**; see folder **`README.md`** and **`MIGRATION_TASKS_YARDI_BH_PROGRESS.md`**.
- **`catalog_qa/`** — **`QA_CATALOG_METRIC_TRANSFORM_DEV_LINEAGE`**: materialized **`TRANSFORM.DEV`** checks that **`REFERENCE.CATALOG.METRIC`** `table_path` / `snowflake_column` align with **`TRANSFORM.INFORMATION_SCHEMA`** (see **`docs/migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md`**).

Add new vendor folders here when cutting over from pretium-ai-dbt; pair each with:

1. A checklist under **`docs/migration/MIGRATION_TASKS_*.md`**
2. An inventory workbook under **`scripts/sql/migration/inventory_*_for_dev_facts.sql`** (or the shared BPS/Census/BLS/LODES script)
3. Rows in **`docs/migration/MIGRATION_TASKS.md`** until status is **migrated**
