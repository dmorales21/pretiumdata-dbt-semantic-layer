# pretiumdata-dbt-semantic-layer

Governed dbt repository for Pretium Partners' analytics and semantic layers.

## Scope

This repo owns three output layers:

| Layer | Database | Schema | Owner |
|---|---|---|---|
| Reference Catalog | `REFERENCE` | `CATALOG` | Alex |
| Reference Draft | `REFERENCE` | `DRAFT` | Alex |
| Analytics DEV | `ANALYTICS` | `DBT_DEV` | Alex |
| Analytics STAGE | `ANALYTICS` | `DBT_STAGE` | Alex |
| Analytics PROD | `ANALYTICS` | `DBT_PROD` | Alex |
| Semantic Mart | `MART_DEV/STAGING/PROD` | `SEMANTIC` | Alex + Spencer |

It does **not** own: RAW, SOURCE_ENTITY, TRANSFORM, SERVING. Those live in `pretium-ai-dbt`.

---

## Rules

All schema rules are defined in `docs/SCHEMA_RULES.md` — the canonical reference for object placement, naming, ownership, lineage, and retention across the entire warehouse. Every object built in this repo must conform to those rules.

Key constraints:
- Every `[concept]`, `[geo_level]`, `[frequency]`, `[function]`, `[model_type]`, `[estimate_type]`, `[business_team]`, `[opco]`, `[vertical]`, `[product_type]` token used in any object name must have an active row in `REFERENCE.CATALOG` before the object is created
- PROD objects never read from `TRANSFORM.DEV` or `SOURCE_PROD`
- `ANALYTICS.DBT_STAGE.QA_*` must have 0 ERROR rows before any `DBT_PROD` write
- `SERVING.DEMO` is dev-only — no PROD objects may read from it
- `data_status_code = blocked` → no downstream reads permitted

---

## Repository layout

```
pretiumdata-dbt-semantic-layer/
├── docs/
│   ├── SCHEMA_RULES.md          ← canonical warehouse rule table
│   ├── CATALOG_SEED_ORDER.md    ← wave order for dbt seed
│   ├── PROFILES_TEMPLATE.md     ← copy to ~/.dbt/profiles.yml
│   └── OPERATING_MODEL.md       ← Snowflake target summary
├── models/
│   ├── analytics/
│   │   ├── feature/             ← FEATURE_ prefix, view
│   │   ├── model/               ← MODEL_ prefix, view
│   │   ├── estimate/            ← ESTIMATE_ prefix, table
│   │   ├── bi/                  ← BI_ prefix, view
│   │   └── ai/                  ← AI_ prefix, table
│   ├── mart/
│   │   └── semantic/            ← entity/dim/bridge/registry/glossary/explain/retrieval
│   ├── intermediate/
│   │   └── semantic_prep/
│   └── sources/
├── seeds/
│   ├── reference/
│   │   ├── catalog/             ← 67 seed CSVs + 7 schema YMLs → REFERENCE.CATALOG
│   │   └── draft/               ← in-progress objects → REFERENCE.DRAFT
│   └── semantic/                ← semantic lookup seeds → MART_*.SEMANTIC
├── tests/
│   ├── generic/
│   └── singular/
├── macros/
├── dbt_project.yml
└── packages.yml
```

---

## Setup

```bash
# 1. Python environment
python -m venv .venv && source .venv/bin/activate
pip install dbt-snowflake sqlfluff

# 2. Install dbt packages
dbt deps

# 3. Profiles — copy template and fill in credentials
cp docs/PROFILES_TEMPLATE.md ~/.dbt/profiles.yml
# Edit: replace <snowflake_account> and <username>

# 4. Validate
dbt debug --target dev
dbt parse
```

---

## Seeding REFERENCE.CATALOG

```bash
# See docs/CATALOG_SEED_ORDER.md for full wave order
# Wave 1 first — no FK dependencies
dbt seed --target reference --select reference.catalog.vertical
dbt seed --target reference --select reference.catalog.frequency
# ... follow wave order in docs/CATALOG_SEED_ORDER.md

# Test after all waves complete
dbt test --target reference --select reference.catalog.*
```

---

## Analytics model development (Alex)

```bash
# Build and test in DEV
dbt run --target dev --select analytics.*
dbt test --target dev --select analytics.*

# Promote to STAGE — requires passing QA gate
dbt run --target staging --select analytics.*
dbt test --target staging --select analytics.*

# Promote to PROD — gated by QA_ tables having 0 ERROR rows
dbt run --target prod --select analytics.*
```

---

## Naming conventions

| Prefix | Layer | Target | Object type |
|---|---|---|---|
| `FEATURE_` | Analytics | DBT_DEV/STAGE/PROD | View |
| `MODEL_` | Analytics | DBT_DEV/STAGE/PROD | View |
| `ESTIMATE_` | Analytics | DBT_DEV/STAGE/PROD | Table/Iceberg |
| `BI_` | Analytics | DBT_DEV/STAGE/PROD | View |
| `AI_` | Analytics | DBT_DEV/STAGE/PROD | Table |
| `QA_` | Analytics | DBT_STAGE | Table (gate) |
| `RAW_` | Transform.DEV | DEV only | Table |
| `FACT_` | Transform.DEV | DEV only | Dynamic Table |
| `CONCEPT_` | Transform.DEV | DEV only | Dynamic Table |
| `REF_` | Transform.DEV | DEV only | Table |
| `GEO_` | Reference.DRAFT | DEV only | Table |
| `AI_` | Reference.DRAFT | DEV only | Table |
| `CAT_` | Reference.DRAFT | DEV only | Table |

Structure follows: `.[concept]_[function/model]_[geo_level]_[frequency]`
OpCo objects: `.[opco]_[concept]_[function]_[geo_level]_[frequency]`
