# Naming rules — index (no new policy)

**Owner:** Alex  
**Purpose:** Single entry point that **only links** canonical sections. Naming authority and physical layout are defined elsewhere; do not duplicate matrix rows here.

## Read in this order

| Priority | Topic | Document |
|----------|--------|------------|
| 1 | **Full Snowflake ↔ dbt naming matrix** (`FACT_*`, `CONCEPT_*`, `FEATURE_*`, `MODEL_*`, `ESTIMATE_*`, `REF_*`, vendor namespaces, geography) | [SCHEMA_RULES.md](./SCHEMA_RULES.md) — matrix + **Alex — responsibilities** (generated matrix: edit **`schema_rules.csv`**, not the table in the markdown). |
| 2 | **Quick dbt filename / column reminders** | [MIGRATION_RULES.md §7](../migration/MIGRATION_RULES.md#7-naming-conventions) — short list; **not** exhaustive for Snowflake prefixes. |
| 3 | **Where model files live** (`models/transform/dev/…`, `models/analytics/…`) | [MIGRATION_RULES.md §4](../migration/MIGRATION_RULES.md#4-new-repo-path-conventions) — path table (including **CONCEPT** under `models/transform/dev/<vendor_or_domain>/`). |
| 4 | **Architecture split** (naming defers to SCHEMA_RULES) | [ARCHITECTURE_RULES.md](./ARCHITECTURE_RULES.md) — intro states semantic-layer naming pattern; layer split and schema ownership. |
| 5 | **Metric / catalog intake** (gates + related playbooks) | [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md). |
| 6 | **Lineage YAML** (stable IDs = **model names**; not a naming spec) | [registry/lineage/README.md](../../registry/lineage/README.md). |

## Common clarifications

- **`ref_` dbt models** vs **`REF_*` Snowflake objects:** the matrix in **SCHEMA_RULES** defines how crosswalks and seeds map; do not assume every `ref_`-prefixed artifact maps 1:1 without checking that row.
- **`MIGRATION_RULES` §7** lists `fact_`, `concept_`, `feature_`, `ref_`, `raw_` for **dbt model filenames**; **`MODEL_*`**, **`ESTIMATE_*`**, and related **Snowflake** conventions are spelled out in **SCHEMA_RULES**, not §7 alone.
- **Geo labels:** normalize vendor **`GEO_LEVEL_CODE`** to **`REFERENCE.CATALOG.geo_level`** — see **MIGRATION_RULES** §6–§7 and **ARCHITECTURE_RULES** (Geo Level Vocabulary Alignment).
