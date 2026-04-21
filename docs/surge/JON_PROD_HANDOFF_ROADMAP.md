# PROD handoff roadmap — Jon (`TRANSFORM.[VENDOR]` and upstream ingest)

**Audience:** **Jon** — Snowflake owner of the **vendor canonical PROD** layer **`TRANSFORM.[VENDOR]`** and promotion from **`SOURCE_PROD`** landings, per [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md) and [`../OPERATING_MODEL.md`](../OPERATING_MODEL.md).

**Alex’s scope (this repo):** build **`TRANSFORM.DEV`** **`FACT_*` / `CONCEPT_*` / `REF_*`**, **`REFERENCE.*`**, and **`ANALYTICS.DBT_*`** — **read** Jon’s PROD schemas, **do not** author dbt writes into **`TRANSFORM.[VENDOR]`**.

---

## 1. Why this handoff exists

Today many **`FACT_*`** models read **`SOURCE_PROD.[VENDOR].RAW_*`** directly when **`TRANSFORM.[VENDOR]`** is not yet available. That is an **intentional dev path**, not the end state.

**End state:** Alex **`FACT_*`** should **`ref()`** (or `source()`) **Jon-cleansed** tables in **`TRANSFORM.[VENDOR]`** once those objects exist and grants are stable. Vendor-specific **crosswalks** promoted by Jon move from Alex’s **`TRANSFORM.DEV` `REF_*`** into **`TRANSFORM.[VENDOR]`** as Jon’s canonical tables.

---

## 2. Promotion sequence (recommended)

| Step | Jon action | Unblocks |
|------|------------|----------|
| **J0 — Landings** | Ensure **`SOURCE_PROD.[VENDOR].RAW_*`** contracts match ingest (column renames, PII boundaries) | Alex `source()` declarations compile |
| **J1 — Cleanse silver** | Ship typed cleanse / silver tables to **`TRANSFORM.[VENDOR]`** with stable keys and date grains | Alex re-points **`FACT_*`** reads off RAW-only paths |
| **J2 — Crosswalks** | Promote vendor xwalks (metro → CBSA, vendor geo IDs, …) to **`TRANSFORM.[VENDOR]`** | Metric registration **census / geo compliance**; fewer ad-hoc joins in **`FACT_*`** |
| **J3 — Grants + contract tests** | Document primary keys, refresh cadence, breaking-change policy | Downstream QA (`QA_*`) and serving demos |
| **J4 — Optional: TRANSFORM.FACT** | Future canonical fact schema (not Alex-owned today) | Long-term retirement of duplicate **`TRANSFORM.DEV`** paths per architecture rules |

**TRANSFORM.FACT:** Architecture rules state **`TRANSFORM.FACT` does not yet exist** and is **Jon’s** canonical promotion target when built — Alex does not create it.

---

## 3. Vendor clusters waiting on PROD parity (engineering view)

Use **[`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md)** for live status. Representative **`T-VENDOR-*-READY`** rows that typically need **`TRANSFORM.[VENDOR]`** readiness before Alex can declare migration done:

- ApartmentIQ, Yardi Matrix, Yardi operational (BH / Progress)
- CoStar, Cherre, First Street, RCA / MSCI
- Redfin, Stanford
- (Government stacks often read **`TRANSFORM.BLS`**, **`TRANSFORM.CENSUS`**, **`TRANSFORM.LODES`**, **`TRANSFORM.BPS`** — already part of Jon’s world; Alex facts already reference those where declared in sources)

Each vendor doc under **`docs/migration/MIGRATION_TASKS_*.md`** lists **inventory SQL**, smoke gates, and catalog dataset rows (`DS_*`) to coordinate.

---

## 4. Geography boundary (avoid rework)

- **Jon / REFERENCE.GEOGRAPHY (Cybersyn spine via Jon path in matrix):** per [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md), non-vendor census spine stays out of vendor schemas.
- **Vendor-specific geo normalization** belongs in **`TRANSFORM.[VENDOR]`** (or temporarily **`TRANSFORM.DEV` `REF_*`**).

If Jon promotes a table that duplicates a **`REFERENCE.GEOGRAPHY`** concern, flag it early — Alex cannot place vendor logic in **`REFERENCE.GEOGRAPHY`**.

---

## 5. Communication protocol (surge week)

1. **Before Jon ships a breaking rename** on a table Alex reads: post the old/new FQN pair in the migration batch notes (or internal channel) so Alex updates `sources_*.yml` in the same merge window.
2. **After Jon promotes cleanse tables:** Alex opens a focused PR to switch `FACT_*` from `RAW_*` to **`TRANSFORM.[VENDOR]`** and logs the batch in [`../migration/MIGRATION_LOG.md`](../migration/MIGRATION_LOG.md).
3. **Metric registration** waits on stable physical `table_path` values — coordinate when Jon moves a feed from DEV-only RAW to PROD silver.

---

## 6. Related Jon-facing artifacts

- Yardi batch runbook / reconciliation: [`../migration/artifacts/batch012_yardi/`](../migration/artifacts/batch012_yardi/)
- Baseline RAW vs TRANSFORM homes: [`../migration/MIGRATION_BASELINE_RAW_TRANSFORM.md`](../migration/MIGRATION_BASELINE_RAW_TRANSFORM.md)
- Vendor design principles (cleansed layer expectations): [`../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md`](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)
