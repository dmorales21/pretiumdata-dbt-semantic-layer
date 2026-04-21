# Migration readiness — CoStar (`TRANSFORM.COSTAR`, `SOURCE_PROD.COSTAR`, `RAW.COSTAR`, typed `FACT_*`)

**Owner:** Alex (vendor / platform landings **Jon**; **`SOURCE_PROD` / S3 ingest** DE; migration **`TRANSFORM.DEV` `FACT_*`** **Alex**)  
**Governing docs:** `MIGRATION_RULES.md`, `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1–2, pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md`  
**Purpose:** Gate **full** CoStar migration by inventorying **every read path** and **every metric column / scenario dimension** before modeling or re-pointing `TRANSFORM.DEV.FACT_*` and `REFERENCE.CATALOG` dataset/metric rows.

**CoStar is multi-home today (do not assume a single schema):**

| Physical home | Role (typical) |
|---------------|----------------|
| **`TRANSFORM.COSTAR`** | Jon-wide **SCENARIOS** (and any sibling objects); baseline **~1** base object — re-verify with §1. |
| **`SOURCE_PROD.COSTAR`** | **`scenarios_metrics`**, **`COSTAR_EXPORT_PARQUET`** (VARIANT wide rows), **`METRIC_CATALOG_COSTAR_MF_MARKET_EXPORT`** — feeds cleaned/fact chains in pretium-ai-dbt. |
| **`RAW.COSTAR`** | Legacy mirror; prefer **`TRANSFORM`** / **`SOURCE_PROD`** per baseline §1 priority. |
| **`TRANSFORM.FACT` / `TRANSFORM.DEV`** | Wide MF export in **DEV** (**`source('transform_dev','fact_costar_cbsa_monthly')`**, identifier **`FACT_COSTAR_CBSA_MONTHLY`** by default) and any sibling **`FACT_COSTAR_*`** — reconcile with catalog **`DS_033`**, **`DS_034`**. |
| **`TRANSFORM_PROD.CLEANED` / `FACT` / `REF`** | **`cleaned_costar_*`**, **`fact_costar_*`**, **`ref_costar_*`** — **Jon PROD cleanse** path: **skip duplicate rebuild**; re-point reads per `MIGRATION_TASKS.md` **T-TRANSFORM-PROD-CLEANED**. |

**Task ID (update status in `MIGRATION_TASKS.md`):**

| Task ID | Scope | Status |
|---------|--------|--------|
| **T-VENDOR-COSTAR-READY** | All CoStar physical objects + metrics registry + smoke gates below | `pending` |

---

## 0. Preconditions

- [ ] **Role:** Migration / analytics role can `SELECT` **`TRANSFORM.COSTAR`**, **`SOURCE_PROD.COSTAR`**, and (if still used) **`RAW.COSTAR`**; log grant gaps in **`MIGRATION_LOG.md`**.
- [ ] **License / PII:** CoStar exports may be redistribution-sensitive — confirm **SERVING** / demo / strata allowlists before exposing any new view.

---

## 1. Authoritative object inventory (all databases)

Run **`scripts/sql/migration/inventory_costar_for_dev_facts.sql`** (blocks **A–L**; **A–D** minimum before deep dives), or run the equivalent queries manually.

- [ ] **`TRANSFORM.COSTAR`:** full table/view list (`INFORMATION_SCHEMA`).
- [ ] **`SOURCE_PROD.COSTAR`:** all tables (including parquet load + metric catalog).
- [ ] **`RAW.COSTAR`:** confirm whether still referenced; if yes, document **one** canonical path to retire **`RAW`** reads.
- [ ] **`TRANSFORM.DEV` / `TRANSFORM.FACT`:** `SHOW OBJECTS LIKE '%COSTAR%'` (or `INFORMATION_SCHEMA`) — align with **`source('transform_dev', 'fact_costar_cbsa_monthly')`** (var **`transform_dev_costar_mf_market_identifier`**) in semantic-layer.
- [ ] **Reconcile** to pretium-ai-dbt `source('costar', …)` (`SOURCE_PROD.COSTAR`) and any hardcoded **`TRANSFORM.COSTAR.SCENARIOS`** reads (e.g. `fact_costar_cbsa_monthly.sql`).

---

## 1.5 Pre-`FACT_*` modeling — query **all** objects and **uniques** (required)

**Operational note:** Run **§A → §B** (then **§C → §D**) first and export all four result sets. If **§I** or **§J** fails to compile, align identifiers from **§D** / **§B** before locking `FACT_*` or **`OBJECT_KEYS`** documentation.

**Canonical script:** `pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_costar_for_dev_facts.sql`

| Block | What it records | Why it matters for `FACT_*` |
|-------|------------------|-----------------------------|
| **A** | All tables/views in **`TRANSFORM.COSTAR`** | Drift vs baseline (~1 silver table); extend **§E** if **A** lists more. |
| **B** | All columns (ordinal, type, nullable) — **`TRANSFORM.COSTAR`** | Catch renames before **`FACT_*`** / `source()` DDL. |
| **C** | All tables/views in **`SOURCE_PROD.COSTAR`** | Parquet + metric catalog + narrow scenarios feed. |
| **D** | All columns — **`SOURCE_PROD.COSTAR`** | VARIANT **`v`** / `_loaded_at` / metric catalog columns. |
| **E** | **`COUNT(*)`** on **SCENARIOS**, **SCENARIOS_METRICS**, **COSTAR_EXPORT_PARQUET**, **METRIC_CATALOG_COSTAR_MF_MARKET_EXPORT** | Capacity; adjust names if **A/C** differ. |
| **F** | **SCENARIOS** time spine + **`PROPERTY_TYPE`**, **`FORECAST_SCENARIO`**, **`IS_FORECAST`** distributions | Same dimensions as `fact_costar_cbsa_monthly` grain design. |
| **G** | **SCENARIOS** duplicate-grain check (CBSA × property_type × month × scenario × forecast flag) | `bad_rows > 0` → fix upstream or change grain before migration. |
| **H** | **SCENARIOS** non-null counts on a **representative** wide metric subset | Which columns become **`FACT_*`** fields vs deferred. |
| **I** | **`SCENARIOS_METRICS`** — distinct **`SCENARIO_CODE`**, geo-key presence, date range | Avoid double-counting vs wide **SCENARIOS** in one KPI path. |
| **J** | **`COSTAR_EXPORT_PARQUET`** — sample **`OBJECT_KEYS(v)`** (5 rows) | DataExport / unpivot / **`metric_catalog_costar_mf_market_export`** alignment. |
| **K** | **`TRANSFORM.FACT`** / **`TRANSFORM.DEV`** — `%COSTAR%` objects | Reconcile with **`source('transform_dev', 'fact_costar_cbsa_monthly')`** and dev **`FACT_COSTAR_*`**. |
| **L** | **`RAW.COSTAR`** — object list | Legacy mirror; one canonical read path to **`TRANSFORM`** / **`SOURCE_PROD`**. |

**Deliverables (store with `MIGRATION_LOG.md` or `docs/migration/artifacts/`):**

- [ ] CSV from **A–D** (both schemas: objects + columns).
- [ ] CSV from **E–J** (counts, spine, duplicate check, non-nulls, scenarios_metrics, parquet keys).
- [ ] CSV from **K–L** (typed publish surface + RAW list).
- [ ] **Metric list:** (1) wide **SCENARIOS** columns used in analytics facts, (2) **UNPIVOT** keys in `fact_costar_mf_market_export_ts`, (3) **`METRIC_CATALOG_COSTAR_MF_MARKET_EXPORT`** / `REFERENCE` draft — **one combined registry** with `metric_code` / column mapping; **diff** VARIANT **`OBJECT_KEYS`** from **§J** vs catalog / **`register_costar_mf_market_export_metrics.sql`** seed IDs.

---

## 2. Column-level review (every CoStar-backed object)

For each table/view in §1:

- [ ] `DESCRIBE TABLE` — types, nullable VARIANT paths for parquet.
- [ ] **Grain** documented (CBSA vs ZIP vs submarket; monthly vs quarterly).
- [ ] **Scenario model:** `SCENARIO_CODE`, `FORECAST_SCENARIO`, `IS_FORECAST` semantics — which combination is **canonical** for IC vs exploratory.

---

## 3. Crosswalks and geo

- [ ] **`ref_costar_market_xwalk` / `ref_costar_submarket_xwalk`** (pretium-ai-dbt **TRANSFORM_PROD.REF**) — still authoritative? If superseded by **`REFERENCE.GEOGRAPHY`**, plan cutover and log **`old_reference` → `new_reference`** per compliance doc.
- [ ] **CBSA normalization:** `LPAD(TRIM(CBSA_CODE), 5, '0')` (see `fact_costar_cbsa_monthly`) — count rows where trim/lpad changes key; document exceptions.

---

## 4. Semantic-layer and catalog alignment

- [ ] **`models/sources/sources_transform.yml`:** **`transform_dev.fact_costar_cbsa_monthly`** (wide MF export) — confirm **one** physical identifier in **DEV**; add **`TRANSFORM.COSTAR`** sources in YAML **only** if Alex models must read vendor-native tables directly.
- [ ] **`REFERENCE.CATALOG` `dataset.csv`:** validate **`DS_033`** (scenarios / **`TRANSFORM.COSTAR`**) and **`DS_034`** (MF export / **`TRANSFORM.DEV`**) — `pipeline_status`, `source_schema`, `coverage_pct` after inventory.
- [ ] **Admin / metric registry:** today **`register_costar_mf_market_export_metrics.sql`** → **`ADMIN.CATALOG.DIM_METRIC`** — run **`inventory_costar_for_dev_facts.sql` §A–L first** (grain + **`OBJECT_KEYS`**) so registry rows match physical unpivot; plan **`REFERENCE.CATALOG`** / **`REFERENCE.DRAFT`** target per registry migration; no silent duplicate metric IDs.

---

## 5. Downstream consumers (grep before cutover)

- [ ] pretium-ai-dbt: `fact_costar_*`, `cleaned_costar_*`, `mart_costar_*`, `feature_*costar*`, `raw_costar_scenarios_metrics_source_prod_dev.sql`, EDW delivery **`v_*costar*`**, seeds **`metric_catalog_costar_*`**, **`costar_cbsa_metro_division_rollup`**.
- [ ] strata / tearsheet: `MIGRATION_TASKS_TEARSHEET_SERVICE.md` row **`MART_COSTAR_MF_RENT_CBSA`** — include in batch plan.

---

## 6. Quality gates

- [ ] **Smoke:** `SELECT 1` from **SCENARIOS**, **scenarios_metrics**, **COSTAR_EXPORT_PARQUET** (limit), metric catalog table.
- [ ] **Freshness:** vs `vendor` / `dataset` rows for **`costar`** (`vendor.csv`, `dataset.csv`).
- [ ] **No double-count:** document which features read **wide SCENARIOS** vs **long export fact** vs **narrow scenarios_metrics** — each **`metric_id`** appears in **one** canonical path post-migration.

---

## 7. Log and exit criteria

- [ ] **`MIGRATION_LOG.md`:** inventory date, table counts per database, scenario + metric catalogs attached, blockers.
- [ ] **`T-VENDOR-COSTAR-READY`** → `migrated` only when §1–2, §1.5, §4–6 are complete.

**Exit criteria (“ready to migrate in full”):** All CoStar homes inventoried; **§1.5 artifacts on file** (dated exports for workbook **A–L**, linked from **`MIGRATION_LOG.md`** or **`docs/migration/artifacts/`**); **§G** duplicate-grain at zero or waiver documented; **§J** VARIANT keys reconciled to metric catalog; grains and scenario rules frozen; catalog / source YAML aligned; smoke clean — **then** implement **`TRANSFORM.DEV` `FACT_*`** and consumer moves per **`MIGRATION_RULES.md`**.
