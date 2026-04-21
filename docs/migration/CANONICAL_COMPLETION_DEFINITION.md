# Canonical completion — **pretiumdata-dbt-semantic-layer** only

**Owner:** Alex (migration governance)

## Rule

Work is **not** considered migrated, complete, or production-ready until it is **merged and owned** in the **pretiumdata-dbt-semantic-layer** dbt project (this repository’s `pretiumdata-dbt-semantic-layer/` tree — the Pretium semantic / five-target dbt home).

Edits in **pretium-ai-dbt** are **provisional** (parity smoke, corridor scripts, or historical reference). They **do not** close **`T-*`** tasks, **`MIGRATION_LOG`** batches, or catalog rows by themselves.

## What “done” requires

1. **Code:** dbt models, sources YAML, seeds, macros, and tests live under this repo with the layer contract in **`MIGRATION_RULES.md`** (`FACT_*` / `CONCEPT_*` → **`TRANSFORM.DEV`**; **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** → **`ANALYTICS.DBT_DEV`**; **`CONCEPT_*`** unions live under **`models/transform/dev/concept/`** per **`ARCHITECTURE_RULES.md`**).
2. **Governance:** **`MIGRATION_TASKS.md`** / task-specific docs updated; **`MIGRATION_LOG.md`** append when a batch closes.
3. **Catalog:** **`REFERENCE.CATALOG`** seeds here (`dataset`, `metric`, bridges) when the change is user-facing or metric-registered.

## Repo naming

“Pretium semantic” / “semantic layer” in conversation means **this** Git repository (**pretiumdata-dbt-semantic-layer**), not **pretium-ai-dbt**.
