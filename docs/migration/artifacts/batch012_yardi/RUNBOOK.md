# Runbook — Yardi §1.5 inventory (Snowflake)

Run from a role with **`SELECT`** on **`TRANSFORM.YARDI`** and **`INFORMATION_SCHEMA`**.

## Minimum (§A + §B)

```bash
cd /Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
snowsql -c pretium -o output_format=csv -o header=true -o output_file=docs/migration/artifacts/batch012_yardi/2026-04-19_batch012_yardi_section_a_tables.csv -f scripts/sql/migration/inventory_yardi_batch012_section_a_tables.sql
snowsql -c pretium -o output_format=csv -o header=true -o output_file=docs/migration/artifacts/batch012_yardi/2026-04-19_batch012_yardi_section_b_columns.csv -f scripts/sql/migration/inventory_yardi_batch012_section_b_columns.sql
```

**Note:** §B can be large; prefer off-hours or `LIMIT` none (full export) per DE policy.

## Full workbook (§A–J)

Single file (all sections in one session):

```bash
snowsql -c pretium -f scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql
```

Export each result set to CSV under this directory; name files `2026-MM-DD_batch012_yardi_section_<letter>_<topic>.csv`.

## After export

1. Diff **`table_name`** from §A against `TRANSFORM_YARDI_SOURCE_RECONCILIATION.md` and dbt `sources_transform_yardi_opco.yml` / pretium-ai-dbt `sources.yml` **`transform_yardi`** tables.
2. Append **`MIGRATION_LOG.md`** batch **012b** (or later) with artifact filenames and **explicit** “**`T-VENDOR-YARDI-READY` still pending**” if §C–J are not yet filed.
