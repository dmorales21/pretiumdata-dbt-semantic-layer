# Migration readiness — `TRANSFORM.YARDI` (BH + Progress operational silver)

**Owner:** Alex ( **`TRANSFORM.YARDI`** landings **Jon**; **`TRANSFORM.DEV` `FACT_*`** **Alex**)  
**Governing docs:** `MIGRATION_RULES.md`, `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1–2, pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md`  
**Purpose:** Gate **full** migration of **operational** Yardi PMS silver by inventorying **every** `TRANSFORM.YARDI` object, **parallel `*_BH` vs `*_PROGRESS`** tables, keys, status uniques, and ledger metrics **before** modeling `TRANSFORM.DEV.FACT_*` or re-pointing consumers off legacy **`DS_SOURCE_PROD_YARDI*`** / **`yardi_bh` / `yardi_progress`** shares.

**Not in scope here (separate tasks):**

- **`TRANSFORM.YARDI_MATRIX`** — market/submarket performance ( **`T-VENDOR-YARDI-MATRIX-READY`** in `MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md` ).
- **`TRANSFORM_PROD.CLEANED` / `FACT` Yardi chains** — Jon PROD cleanse; **do not duplicate**; align with **`T-TRANSFORM-PROD-CLEANED`** in `MIGRATION_TASKS.md`.

**Parallel OpCo naming (single schema):** All silver lives under **`TRANSFORM.YARDI`**. **BH** tables use the **`_BH`** suffix; **Progress Residential** uses **`_PROGRESS`**. Same conceptual object (property, unit, tenant, ledger) exists in **two** tables — migration and `FACT_*` design must treat them as **symmetric** unless a deliberate asymmetry is documented (e.g. `UNITTYPE_PROGRESS` only on Progress).

**Task ID (update status in `MIGRATION_TASKS.md`):**

| Task ID | Scope | Status |
|---------|--------|--------|
| **T-VENDOR-YARDI-READY** | **`TRANSFORM.YARDI`** `*_BH` + `*_PROGRESS` + pretium-ai-dbt Yardi consumers | `pending` |

**Baseline snapshot note:** `MIGRATION_BASELINE_RAW_TRANSFORM.md` lists **~15** objects under `TRANSFORM.YARDI`. pretium-ai-dbt `source('transform_yardi', …)` currently declares **10** tables — treat baseline + **`INFORMATION_SCHEMA`** as authoritative; extend `sources.yml` when Snowflake has objects not yet declared.

**Semantic-layer landing (batch 012):** **`pretiumdata-dbt-semantic-layer`** now has **`models/transform/dev/fund_opco/`** `FACT_PROGRESS_YARDI_PROPERTY` / `FACT_BH_YARDI_PROPERTY` / unit / ledger tables reading **`models/sources/sources_transform_yardi_opco.yml`** plus legacy **`yardi_bh.TRANS`** for BH ledger (`sources_yardi_bh_legacy.yml`). This is a **pilot slice** — keep **`T-VENDOR-YARDI-READY`** **`pending`** until §1–2 / §1.5 exit criteria close.

---

## 0. Preconditions

- [ ] **Role:** Migration role can `SELECT` all **`TRANSFORM.YARDI.*`** objects used by **`fact_bh_*`**, **`fact_progress_*`**, and cleaned paths; log grant gaps in **`MIGRATION_LOG.md`**.
- [ ] **PII / ops sensitivity:** Property, unit, tenant, and ledger tables are **high sensitivity** — document masking and **`SERVING`** rules before any demo exposure.
- [ ] **Legacy shares:** `yardi_bh`, `yardi_progress`, legacy `yardi` alias (`DS_SOURCE_PROD_YARDI*`) — inventory which models still read them vs **`source('transform_yardi', …)`**; plan cutover per `CLEANED_SOURCE_AND_MODEL_DB.md` / compliance doc.

---

## 1. Authoritative object inventory

- [ ] Run **`scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql`** blocks **A–B** (and **C–J** as needed).
- [ ] Reconcile **`INFORMATION_SCHEMA`** table list to pretium-ai-dbt **`transform_yardi`** in `dbt/models/sources.yml` (add missing **`TRANS_BH`**, **`UNITTYPE_BH`**, or others if present in Snowflake only).
- [ ] **Symmetric pairs:** for each logical entity (property, unit, unit status, tenant, transaction ledger), confirm **both** OpCo tables exist when expected, or document **intentional** BH-only / Progress-only gaps.

---

## 1.5 Pre-`FACT_*` modeling — query **all** objects and **uniques** (required)

**Operational note:** Run **§A → §B** first and export. If **§H** or **§I** fails to compile, align column names from **§B** (same workflow as other vendor inventory workbooks).

**Canonical script:** `pretiumdata-dbt-semantic-layer/scripts/sql/migration/inventory_yardi_bh_progress_for_dev_facts.sql`

| Block | What it records | Why it matters for `FACT_*` |
|-------|------------------|------------------------------|
| **A–B** | Tables + columns for **`TRANSFORM.YARDI`** | Confirms drift vs YAML; surfaces rename before **`FACT_*`**. |
| **C** | Row counts per core table (BH + Progress pairs + **`TRANS_BH`**) | Capacity; pairs **BH vs Progress** row ratios sanity-check. |
| **D–F** | Duplicate checks on **`HMY`** (property / unit), **`HMYPERSON`** (tenant), **`HMY`** (transaction id) | Natural keys for asset / ledger **`FACT_*`**. |
| **G** | **`SSTATUS`** (or equivalent) uniques on **`UNIT_*`** | Inventory / occupancy-style metrics. |
| **H** | **`UNIT_STATUS_*`** time spine + optional duplicate-grain template | History tables drive weekly / monthly rollups (`UNIT_STATUS_BH` / `_PROGRESS`). |
| **I** | **`TRANS_BH` / `TRANS_PROGRESS`** — post-date spine, **`VOID`**, **`ITYPE`** (or equivalent) cardinality | Feeds **`fact_bh_financials_monthly`**, delinquency, Progress mirrors — **metric taxonomy** for cashflow facts. |
| **J** | Property geo — distinct **state**, **ZIP** pattern | CBSA bridge and **`REFERENCE.GEOGRAPHY`** joins. |

**Deliverables (store with `MIGRATION_LOG.md` or `docs/migration/artifacts/`):**

- [ ] **Pilot folder:** `docs/migration/artifacts/batch012_yardi/` — **`RUNBOOK.md`**, §A–B split scripts (`inventory_yardi_batch012_section_a_tables.sql`, `inventory_yardi_batch012_section_b_columns.sql`), **`TRANSFORM_YARDI_SOURCE_RECONCILIATION.md`** (batch **012b**).
- [ ] Dated CSV / worksheet exports for **A–B** and **C–J** outputs.
- [ ] **Pair comparison sheet:** for each parallel table pair, row count + key null rates + “symmetric columns?” (yes / drift).
- [ ] **Ledger metric list:** distinct transaction type / charge dimensions from **§I** to map to **`metric_code`** / governance (no duplicate semantics across BH vs Progress unless OpCo-specific is explicit).

---

## 2. Column-level review (every object)

For each **`TRANSFORM.YARDI`** table:

- [ ] `DESCRIBE TABLE` — confirm **`HMY`**, **`HPROPERTY`**, **`HUNIT`**, **`HPROP`**, **`UPOSTDATE`**, **`SDATEOCCURRED`** (BH Progress differences documented in `fact_bh_financials_monthly` / `fact_progress_financials_monthly` comments).
- [ ] **Grain** per consumer fact: e.g. `(property_id, post_month)` from ledger; `(unit_id, week)` from rent-ready paths.
- [ ] **Join graph:** `TRANS_*` → **`UNIT_*`** → **`PROPERTY_*`** (note **`TRANS_PROGRESS`** uses **`HPROP`** not **`HPROPERTY`** per analytics model comments).

---

## 3. Catalog and dataset alignment

- [ ] **`REFERENCE.CATALOG` `dataset.csv`:** **`DS_063`** (Progress), **`DS_064`** (BH) — refresh **`coverage_pct`**, **`pipeline_status`**, row-count notes after §1.5.
- [ ] **`opco_code`** on dataset rows vs actual table suffixes (**`progress`**, **`bh`**) — must stay consistent with `opco` seed.

---

## 4. Semantic-layer sources

- [ ] Register **`TRANSFORM.YARDI`** tables in **pretiumdata-dbt-semantic-layer** `models/sources/*.yml` when first consumer compiles there — until then, pretium-ai-dbt **`transform_yardi`** is the contract of record; **no silent second definition**.

---

## 5. Downstream consumers (grep before cutover)

- [ ] pretium-ai-dbt: **`fact_bh_*`**, **`fact_progress_*`**, **`fact_housing_*yardi*`**, **`cleaned_yardi_*`**, **`yardi_*`**, **`dev_yardi_*`**, rent-ready **`mart_yardi_*`**, **`ref_property_canonical_yardi_xwalk`**.
- [ ] Strata / tearsheet: any **`TRANSFORM.YARDI`** literal in app SQL — list and migrate to **`source()`** or documented compat view.

---

## 6. Quality gates

- [ ] **Smoke:** `SELECT 1` from **every** table in **`TRANSFORM.YARDI`** inventory list (migration role).
- [ ] **Parity:** spot-check row counts vs **`DS_063` / `DS_064`** narrative; document order-of-magnitude deltas.
- [ ] **Weekly / incremental facts:** if **`transform_yardi_*_weekly_facts_enabled`** (or similar) toggles exist in `dbt_project.yml`, document dependency on **`UNIT_STATUS_*`** freshness.

---

## 7. Log and exit criteria

- [ ] **`MIGRATION_LOG.md`:** run date, table count, BH vs Progress coverage, blockers, PII notes.
- [ ] **`T-VENDOR-YARDI-READY`** → `migrated` only when §1–2, §1.5, §3, §6 are complete and downstream list in §5 is triaged.

**Exit criteria (“ready to migrate in full”):** All **`TRANSFORM.YARDI`** objects described; **§1.5 artifacts on file** (dated CSV exports for workbook **A–J**, linked from **`MIGRATION_LOG.md`** or **`docs/migration/artifacts/`**); duplicate-key checks (**§D–F**, **§H**) and transaction **HMY** uniqueness (**§I**) at zero or waiver documented; **`sources.yml`** matches Snowflake; catalog datasets updated; smoke clean — **then** implement or move **`TRANSFORM.DEV` `FACT_*`** per **`MIGRATION_RULES.md`**.
