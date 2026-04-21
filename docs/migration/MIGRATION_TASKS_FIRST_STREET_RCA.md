# Migration readiness — First Street (`TRANSFORM.FIRST_STREET` + `SOURCE_PROD.FIRST_STREET`) and RCA / MSCI (`TRANSFORM.RCA` + share)

**Owner:** Alex  
**Governing docs:** `MIGRATION_RULES.md`, `MIGRATION_BASELINE_RAW_TRANSFORM.md`, pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md`  
**RCA canonical modeling plan (read first):** pretium-ai-dbt **`docs/governance/RCA_DATA_MODELING_PLAN_TRANSFORM_RCA.md`**

**Task IDs (update `MIGRATION_TASKS.md`):**

| Task ID | Scope | Status |
|---------|--------|--------|
| **T-VENDOR-FIRST-STREET-READY** | **`TRANSFORM.FIRST_STREET`** historic + climate objects; **`SOURCE_PROD.FIRST_STREET`** climate load | `pending` |
| **T-VENDOR-RCA-READY** | **MSCI share** + **`TRANSFORM_PROD.CLEANED.CLEANED_RCA_*`** + **`TRANSFORM.RCA`** pass-through views; dbt `transform_rca` + seeds/tests | `pending` |

---

## Part A — First Street

### A0. Physical homes

| Location | Role |
|----------|------|
| **`TRANSFORM.FIRST_STREET`** | Historic fire / flood / wind + **`CLIMATE_RISK`** (ZIP pivoted risk tall). |
| **`SOURCE_PROD.FIRST_STREET`** | Climate ZIP loads (`first_street_load`, etc.) per `sources.yml` — not the same objects as historic tables. |

### A1. Object inventory

- [ ] Run **`scripts/sql/migration/inventory_first_street_rca_for_dev_facts.sql`** blocks **FS-A / FS-B**.
- [ ] Reconcile to pretium-ai-dbt `source('first_street_historic', …)` and `source('first_street', …)`.

### A1.5 Uniques and grain (required before new `FACT_*`)

- [ ] Execute **FS-C–FS-E** in the inventory script (row counts, duplicate `(ZIPCODE, EVENT_ID)` where applicable, **`CLIMATE_RISK`** `(ZIPCODE, RISK_TYPE)` duplicate check).
- [ ] Archive CSV outputs under `docs/migration/artifacts/` and link from **`MIGRATION_LOG.md`**.

### A2. **Documented vs physical vs consumed** (historic tables)

`dbt/models/sources.yml` documents a **minimal** column list for historic tables. The **cleaned** models read **additional** columns from **`TRANSFORM.FIRST_STREET`**. If those columns are missing in Snowflake, cleaned models fail at runtime.

| Source object | Column / group | In `sources.yml` column list? | **Required** by cleaned model (grep `cleaned_first_street_historic_*`) |
|---------------|----------------|------------------------------|------------------------------------------------------------------------|
| **`historic_fire_events`** | `ZIPCODE`, `EVENT_ID`, `EVENT_NAME`, `EVENT_YEAR`, `EVENT_MONTH`, `AREA`, `AFFECTED_PROPERTIES`, `LOAD_DATE` | Yes (partial) | Also uses **`CBSA`**, **`STATE`**, **`CITY`**, **`RISK_TYPE`**, **`EVENT_NEARBY_PROPERTIES`**, **`EVENT_AFFECTED_PROPERTIES`** — **not** listed under fire in YAML today → treat as **physical-verify required**. |
| **`historic_flood_events`** | ZIP / event / month / year / name / affected / `LOAD_DATE` | Yes (partial) | Also **`CBSA`**, **`STATE`**, **`CITY`**, **`RISK_TYPE`**. |
| **`historic_wind_events`** | ZIP / event / year / month / `EVENT_DATE`, `EVENT_TYPE`, `DAMAGES`, `LOAD_DATE` | Yes (partial) | Also **`CBSA`**, **`STATE`**, **`CITY`**, **`RISK_TYPE`**. |

- [ ] **`DESCRIBE TABLE`** each historic table in Snowflake; confirm **every** column in the “Required by cleaned” column exists (case-insensitive).
- [ ] If Snowflake has columns **not** in YAML, extend **`sources.yml`** (or semantic-layer sources) for contract clarity.

### A3. `CLIMATE_RISK`

- [ ] Confirm **`RISK_TYPE`** domain (flood, fire, heat, wind, air) and row multiple per ZIP.
- [ ] Align **`sources.yml`** “37 columns” narrative with **`DESCRIBE`**; map to **`fact_first_street_climate_risk_*`** snapshot models.

### A4. Exit (First Street)

- [ ] Smoke `SELECT 1` on all **`TRANSFORM.FIRST_STREET`** inventory tables.
- [ ] **`T-VENDOR-FIRST-STREET-READY`** → `migrated` when A1–A3 + artifacts complete.

---

## Part B — RCA / MSCI (`TRANSFORM.RCA`)

### B0. Architecture (from `RCA_DATA_MODELING_PLAN_TRANSFORM_RCA.md`)

1. **MSCI imported database** (name may vary): secure views under **`REAL_ESTATE`** (e.g. `RCA_PRETIUM_TRANSACTION` ~**235** columns per plan snapshot).
2. **`TRANSFORM_PROD.CLEANED`:** **`CLEANED_RCA_*`** pass-throughs + **`CLEANED_RCA_RECORDER_DICTIONARY`** table + dictionary/entity views (**22** baseline consumer objects).
3. **`TRANSFORM.RCA`:** **Pass-through views** over **`TRANSFORM_PROD.CLEANED`** — see pretium-ai-dbt **`scripts/sql/rca/16_populate_transform_rca_from_transform_prod_cleaned.sql`** (unprefixed names: `"TRANSACTION"`, `INVESTOR`, `LENDER`, `…_AGGREGATE`, entity views, `RECORDER_DICTIONARY`, `TRANSACTION_DICTIONARY`).
4. **dbt `source('transform_rca', …)`** defaults to **`transform_prod.cleaned`** with identifiers **`CLEANED_RCA_*`** — not the same database/schema as **`TRANSFORM.RCA`**, but **column sets match** for the pass-through chain.

**Implication:** **`TRANSFORM.RCA."TRANSACTION"`** columns = **`CLEANED_RCA_TRANSACTION`** columns = MSCI **`RCA_PRETIUM_TRANSACTION`** projection (minus any DDL drift). There is **no separate** column set for `TRANSFORM.RCA`; field gaps are always **share vs cleaned vs seed catalog** alignment.

### B1. Object inventory

- [ ] Run inventory script **RC-A / RC-B** (tables/views in **`TRANSFORM.RCA`**; optional **`TRANSFORM_PROD.CLEANED`** `CLEANED_RCA_%` list).
- [ ] Confirm **19** views from **`16_populate_*.sql`** exist (or document drift if MSCI/deploy added/removed objects).

### B1.5 Uniques and grains (ledger / bridge design)

- [ ] Run **RC-C–RC-F** (row counts, duplicate checks on keys from modeling plan §5, **`ITYPE`/`STATUS`-style enums** where applicable — adjust column names from **RC-B** `DESCRIBE` if different).
- [ ] Transaction grain: validate **`PROPERTY_ID`**, **`STATUS_DT`**, **`DEAL_ID`**, **`PROPERTYKEY_ID`** non-null rates and duplicate analysis per plan §5.2–5.3.

### B2. **Field alignment — documentation vs `TRANSFORM.RCA`**

Use two layers of truth:

| Layer | Path | Use for |
|-------|------|--------|
| **Semantic glossary** | pretium-ai-dbt `docs/governance/exports/ic_memo_msci_rca_transactions_field_catalog.csv` (+ parser `parse_msci_rca_transactions_dictionary.py`) | Definitions, business names. |
| **Physical columns** | `INFORMATION_SCHEMA.COLUMNS` on **`TRANSFORM.RCA."TRANSACTION"`** (or `TRANSFORM_PROD.CLEANED.CLEANED_RCA_TRANSACTION` if `TRANSFORM.RCA` not deployed) | What you can `SELECT`. |
| **dq / metric seed** | `dbt/seeds/rca/rca_transaction_field_inventory.csv` (~**485** `field_name` rows) | Intended coverage for tests / admin catalog — can be **broader** than the **~235** columns on the Pretium transaction slice (plan §1.1). |

**Modeling-critical fields** (explicitly named in **`RCA_DATA_MODELING_PLAN_TRANSFORM_RCA.md` §5** — verify each exists on physical `"TRANSACTION"` / `INVESTOR` / `LENDER` via `DESCRIBE` or **RC-G** in SQL script):

| Theme | Fields to verify on physical transaction / investor / lender feeds |
|-------|---------------------------------------------------------------------|
| **Asset spine** | `PROPERTYKEY_ID` |
| **Event / deal keys** | `PROPERTY_ID`, `STATUS_DT`, `DEAL_ID`, `PORTFOLIO` (duplicate analysis per §5.2) |
| **Investor bridge** | `PRINCIPAL_ENTITY_ID`, `SUB_ENTITY_ID`, `LEGAL_ENTITY_KEY_ID`, `PROPERTY_KEY_ID`, `PROPERTY_ID`, `DEAL_ID`, `MAX_CHANGED_DT`, `STATUS_DT` |
| **Lending** | `LOAN_ID`, `LOAN_ASSET_ID`, `CURRENT_PROPERTY_ID`, `CURRENT_DEAL_ID`, `ORIGINAL_PROPERTY_ID`, `ORIGINAL_DEAL_ID`, `LOAN_AMT_USD`, `LOAN_ORIGINATION_DT`, LTV/DSCR/rate fields as applicable |
| **Geography (plan wording)** | `RCA_METROS_TX`, `RCA_MARKETS_TX`, `RCA_SUBMARKET_TX` (transaction); `RCA_METRO_TX`, `RCA_MARKET_TX`, `RCA_SUB_MARKET_TX` (investor); `CBD_FG`; lat/long columns as present on feed |

- [ ] Run **RC-G** in **`inventory_first_street_rca_for_dev_facts.sql`**: fields from **`rca_transaction_field_inventory`** seed **not** present as columns on **`TRANSFORM.RCA."TRANSACTION"`** (expected if seed is **superset** of Pretium slice).
- [ ] Run **RC-H**: columns on **`TRANSFORM.RCA."TRANSACTION"`** **not** listed in seed (optional — detects MSCI adds not yet in seed).
- [ ] Record results in **`MIGRATION_LOG.md`** (attach CSV).

### B3. MSCI share vs consumer

- [ ] pretium-ai-dbt **`scripts/sql/transform_rca/discover_rca_snowflake_inventory.sql`** — refresh if share database name changes.
- [ ] Reconcile row counts (plan §1.1 approximates) after major entitlement updates.

### B4. Exit (RCA)

- [ ] Smoke **`TRANSFORM.RCA`** views + dictionary table source.
- [ ] **`T-VENDOR-RCA-READY`** → `migrated` when B1–B3 + **RC-G** catalog diff on file.

---

## Part C — Semantic-layer / dbt

- [ ] Register **`TRANSFORM.FIRST_STREET`** / **`TRANSFORM.RCA`** in **pretiumdata-dbt-semantic-layer** `models/sources/` when first consumer compiles there.
- [ ] **`REFERENCE.CATALOG` `dataset.csv`:** refresh rows tied to First Street / RCA vendors after inventory (coverage, `source_schema`).

---

**Exit criteria (combined doc):** Artifacts on file for **§A1.5** and **§B1.5**; First Street **§A2** column parity verified; RCA **§B2** seed vs physical diff run; logs updated; task statuses flipped in **`MIGRATION_TASKS.md`**.
