# Migration tasks — `tearsheet.service.ts` Snowflake objects (full lineage)

**Source of object list:** executable SQL in **`strata_backend`** `tearsheet.service.ts` (forked scope).  
**Lineage traced in:** **pretium-ai-dbt** (`dbt/models/**`, `sources.yml`, `scripts/validation/*`).  
**Canon targets:** `SOURCE_PROD.[VENDOR]`, `TRANSFORM.DEV`, `ANALYTICS.DBT_DEV`, `REFERENCE.*`, `ADMIN.CATALOG` (until merged to catalog seeds), `SERVING.DEMO` / partner-owned EDW surfaces per `MIGRATION_PLAN.md`.

**Counts:** 8 `ADMIN.CATALOG` + 4 `EDW_PROD.REFERENCE` + 1 `TRANSFORM_PROD.REF` + 3 `TRANSFORM_PROD.CLEANED` + 22 `EDW_PROD.MART` = **38** qualified objects.

---

## 1. `ADMIN.CATALOG` (8 objects)

These are **`source('admin_catalog', …)`** in dbt (see `dbt/models/sources.yml` — `admin_catalog`). Physical tables are maintained by the **catalog Streamlit app**, not rebuilt as dbt models in the mart path.

| Snowflake object | pretium-ai-dbt / repo role | Upstream / notes | Migration task |
|------------------|----------------------------|------------------|------------------|
| `DIM_AI_PROMPT_CONFIG` | Registry row in `registry_semantic_object.csv`; config in `dbt_project.yml` `semantic_models` | Seed / admin app — no `models/admin/catalog/dim_ai_prompt_config.sql` | **T-TEARSHEET-ADM-01** — register in semantic-layer catalog seeds or `source()`; do not duplicate logic in `TRANSFORM.DEV`. |
| `DIM_OFFERING` | `edw_prod/reference/dim_offering.sql` reads `source('admin_catalog','dim_offering')` when `admin_catalog_available` | ADMIN is SoT; EDW is thin export | **T-TEARSHEET-ADM-02** — keep `ADMIN.CATALOG` SoT; EDW mirror → later `REFERENCE.CATALOG` / `SERVING` per registry plan. |
| `OFFERING_ASSET_TYPE_MAP` | `source('admin_catalog', …)` (listed under same source) | ADMIN | **T-TEARSHEET-ADM-03** |
| `DIM_ASSET_CLASS` | `source('admin_catalog', …)` | ADMIN | **T-TEARSHEET-ADM-04** |
| `OFFERING_PRODUCT_TYPE_MAP` | `source('admin_catalog', …)` — **product routing SoT** | ADMIN | **T-TEARSHEET-ADM-05** |
| `BRIDGE_TENANT_TYPE_OFFERING` | `source('admin_catalog', …)` | ADMIN | **T-TEARSHEET-ADM-06** |
| `BRIDGE_PRODUCT_TYPE_METRIC` | `source('admin_catalog', …)` | ADMIN | **T-TEARSHEET-ADM-07** |
| `DIM_OFFERING_SIGNAL_RELEVANCE` | `source('admin_catalog', …)` | ADMIN | **T-TEARSHEET-ADM-08** |

**Lineage summary:** Tearsheet → **ADMIN.CATALOG** (governance). dbt only **replicates** offering into `EDW_PROD.REFERENCE.DIM_OFFERING` for joins.

---

## 2. `EDW_PROD.REFERENCE` (4 objects)

| Snowflake object | dbt model (pretium-ai-dbt) | Upstream lineage | Migration task |
|------------------|----------------------------|------------------|------------------|
| `DIM_CBSA` | `dbt/models/edw_prod/reference/dim_cbsa.sql` | **`TRANSFORM_PROD.REF.H3_CANON_CBSA`** (primary) + optional **`ADMIN.CATALOG.DIM_GEOGRAPHY`** metadata | **T-TEARSHEET-REF-01** — long term: `REFERENCE.GEOGRAPHY` / catalog CBSA spine; stop hard dependency on `TRANSFORM_PROD.REF` per zero-legacy rule. |
| `DIM_ZIP` | `dbt/models/edw_prod/reference/dim_zip.sql` | **`source('ref','h3_xwalk_6810_canon')`** → **TRANSFORM_PROD.REF.H3_XWALK_6810_CANON** (ZIP grain) | **T-TEARSHEET-REF-02** — migrate spine to **`REFERENCE.GEOGRAPHY`** + vendor-neutral ZIP↔CBSA; retire `h3_xwalk_6810_canon` dependency per geo rules. |
| `DIM_GLOSSARY_BUSINESS_DEFINITIONS` | *No dbt SQL match in repo* | Likely **EDW-only or external job** — confirm in Snowflake / other repo | **T-TEARSHEET-REF-03** — inventory + add dbt ownership or `source()` only. |
| `DIM_TEARSHEET_SOURCE_CATALOG` | *No dbt SQL match in repo* | Same as above | **T-TEARSHEET-REF-04** |

**Comment-only:** `DIM_COUNTY` — service uses **`DIM_ZIP`** for county→CBSA because `DIM_COUNTY` lacks `CBSA_CODE`; migration should **not** reintroduce `DIM_COUNTY` for that path without schema fix.

---

## 3. `TRANSFORM_PROD.REF` (1 object)

| Snowflake object | dbt model | Upstream | Migration task |
|------------------|-----------|----------|------------------|
| `CITY_SPINE` | `dbt/models/transform_prod/ref/city_spine.sql` | **Jon ref** — built from vendor / geography inputs (see model header) | **T-TEARSHEET-TPR-01** — **do not migrate to Alex `TRANSFORM.DEV`**; consume via **`TRANSFORM.REF`** or promoted Jon schema; if Alex needs subset, **`REF_*` seed** in `TRANSFORM.DEV` with doc’d lineage only. |

---

## 4. `TRANSFORM_PROD.CLEANED` — JBREC BTR (3 objects)

| Snowflake object | dbt model | Upstream | Migration task |
|------------------|-----------|----------|------------------|
| `CLEANED_JBREC_BTR_RENT_AND_OCCUPANCY` | `transform_prod/cleaned/cleaned_jbrec_btr_rent_and_occupancy.sql` | **`SOURCE_PROD.JBREC`** (or share) → cleaned | **T-TEARSHEET-JBREC-01** — Jon cleansed; Alex **`FACT_*`** reads **`SOURCE_PROD`** or **`TRANSFORM.JBREC`** when promoted. |
| `CLEANED_JBREC_BTR_FORECAST` | `transform_prod/cleaned/cleaned_jbrec_btr_forecast.sql` | `source('jbrec','btr_forecast')` → **SOURCE_PROD.JBREC** | **T-TEARSHEET-JBREC-02** |
| `CLEANED_JBREC_BTR_COMMUNITY_COUNT_BY_MARKET` | `transform_prod/cleaned/cleaned_jbrec_btr_community_count_by_market.sql` | JBREC source tables (see model) | **T-TEARSHEET-JBREC-03** |

**Downstream (tearsheet-relevant):**  
`feature_btr_rent_absorption_cbsa` ← **`ref('cleaned_jbrec_btr_rent_and_occupancy')`**  
→ `mart_jbrec_btr_rent_cbsa` ← **`ref('feature_btr_rent_absorption_cbsa')`**  
So tearsheet **`MART_JBREC_BTR_RENT_CBSA`** lineage = **cleaned → feature → mart** (not direct SQL on cleaned in mart file).

---

## 5. `EDW_PROD.MART` (22 objects)

| Snowflake object | dbt model | Primary upstream (1 hop) | Deeper spine (when known) | Migration task |
|------------------|-----------|----------------------------|---------------------------|------------------|
| `MART_MARKERR_RENT_ABSORPTION_ZIP` | `edw_prod/mart/absorption/mart_markerr_rent_absorption_zip.sql` | `feature_markerr_rent_absorption_zip` | Markerr facts / cleaned (see feature model) | **T-TEARSHEET-MART-01** |
| `MART_PRETIUM_ROLLUP_ZIP` | *Not a dbt model in this repo* | **`scripts/validation/ADMIN_PHASE2_1_CLONE_MODELS_TABLES_TO_MART.sql`** clones **`ADMIN.MODELS.PRETIUM_ROLLUP_ZIP` → `EDW_PROD.MART`** | ADMIN / portfolio job | **T-TEARSHEET-MART-02** — own pipeline: promote to **`MODEL_*`** in `ANALYTICS.DBT_DEV` or keep EDW with explicit `source()`. |
| `MART_MARKERR_RENT_ABSORPTION_CBSA` | `edw_prod/mart/absorption/mart_markerr_rent_absorption_cbsa.sql` | `feature_markerr_rent_absorption_cbsa` | Markerr vendor + geo | **T-TEARSHEET-MART-03** |
| `MART_JBREC_BTR_RENT_CBSA` | `edw_prod/mart/rental_forecast/mart_jbrec_btr_rent_cbsa.sql` | `feature_btr_rent_absorption_cbsa` | **`cleaned_jbrec_btr_rent_and_occupancy`** | **T-TEARSHEET-MART-04** |
| `MART_GREENSTREET_SFR` | `edw_prod/mart/greenstreet/mart_greenstreet_sfr.sql` | `fact_gs_macro_market_all_ts`, `fact_gs_market_forecast_all_ts`, `dim_cbsa` | Green Street vendor facts | **T-TEARSHEET-MART-05** |
| `MART_CHERRE_MLS_ABSORPTION_CBSA` | `edw_prod/mart/absorption/mart_cherre_mls_absorption_cbsa.sql` | Cherre MLS feature stack | **T-TEARSHEET-MART-06** |
| `MART_OWN_VS_RENT_CBSA` | `edw_prod/mart/affordability/mart_own_vs_rent_cbsa.sql` | `mart_rates_daily` + other marts | Rates + rent afford | **T-TEARSHEET-MART-07** |
| `MART_PERMITS_MARKET` | `edw_prod/mart/permits/*` | BPS / permits facts | **T-TEARSHEET-MART-08** |
| `MART_RATES_WEEKLY` | `edw_prod/mart/rates/mart_rates_weekly.sql` | Weekly rates fact / cleaned | **T-TEARSHEET-MART-09** |
| `MART_RATES_DAILY` | `edw_prod/mart/rates/mart_rates_daily.sql` | **`ref('fact_rates_daily_snapshot_ts')`** | **SOURCE_PROD.RATES** → cleaned pipeline (see mart header) | **T-TEARSHEET-MART-10** |
| `MART_REDFIN_CONDO_CBSA` | `edw_prod/mart/pricing/mart_redfin_condo_cbsa.sql` | Redfin / ZIP rollup facts | **T-TEARSHEET-MART-11** |
| `MART_MARKERR_SFR_RENT_CBSA` | `edw_prod/mart/rent_signals/mart_markerr_sfr_rent_cbsa.sql` | Markerr SFR features | **T-TEARSHEET-MART-12** |
| `MART_COSTAR_MF_RENT_CBSA` | `edw_prod/mart/mf_rent/mart_costar_mf_rent_cbsa.sql` | Costar vendor | **T-TEARSHEET-MART-13** |
| `MART_CHERRE_RECORDER_MORTGAGES_CBSA` | `edw_prod/mart/cherre/mart_cherre_recorder_mortgages_cbsa.sql` | Cherre recorder facts | **T-TEARSHEET-MART-14** |
| `MART_CHERRE_DEMOGRAPHICS_CBSA` | `edw_prod/mart/demand/mart_cherre_demographics_cbsa.sql` | Cherre demographics facts | **T-TEARSHEET-MART-15** |
| `MART_HPA_CBSA` | `edw_prod/mart/pricing/mart_hpa_cbsa.sql` | **`mart_redfin_condo_cbsa`** + other HPA inputs | **T-TEARSHEET-MART-16** |
| `MART_PARCLLABS_MARKET_CBSA` | `edw_prod/mart/ownership/mart_parcllabs_market_cbsa.sql` | Parcl vendor | **T-TEARSHEET-MART-17** |
| `MART_ZONDA_BTR_RENT_CBSA` | `edw_prod/mart/rental_forecast/mart_zonda_btr_rent_cbsa.sql` | **`mart_jbrec_btr_rent_cbsa`** + Zonda features | **T-TEARSHEET-MART-18** |
| `MART_LABOR_LAUS_CBSA` | `edw_prod/mart/labor/mart_labor_laus_cbsa.sql` | BLS LAUS facts / features | **T-TEARSHEET-MART-19** |
| `MART_MARKET_SELECTION_MONTHLY` | `edw_prod/mart/market_selection/mart_market_selection_monthly.sql` | **`feature_cbsa_score_monthly`** | **`feature_cbsa_pillar_scores_monthly`** → `v_signals_cbsa_pillar_input` → … → county/CBSA **facts** | **T-TEARSHEET-MART-20** — **highest fan-in** for tearsheet “context”. |

**Marts 06–19:** Exact `ref()` chains live in each `mart_*.sql` under `dbt/models/edw_prod/mart/**`; extend this doc per-file when executing a batch (log in `MIGRATION_LOG.md`).

---

## 6. Comment-only / deprecated (not live in `tearsheet.service.ts`)

| Object | Note |
|--------|------|
| `EDW_PROD.REFERENCE.DIM_COUNTY` | Documented path only — implementation uses **`DIM_ZIP`**. |
| `TRANSFORM_PROD.CLEANED.CLEANED_REDFIN_CBSA` | Deprecated vs **`MART_REDFIN_CONDO_CBSA`**. |
| `TRANSFORM_PROD.FACT.PARCLLABS_MARKET_CBSA` | Deprecated vs **`MART_PARCLLABS_MARKET_CBSA`**. |

---

## 7. Canon migration order (recommended)

1. **ADMIN.CATALOG** sources + **`DIM_OFFERING`** export contract (T-TEARSHEET-ADM-*).  
2. **REFERENCE** spine for **`DIM_CBSA` / `DIM_ZIP`** — remove **`TRANSFORM_PROD.REF.H3_CANON_CBSA`** dependency from **`dim_cbsa`** (T-TEARSHEET-REF-01/02).  
3. **Glossary / tearsheet catalog** rows — resolve ownership (T-TEARSHEET-REF-03/04).  
4. **JBREC cleaned** — confirm **`SOURCE_PROD.JBREC`** parity; freeze Jon cleaned reads (T-TEARSHEET-JBREC-*).  
5. **`MART_MARKET_SELECTION_MONTHLY` upstream** (`feature_cbsa_score_monthly` stack) — largest cross-vendor graph (**T-TEARSHEET-MART-20** + `T-PROD-*` clusters).  
6. **Remaining marts** in dependency order (rates → own-vs-rent; Markerr ZIP/CBSA; vendor-specific).

---

## 8. `MIGRATION_LOG.md` usage

For each **T-TEARSHEET-** task executed, append **Model registry** / **Geo corrections** / **Type fixes** rows for every dbt model touched and bump **Batch history**.

## 9. Retire old names in `tearsheet.service.ts` (and callers)

When a mart or dim moves to a **canonical** database/schema/object (per **`DEPRECATION_MIGRATION_COMPLIANCE.md`** and **`MIGRATION_RULES.md` §2A**): update **executable SQL** to the **new three-part name** only; remove references to legacy **`TRANSFORM_PROD.*`**, **`ANALYTICS.FACTS.*`** (wrong physical layer), or superseded **`EDW_PROD.*`** objects. Log **`old_reference` → `new_reference`** and list retired Snowflake objects under **Deprecation candidates** until **`confirmed_drop`**.

---

*Last updated: 2026-04-19 — pretium-ai-dbt path trace + Snowflake object names from user inventory.*
