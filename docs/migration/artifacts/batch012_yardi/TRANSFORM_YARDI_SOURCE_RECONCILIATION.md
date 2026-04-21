# TRANSFORM.YARDI — dbt `source('transform_yardi', …)` vs inventory script

**Purpose:** Close **§1.5** “reconcile YAML vs `INFORMATION_SCHEMA`” without claiming **Yardi migrated**.

## Inventory script coverage

`scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql` references these **logical** tables (§C+):

| Object | Used in § |
|--------|-----------|
| PROPERTY_BH / PROPERTY_PROGRESS | C, D, J |
| TENANT_BH / TENANT_PROGRESS | C, F |
| UNIT_BH / UNIT_PROGRESS | C, E, G |
| UNIT_STATUS_BH / UNIT_STATUS_PROGRESS | C, H |
| UNITTYPE_PROGRESS | C |
| TRANS_BH / TRANS_PROGRESS | C, I |
| *(§B lists all columns for every table in `TRANSFORM.YARDI`)* | B |

## Declared in pretium-ai-dbt (`dbt/models/sources.yml` → `transform_yardi`)

As of batch **012b**, the project declares at least:

PROPERTY_BH, PROPERTY_PROGRESS, TENANT_BH, TENANT_PROGRESS, UNIT_BH, UNIT_PROGRESS, UNIT_STATUS_BH, UNIT_STATUS_PROGRESS, UNITTYPE_PROGRESS, UNITTYPE_BH, TRANS_PROGRESS, **TRANS_BH**.

**Gap closed in 012b:** `TRANS_BH` and `UNITTYPE_BH` are read in analytics SQL as `TRANSFORM.YARDI.*` literals; they are now registered on `transform_yardi` for future `source()` refactors and for parity with §C row-counts.

## Declared in pretiumdata-dbt-semantic-layer

`models/sources/sources_transform_yardi_opco.yml` mirrors the same table set **used or anticipated** by OPCO / analytics ports (fund_opco uses a subset; YAML stays wider to avoid drift on compile).

## Operator check (after §A CSV exists)

1. Every **`table_name`** from §A that any pretium-ai-dbt model references (grep `source('transform_yardi'` and `TRANSFORM.YARDI.`) appears under **`transform_yardi.tables`** **or** is explicitly documented as out-of-scope (e.g. dictionary-only).
2. No stray **`source('transform_yardi', 'MISSING')`** — `dbt compile` is necessary but not sufficient; §A is authoritative for **Snowflake** presence.

## Not in scope here

- **`TRANSFORM.YARDI_MATRIX`** — `MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`
- **`SOURCE_ENTITY.PROGRESS` landings** — OPCO fund-tab; use selector `fund_opco_yardi_silver_facts_only` in pretium-ai-dbt; not corridor spine input
