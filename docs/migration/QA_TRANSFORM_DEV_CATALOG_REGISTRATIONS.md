# QA — `TRANSFORM.DEV` objects registered in `REFERENCE.CATALOG`

**Owner:** Alex  
**Repo (source of truth):** `pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/`

## What this covers

Active **`REFERENCE.CATALOG.METRIC`** rows whose **`table_path`** points at **`TRANSFORM.DEV.*`** (typed **`FACT_*`**, **`CONCEPT_*`**, **`REF_*`**, and other dev relations named in the catalog). The script checks:

1. **`table_path`** parses as **`TRANSFORM.DEV.<OBJECT>`** (three-part FQN).
2. The relation **exists** in Snowflake (`INFORMATION_SCHEMA.TABLES` in **`TRANSFORM` / `DEV`**).
3. **`snowflake_column`** (when non-blank) **exists** on that relation (`INFORMATION_SCHEMA.COLUMNS`).
4. A **detail listing** of missing objects and affected **`metric_code`** values (for remediation).

## What this is not

- **`ANALYTICS.DBT_STAGE.QA_*`** tables are the **promotion gate** (0 **ERROR** rows before **`DBT_PROD`** writes per **`SCHEMA_RULES.md`** / **`README.md`**). They are **not** stored under `TRANSFORM.DEV` and are not the subject of `qa_transform_dev_catalog_metric_table_paths.sql`.
- This script does **not** substitute **`dbt test`** on individual models; it validates **catalog registration ↔ Snowflake** after seeds and builds are in place.
- It does **not** cover **`metric_derived`** or **CONCEPT/FEATURE/MODEL** tables — see [QA_METRIC_LAYER_VALIDATION.md](./QA_METRIC_LAYER_VALIDATION.md) for the full stack.

## How to run

### Troubleshooting `DETAIL:missing_TRANSFORM_DEV_object`

1. **Wrong `INFORMATION_SCHEMA` database (common false positive):** The Snowflake script must read **`TRANSFORM.INFORMATION_SCHEMA.TABLES`** / **`.COLUMNS`**, not unqualified `information_schema.*` while your session **`database`** is **`REFERENCE`** or **`ANALYTICS`** (those catalogs only list tables in the *current* database, so every **`TRANSFORM.DEV.*`** path looks missing). Re-run with the updated script in this repo.
2. **Objects truly not built:** After fixing (1), if rows remain, materialize the dbt models that land on **`TRANSFORM.DEV`** — for the catalog-backed core surface use:
   `dbt run --selector catalog_metric_transform_dev_surface`  
   (see **`selectors.yml`**). Vendor stacks (FHFA, HUD, IRS, BLS, BPS, LODES, O*NET, Pretium Epoch) may need sources and parent facts built first per their migration docs.
3. **Row-level QA table:** `dbt run --select qa_catalog_metric_transform_dev_lineage` materializes **`TRANSFORM.DEV.QA_CATALOG_METRIC_TRANSFORM_DEV_LINEAGE`** for dashboards (`qa_status`).

From the **inner** project root (directory containing `dbt_project.yml`):

1. Ensure **`REFERENCE.CATALOG.METRIC`** (and dependencies) are loaded:  
   `dbt seed --select path:seeds/reference/catalog` (use your real Snowflake target; see **`ci/profiles.yml`** / `RUN_SNOWFLAKE_CHECKS` in **`scripts/ci/run_catalog_quality_checks.sh`**).
2. Seed the **draft** harmonized boundary parquet manifest (tract / ZCTA file list used for stage QA):  
   `dbt seed --select qa_tract_zcta_harmonized_parquet_manifest`
3. Run dimensional catalog checks if desired:  
   `scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`
4. Run this QA script (role must **see** `TRANSFORM.INFORMATION_SCHEMA` and **`TRANSFORM.DEV`**):  
   `scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql`  
   **Coverage / gaps (row counts + unregistered `FACT_*`/`CONCEPT_*`/`REF_*`):**  
   `scripts/sql/validation/catalog_metric_registration_coverage.sql`
5. **Materialized `TRANSFORM.DEV` QA table (dbt):** refresh row-level catalog ↔ object alignment for dashboards and joins:  
   `dbt run --select qa_catalog_metric_transform_dev_lineage`  
   Physical name follows Snowflake default uppercasing: **`TRANSFORM.DEV.QA_CATALOG_METRIC_TRANSFORM_DEV_LINEAGE`**. Filter `WHERE qa_status <> 'OK'` for the same failures as summary checks 1–3 in the Snowflake script.

**Pass criteria:** checks **1–3** each report **`failure_rows = 0`**. Use block **4** only when check **2** fails, to see which **`table_path`** values to fix or which dbt models to build. For the dbt QA table, **`qa_status = 'OK'`** on all active **`TRANSFORM.DEV`** metric rows.

### Harmonized tract / ZCTA parquet (operator inventory)

Expected file names and approximate sizes are versioned in **`seeds/reference/draft/qa_tract_zcta_harmonized_parquet_manifest.csv`** (REFERENCE.DRAFT after seed). Stage / landing QA: **`scripts/sql/validation/qa_boundary_parquet_stage_list_template.sql`** — align with **`docs/rules/SCHEMA_RULES.md`** (landed geo vendor files → **`SOURCE_PROD` / `RAW`**, not **`TRANSFORM.DEV`** raw blobs; **`TRANSFORM.DEV.QA_*`** holds **check results** and curated QA manifests referenced from this doc).

## Related rules

- **`docs/rules/SCHEMA_RULES.md`** — matrix, enforcement, **`QA_*`** in **`ANALYTICS.DBT_STAGE`**.
- **`docs/migration/MIGRATION_RULES.md`** — build order, no legacy `*_PROD` in the dbt graph.
- **`docs/rules/NAMING_RULES_INDEX.md`** — links naming authority and migration §7 vs full matrix.
