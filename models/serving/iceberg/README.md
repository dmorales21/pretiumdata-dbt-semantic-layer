# `SERVING.ICEBERG` — dbt contract stubs

This folder defines the **contract** for native Iceberg tables under **`SERVING.ICEBERG`**: one disabled `*.sql` stub per warehouse relation. The stub name (file stem, or `alias=` in `{{ config(...) }}`) must match the Snowflake **table** identifier (unquoted identifiers fold to uppercase in Snowflake).

When the warehouse set changes (for example a single **`ACS5`** table is replaced by **`ACS5_CBSA`** and **`ACS5_COUNTY`**), add or remove stubs here so the generated spec stays aligned; the generator prints a warning for any stub with no matching table.

**`catalog_core.sql`** — contract stub for **`SERVING.ICEBERG.CATALOG_CORE`**, the intended union of small catalog tables for lake export (includes **`concept_explanation`** alongside **`concept`**, **`dataset`**, etc.). Physical `UNION ALL` + column normalization still lives in Snowflake Tasks / export jobs.

**Regenerate the column-level Markdown spec** (run from this **pretiumdata-dbt-semantic-layer** repo root):

```bash
cd /path/to/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
./scripts/serving/run_generate_serving_iceberg_landing_zone_spec.sh
```

Default output: **`SERVING_ICEBERG_LANDING_ZONE_SPEC.md`** in this directory (same folder as the stubs). Requires **`snowsql`** and a working connection (default **`-c pretium`**; override with `SNOWSQL_CONNECTION`).

To document **every** table in the schema regardless of stubs:

```bash
./scripts/serving/run_generate_serving_iceberg_landing_zone_spec.sh -- --full-schema \
  --output docs/serving/SERVING_ICEBERG_LANDING_ZONE_SPEC.md
```

See also: `dbt_project.yml` → `models.pretiumdata_dbt_semantic_layer.serving.iceberg` (`vars.serving_database`, default **`SERVING`**).
