# Migration readiness — `TRANSFORM.APARTMENTIQ` + `TRANSFORM.YARDI_MATRIX`

**Owner:** Alex (vendor landings **Jon**; migration **Alex** `FACT_*` / consumers)  
**Governing docs:** `MIGRATION_RULES.md`, `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1–2, pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md`  
**Purpose:** Gate **full** migration of ApartmentIQ and Yardi Matrix data by **reviewing every object and every measurable column / metric pivot** in the two vendor schemas before registering sources, building `TRANSFORM.DEV` wrappers, or promoting `REFERENCE.CATALOG` dataset/metric rows.

**Paired task IDs (update status in `MIGRATION_TASKS.md`):**

| Task ID | Snowflake scope | Status |
|---------|-----------------|--------|
| **T-VENDOR-APARTMENTIQ-READY** | `TRANSFORM.APARTMENTIQ` (+ downstream `FACT_*` / cleaned parity in old repo) | `pending` |
| **T-VENDOR-YARDI-MATRIX-READY** | `TRANSFORM.YARDI_MATRIX` (+ DATATYPE / geo bridge behavior) | `pending` |

**Baseline snapshot note:** `MIGRATION_BASELINE_RAW_TRANSFORM.md` lists **~7** objects under `TRANSFORM.APARTMENTIQ` and **~3** under `TRANSFORM.YARDI_MATRIX`. Treat those counts as **non-authoritative** until the inventory query below is re-run (drift, new tables, or case variants).

---

## 0. Preconditions

- [x] **pretiumdata-dbt-semantic-layer `source()` parity (batch 009):** `models/sources/sources_apartmentiq_yardi_matrix.yml` declares **`transform_apartmentiq`** and **`transform_yardi_matrix`** with the same core tables as pretium-ai-dbt `sources.yml` — enables `dbt compile` for future `FACT_*` without editing pretium-ai-dbt. **Snowflake §A–H inventory CSVs are still mandatory** before flipping **`T-VENDOR-*-READY`** to migrated.
- [ ] **Role:** Run all Snowflake steps with the same role used for migration (`pretium` / agreed Alex read role); record any **missing grants** in `MIGRATION_LOG.md`.
- [ ] **Not in scope here:** **`TRANSFORM.YARDI`** (operational BH + Progress silver) vs **`TRANSFORM.YARDI_MATRIX`** (market performance). Do not conflate — operational Yardi is **`MIGRATION_TASKS_YARDI_BH_PROGRESS.md`** / **`T-VENDOR-YARDI-READY`**; this file is **ApartmentIQ + Yardi Matrix** only.

---

## 1. Authoritative object inventory (both schemas)

Run in Snowflake (adapt database if account uses `TRANSFORM_PROD`):

```sql
-- Full list: name, kind (approx row counts: ACCOUNT_USAGE or COUNT(*) per table separately)
SELECT table_catalog, table_schema, table_name, table_type
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE table_schema IN ('APARTMENTIQ', 'YARDI_MATRIX')
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_schema, table_name;
```

- [ ] **ApartmentIQ:** Paste result (or saved CSV) into `MIGRATION_LOG.md` or a dated appendix under `docs/migration/artifacts/` and link from log **Summary**.
- [ ] **Yardi Matrix:** Same.
- [ ] **Reconcile** to pretium-ai-dbt `source('transform_apartmentiq', …)` / `source('transform_yardi_matrix', …)` in `dbt/models/sources.yml` (table list + `identifier` overrides). Any object **only** in Snowflake → add to sources YAML in **pretiumdata-dbt-semantic-layer** when first consumer migrates; any object **only** in YAML → confirm dropped or renamed in Snowflake.

---

## 1.5 Pre-`FACT_*` modeling — query **all** objects and **uniques** (required)

**Operational note:** Run **§A → §B** first and export both. If any identifier in **§G** or **§H** fails to compile, fix names from **§B** (`column_name` / `ordinal_position`) before locking `FACT_*` shapes or treating **§G** as complete.

Before any `TRANSFORM.DEV.FACT_*` DDL or dbt models, run the bundled workbook and **archive every result set** (CSV or worksheet export with run date) under `docs/migration/artifacts/` and link from **`MIGRATION_LOG.md`**. This is the evidence base for **metric_id / column mapping** and **grain** design.

**Canonical script (run sections A–H in order; header documents block purposes A–H):**

`pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_apartmentiq_yardi_matrix_for_dev_facts.sql`

| Section | What it records | Why it matters for `FACT_*` |
|--------|------------------|-----------------------------|
| **A** | Full object list in both schemas | Ensures no orphan `source()`; catch drift vs baseline (~7 / ~3 tables). |
| **B** | Every column + type | Detect renames before typing `FACT_*` columns. |
| **C** | Row counts per known table | Capacity + join explosion estimates. |
| **D** | Duplicate-key checks on declared grains | If `bad_rows > 0`, resolve upstream or change grain before migration. |
| **E** | Time spine + geo cardinality (ApartmentIQ) + distinct property/month & unit/month pairs | Confirms month property / month unit grains and geo spread. |
| **F** | Non-null counts for wide KPI columns | Which measures become **FACT** value columns vs sparse skips. |
| **G** | Distinct `DATATYPE`, `ASSETCLASS`, combos + period bounds + Matrix duplicate grain | **Authoritative metric list** for Yardi Matrix EAV → typed `FACT_*` rows / catalog keys. |
| **H** | Bridge distinct ZIP / ZCTA / market keys | Geo join coverage for rolling submarket metrics to county/CBSA. |

**Deliverables to store with `MIGRATION_LOG.md` (or `docs/migration/artifacts/`):**

- [ ] CSV (or pasted table) from **§A** + **§B**.
- [ ] CSV from **§C–E** and **§G–H** (counts and uniques).
- [ ] For **§G**: treat `DISTINCT TRIM(DATATYPE)` and `ASSETCLASS × DATATYPE` as the **authoritative list of metrics to migrate**; reconcile with `REFERENCE.DRAFT.catalog_metric` / future `metric` seed rows.
- [ ] **Diff vs SOURCE_ENTITY:** run pretium-ai-dbt `scripts/sql/admin/catalog/export_yardi_matrix_datatype_catalog.sql` (reads `SOURCE_ENTITY.BH.MATRIX_MARKETPERFORMANCE`) and **diff** `TRIM(DATATYPE)` (and combos if you extend the export) vs **§G** output from **`TRANSFORM.YARDI_MATRIX.MARKETPERFORMANCE_BH`** — silver should match or drift must be documented in the log.

---

## 2. Column-level review (every object)

For **each** base table / view in each schema:

- [ ] `DESCRIBE TABLE TRANSFORM.APARTMENTIQ.<OBJECT>;` (and `YARDI_MATRIX`) — capture types, nullability, comment drift.
- [ ] **Primary grain:** document natural keys (e.g. property / unit / month) per table; flag **degenerate** or duplicate-key risk.
- [ ] **Time spine:** min/max period columns, timezone, and whether month-end vs month-begin is defined.
- [ ] **OpCo / entity suffix:** confirm `_BH` (and any future `_PROGRESS` or other) naming; document which OpCo rows land in which table.
- [ ] **PII / governance:** mark columns that must not leave `TRANSFORM` or that need masking for `SERVING` / demo paths.

**Deliverable:** One short **per-schema** subsection (this file or linked CSV) listing **object → grain → key columns → time column**.

---

## 3. Metrics definition (ApartmentIQ)

ApartmentIQ metrics are largely **explicit columns** on `PROPERTYKPI_BH` / `UNITKPI_BH` (not a single long-form `DATATYPE` pivot).

- [ ] **Property KPI:** enumerate every numeric/KPI column used (or intended) in pretium-ai-dbt: `cleaned_apartmentiq_property_kpi`, `mart_apartmentiq_property_kpi`, `fact_apartmentiq_pricing_cbsa`, EDW delivery `v_apartmentiq_*` — map **each** to a **`concept_code`** / future **`metric_code`** in `REFERENCE.CATALOG` (or `REFERENCE.DRAFT.catalog_metric` until FACT promotion).
- [ ] **Unit KPI:** same for unit grain; confirm join path `UNITKPI_BH` → `UNIT_BH` → `PROPERTY_BH` / `BHCOMP_BH`.
- [ ] **Coverage:** row counts by month and by geography (property lat/long, market id, or rolled CBSA); compare to **dataset** row `DS_055` expectations in `seeds/reference/catalog/dataset.csv` (`coverage_pct`, `pipeline_status`).
- [ ] **Parity:** vs `SOURCE_ENTITY.BH` legacy `APARTMENTIQ_*` if still read anywhere — document **cutover** or **union** decision in `MIGRATION_LOG.md`.

---

## 4. Metrics definition (Yardi Matrix)

Matrix facts are primarily **`MARKETPERFORMANCE_BH`** long-form with **`DATATYPE`** / **`DATAVALUE`** (see pretium-ai-dbt `sources.yml` `datatype_catalog_script` meta).

- [ ] **Run or refresh** datatype catalog script: `scripts/sql/admin/catalog/export_yardi_matrix_datatype_catalog.sql` (pretium-ai-dbt) — produce **SOURCE_ENTITY** `DATATYPE` pull for IC memo / catalog builders. **Pair** with semantic-layer **`inventory_apartmentiq_yardi_matrix_for_dev_facts.sql` §G–H** for **TRANSFORM** silver uniques, period bounds, duplicate-grain proof, and ZIP/ZCTA bridge — then **diff** as required in **§1.5**.
- [ ] **Crosswalk:** validate **`SUBMARKETMATCHZIPZCTA_BH`** join rates to `REFERENCE.GEOGRAPHY` / county / CBSA spine; document unmatched ZIP/ZCTA share.
- [ ] **Pivot safety:** for each **consumer** metric (rent growth, concessions, occupancy-like, etc.), document the **exact `DATATYPE` value set** and any **versioning** (renames, null spikes).
- [ ] **Coverage:** time and geo coverage vs **dataset** row `DS_065` (`yardi_matrix_bh_monthly`) in `dataset.csv`.
- [ ] **Third object (if present):** baseline **~3** tables — identify the object not listed in current `transform_yardi_matrix` sources (if any); add description and metric relevance.

---

## 5. Semantic-layer and FACT alignment

- [ ] **pretiumdata-dbt-semantic-layer `models/sources/sources_transform.yml`:** today **`apartmentiq_pricing_cbsa_monthly`** appears under **`TRANSFORM.FACT`**, not under **`TRANSFORM.APARTMENTIQ`**. After review, either **keep** FACT-only contract (Jon promotes to FACT) or **add** explicit `source` definitions for `TRANSFORM.APARTMENTIQ.*` if Alex models must read vendor-native tables — document the **single** allowed read path in YAML comments.
- [ ] **Yardi Matrix:** register `TRANSFORM.YARDI_MATRIX` tables in `sources_transform.yml` (or agreed sibling file) **before** any new `FACT_*` in `TRANSFORM.DEV` references them.
- [ ] **`FACT_*` promotion:** for each planned **`TRANSFORM.DEV.FACT_*`**, list upstream `source()` chain → no orphan refs to `TRANSFORM_PROD.CLEANED.*` for these vendors unless Jon contract says otherwise.

---

## 6. Quality gates before “migrate in full”

- [ ] **Smoke:** `SELECT 1` or `LIMIT 1` from **every** table in both schemas under migration role (reuse repo smoke patterns under pretium-ai-dbt `docs/governance/audits/` where applicable).
- [ ] **Freshness:** confirm refresh cadence vs `vendor.refresh_cadence` / `dataset` seeds for `apartmentiq` and `yardi` (Matrix may share vendor_code `yardi` in catalog — align naming in log if Matrix is a **separate** dataset row).
- [ ] **Tests:** dbt `source_freshness` / custom row-count floors — add to semantic-layer or migration CI when sources exist.
- [ ] **Downstream inventory:** grep pretium-ai-dbt + strata + tearsheet docs for `APARTMENTIQ`, `YARDI_MATRIX`, `PROPERTYKPI`, `MARKETPERFORMANCE`, `SUBMARKETMATCH` — list **each** consumer; mark migrated vs blocked.

---

## 7. Log and exit criteria

- [ ] Append **`MIGRATION_LOG.md`** with: inventory date, table count, blockers (grants, empty tables, DDL errors), and **confirmed** metric/datatype coverage statement.
- [ ] Set **T-VENDOR-APARTMENTIQ-READY** and **T-VENDOR-YARDI-MATRIX-READY** to `migrated` (or `blocked` with reason) **in `MIGRATION_TASKS.md`** only when §1–4 and §6 are complete.

**Exit criteria (“ready to migrate in full”):** All objects described; **§1.5 artifacts on file** (dated CSV or worksheet exports for **A–H** from `inventory_apartmentiq_yardi_matrix_for_dev_facts.sql`, linked from `MIGRATION_LOG.md` or `docs/migration/artifacts/`); **§G** outputs treated as the Matrix **authoritative metric list** with **SOURCE_ENTITY vs TRANSFORM `DATATYPE` diff** recorded; duplicate-grain checks (**§D**, **§G6**) at zero or waiver documented; all producer metrics (wide KPI columns or Matrix `DATATYPE` / combos) cataloged and mapped to governance IDs; sources registered in semantic-layer; smoke clean; log updated — **then** proceed with model/seed moves per `MIGRATION_RULES.md` priority waves.
