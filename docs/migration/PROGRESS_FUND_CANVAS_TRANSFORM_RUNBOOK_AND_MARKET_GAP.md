# Progress fund canvas — TRANSFORM runbook and market-data gap review

This document **operationalizes** the Progress rent / fund-modeling thread (SOURCE_ENTITY.PROGRESS + `TRANSFORM.YARDI` silver where needed) and **maps** that work to the broader **shared market layer** (rent, vacancy, macro, geo) the calculator framing assumes.

**Repos:** implementation lives in **pretiumdata-dbt-semantic-layer** (`models/transform/dev/fund_opco/`, mart `concept_*`). **pretium-ai-dbt** hosts **`vet_source_entity_progress_fund_objects.sql`** (Snowflake column inventory).

---

## A. What to prioritize in TRANSFORM (ordered)

### 1. Access path — `SOURCE_ENTITY.PROGRESS` for the dbt role

**Goal:** The role that runs semantic-layer dbt must see **tables and columns** the models declare (not only `INFORMATION_SCHEMA` empty — see `MIGRATION_LOG` batch **018** vs **020**).

**Actions:**

1. As that role, run **`pretium-ai-dbt/scripts/sql/migration/vet_source_entity_progress_fund_objects.sql`** (adjust schema literal if not `PROGRESS`).
2. Confirm **no missing tables** in the script’s “missing tables” block and that **join-key columns** exist on the landings you will use (at minimum for the property spine and rent concept):
   - **SFDC properties:** `SFDC_PROPERTIES__C` — defaults assume **`PROPERTYNUMBER__C`** (override via `concept_progress_sfdc_yardi_property_code_column`).
   - **Yardi prop attributes:** `YARDI_PROPATTRIBUTES` — defaults assume **`SCODE`**, **`HPROPERTY`** (override `concept_progress_yardi_propattr_property_code_column` for the code side).
   - **Yardi unit type / unit (entity):** `YARDI_UNITTYPE`, `YARDI_UNIT` — `concept_progress_rent` aggregates use **`SCODE`**, **`HPROPERTY`**, **`SRENT`**; vet that these identifiers exist and are populated.
3. If the role sees **0** objects, fix **share / grant** on `SOURCE_ENTITY` (warehouse admin), not dbt.

**dbt var:** `source_entity_progress_schema` (default `PROGRESS`) in **`dbt_project.yml`**.

---

### 2. Materialize the SOURCE_ENTITY read-through layer (`fact_sfdc_*`, `fact_se_yardi_*`)

**Goal:** All **views** under `TRANSFORM.DEV` tagged **`source_entity_progress_fact`** resolve and return expected row shapes.

**Prerequisite:** Step **1** passes for the same role.

**Command (semantic-layer project root):**

```bash
dbt run --selector source_entity_progress_facts \
  --vars '{"transform_dev_enable_source_entity_progress_facts": true}'
```

**Spine + rent concept dependencies (minimum set):**

| Model | Role |
|-------|------|
| `fact_sfdc_properties_c` | SFDC property master for `concept_progress_property` / `concept_progress_rent` |
| `fact_se_yardi_property_attribute` | Yardi prop attributes join to SFDC property code |
| `fact_se_yardi_unit_type_market_rent` | Entity unit-type market rent (`SRENT` roll-ups in `concept_progress_rent`) |
| `fact_se_yardi_unit_master` | Entity unit master (`SRENT` roll-ups by `HPROPERTY`) |

Other **`fact_sfdc_*` / `fact_se_yardi_*`** models are still part of the same batch for **fund allocation, market/submarket, acquisition UW, velocity, disposition/BPO**; run the **full selector** so you do not maintain a partial graph.

---

### 3. Materialize concepts — spine first, then rent

**Goal:** **`concept_progress_property`** (and peers) as **tables** in `TRANSFORM.DEV`, then **`concept_progress_rent`**.

**Prerequisite:** Step **2** completed (or at least the upstream facts for the models you select).

**Commands:**

```bash
# All fund canvas concepts (tag source_entity_progress_concept), including property + rent
dbt run --selector source_entity_progress_concepts \
  --vars '{"transform_dev_enable_source_entity_progress_facts": true}'
```

**Explicit order if you run by name:** `concept_progress_property` (and any facts it refs) **before** `concept_progress_rent`. The rent model **refs** the property concept and entity facts; dbt’s DAG enforces order when you use **`dbt run --select +concept_progress_rent`**.

**Optional Jon silver branch inside `concept_progress_rent`:** averages from **`TRANSFORM.YARDI.UNIT_PROGRESS`** are included only when **`transform_dev_enable_fund_opco_facts`** is true (default **true** in `dbt_project.yml`). That path does **not** use `ref('fact_progress_yardi_unit')` so disabling the fact model does not disable the rent concept; the role still needs **SELECT** on `TRANSFORM.YARDI.UNIT_PROGRESS` if you want non-null silver roll-ups.

---

### 4. Vet join keys once on real landings

**Goal:** Non-empty joins on production-like data; wrong keys produce **orphan SFDC rows** or **false matches**.

**Actions:**

1. After steps **2–3**, profile join cardinality:
   - Count SFDC rows with **non-null** property code vs count of **matched** Yardi prop-attribute rows on the join used in `concept_progress_property`.
   - Spot-check a handful of known **`PROPERTYNUMBER__C` / `SCODE`** pairs.
2. Align **`dbt_project.yml`** vars with vet output:
   - `concept_progress_sfdc_yardi_property_code_column`
   - `concept_progress_yardi_propattr_property_code_column`
   - For acquisition concepts: `concept_progress_fdd_acquisition_fk_column`, `concept_progress_sfdc_acquisition_id_column`
3. For **`concept_progress_rent`**, validate **`HPROPERTY`** alignment between **`yardi_propattr__HPROPERTY`** on the spine and **`HPROPERTY`** on **`fact_se_yardi_unit_master`** / **`fact_se_yardi_unit_type_market_rent`** (and **`UNIT_PROGRESS.HPROPERTY`** for silver).

---

### 5. Broader TRANSFORM backlog — one Yardi story (Jon silver vs SOURCE_ENTITY)

**Task register:** **`MIGRATION_TASKS.md`** — **`T-VENDOR-YARDI-READY`** remains **pending** (Jon **`TRANSFORM.YARDI`** `*_BH` / `*_PROGRESS` parity, inventory artifacts, semantic-layer **`FACT_PROGRESS_YARDI_*` / `FACT_BH_YARDI_*`**).

**Why it matters for “one story”:**

- **SOURCE_ENTITY.PROGRESS** landings (`fact_se_yardi_*`) are **CRM/entity mirrors** for fund tabs and joins to SFDC.
- **Jon silver** (`TRANSFORM.YARDI.*_PROGRESS`, etc.) is **operational** supply / unit / ledger truth for many housing analytics paths.

**Prioritization:** Complete **SOURCE_ENTITY access + batch 024 facts/concepts** for **fund canvas** in parallel with **T-VENDOR-YARDI-READY** checklist (`MIGRATION_TASKS_YARDI_BH_PROGRESS.md`); merge narratives only after **both** roles can SELECT and **join keys** are documented between entity and silver where product requires it.

---

## B. Quick reference — selectors and flags

| Item | Value |
|------|--------|
| Enable SOURCE_ENTITY facts/concepts | `--vars '{"transform_dev_enable_source_entity_progress_facts": true}'` |
| Fact selector | `source_entity_progress_facts` (`tag:source_entity_progress_fact`) |
| Concept selector | `source_entity_progress_concepts` (`tag:source_entity_progress_concept`) |
| Jon fund_opco facts (property/unit/ledger) | `transform_dev_enable_fund_opco_facts` (default true) |

**Selector definitions:** `selectors.yml`.

---

## C. Market data — what is already in vs what still needs to be brought in

This section ties **repo reality** (semantic-layer **mart `concept_*`**, **TRANSFORM.DEV** facts, migration **tasks**) to the **shared market layer** idea (rent, vacancy, supply, affordability, migration, jobs, climate, peer rank). **Progress fund canvas** supplies **asset-level rent and underwriting fields**; it does **not** by itself replace **market** rent indices, demographics, or climate.

### C.1 Already modeled or partially landed (semantic / transform path)

| Area | What exists today (high level) | Notes |
|------|----------------------------------|--------|
| **Market rent (non-Progress vendors)** | **`concept_rent_market_monthly`** | Multi-vendor monthly market rent concept (Zillow, ApartmentIQ, Yardi Matrix, CoStar, Markerr, HUD/Cybersyn, Cherre stub, etc. per model YAML). **Vendor migration tasks** (ApartmentIQ, Yardi Matrix, Yardi opco) largely still **pending** in `MIGRATION_TASKS.md`. |
| **Property rent (non-Progress)** | **`concept_rent_property_monthly`** | ApartmentIQ branch + stubs; depends on **`TRANSFORM.APARTMENTIQ`** readiness. |
| **AVM / valuation market** | **`concept_avm_market_monthly`**, **`concept_valuation_market_monthly`** | Cherre-centric with stubs; not Progress-specific. |
| **Progress asset / fund tab** | **`fact_sfdc_*`**, **`fact_se_yardi_*`**, **`concept_progress_*`**, **`concept_progress_rent`** | **SOURCE_ENTITY** + joins; **effective/asking rent**-like fields from SFDC + entity Yardi + optional **`UNIT_PROGRESS`** contract rent average. **Gated** until grants + `dbt run` with enable var. |
| **Labor / automation (market-relevant)** | **`fact_county_soc_employment`**, **`fact_county_ai_replacement_risk`**, refs (batches **025–026**) | Feeds **jobs / structural risk** strands; **FEATURE/MART calculator overlays** still open per `T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK`. |
| **Geography spine** | **REFERENCE.GEOGRAPHY** + bridge patterns in rent concepts | Used for CBSA/ZIP alignment in market rent/property concepts. |

### C.2 Gaps vs a full “rent + market + macro” calculator spine

Below is a **gap map** (not an instruction to build everything at once). **Progress fund canvas** checks the **left column** for deal-level rent; the **right column** is mostly **separate TRANSFORM/vendor tasks**.

| Calculator-style need (from internal framing) | Satisfied today? | Primary bring-in / unblock |
|-----------------------------------------------|-------------------|----------------------------|
| **Effective / asking rent (asset)** | **Partial** — SFDC + entity Yardi + optional silver unit average via `concept_progress_rent` | Grants + materialize **024**; vet keys; optional **`UNIT_PROGRESS`**. |
| **Effective / asking rent (market)** | **Partial** — `concept_rent_market_monthly` / `concept_rent_property_monthly` | **`T-VENDOR-APARTMENTIQ-READY`**, **`T-VENDOR-YARDI-MATRIX-READY`**, **`T-VENDOR-YARDI-READY`**, Zillow/CoStar/Cherre tasks as needed for vendor depth. |
| **Rent growth trend** | **Gap** at governed **concept** layer for full national stack | Time-series vendors + **FEATURE** / **`T-ANALYTICS-FEATURE-EFFECTIVE-RENT-STACK`**. |
| **Vacancy / absorption / months of supply** | **Gap** in semantic-layer **shared concepts** for Progress-specific canvas | **Jon Yardi** occupancy/supply facts (`T-VENDOR-YARDI-READY`), BPS permits (`T-TRANSFORM-BPS-*`), possibly **`analytics_prod`** market pillars (tasks **T-PROD-FEATURES** / signals) — not in **`concept_progress_rent`**. |
| **Affordability spread / rent burden** | **Gap** as unified **concept** | **ACS / income** (`T-TRANSFORM-CENSUS-ACS5-READY` and consumers), CFPB/Cybersyn where authorized (`T-CYBERSYN-*`). |
| **Population growth / migration** | **Gap** at thin **TRANSFORM.DEV** read-through for many vendors | **LODES** (`T-TRANSFORM-LODES-*`), Census/ACS, Cybersyn population series — corridor tasks. |
| **Job growth / unemployment** | **Partial** — BLS LAUS / QCEW paths in task register | **`T-TRANSFORM-BLS-LAUS-*`**, **`fact_bls_*`**, QCEW consumers; link to **CBSA** carefully (LAUS CBSA ≠ OMB CBSA in docs). |
| **Peer ranking** | **Gap** — typically **MODEL_** / score tier | **Analytics** models (`T-ANALYTICS-MODELS`, **T-PROD-INTEL**), not fund_opco concepts. |
| **Climate risk / score** | **Gap** for **First Street** governed facts | **`T-VENDOR-FIRST-STREET-READY`**. |
| **Valuation calculator (cap, NOI, rates, beta)** | **Partial** — market valuation concept + rates vendors piecemeal | **CoStar**, **RCA**, **Freddie/FHFA**/Treasury proxies — tasks **T-VENDOR-COSTAR-READY**, **T-VENDOR-RCA-READY**, plus explicit **rates** feeds (not covered by Progress canvas). |
| **Fund calculator (concentration, deployment)** | **Partial** — `concept_progress_fund_allocation`, pipeline/portfolio **facts** exist in batch **024** | Materialize facts + concepts; **portfolio math** likely **FEATURE/MODEL** layer. |
| **Underwriting screener (comps, permits, geo buffers)** | **Partial** — acquisition/FDD/BPO **concepts** | **Cherre** stock/MLS (`T-VENDOR-CHERRE-READY`), **BPS permits**, **hex / corridor** tasks for **1/3/5 mi** buffers. |

### C.3 Practical sequencing suggestion

1. **Unblock Progress canvas in TRANSFORM:** steps **A.1–A.4** (this doc).
2. **Feed “market summary” rent/vacancy/supply:** prioritize **`T-VENDOR-YARDI-READY`** + **ApartmentIQ / Matrix** tasks that **`concept_rent_*`** already names.
3. **Feed affordability / migration / jobs:** **ACS5 + LODES + BLS** tasks in **`MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`** (still largely pending).
4. **Feed climate + conviction overlays:** **First Street** + **intel/model** tasks once base market spine is dense enough.

---

## D. Related docs

- `models/transform/dev/fund_opco/README.md` — model table + dbt commands.
- `docs/migration/MIGRATION_TASKS.md` — **T-VENDOR-YARDI-READY**, **T-TRANSFORM-DEV**, analytics tasks.
- `docs/migration/MIGRATION_LOG.md` — batches **024**, **024b**, **024c**, **024d**.
- pretium-ai-dbt `docs/governance/CORRIDOR_PRODUCT_AGNOSTIC_DEV_PIPELINE.md` — corridor vs fund_opco scope split (if linking analytics vs transform dev).
