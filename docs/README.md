# Documentation — rules of the road (pretiumdata-dbt-semantic-layer)

This **`docs/`** tree is the **canonical** place for migration governance, operating model, and schema/architecture rules. **Do not** maintain parallel migration playbooks inside **pretium-ai-dbt**; link here from the legacy repo.

**Completion rule:** migration or product work counts as **done** only after it lands here — see [migration/CANONICAL_COMPLETION_DEFINITION.md](./migration/CANONICAL_COMPLETION_DEFINITION.md). **pretium-ai-dbt** alone is never the closure surface for **`T-*`** tasks.

## Start here

| Topic | Path |
|-------|------|
| **Operating model** (who owns what, repo split) | [OPERATING_MODEL.md](./OPERATING_MODEL.md) |
| **Migration rules** (checklists, logging, cutover) | [migration/MIGRATION_RULES.md](./migration/MIGRATION_RULES.md) |
| **Migration task register** | [migration/MIGRATION_TASKS.md](./migration/MIGRATION_TASKS.md) |
| **Fact systemization playbook** (`FACT_*` waves + per-model checklist) | [migration/MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md](./migration/MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md) |
| **Model stack — features, estimation, data prep, labor/automation risk** (consolidated) | [migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md](./migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) |
| **Vendors / datasets / metrics registry (rollup)** | [migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md](./migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md) |
| **Baseline RAW vs TRANSFORM** | [migration/MIGRATION_BASELINE_RAW_TRANSFORM.md](./migration/MIGRATION_BASELINE_RAW_TRANSFORM.md) |
| **Migration log** (append-only audit — short batch rows) | [migration/MIGRATION_LOG.md](./migration/MIGRATION_LOG.md) |
| **Migration batch index** (verbose batch narratives + artifacts) | [migration/MIGRATION_BATCH_INDEX.md](./migration/MIGRATION_BATCH_INDEX.md) |
| **New metric intake** (REFERENCE.CATALOG checklist) | [migration/METRIC_INTAKE_CHECKLIST.md](./migration/METRIC_INTAKE_CHECKLIST.md) |
| **Analytics features from catalog** (FACT→CONCEPT→FEATURE, four chains, Pilot A, CI) | [migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](./migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) |
| **`SIGNALS` / `MODELS` catalog (design-only)** | [reference/CATALOG_SIGNALS_LAYOUT.md](./reference/CATALOG_SIGNALS_LAYOUT.md), [reference/CATALOG_MODELS_LAYOUT.md](./reference/CATALOG_MODELS_LAYOUT.md) |
| **`catalog_wishlist`** (REFERENCE.CATALOG backlog / blocked items) | [reference/CATALOG_WISHLIST.md](./reference/CATALOG_WISHLIST.md) |
| **When is work “done”?** (canonical repo only) | [migration/CANONICAL_COMPLETION_DEFINITION.md](./migration/CANONICAL_COMPLETION_DEFINITION.md) |
| **PR CI — parse + catalog smoke** | [`.github/workflows/semantic_layer_catalog_and_quality.yml`](../.github/workflows/semantic_layer_catalog_and_quality.yml); local: [`scripts/ci/run_catalog_quality_checks.sh`](../scripts/ci/run_catalog_quality_checks.sh) |
| **Concept methods — FACT-only prioritized backlog** | [migration/MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md](./migration/MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md) |
| **Migration status rollup** (verified snapshot for agents) | [migration/MIGRATION_STATUS_AGENT_ROLLUP.md](./migration/MIGRATION_STATUS_AGENT_ROLLUP.md) |
| **Catalog seed order** (REFERENCE.CATALOG) | [CATALOG_SEED_ORDER.md](./CATALOG_SEED_ORDER.md) |
| **`metric_derived`** (FEATURE / MODEL / ESTIMATE registry) | [reference/CATALOG_METRIC_DERIVED_LAYOUT.md](./reference/CATALOG_METRIC_DERIVED_LAYOUT.md) |
| **`pretium_s3` / DuckLake + Claude** (share scope, cost framing vs Snowflake, Iceberg `SNOWFLAKE` vs `POLARIS`) | [reference/PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md](./reference/PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md) |
| **Vendor × concept coverage + `source_schema` vet** | [migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md](./migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) |
| **Catalog-only vendors — SnowSQL vet (FBI/FDIC/NOAA/…)** | [migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md](./migration/VENDOR_CATALOG_ONLY_SNOWSQL_VET.md) |
| **Pipeline status** | [PIPELINE_STATUS.md](./PIPELINE_STATUS.md) |
| **Cybersyn bring-in matrix** (`CYBERSYN_DATA_CATALOG` + catalog validation) | [reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md](./reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md) |
| **Cybersyn migration tasks** (checklist + `T-CYBERSYN-GLOBAL-GOVERNMENT-READY`) | [migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md](./migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md) |
| **Cybersyn catalog → vendor map** (seed + `dbt test`, one row per `table_name`) | [reference/catalog/cybersyn_catalog_table_vendor_map.csv](../seeds/reference/catalog/cybersyn_catalog_table_vendor_map.csv) — regenerate: `scripts/reference/catalog/regenerate_cybersyn_catalog_table_vendor_map.py` |
| **Cherre migration + hope-list (market vs deal)** | [migration/MIGRATION_TASKS_CHERRE.md](./migration/MIGRATION_TASKS_CHERRE.md) — `T-VENDOR-CHERRE-READY`; smoke `scripts/sql/migration/inventory_cherre_transform_smoke.sql` |

## Rules (non-migration)

| Topic | Path |
|-------|------|
| Architecture | [rules/ARCHITECTURE_RULES.md](./rules/ARCHITECTURE_RULES.md) |
| Schema conventions | [rules/SCHEMA_RULES.md](./rules/SCHEMA_RULES.md) |
| Transform vendor design | [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](./rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md) |

## `TRANSFORM.DEV` dbt models

Canonical **fact** implementations that land in **`TRANSFORM.DEV`** are authored under **`models/transform/dev/`** (for example `models/transform/dev/zillow/`). Inventory SQL and migration task docs under **`docs/migration/`** describe how each vendor cluster is validated before cutover.

## `REFERENCE.GEOGRAPHY` dbt models

Canonical geography utilities (Cybersyn read path in **`models/sources/sources_global_government.yml`** — adjust if your account uses a different database/schema): **`models/reference/geography/`** — seed **`REFERENCE.CATALOG.geo_level`** (`seeds/reference/catalog/geo_level.csv`, including **`source_snow_cybersyn_level`** for Cybersyn `LEVEL`), table **`GEOGRAPHY_LEVEL_DICTIONARY`**, plus **`GEOGRAPHY_INDEX`**, **`GEOGRAPHY_CODES`**, **`GEOGRAPHY_SHAPES`**, **`GEOGRAPHY_RELATIONSHIPS`**, and the flattened **latest** join surface **`GEOGRAPHY_CURRENT`** (physical dbt relation today: **`GEOGRAPHY_LATEST`** until renamed). **Column contract:** **`models/reference/geography/schema.yml`**. Cybersyn **`LEVEL`** must map through **`GEOGRAPHY_LEVEL_DICTIONARY`** before broad joins; Snowflake tables named `*_pit` are **latest/as-of/history-grain** companions in **SOURCE_SNOW** — not “PIT” labels on **REFERENCE** outputs.

## Clone location

Absolute path on disk (Alex’s machine):  
`/Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/docs/`

When **pretium-ai-dbt** and this repo sit as sibling folders under `~/dev/pretium/`, use paths like `../pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/docs/migration/...` from the AI dbt repo root.
