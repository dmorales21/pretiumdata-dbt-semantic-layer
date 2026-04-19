# SQL validation scripts (`scripts/sql/validation/`)

**Purpose:** Snowflake-runnable checks referenced from [PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../../docs/migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) §E / §H. Each script documents **pass criteria** (expected `failure_rows` or tolerance).

| Script | Pass criteria | Notes |
|--------|----------------|-------|
| [dimensional_reference_catalog_and_geography.sql](./dimensional_reference_catalog_and_geography.sql) | `failure_rows = 0` for each catalog FK-style check; `GEOGRAPHY_INDEX` `unmapped` count is a **backlog signal**, not a hard catalog failure | Run after catalog seed changes |
| [feature_rent_market_spine_vs_concept_reconciliation.sql](./feature_rent_market_spine_vs_concept_reconciliation.sql) | **Tolerance T = 0:** `abs_delta = 0` on row counts; `failure_rows = 0` on key overlap check | **Pilot A** (Q); edit `MART_DEV` / `ANALYTICS` literals for your env |

**Adding a script:** append a row here + a subsection in the playbook with tolerance **T** and owner.

**Repo gates:** PR workflow **`.github/workflows/semantic_layer_catalog_and_quality.yml`** (parse + catalog `dbt ls`). After catalog edits, also run **`scripts/ci/run_catalog_quality_checks.sh`** locally with **`RUN_SNOWFLAKE_CHECKS=1`** when credentials are available.
