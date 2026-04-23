# ENUM consolidation — dbt refs & tests (audit checklist)

**Purpose:** Record what still depends on **per-table enum seeds** so you can **stop seeding ~65 small tables into Snowflake** (local-only CSVs) **without** breaking `dbt parse`, `dbt seed`, or `catalog_enum`. Scope: **`models/`**, **`seeds/`**, **`tests/`**, **`scripts/`** (exclude **`target/`**).

**Related:** [`../reference/AUTO_REFRESH_STRATEGY_BY_CONTENT_TYPE.md`](../reference/AUTO_REFRESH_STRATEGY_BY_CONTENT_TYPE.md) · [`models/reference/catalog/catalog_enum.sql`](../../models/reference/catalog/catalog_enum.sql) · [`../../models/serving/iceberg/README.md`](../../models/serving/iceberg/README.md)

---

## Definition of done — “only `ENUM` in Snowflake”

**Snowflake (`REFERENCE.CATALOG`)**

- [ ] **Exactly one** physical lookup for consolidated small enums: **`ENUM`** (from dbt `catalog_enum` or a Task-built equivalent).
- [ ] **No** per-enum tables (`ABSORPTION_TIER`, `RENT_TIER`, …) unless you deliberately keep **non-enum** dimensions (see below).
- [ ] Consumers (Presley, BI, shares) read **`ENUM`** with **`WHERE enum_table = '…'`** (or use views you publish on top of **`ENUM`**).

**dbt repo (this is what “complete” really means)**

- [x] **`catalog_enum`** reads **`ref('catalog_enum_source')`** plus **`frequency`**, **`asset_type`**, **`tenant_type`** (no `ref()` to the ~57 dropped per-enum seeds).
- [x] **`relationships`** tests on merged enums use ephemeral **`erf__<enum_table>`** models over **`catalog_enum_source`** (not removed seed node names).
- [x] **`_catalog.yml`** / **`CATALOG_SEED_ORDER.md`** no longer list the merged tables as separate seeds.
- [x] **`dbt parse`** passes on a clean clone (CI parse job unchanged).

**Keep out of “enum purge” (usually still seeded or modeled)**

Core dimensions that **facts and metrics join to** and are not the 65-style tier tables: e.g. **`concept`**, **`metric`**, **`dataset`**, **`domain`**, **`geo_level`**, **`frequency`**, **`vertical`**, **`vendor`**, bridges, **`metric_derived`**. Treat **`frequency` / `geo_level`** as **grain dimensions**, not disposable enums, unless you explicitly migrate those FKs to **`ENUM`** too (bigger change).

---

## Verification — prove completeness

Run from repo root (adjust `--target`).

1. **No stray refs to old enum seeds in models/tests**

   ```bash
   rg "ref\\('(absorption_tier|amenity_tier|rent_tier|ltv_tier)\\)" models tests --glob '!target/**'
   ```

   Extend the alternation with your full dropped list; expect **no hits** outside archived SQL (if any).

2. **No `relationships` to dropped seeds in catalog YAML**

   ```bash
   rg "to:\\s*ref\\('" seeds/reference/catalog --glob '*.yml' | rg "tier|_type|_status" 
   ```

   Tighten patterns to your naming; **fix every hit** or confirm it targets a **kept** seed.

3. **dbt graph compiles**

   ```bash
   dbt parse
   dbt ls --select +catalog_enum
   ```

4. **Fresh database: seed + build catalog only**

   On a scratch **`reference`** target (or dev):

   ```bash
   dbt seed --select <your narrowed catalog selector>
   dbt run --select catalog_enum
   dbt test --select catalog_enum <any catalog tests you kept>
   ```

5. **Snowflake inventory (manual)**

   ```sql
   select table_name
   from reference.information_schema.tables
   where table_schema = 'CATALOG'
     and table_type = 'BASE TABLE'
     and table_name not in ('ENUM', /* keep: */ 'CONCEPT', 'METRIC', 'DATASET', 'DOMAIN', 'GEO_LEVEL', 'FREQUENCY', 'VERTICAL', 'VENDOR')
     and regexp_like(table_name, '.*_(TIER|TYPE|STATUS)$|^ABSORPTION|^AMENITY|^RENT_|^LTV_|^DSCR_'); -- tune
   ```

   Expect **no rows** (or only explicitly retained tables).

---

## Completion checklist (do these before dropping seed nodes)

1. **`catalog_enum.sql`** — Replace `UNION ALL` over `{{ ref('<enum_seed>') }}` with one of:
   - **`ref('catalog_enum_seed')`** on a **single** wide seed built from local enum CSVs in CI, or  
   - **`select * from {{ ref('enum') }}`** if **`ENUM`** is the only Snowflake table and dbt **reads** it (not ideal for first build), or  
   - A **macro-generated** SQL from a manifest of local files (advanced).

2. **Seed `relationships` tests** — For each `to: ref('absorption_tier')`-style test on a dropped table, either:
   - Re-point to **`ref('catalog_enum')`** with `where: "enum_table = 'absorption_tier'"` and `field: code` (pattern depends on test type), or  
   - Move validation to **CI** (Python / `dbt test` on DuckDB with staged CSVs), or  
   - Add thin **`view`** models in Snowflake that **select** from **`ENUM`** (one view per legacy name) *only if* you must preserve old `ref()` names temporarily.

3. **`_catalog.yml` / Wave docs** — Remove or mark deprecated any `source('catalog', '<enum>')` entries that implied Snowflake tables you no longer load.

4. **`dbt seed --select reference.catalog.*`** — Narrow selectors so CI does not expect dropped seeds; update [`CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md).

---

## 1. `catalog_enum` — merged seed + three first-class dimensions

**File:** `models/reference/catalog/catalog_enum.sql`

**Behavior:** Builds **`REFERENCE.CATALOG.ENUM`** (`alias='enum'`) from **`{{ ref('catalog_enum_source') }}`** (tall merged rows for ~57 logical enum tables) **`UNION ALL`** **`frequency`**, **`asset_type`**, and **`tenant_type`** (still separate CSV seeds).

**Ephemeral helpers:** `models/reference/catalog/enum_refs/erf__*.sql` — one model per merged enum for **`relationships`** tests; regenerated by **`scripts/reference/catalog/build_catalog_enum_source_seed.py`** (erf-only mode when per-enum CSVs are absent).

**Other `models/**/*.sql`:** No `ref('data_status')` etc. on dropped seed names outside **`catalog_enum`** / **`erf__*`**.

---

## 2. Seed YAML — `relationships` after cutover

Merged enums: **`to: ref('erf__<enum_table>')`** (e.g. **`erf__data_status`**, **`erf__metric_category`**) with the same **`field:`** as before (e.g. **`data_status_code`**, **`category_code`**).

**Still `ref()` real seeds** for first-class dimensions: **`vertical`**, **`domain`**, **`frequency`**, **`geo_level`**, **`concept`**, **`vendor`**, **`product_type`**, **`metric`**, **`dataset`**, **`offering`**, **`asset_type`**, **`tenant_type`**, **`opco`**, bridges, etc.

**Removed YAML files** (only contained seeds that moved into **`catalog_enum_source`**): **`schema_financial_tiers.yml`**, **`schema_hazard_environmental.yml`**, **`schema_market_analytics.yml`**, **`schema_property_attributes.yml`**. Per-enum **`accepted_values`** column tests that lived there are not carried forward; tighten **`catalog_enum_source`** or add singular tests if you need them back.

**Note:** **`tenant_type`** (offering / B2B) is **not** the same logical table as **`tenancy`** (unit occupancy vocabulary in **`ENUM`**).

---

## 3. `DOMAIN` — do not drop without follow-up

- **`ref('domain')`:** `schema_data_infrastructure.yml` (concept → domain), `schema_concept_explanation.yml` (domain_code → domain).
- **SQL:** `scripts/sql/reference/catalog/migrate_domain_five_way.sql` references **`REFERENCE.CATALOG.DOMAIN`**.

---

## 4. `OFFERING_SIGNAL_RELEVANCE`

- **No** `ref('offering_signal_relevance')` in **`models/`** or **`tests/`** in this audit.
- Still a **seed** with YAML in `schema_offering_tearsheet.yml`, CSV, and `_catalog.yml`.
- **Docs:** `docs/reference/OFFERING_INTELLIGENCE_CANON.md`, `docs/CATALOG_SEED_ORDER.md`, migration inventories (may reference sibling repo paths).

---

## 5. `METRIC_RAW`

- **No** `ref('metric_raw')` in **`models/`** or **`tests/`** for semantic-layer SQL consumers.
- **Seeds / CI / scripts:** `schema_metric_raw.yml`, `_catalog.yml`, `build_metric_csv_from_metric_raw.py`, `sync_metric_csv_from_pretium_ai_dbt.py`, `.github/workflows/semantic_layer_catalog_and_quality.yml`, `print_catalog_metrics_by_concept_inventory.py`, `_gen_metric_csv.py` — **authoring / CI pipeline**, not the dbt model graph.

---

## 6. `BUSINESS_TEAM` (often on “drop” lists)

- **Not** referenced in **`catalog_enum.sql`** (verify if added later).
- **No** `ref('business_team')` in repo grep (seed graph).
- Still defined as seed: `schema_entity_org.yml`, `business_team.csv`, `_catalog.yml`.
- **`models/sources/sources_transform.yml`** may declare a **`source('…', 'business_team')`** — different contract than **`ref('business_team')`** seed; reconcile names before dropping either.

---

## 7. Practical implication

**dbt project:** Per-enum CSV seeds for the merged set are **removed from `seeds/`**; authoritative merged rows are **`catalog_enum_source.csv`**. Snowflake may still have legacy **`REFERENCE.CATALOG.<ENUM_TABLE>`** tables until you drop them after consumer migration.

**Warehouse cleanup:** Dropping legacy per-enum Snowflake tables is safe for dbt once consumers read **`ENUM`** (or **`catalog_enum_source`**) instead of those tables.

---

## Optional follow-up doc

Batch **034** in [`MIGRATION_LOG.md`](./MIGRATION_LOG.md) records the dbt-side cutover (2026-04-23). Add a follow-up row when legacy per-enum **Snowflake** tables are dropped after consumer migration.
