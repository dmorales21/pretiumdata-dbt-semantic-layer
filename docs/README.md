# Documentation — rules of the road (pretiumdata-dbt-semantic-layer)

This **`docs/`** tree is the **canonical** place for migration governance, operating model, and schema/architecture rules. **Do not** maintain parallel migration playbooks inside **pretium-ai-dbt**; link here from the legacy repo.

**Completion rule:** migration or product work counts as **done** only after it lands here — see [migration/CANONICAL_COMPLETION_DEFINITION.md](./migration/CANONICAL_COMPLETION_DEFINITION.md). **pretium-ai-dbt** alone is never the closure surface for **`T-*`** tasks.

## Start here

| Topic | Path |
|-------|------|
| **Operating model** (who owns what, repo split) | [OPERATING_MODEL.md](./OPERATING_MODEL.md) |
| **Migration rules** (checklists, logging, cutover; **no `*_PROD` DB in dbt graph**) | [migration/MIGRATION_RULES.md](./migration/MIGRATION_RULES.md) — CI: [`scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh`](../scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh) |
| **Migration task register** | [migration/MIGRATION_TASKS.md](./migration/MIGRATION_TASKS.md) |
| **Schema alignment plan** (PITI / place / Deephaven / concept vs catalog — tasks by ✅ / 🟨 / ⬜) | [migration/SCHEMA_ALIGNMENT_PLAN.md](./migration/SCHEMA_ALIGNMENT_PLAN.md) |
| **Fact systemization playbook** (`FACT_*` waves + per-model checklist) | [migration/MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md](./migration/MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md) |
| **Model stack — features, estimation, data prep, labor/automation risk** (consolidated) | [migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md](./migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) |
| **Labor / automation risk — semantic-layer `TRANSFORM.DEV` objects + vendor ref** | [migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md](./migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md) |
| **Progress disposition facts on `TRANSFORM.DEV` (42S02 vs OpCo), build + gate** | [migration/TRANSFORM_DEV_DISPOSITION_PROGRESS_SNOWSQL_DIAGNOSTIC.md](./migration/TRANSFORM_DEV_DISPOSITION_PROGRESS_SNOWSQL_DIAGNOSTIC.md) — dbt: **`models/transform/dev/progress_crm/`** |
| **Vendors / datasets / metrics registry (rollup)** | [migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md](./migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md) |
| **Baseline RAW vs TRANSFORM** | [migration/MIGRATION_BASELINE_RAW_TRANSFORM.md](./migration/MIGRATION_BASELINE_RAW_TRANSFORM.md) |
| **Migration log** (append-only audit — short batch rows) | [migration/MIGRATION_LOG.md](./migration/MIGRATION_LOG.md) |
| **Migration batch index** (verbose batch narratives + artifacts) | [migration/MIGRATION_BATCH_INDEX.md](./migration/MIGRATION_BATCH_INDEX.md) |
| **Layer 2 FEATURE backlog vs `MIGRATION_PLAN`** (priorities + blockers) | [migration/MIGRATION_LAYER2_EXECUTION_TRACKER.md](./migration/MIGRATION_LAYER2_EXECUTION_TRACKER.md) |
| **New metric intake** (REFERENCE.CATALOG checklist) | [migration/METRIC_INTAKE_CHECKLIST.md](./migration/METRIC_INTAKE_CHECKLIST.md) |
| **`metric.csv` SoT + vendor-by-vendor catalog intake** | [migration/MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md](./migration/MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md) |
| **Analytics features from catalog** (FACT→CONCEPT→FEATURE, four chains, Pilot A, CI) | [migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](./migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) |
| **`SIGNALS` / `MODELS` catalog (design-only)** | [reference/CATALOG_SIGNALS_LAYOUT.md](./reference/CATALOG_SIGNALS_LAYOUT.md), [reference/CATALOG_MODELS_LAYOUT.md](./reference/CATALOG_MODELS_LAYOUT.md) |
| **`catalog_wishlist`** (REFERENCE.CATALOG backlog / blocked items) | [reference/CATALOG_WISHLIST.md](./reference/CATALOG_WISHLIST.md) |
| **Wishlist → data/model priorities** (WL_020 / 047 / 048 first; tiers 0–5) | [reference/CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md](./reference/CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md) |
| **Duck Lake + catalog — P0 inventory & share targets** | [reference/DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md](./reference/DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md) |
| **`SERVING.DEMO` — Iceberg/Parquet targets & gaps (Alex rows 81–83)** | [reference/SERVING_DEMO_ICEBERG_TARGETS.md](./reference/SERVING_DEMO_ICEBERG_TARGETS.md) |
| **Snowflake → Iceberg / Parquet export — DuckDB pushdown best practices** (`SERVING.DEMO`, `SERVING.ICEBERG`) | [reference/SNOWFLAKE_ICEBERG_EXPORT_DUCKDB_BEST_PRACTICES.md](./reference/SNOWFLAKE_ICEBERG_EXPORT_DUCKDB_BEST_PRACTICES.md) |
| **Auto-refresh by content type** (Tasks, gates, portfolio/market chains, catalog/geo) | [reference/AUTO_REFRESH_STRATEGY_BY_CONTENT_TYPE.md](./reference/AUTO_REFRESH_STRATEGY_BY_CONTENT_TYPE.md) |
| **When is work “done”?** (canonical repo only) | [migration/CANONICAL_COMPLETION_DEFINITION.md](./migration/CANONICAL_COMPLETION_DEFINITION.md) |
| **PR CI — parse + catalog smoke** | [`.github/workflows/semantic_layer_catalog_and_quality.yml`](../.github/workflows/semantic_layer_catalog_and_quality.yml); local: [`scripts/ci/run_catalog_quality_checks.sh`](../scripts/ci/run_catalog_quality_checks.sh) |
| **Concept methods — FACT-only prioritized backlog** | [migration/MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md](./migration/MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md) |
| **Migration status rollup** (verified snapshot for agents) | [migration/MIGRATION_STATUS_AGENT_ROLLUP.md](./migration/MIGRATION_STATUS_AGENT_ROLLUP.md) |
| **Catalog seed order** (REFERENCE.CATALOG) | [CATALOG_SEED_ORDER.md](./CATALOG_SEED_ORDER.md) |
| **ENUM consolidation — dbt refs & tests** (audit before local-only enums) | [migration/ENUM_CONSOLIDATION_DBT_REFS.md](./migration/ENUM_CONSOLIDATION_DBT_REFS.md) |
| **Concepts by domain** (registry mirror of `concept.domain`) | [reference/concepts_by_domain.csv](./reference/concepts_by_domain.csv) |
| **CONCEPT mart — mathematical features** (analytics-engine parity) | [reference/CONCEPT_MART_MATHEMATICAL_FEATURES.md](./reference/CONCEPT_MART_MATHEMATICAL_FEATURES.md) |
| **Concept prose style contract** | [reference/CONCEPT_TEXT_STYLE_GUIDE.md](./reference/CONCEPT_TEXT_STYLE_GUIDE.md) |
| **`metric_derived`** (FEATURE / MODEL / ESTIMATE registry) | [reference/CATALOG_METRIC_DERIVED_LAYOUT.md](./reference/CATALOG_METRIC_DERIVED_LAYOUT.md) |
| **SERVING.DEMO gap migration (T0–T4 plan)** | [migration/SERVING_METRICS_GAP_MIGRATION_PLAN.md](./migration/SERVING_METRICS_GAP_MIGRATION_PLAN.md) |
| **Vendor × concept coverage + `source_schema` vet** | [migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md](./migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) |
| **Vendor context hub (per-vendor methodology + dictionaries)** | [vendor/vendors.md](./vendor/vendors.md) — [`vendor/0_inventory/`](./vendor/0_inventory/) + `vendor/{vendor_code}/` |
| **Catalog-only vendors — SnowSQL vet (FBI/FDIC/NOAA/…)** | [migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md](./migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md) |
| **Pipeline status** | [PIPELINE_STATUS.md](./PIPELINE_STATUS.md) |
| **Cybersyn bring-in matrix** (`CYBERSYN_DATA_CATALOG` + catalog validation) | [reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md](./reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md) |
| **Cybersyn migration tasks** (checklist + `T-CYBERSYN-GLOBAL-GOVERNMENT-READY`) | [migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md](./migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md) |
| **QA — `TRANSFORM.DEV` objects registered in `REFERENCE.CATALOG.METRIC`** (Snowflake script + dbt `qa_catalog_metric_transform_dev_lineage`; distinct from `ANALYTICS.DBT_STAGE.QA_*`) | [migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md](./migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md) |
| **Cybersyn catalog → vendor map** (seed + `dbt test`, one row per `table_name`) | [reference/catalog/cybersyn_catalog_table_vendor_map.csv](../seeds/reference/catalog/cybersyn_catalog_table_vendor_map.csv) — regenerate: `scripts/reference/catalog/regenerate_cybersyn_catalog_table_vendor_map.py` |
| **Cherre migration + hope-list (market vs deal)** | [migration/MIGRATION_TASKS_CHERRE.md](./migration/MIGRATION_TASKS_CHERRE.md) — `T-VENDOR-CHERRE-READY`; smoke `scripts/sql/migration/inventory_cherre_transform_smoke.sql` |

## Guides (short references)

| Topic | Path |
|-------|------|
| **Data layers — question each stage answers** (Ingest→…→Decide; Pretium DB/dbt anchors) | [guides/DATA_LAYER_QUESTIONS_BY_PIPELINE_STAGE.md](./guides/DATA_LAYER_QUESTIONS_BY_PIPELINE_STAGE.md) — index: [guides/README.md](./guides/README.md) |

## Rules (non-migration)

| Topic | Path |
|-------|------|
| **Naming — index** (links SCHEMA_RULES, MIGRATION §4/§7, lineage) | [rules/NAMING_RULES_INDEX.md](./rules/NAMING_RULES_INDEX.md) |
| Architecture | [rules/ARCHITECTURE_RULES.md](./rules/ARCHITECTURE_RULES.md) |
| Schema conventions | [rules/SCHEMA_RULES.md](./rules/SCHEMA_RULES.md) |
| Transform vendor design | [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](./rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md) |

## `TRANSFORM.DEV` dbt models

Canonical **fact** implementations that land in **`TRANSFORM.DEV`** are authored under **`models/transform/dev/`** (for example `models/transform/dev/zillow/`, **`models/transform/dev/progress_crm/`** for **FACT_PROGRESS_DISPOSITION** and **FACT_PROGRESS_DISPOSITION_LATEST**). Inventory SQL and migration task docs under **`docs/migration/`** describe how each vendor cluster is validated before cutover.

**Zillow for-sale ZIP × month (inventory + Parcl-shaped absorption + governed signal slice):** the four **`FACT_*`** models that read **`source('zillow', 'zip_monthly_for_sale')`** (**`SOURCE_PROD.ZILLOW`**) are implemented today only in sibling **pretium-ai-dbt** (`dbt/models/transform/dev/zillow/`). They are **not** yet in this repo’s `models/transform/dev/zillow/` tree (that folder is the **research** `raw_*` stack). See [migration/MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md](./migration/MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md) §1.6.

## `REFERENCE.GEOGRAPHY` dbt models

Canonical geography utilities (Cybersyn read path in **`models/sources/sources_global_government.yml`** — adjust if your account uses a different database/schema): **`models/reference/geography/`** — seed **`REFERENCE.CATALOG.geo_level`** (`seeds/reference/catalog/geo_level.csv`, including **`source_snow_cybersyn_level`** for Cybersyn `LEVEL`), table **`GEOGRAPHY_LEVEL_DICTIONARY`**, plus **`GEOGRAPHY_INDEX`**, **`GEOGRAPHY_CODES`**, **`GEOGRAPHY_SHAPES`**, **`GEOGRAPHY_RELATIONSHIPS`**, and the flattened **latest** join surface **`GEOGRAPHY_CURRENT`** (physical dbt relation today: **`GEOGRAPHY_LATEST`** until renamed). **Column contract:** **`models/reference/geography/schema.yml`**. Cybersyn **`LEVEL`** must map through **`GEOGRAPHY_LEVEL_DICTIONARY`** before broad joins; Snowflake tables named `*_pit` are **latest/as-of/history-grain** companions in **SOURCE_SNOW** — not “PIT” labels on **REFERENCE** outputs.

## Clone location

Absolute path on disk (Alex’s machine):  
`/Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/docs/`

When **pretium-ai-dbt** and this repo sit as sibling folders under `~/dev/pretium/`, use paths like `../pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/docs/migration/...` from the AI dbt repo root.
