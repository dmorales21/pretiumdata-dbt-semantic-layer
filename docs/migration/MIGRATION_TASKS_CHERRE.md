# Cherre — migration prep + product “hope list” attributes

**Owner:** Alex (typed **`FACT_*` / `CONCEPT_*`**); **Jon** owns **`TRANSFORM.CHERRE`** physical tables — read via `source()` only.  
**Governing reads:** `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1–2, `MIGRATION_RULES.md`, **this repo** `models/sources/sources_cherre_transform.yml` (`source('cherre_transform', …)`). Legacy pretium-ai-dbt `sources.yml` is context-only — not the write canon.

**Related tasks:** **`T-VENDOR-CHERRE-READY`** (this doc), **`T-CORRIDOR-CHERRE-TAX-ASSESSOR-STOCK-READY`**, **`T-ANALYTICS-FACTS`** / **`T-ANALYTICS-FEATURES`** (H3 MF tier), **`T-STRATA-TRANSFORM-VENDOR-READS`** (observe).  
**Registry / Presley:** `MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md` (CHERRE datasets), `PRESLEY_REGISTRY_REQUIRED_FACT_TABLES.md` (Cherre hex snapshots).

---

## 0. Semantic-layer dbt registration (this repo — validated contract)

| Layer | Object | Role |
|-------|--------|------|
| **Config** | `dbt_project.yml` → `models.transform.dev.cherre` | **`+database: TRANSFORM`**, **`+schema: DEV`**, **`+materialized: view`**, tags `transform` / `transform_dev` / `cherre` / `cherre_read_surface` (same pattern as `bps` / `irs` / `zillow`-family dev facts). |
| **Sources** | `models/sources/sources_cherre_transform.yml` → `source('cherre_transform', …)` | **`TRANSFORM.CHERRE`** read-only; tables registered: **`RECORDER_V2_WITH_GEO`**, **`TAX_ASSESSOR_V2_SNAPSHOT`**, **`TAX_ASSESSOR_GEO_STATS`**, **`USA_AVM_GEO_STATS`**, **`MLS_LISTING_EVENTS`**, **`USA_DEMOGRAPHICS_V2`**. This repo does not write to **`TRANSFORM.CHERRE`**. |
| **Models** | `models/transform/dev/cherre/*.sql` | Four passthrough **views** with Snowflake aliases **`CHERRE_*`**: `cherre_recorder_v2_with_geo`, `cherre_tax_assessor_v2_snapshot`, `cherre_tax_assessor_geo_stats`, `cherre_avm_geo_stats` — each **`select *` from** the matching **`source('cherre_transform', …)`** only. |
| **Schema docs** | `models/transform/dev/cherre/schema.yml` | Model descriptions + tags (no column tests yet — acceptable for thin passthroughs). |
| **Catalog seeds** | `seeds/reference/catalog/dataset.csv` **DS_025–DS_030** | Primary **promoted** `TRANSFORM.CHERRE` datasets (MLS, recorder sales/mortgages, assessor parcel **TAX_ASSESSOR_V2**, AVM **USA_AVM_V2**, demographics). Passthrough views above are **supporting / rollup / geo** surfaces (Dynamic Tables in typical accounts); they are not duplicate dataset rows until you add explicit **`dataset_id`** / metric rows for those physical names. |
| **Separate read path** | `models/sources/sources_transform.yml` → **`source('transform_fact', 'cherre_*_all_ts')`** | Jon **`TRANSFORM.FACT`** grain objects for **analytics** lineage — **not** the same as **`cherre_transform`** warehouse silver. Prefer **`cherre_transform`** + **`ref('cherre_*')`** for **`TRANSFORM.CHERRE`**-native reads in new **`TRANSFORM.DEV`** work. |

**Compile:** `dbt compile --select path:models/transform/dev/cherre` succeeds when the profile resolves (Snowflake login may warn on SSL in some local setups).

---

## 1. Migration prep checklist (complete before “Cherre migrated”)

| # | Gate | Evidence |
|---|------|----------|
| 1 | **Physical home** | `SHOW TABLES IN SCHEMA TRANSFORM.CHERRE` matches baseline (~14 promoted objects, account-dependent). |
| 2 | **dbt `source()`** | Semantic-layer `source('cherre_transform', …)` resolves to **TRANSFORM.CHERRE** for the migration role; legacy share paths in pretium-ai-dbt are read for inventory only until fully retired. |
| 3 | **No duplicate read path** | Prefer **`TRANSFORM.CHERRE.*`** over **`RAW.CHERRE.*`** per baseline doc; document any interim `TRANSFORM.DEV` sample models as non-canonical. |
| 4 | **REFERENCE.GEOGRAPHY** | All rolled-up **`FACT_CHERRE_*`** join keys (`county_fips`, `cbsa_id`, `GEO_ID` / H3) documented against **`REFERENCE.CATALOG.geo_level`** — not ad hoc vendor strings. |
| 5 | **Catalog datasets** | Semantic-layer **`REFERENCE.CATALOG.dataset`** rows **DS_025–DS_030** (`cherre_*`) stay aligned with promoted `TRANSFORM.CHERRE` table names and grains. |
| 6 | **pretium-ai-dbt `dim_dataset_config`** | **CHERRE** `dataset_id` rows (10) point at the same physical tables you will not break during port. |
| 7 | **Corridor Ward** | **`TAX_ASSESSOR_V2`** → **`TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8`** smoke + segment cardinality (`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md` §3). |
| 8 | **Concept-method backlog** | `MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md` P3a / P4a / P5a–b (MLS, recorder, AVM, stock snapshots) have owners and test stubs before production flip. |
| 9 | **Strata / tearsheet consumers** | `MIGRATION_TASKS_STRATA_BACKEND_LINEAGE.md` + `MIGRATION_TASKS_TEARSHEET_SERVICE.md` Cherre mart rows either re-homed to **`TRANSFORM.DEV`** facts or marked legacy. |

**Inventory SQL (optional):** extend `scripts/sql/migration/` with a Cherre-specific `DESCRIBE` + row-count smoke mirroring other vendor inventories when you open the warehouse window.

---

## 2. Hope list ↔ Cherre (non-deal market / reference only)

**Rule:** Rows below are **geo × time × segment** (or **parcel-universe facts** without Pretium `deal_id`). Anything **keyed to internal deal / IC / UW overrides** stays out of this table.

### 2.1 Scope — Admin & screening

| Hope (examples) | Cherre primary objects | Attributes / signals to preserve in migration |
|-----------------|--------------------------|--------------------------------------------------|
| CBSA / county / place / ZCTA context | **`USA_DEMOGRAPHICS_V2`**, assessor rollups | Tract / county / CBSA join keys; **do not** treat assessor ZIP as USPS without crosswalk. |
| H3 / hex market tiles | **`FACT_CHERRE_STOCK_H3_R8`**, **`FACT_CHERRE_*_H3_R8_*`** | `H3_CELL`, vintage, **SFR/MF/vacant** segment flags; unit counts **at market grain** only. |
| Investable universe / tier inputs (policy-driven) | Assessor + MLS aggregates | Land / improvement value bands, use codes, year-built cohorts for **screening rules** — not user starred lists. |

### 2.2 Assess — demand, supply, labor context

| Hope | Cherre objects | Attributes |
|------|----------------|------------|
| Demographics / affordability **backdrop** | **`USA_DEMOGRAPHICS_V2`**, tract rollups | Income, age, tenure, education, household counts — **market** slice; align or de-duplicate vs **ACS** where both exist. |
| **Stock / pipeline / deliveries** context | **`TAX_ASSESSOR_V2`**, MLS listing history | Unit count, building type, status fields that feed **market** stock and pipeline metrics (not subject lease-up narrative). |
| Labor access (where you blend Cherre) | Usually **LODES/BLS**, not core Cherre | If Cherre demo includes **employment** proxies, document overlap with ACS to avoid double-counting. |

### 2.3 Price — market defaults & capital context

| Hope | Cherre objects | Attributes |
|------|----------------|------------|
| Market rent / value **indices** | **`USA_AVM_V2`**, AVM county/H3 monthly facts | Model vintage, value estimate, month; **median / percentile** aggregates — not subject AVM for pricing a specific deal. |
| Market **vacancy / absorption** proxies | MLS hex/county monthly (`FACT_CHERRE_MLS_H3_R8_MONTHLY` lineage) | Active listing counts, DOM, list price where licensed for **market** absorption. |
| Cap / pricing **reference** (where modeled from recorder) | **`RECORDER_V2`** aggregates | Arms-length sale price distributions; recording lag metadata. |

### 2.4 Comp — comparable universe

| Hope | Cherre objects | Attributes |
|------|----------------|------------|
| **Parcel / assessor** universe | **`TAX_ASSESSOR_V2`** | Parcel id, lat/long, land/improvement values, sqft, use, year built, owner **type** (avoid PII in shared marts). |
| **Recorded transactions** | **`RECORDER_V2`** | Sale date, price, deed type, multi-parcel flags, arms-length filters. |
| **Mortgage / lien context** (market norms) | **`RECORDER_MORTGAGE_V2`** | Loan amount distribution, lender category **aggregates** — not subject loan quote. |
| **MLS lease / list comps** | **`MLS_LISTING_EVENTS`** (share table name per account) | List price, status, property type, geo keys — **not** promoted working-set weights. |

### 2.5 Trade — execution context (light)

| Hope | Cherre | Notes |
|------|--------|-------|
| Seasonality / volume context | Recorder + MLS **market** time series | Cherre is secondary to **FRED / issuance** feeds; use Cherre only where you expose **market** transaction volume. |

### 2.6 Manage — benchmarks & alerts

| Hope | Cherre objects | Attributes |
|------|----------------|------------|
| Actual vs thesis **market** benchmarks | Same series as Assess/Price at **geo × month** | Version / refresh date on AVM and MLS so “stale market” alerts are explainable. |
| Reference anomalies | MLS spike / recorder drop detectors | Row-count QA at county or H3 grain. |

### 2.7 Fund — pacing & concentration (reference only)

| Hope | Cherre | Notes |
|------|--------|-------|
| **MSA / geo weights** in anonymized benchmarks | County/CBSA rollups of stock / deliveries | Use **published** segment definitions; do not embed **fund mandate** in Cherre facts. |

---

## 3. `TRANSFORM.CHERRE` — typical promoted tables (verify in your account)

Use as the checklist for **`source()`** registration in **pretiumdata-dbt-semantic-layer** `models/sources/sources_cherre_transform.yml` when you port reads:

| Table (pattern) | Dataset seed (semantic layer) | Primary hope-list tabs |
|-----------------|--------------------------------|-------------------------|
| `TAX_ASSESSOR_V2` | DS_028 | Scope, Assess, Comp, Fund |
| `USA_AVM_V2` | DS_029 | Price, Assess, Manage |
| `MLS_LISTING_EVENTS` (or licensed variant) | DS_025 | Assess, Price, Comp |
| `RECORDER_V2` | DS_026 | Price, Comp, Trade (volume) |
| `RECORDER_MORTGAGE_V2` | DS_027 | Comp, Price (leverage context) |
| `USA_DEMOGRAPHICS_V2` | DS_030 | Assess, Scope |

### 3.1 Dynamic tables in `TRANSFORM.CHERRE` (verify in your account; not asserted in repo DDL)

**pretium-ai-dbt** and this doc treat **`TRANSFORM.CHERRE.*`** as the **canonical warehouse read** for promoted Cherre landings. They may be implemented as **base tables**, **views**, or **Snowflake Dynamic Tables** depending on DE / platform DDL. The repo does **not** embed `CREATE DYNAMIC TABLE` for Cherre; **confirm type** before assuming refresh semantics.

**Discover the physical kind (run as migration role):**

```bash
snowsql -c pretium -f scripts/sql/migration/list_cherre_transform_dynamic_tables.sql
```

```sql
SHOW TABLES IN SCHEMA TRANSFORM.CHERRE;
SHOW DYNAMIC TABLES IN SCHEMA TRANSFORM.CHERRE;
SELECT table_name, table_type
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'CHERRE'
ORDER BY 1;
```

**Account snapshot (2026-04-19, `pretium` profile):** `INFORMATION_SCHEMA.TABLES` listed **14** `CHERRE` relations, all **`BASE TABLE`**. **`SHOW DYNAMIC TABLES IN SCHEMA TRANSFORM.CHERRE`** returned **four** Dynamic Tables: **`RECORDER_V2_WITH_GEO`**, **`TAX_ASSESSOR_GEO_STATS`**, **`TAX_ASSESSOR_V2_SNAPSHOT`**, **`USA_AVM_GEO_STATS`** (the remaining promoted objects in that schema are regular base tables refreshed outside the DT catalog UI). **`TAX_ASSESSOR_V2_SNAPSHOT`** was **`SUSPENDED`** / **`INCREMENTAL`** at snapshot time—re-check **`scheduling_state`** before relying on freshness.

**If the relation is a Dynamic Table — consumer rules**

| Topic | Instruction |
|-------|----------------|
| **Read contract** | Query with **`SELECT` only**. Do not `INSERT` / `MERGE` / `DELETE` into the DT. Typed facts (`TRANSFORM.DEV.FACT_CHERRE_*`, marts) are the right place for derived persistence. |
| **Staleness** | Freshness follows DE’s **`TARGET_LAG`** / warehouse schedule and upstream health. For analytics, pair reads with vendor timestamps already on the row (**`DATA_PUBLISH_DATE`**, **`CHERRE_INGEST_DATETIME`**, event dates)—not **`CURRENT_TIMESTAMP()`** alone as a “freshness proof.” |
| **Cost and warehouse** | Dynamic Tables consume credits on **refresh** and on **initial/full** rebuilds. In exploratory SQL, **filter early** (e.g. `county_fips`, `date_reference` / month, `tax_assessor_id`, `cc_list_id`) and use **`SAMPLE`** on huge objects (e.g. **`USA_AVM_V2`**) so ad hoc work does not force unnecessary full scans of the DT’s query definition. |
| **Operational checks** | Use **`DESCRIBE DYNAMIC TABLE TRANSFORM.CHERRE.<NAME>`** (or Snowsight lineage) to see **upstream objects** and refresh state. If upstream is renamed or grants break, the DT **suspends** until DE repairs—surface that in runbooks alongside `FACT_*` smoke tests. |
| **dbt** | Canonical reads: **`models/sources/sources_cherre_transform.yml`** + **`ref('cherre_*')`** passthrough views under **`models/transform/dev/cherre/`** (physical **TRANSFORM.DEV** only). Swapping table → Dynamic Table behind the same Snowflake name should not require SQL changes—only catalog / dataset notes if governance changes. |

**If the relation is a normal table or view**

Same hope-list and **`DS_025`–`DS_030`** mapping as §3; prefer **`TRANSFORM.CHERRE`** over **`RAW.CHERRE`** per **`MIGRATION_BASELINE_RAW_TRANSFORM.md`**.

---

## 4. Internal / deal (explicitly **not** Cherre migration targets for shared marts)

- Pretium **`deal_id`**, IC memo fields, **shortlist** membership, **corridor** custom polygons, **UW** growth / cap-rate **overrides**, **promoted comp sets**, **asset manager** tasks.  
- These may **join** to Cherre facts but should live in **OpCo / internal** tables or **`SERVING`** views — not in vendor-agnostic **`TRANSFORM.DEV.FACT_CHERRE_*`** definitions.

---

## 5. Follow-up (optional)

- Map each tab above to **named `object_name`** rows in Presley / Strata when you open **`docs/guide_snowflake_architecture.md`** (if present in your branch) — keep one column **`vendor_code` = `cherre`** on long-form facts for registry joins.
