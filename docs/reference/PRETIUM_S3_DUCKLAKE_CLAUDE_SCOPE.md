# `pretium_s3` (DuckLake share) + Claude — scope, cost framing, Iceberg catalogs

Operational framing for read-only lake consumption (MotherDuck / DuckDB-style) versus Snowflake authoring paths. Not a pricing quote.

---

## Scope: `pretium_s3` (DuckLake share) + Claude

### You can

- Run **read-only SQL** against whatever is **actually registered in that share** (tables/views that exist in the DuckLake catalog backing the share).
- Use **full DuckDB SQL** on those objects: filters, aggregates, windows, joins, H3 helpers if the extension is available in that environment, etc.
- **Join across attached databases** in one query (e.g. share DB + `catalog` + `s3_pretiumdata`) **if** the Claude/MotherDuck connector allows multiple attaches for that account—policy-dependent, not guaranteed by “share” alone.
- **Schema introspection** (`DESCRIBE`, `information_schema`, etc.) on attached objects.
- **Iterating in chat**: NL → SQL → results → refine.

### You cannot (via typical Claude + read-only lake patterns)

- **INSERT/UPDATE/DELETE** or DDL that mutates shared data (read-only share).
- See **MotherDuck org admin**, unrelated DBs, or **raw S3** outside what’s exposed through the catalog/share.
- Rely on **stored procedures**, **scheduled jobs**, or **UDFs** “through Claude” unless the product explicitly exposes them (usually it doesn’t).

### Right now

“**Currently no tables surfaced**” means **Claude can do nothing data-wise** until you **materialize objects + grant them through the share** (or attach another DB that already has data). The share is a **curated read surface**, not the bucket listing ([`pret-iceberg` in us-west-2](https://us-west-2.console.aws.amazon.com/s3/buckets/pret-iceberg?region=us-west-2&tab=objects) is separate infrastructure until wired into the catalog consumers use).

---

## Query cost vs Snowflake (framing, not a quote)

They are **different meters**:

| Dimension | MotherDuck / DuckDB on lake | Snowflake |
|-----------|-----------------------------|-----------|
| **Unit** | Compute time + object storage scan; often **no per-query warehouse minimum** like SF | **Credits** × warehouse size × runtime; **minimum billing granularity** per warehouse policy |
| **Tiny ad hoc** | Can be very cheap if data is **small / well pruned / partitioned** | Often **dominated by warehouse spin-up / minimum** for small work |
| **Heavy scan** | Cost **scales with bytes read** (partitioning / file layout matter a lot) | Cost scales with **warehouse size + time**; pruning helps via micro-partitions/clustering |
| **Concurrency** | **Single-node DuckDB** style limits; not a warehouse fleet | **Built for many concurrent queries** on separate warehouses |

**Rule of thumb:** Read-only, **pre-materialized**, **partitioned** analyst slices on S3/DuckLake are usually **much cheaper** than spinning Snowflake warehouses for the same exploratory traffic—**if** user count and concurrency stay modest and you **don’t** duplicate huge unpartitioned scans.

---

## Snowflake `CATALOG = 'SNOWFLAKE'` vs `CATALOG = 'POLARIS'` for Iceberg

Both can use the same **`EXTERNAL_VOLUME`** / S3 layout; the difference is **who owns Iceberg table metadata and how other engines discover it**.

### `CATALOG = 'SNOWFLAKE'`

- Metadata and table operations are **integrated with Snowflake** (RBAC, lifecycle, engine).
- Best when **Snowflake is the primary builder and reader** of those Iceberg tables.

### `CATALOG = 'POLARIS'` ([Apache Polaris](https://polaris.apache.org/) — Iceberg **REST catalog**)

- **Open catalog API**: other Iceberg-capable engines (Spark, Trino, DuckDB ecosystem paths, etc.) can **attach to the same logical tables** without Snowflake-specific catalog glue.
- Best when **`pretium_s3` / DuckLake / non-SF consumers** should treat the same tables as **first-class, named objects** with **stable REST catalog semantics**.

### How to choose

- **Polaris** if your north star is **one portable semantic publish** (Iceberg on S3) with **multi-engine** attach—aligned with “concepts as portable assets + REST catalog” in your lakehouse story.
- **Snowflake catalog** if Iceberg is mainly **Snowflake-internal** external tables and you **export** a separate consumption path (e.g. COPY Parquet / sync into DuckLake) for Claude/MotherDuck.

You can also use **hybrid** patterns (Snowflake-built tables in one catalog, **replicated or derived** assets in DuckLake for analyst/Claude) at the cost of more pipelines and lineage discipline.

---

## One sentence “why” (reuse)

Use **Snowflake** to **author** canonical semantics; use **Iceberg + (Polaris when you need open attach) + DuckLake/MotherDuck** to **serve read-only, catalog-backed tables** to Claude and analysts **without re-implementing concept logic** in every notebook—after the share actually contains those tables.

**See also:** [DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md](./DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md) — which **`REFERENCE.CATALOG`** seeds are **P0** in Snowflake vs which tables should be **first-class in the Duck Lake share**.
