# Migration registry — **vendors**, **datasets**, and **metrics** to move (pretium-ai-dbt → semantic layer / Alex targets)

**Owner:** Alex  
**Purpose:** One place to see **what must move** across three layers: (1) **vendor / Snowflake homes**, (2) **datasets** (business-named feeds), (3) **metrics** (`metric_id` and catalog registration). This file **indexes** detailed checklists elsewhere; it does not replace **`MIGRATION_TASKS.md`** row-level ownership.

**Governing contract:** pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md` (five-target + `REFERENCE.*`).

**New metrics in REFERENCE.CATALOG:** **[METRIC_INTAKE_CHECKLIST.md](./METRIC_INTAKE_CHECKLIST.md)** — classify native vs derived, register seeds in order, validate dimensionally, log batch. **Canonical `metric.csv` + vendor-by-vendor execution:** **[MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md](./MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md)**. **Features / estimates / four chains:** **[PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](./PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md)**.

---

## 1. How to use this registry

| Layer | What “move” means | Primary sources of truth |
|-------|-------------------|---------------------------|
| **Vendor / physical** | `source()` + grants + correct **database.schema** per `MIGRATION_BASELINE_RAW_TRANSFORM.md` | **`MIGRATION_TASKS.md`** task rows; vendor-specific `MIGRATION_TASKS_*.md`; `dbt/models/sources.yml` (pretium-ai-dbt) → `models/sources/sources_transform.yml` (semantic layer) |
| **Dataset** | Business bundle: landing table(s), cleaned/fact names, geo + time grain, status | **`pretium-ai-dbt/dbt/seeds/dim_dataset_config.csv`** (147 rows / **63** `vendor_id` values, snapshot from repo) + `docs/governance/DATASET_DIM_REGISTRY.yml` where used |
| **Metric** | `metric_id` keys in long-form facts, `DIM_METRIC` / **REFERENCE.CATALOG** alignment, feature/signal contracts | **Canonical:** **`pretiumdata-dbt-semantic-layer/.../seeds/reference/catalog/metric.csv`** (see **`MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md`**). Supporting: **`ADMIN.CATALOG` / `REFERENCE.CATALOG`** migration plan; pretium-ai-dbt `design/final/METRIC_DROP_AND_FEATURE_STRATEGY_REGISTRY.md`; vendor research CSVs under **`pretium-ai-dbt/docs/vendor/metrics/`** (inputs only); `scripts/sql/admin/catalog/register_*.sql` where still used |

**Workflow:** pick a **vendor cluster** from §2 → confirm **datasets** in §3 table (or CSV) → run or extend **inventory SQL** from the linked migration doc → reconcile **metrics** (§4) before flipping the **`T-*`** task to `migrated` and appending **`MIGRATION_LOG.md`**.

---

## 2. Vendor clusters with active migration checklists (`T-*` and docs)

These are the **documented** vendor / platform batches (Snowflake + dbt) with explicit exit criteria in **`docs/migration/`**. Other vendors in §3 still require **`T-TRANSFORM-PROD-FACT`**, **`T-ANALYTICS-*`**, or a **new** `MIGRATION_TASKS_*` file when they become blocking.

| Vendor / theme | Task IDs (representative) | Checklist / inventory |
|----------------|---------------------------|------------------------|
| ApartmentIQ | `T-VENDOR-APARTMENTIQ-READY` | `MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md` |
| Yardi Matrix | `T-VENDOR-YARDI-MATRIX-READY` | same |
| Yardi operational (BH / Progress) | `T-VENDOR-YARDI-READY` | `MIGRATION_TASKS_YARDI_BH_PROGRESS.md` |
| First Street | `T-VENDOR-FIRST-STREET-READY` | `MIGRATION_TASKS_FIRST_STREET_RCA.md` Part A |
| RCA / MSCI | `T-VENDOR-RCA-READY` | same Part B |
| CoStar | `T-VENDOR-COSTAR-READY` | `MIGRATION_TASKS_COSTAR.md` |
| Cherre | `T-VENDOR-CHERRE-READY`, `T-CORRIDOR-CHERRE-TAX-ASSESSOR-STOCK-READY` | `MIGRATION_TASKS_CHERRE.md` |
| Redfin | `T-VENDOR-REDFIN-READY` | `MIGRATION_TASKS_STANFORD_REDFIN.md` Part A |
| Stanford SEDA | `T-VENDOR-STANFORD-READY` | same Part B |
| Oxford (SOURCE_ENTITY) | `T-DEV-REF-OXFORD-METRO-CBSA`, `T-DEV-FACT-OXFORD-*` (**migrated** — `models/transform/dev/oxford/`, batch **008**) | `MIGRATION_TASKS_OXFORD_SOURCE_ENTITY_DEV.md` |
| BPS / Census ACS5 / BLS LAUS / LODES | `T-TRANSFORM-BPS-*`, `T-TRANSFORM-CENSUS-ACS5-*`, `T-TRANSFORM-BLS-*`, `T-TRANSFORM-LODES-OD-BG-*` | `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md` |
| Corridor spine + LODES OD_H3_R8 + Cherre stock + Overture | `T-CORRIDOR-REFERENCE-H3-SPINE-READY`, `T-CORRIDOR-LODES-*`, `T-CORRIDOR-CHERRE-*`, `T-CORRIDOR-OVERTURE-*` | `MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md` |
| Strata backend consumers | `T-STRATA-*` | `MIGRATION_TASKS_STRATA_BACKEND_LINEAGE.md` |
| Tearsheet service | `T-TEARSHEET-*` | `MIGRATION_TASKS_TEARSHEET_SERVICE.md` |

**Bulk model path buckets (metrics implied by model layer):** `T-TRANSFORM-DEV`, `T-TRANSFORM-PROD-FACT`, `T-ANALYTICS-FACTS` / `FEATURES` / `MODELS` / … in **`MIGRATION_TASKS.md`** — use path inventories `MIGRATION_TASKS_INVENTORY_models.txt` when scoping “everything left”.

---

## 3. Dataset catalog — `dim_dataset_config` (pretium-ai-dbt seed)

**Location:** `pretium-ai-dbt/dbt/seeds/dim_dataset_config.csv`  
**Counts:** **147** dataset rows across **63** distinct `vendor_id` values (CSV parse, repo snapshot).

This seed is the **best single-machine list of “datasets”** (dataset_id, source_database, source_schema, geo_grains, canonical_fact_table pointers). It is **not** identical to the **`T-*`** task list: some rows are `MULTI_SOURCE` composites, some vendors appear only here until a migration doc is opened.

### 3.1 Vendor rollup (`vendor_id` → number of `dataset_id` rows)

| Vendor ID | # datasets | Example dataset_ids |
|---|---:|---|
| ANCHOR_LOANS | 1 | ANCHOR_LOANS |
| APARTMENTIQ | 1 | APARTMENTIQ_BH |
| APARTMENT_LIST | 1 | APARTMENT_LIST |
| ATTOM | 1 | ATTOM |
| BANKRATE | 1 | BANKRATE_INSURANCE |
| BKFS | 8 | BKFS_HELOC, BKFS_LOAN, BKFS_LOSS_MITIGATION, BKFS_PROPERTY… |
| BLS | 7 | BLS_CPS, BLS_ECI, BLS_JOLTS, BLS_LAUS… |
| BPS | 3 | BPS_CBSA, BPS_COUNTY, BPS_STATE |
| CBO | 1 | CBO |
| CENSUS | 7 | ACS_CBSA, ACS_TRACT, CENSUS_CBP_CBSA, CENSUS_CBP_COUNTY… |
| CHERRE | 10 | CHERRE_AVM, CHERRE_MLS, CHERRE_MLS_INVENTORY_ZIP, CHERRE_MLS_PRICING_ZIP… |
| COSTAR | 5 | COSTAR_FUNDS, COSTAR_MF_MARKET_EXPORT, COSTAR_OWNERS, COSTAR_PROPERTY… |
| DEEPHAVEN | 1 | DEEPHAVEN |
| ELISE | 1 | ELISE_AI |
| EPOCH_AI | 1 | EPOCH_AI |
| FANNIE_MAE | 1 | FANNIE_MAE_SHORTAGE |
| FDIC | 1 | FDIC |
| FEMA | 1 | FEMA_NRI |
| FIRST_STREET | 1 | FIRST_STREET |
| FRED | 1 | FRED |
| FUNNEL | 1 | FUNNEL |
| GOLDMAN_SACHS | 1 | GOLDMAN_SACHS |
| GREEN_STREET | 7 | GREEN_STREET_FUNDAM_VALUATION, GREEN_STREET_HPA, GREEN_STREET_MACRO_RATES, GREEN_STREET_MARKET_PROJECTIONS… |
| HUD | 5 | HUD_DDA, HUD_FHA, HUD_FMR, HUD_HCV… |
| INSIDEMAPS | 1 | INSIDEMAPS |
| IPEDS | 1 | IPEDS |
| IPUMS | 1 | IPUMS |
| JBREC | 4 | JBREC_BTR, JBREC_MF, JBREC_NATIONAL, JBREC_SFR |
| LEHD | 1 | LEHD_LODES |
| MAINSTAY | 1 | MAINSTAY |
| MARKERR | 9 | MARKERR_CRIME, MARKERR_INCOME, MARKERR_MF_PERMITS, MARKERR_POPULATION… |
| MBA | 1 | MBA |
| MOODYS | 1 | MOODYS |
| MULTI_SOURCE | 10 | FACT_HOUSEHOLD_DEMOGRAPHICS, FACT_HOUSING_AFFORDABLE, FACT_HOUSING_BTR, FACT_HOUSING_CONSTRUCTION_ACTIVITY… |
| NAHB | 1 | NAHB |
| NAR | 1 | NAR |
| NCES | 1 | EDUCATION_K12 |
| NHPD | 1 | NHPD |
| ONET | 1 | ONET |
| OPPORTUNITY_INSIGHTS | 1 | OPPORTUNITY_INSIGHTS |
| OVERTURE | 2 | OVERTURE_BUILDINGS, OVERTURE_PLACES |
| OXFORD_ECONOMICS | 4 | HOU_DEMAND, OXFORD_AMREG, OXFORD_CBSA_CROSSWALK, OXFORD_WDMARCO |
| PARCLLABS | 2 | PARCLLABS, PARCLLABS_OWNERSHIP |
| PREQIN | 1 | PREQIN_NEWS |
| PRETIUM | 4 | GOVERNANCE_INTERNAL, NEWS_ITEMS, PRETIUM_FOOTPRINT, PRETIUM_NEWS |
| QUADRANT | 1 | QUADRANT_INSURANCE |
| RCLCO | 1 | RCLCO |
| REALPAGE | 1 | REALPAGE |
| REALTOR | 2 | REALTOR_MSA, REALTOR_ZIPCODE |
| REDFIN | 2 | REDFIN_MSA, REDFIN_ZIPCODE |
| REGRID | 1 | REGRID |
| SALESFORCE | 1 | SALESFORCE |
| SELENE | 1 | SELENE |
| SHOVELS | 1 | SHOVELS |
| SP_GLOBAL | 1 | SP_GLOBAL_RENT_VS_OWN |
| TAX_FOUNDATION | 1 | TAX_FOUNDATION |
| TPANALYTICS | 1 | TPANALYTICS |
| URBAN_INSTITUTE | 1 | URBAN_INSTITUTE |
| WALKER_DUNLOP | 1 | WALKER_DUNLOP |
| YARDI | 5 | HOUSING_HOU_ASSET_YARDI, HOUSING_HOU_OPERATIONS_YARDI, PROGRESS_YARDI_BH_MIRROR, YARDI_BH… |
| ZELMAN | 1 | ZELMAN |
| ZILLOW | 7 | ZILLOW_AFFORDABILITY, ZILLOW_INVENTORY, ZILLOW_MISC, ZILLOW_ZHVF… |
| ZONDA | 1 | ZONDA |

**Maintenance:** When adding a vendor dataset in pretium-ai-dbt, update **`dim_dataset_config.csv`** (and governance YAML if applicable) so this rollup stays accurate; optionally regenerate §3.1 from CSV via a small script in a later PR.

---

## 4. Metrics — what “move” means

Metrics are **not** fully duplicated in one CSV here; they live in:

| Need | Where to look |
|------|----------------|
| **Drop / rename / feature strategy** | pretium-ai-dbt `design/final/METRIC_DROP_AND_FEATURE_STRATEGY_REGISTRY.md` |
| **Long-form `metric_id` in facts** | `TRANSFORM.DEV` / `TRANSFORM_PROD.FACT` models; grep `metric_id` in `dbt/models/` |
| **Catalog registration** | **Authoritative:** semantic-layer **`seeds/reference/catalog/metric.csv`**. Legacy / research: `scripts/sql/admin/catalog/register_*.sql`; pretium-ai-dbt **`docs/vendor/metrics/*.csv`** (intake inputs only — promote into canonical **`metric.csv`**) |
| **DIM_METRIC / dataset ↔ metric lineage** | `T-ADMIN-CATALOG`, `T-EDW-REF`, `REFERENCE.CATALOG` plan in compliance doc |

**Migration rule of thumb:** every **`metric_id`** consumed by **`FEATURE_*`**, **`MODEL_*`**, signals, or Strata must exist in the **target catalog** (or an explicit bridge) before the vendor’s **`T-*`** task is marked complete.

---

## 5. Related inventories (machine-generated)

| File | Repo | Use |
|------|------|-----|
| `MIGRATION_TASKS_INVENTORY_models.txt` | semantic layer `docs/migration/` | Every pretium-ai-dbt `dbt/models/**/*.sql` path |
| `MIGRATION_TASKS_INVENTORY_seeds.txt` | same | Every seed path (includes metric/dataset seeds) |
| `MIGRATION_TASKS_INVENTORY_macros.txt` | same | Macro dependencies |

---

## 6. Exit — “collected” definition

The portfolio is **collected** for migration planning when:

1. Every **§2** row has either a **green** `migrated` / `skipped` disposition in **`MIGRATION_TASKS.md`** or an explicit **new** `MIGRATION_TASKS_*` + **`T-*`** row.  
2. **`dim_dataset_config.csv`** has no orphan **vendor_id** without a Snowflake home in **`MIGRATION_BASELINE_RAW_TRANSFORM.md`**.  
3. **Metric** ownership is traceable from **§4** tables for each in-scope vendor touching **`TRANSFORM.DEV` `FACT_*`**.

---

*Maintainer: when opening a new vendor migration doc, add a row to §2 and link the **`T-*`** ID here.*
