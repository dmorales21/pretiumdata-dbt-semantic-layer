# Batch 012 — Yardi OPCO pilot (`T-VENDOR-YARDI-READY`)

**Status:** **`T-VENDOR-YARDI-READY` remains `pending`** until §1.5 exit criteria in `MIGRATION_TASKS_YARDI_BH_PROGRESS.md` are satisfied (inventory **A–J** archived here, not only A–B).

**Contents (after operator runs Snowflake):**

| Artifact | Description |
|----------|-------------|
| `RUNBOOK.md` | Exact `snowsql` commands and export hints |
| `*_section_a_tables.csv` | §A — `INFORMATION_SCHEMA.TABLES` for `TRANSFORM.YARDI` |
| `*_section_b_columns.csv` | §B — `INFORMATION_SCHEMA.COLUMNS` (large) |
| Optional | §C–J CSVs from full `inventory_yardi_bh_progress_for_dev_facts.sql` |

**Source reconciliation (code + Snowflake):** see `TRANSFORM_YARDI_SOURCE_RECONCILIATION.md` in this folder (declared dbt `source('transform_yardi', …)` vs objects the inventory script touches).
