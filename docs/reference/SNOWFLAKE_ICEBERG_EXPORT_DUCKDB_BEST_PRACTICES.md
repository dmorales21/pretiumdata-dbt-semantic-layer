# Snowflake Iceberg export — best practices for DuckDB pushdown

**Scope:** When materializing or exporting data from Snowflake into **Iceberg / Parquet** for **`SERVING.DEMO`**, **`SERVING.ICEBERG`**, or other lake paths consumed by **DuckDB** (remote Parquet / Iceberg scans), these practices improve **predicate pushdown**, **partition pruning**, **projection pruning**, and **type-driven statistics** (min/max) so engines skip I/O instead of scanning row-by-row.

**Not a substitute for product contracts:** layer and naming rules remain in [`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) and [`ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md). **Physical Iceberg column inventory** for `SERVING.ICEBERG` is generated under `models/serving/iceberg/SERVING_ICEBERG_LANDING_ZONE_SPEC.md`.

---

## 1. Sort entity key before time

Put the **highest-cardinality or most selective join / filter key** first in written order so Parquet **row groups** cluster on the common filter. For property- or geo-grain tables with a reporting calendar, that often means **stable id, then date**.

```sql
ORDER BY tribeca_id, reporting_date
```

Adjust column names to your grain (`property_id`, `geo_id`, `assessor_parcel_key`, etc.).

---

## 2. Partition large tables by a stable geo (or domain) column

For tables **well above ~10M rows**, **Hive-style partition columns** let DuckDB (and other engines) **prune whole S3 prefixes** when filters include the partition key. Prefer **low churn**, **analyst-stable** columns (for example `state`, `cbsa_code`, `reporting_year`) over volatile hashes unless you have a strong skew plan.

```sql
PARTITION BY (state)
```

---

## 3. Front-load filter columns in `SELECT`

On **wide** tables, list **columns that appear in `WHERE` / `JOIN` / frequent `GROUP BY`** early. Engines still read column chunks selectively, but this matches human review and some tooling defaults; it also signals intent to export authors.

```sql
SELECT
  tribeca_id,
  cbsa_code,
  state,
  zip_code,
  is_owned,
  purchase_price,
  -- …remaining columns
FROM …
```

---

## 4. Resolve types at export time, not only at query time

Cast or parse in the **export `SELECT`** so Parquet stores **typed** columns. That preserves **min/max statistics** for numeric and temporal types and avoids per-row casts in DuckDB.

```sql
TRY_TO_DOUBLE(value) AS value,
  year::integer AS year,
  geo_id::varchar AS geo_id
```

Prefer **lossless** casts; document or null out values that fail validation instead of silently widening semantics.

---

## 5. Export dates as `DATE`, not `BIGINT` or `VARCHAR`

Use **`DATE`** (or **`TIMESTAMP_NTZ`** when time-of-day matters) in the export projection so statistics and comparisons work without string parsing.

```sql
reporting_date::date AS reporting_date
```

---

## 6. Export boolean flags as `BOOLEAN`, not `VARCHAR`

Booleans are narrow and carry clean equality statistics; `'Y'/'N'` strings defeat that unless normalized.

```sql
(owned_flag = 'Y')::boolean AS is_owned
```

---

## 7. Control file / row-group footprint

Target **roughly 128K–512K rows per row group** (order-of-magnitude; tune with data width and query mix). The exact Snowflake knob depends on **write path** (native Iceberg write vs `COPY` / unload-style export); align with your platform’s **Parquet / file size** settings and validate with a sample DuckDB query plan.

Example **Parquet file format** pattern (verify parameter support for your account and export method):

```sql
create file format iceberg_pq
  type = parquet
  compression = snappy
  max_file_size = 268435456;
```

---

## 8. Include partition columns in the projection when using `PARTITION BY`

Snowflake requires **partition key columns** to appear in the **`SELECT`** list when you declare **`PARTITION BY`**.

```sql
select
  state,
  cbsa_code,
  tax_assessor_id,
  -- …
from …
partition by (state);
```

---

## Related docs

- [`SERVING_DEMO_ICEBERG_TARGETS.md`](./SERVING_DEMO_ICEBERG_TARGETS.md) — Alex `SERVING.DEMO` matrix, proposed Iceberg surfaces, gaps  
- [`../runbooks/SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md`](../runbooks/SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md) — release bundle gates before Iceberg publish  
- [`DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md`](./DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md) — catalog / share targets for lake consumers  
