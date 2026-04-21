# Operating model — repos and Snowflake layers

**Owner:** Alex  
**Status:** index (authoritative detail lives in linked rules).

## Repositories

| Repo | Role |
|------|------|
| **pretiumdata-dbt-semantic-layer** | Canonical **dbt** for **`TRANSFORM.DEV`** `FACT_*` / `CONCEPT_*`, **`ANALYTICS.DBT_*`**, **`REFERENCE.CATALOG` / `REFERENCE.AI`**, **`SERVING.DEMO`** per [`rules/SCHEMA_RULES.md`](./rules/SCHEMA_RULES.md) (Alex rows). |
| **pretium-ai-dbt** | Migration **source**, SnowSQL/runbooks, and **`SOURCE_PROD`** ingest until objects are ported or retired. **Closure** for `T-*` tasks is **not** pretium-ai-dbt alone — see [migration/CANONICAL_COMPLETION_DEFINITION.md](./migration/CANONICAL_COMPLETION_DEFINITION.md). |

## Snowflake ownership (summary)

- **Jon:** **`TRANSFORM.[VENDOR]`** PROD vendor canonical layer — Alex **reads**, does not author dbt writes there.
- **Alex:** **`TRANSFORM.DEV`** facts/concepts/ref, **`REFERENCE.CATALOG`** / **`REFERENCE.AI`** / **`REFERENCE.DRAFT`**, **`ANALYTICS.DBT_DEV` / `DBT_STAGE` / `DBT_PROD`** (Alex-owned prefixes), **`SERVING.DEMO`**, **`SOURCE_PROD` landed DEV** registration — full matrix in [`rules/SCHEMA_RULES.md`](./rules/SCHEMA_RULES.md) § **Alex — responsibilities**.

## Binding rules

- [rules/ARCHITECTURE_RULES.md](./rules/ARCHITECTURE_RULES.md) — layer split, geography vs vendor xwalks, metric gates.
- [migration/MIGRATION_RULES.md](./migration/MIGRATION_RULES.md) — migration sequence, **no `*_PROD` DB in semantic-layer dbt graph**.
