# Engineer onboarding — semantic-layer surge

**Goal:** Land in this repo in under a day with the correct **contracts** and **ownership** in mind.

## 1. What this repo is

**pretiumdata-dbt-semantic-layer** is the **canonical dbt** home for:

- **`TRANSFORM.DEV`** — typed **`FACT_*`**, **`CONCEPT_*`**, vendor **`REF_*`** (until promoted to Jon’s **`TRANSFORM.[VENDOR]`**).
- **`REFERENCE.CATALOG` / `REFERENCE.DRAFT` / `REFERENCE.GEOGRAPHY`** — governed vocabulary and geography spine (see [`REFERENCE_AND_AI.md`](./REFERENCE_AND_AI.md)).
- **`ANALYTICS.DBT_*`** — **`FEATURE_*`**, **`MODEL_*`**, **`ESTIMATE_*`** (and **`QA_*`** on STAGE), **not** facts or concepts.
- **`SERVING.DEMO`** — dev delivery views (thin contract; see [`../reference/SERVING_DEMO_ICEBERG_TARGETS.md`](../reference/SERVING_DEMO_ICEBERG_TARGETS.md)).

**pretium-ai-dbt** remains a **migration source** (SnowSQL, some ingest, legacy patterns) until retired. Closure for migration work is **here**, not only in the sibling repo — see [`../migration/CANONICAL_COMPLETION_DEFINITION.md`](../migration/CANONICAL_COMPLETION_DEFINITION.md).

## 2. Non-negotiables (read once, cite often)

1. **Semantics over shortcuts:** governed CSVs (`seeds/reference/catalog/*.csv`) must be **literally correct** (codes, grains, joins), not “close enough.” See repo rule **semantics-over-generic-process**.
2. **No legacy PROD DBs in this dbt graph:** no reads of **`TRANSFORM_PROD`**, **`ANALYTICS_PROD`**, **`EDW_PROD`** from `models/` / `macros/` / `tests/` (CI-enforced; see [`../migration/MIGRATION_RULES.md`](../migration/MIGRATION_RULES.md)).
3. **Prefix placement:** **`FACT_*` / `CONCEPT_*`** only in **`TRANSFORM.DEV`**. **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** only in **`ANALYTICS.DBT_*`**. See [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md).
4. **Catalog tokens before object names:** every `[concept]`, `[geo_level]`, `[frequency]`, … token in a new object name needs an **active** **`REFERENCE.CATALOG`** row first ([`../rules/SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md)).

## 3. Day-zero setup

From repo root (see also root [`README.md`](../../README.md)):

```bash
python -m venv .venv && source .venv/bin/activate
pip install dbt-snowflake sqlfluff
dbt deps
```

Profiles: use your org’s Snowflake profile; for CI-style parse-only work, read the comments in **`ci/profiles.yml`** (parse vs `ci` target).

Validate:

```bash
dbt debug --target dev   # or your Snowflake target
dbt parse
```

Catalog work:

```bash
# Follow wave order strictly
cat docs/CATALOG_SEED_ORDER.md
```

## 4. Where to work by task type

| You are… | Start in… | Also read… |
|----------|-----------|------------|
| Porting / building vendor facts | `models/transform/dev/{vendor}/` | Vendor checklist in `docs/migration/MIGRATION_TASKS_*.md` |
| Unifying market signals | `models/transform/dev/concept/` | [`../migration/MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md`](../migration/MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md) |
| Analytics / scores / forecasts | `models/analytics/feature|model|estimate/` | [`../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`](../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) |
| Registering metrics | `seeds/reference/catalog/metric.csv` | [`../migration/METRIC_INTAKE_CHECKLIST.md`](../migration/METRIC_INTAKE_CHECKLIST.md) |
| QA / gates | `models/analytics/qa/`, `tests/` | [`../migration/QA_GOVERNANCE_TEST_TYPES.md`](../migration/QA_GOVERNANCE_TEST_TYPES.md) |

## 5. Logging and “done”

- Append **batch history** and model moves to [`../migration/MIGRATION_LOG.md`](../migration/MIGRATION_LOG.md) / [`../migration/MIGRATION_BATCH_INDEX.md`](../migration/MIGRATION_BATCH_INDEX.md) per field guide in the log header.
- Update **`T-*`** rows in [`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md) when disposition changes.

## 6. Who to ask

- **Alex-owned** graph targets and **REFERENCE** seeds: Alex (per [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md)).
- **Vendor PROD cleanse** promotion, **`TRANSFORM.[VENDOR]`** tables, **`SOURCE_PROD` → TRANSFORM.[VENDOR]`** pipeline: **Jon** — see [`JON_PROD_HANDOFF_ROADMAP.md`](./JON_PROD_HANDOFF_ROADMAP.md).
