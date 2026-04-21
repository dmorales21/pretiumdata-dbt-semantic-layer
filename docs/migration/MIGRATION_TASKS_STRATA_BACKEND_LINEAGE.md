# Strata backend — Snowflake object lineage & migration tasks

**Source of truth for names:** `strata_backend` SQL / TS (three-part names; legacy **`ANALYTICS.FACTS.*`** in app code is a **namespace alias** — physical **`FACT_*` / `CONCEPT_*`** belong **`TRANSFORM.DEV`** only; **`ANALYTICS.DBT_DEV`** is **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** only).  
**Lineage traced in:** **pretium-ai-dbt** (`dbt/models/**`).  
**Migration tasks:** parent rows in **`MIGRATION_TASKS.md`** (IDs `T-STRATA-*`); log each batch in **`MIGRATION_LOG.md`**.  
**Read priority for vendor bases:** `MIGRATION_BASELINE_RAW_TRANSFORM.md`.

Legend for **Alex post-migration target:** `SP` = `SOURCE_PROD.[VENDOR]`, `TD` = `TRANSFORM.DEV`, `AD` = `ANALYTICS.DBT_DEV`, `AS` = `ANALYTICS.DBT_STAGE`, `SD` = `SERVING.DEMO`, `RG` = `REFERENCE.GEOGRAPHY`, `RC` = `REFERENCE.CATALOG` / `REFERENCE.DRAFT`, `ADM` = `ADMIN.CATALOG`, `EDW` = keep `EDW_PROD.*` until partner contract, `EXT` = external / not migrated, `OBS` = Observe / governance only, `JON` = **read** **Jon’s PROD** `TRANSFORM.[VENDOR]` (Alex **owns both repos**; Alex **does not write** Jon’s PROD schemas).

---

## 1. Metadata / introspection

| Snowflake pattern | Lineage (dbt) | Target | Task ID |
|-------------------|---------------|--------|---------|
| `TRANSFORM.INFORMATION_SCHEMA.COLUMNS` | n/a (Snowflake catalog) | **OBS** | T-STRATA-META-IS |
| `${DATABASE}.INFORMATION_SCHEMA.TABLES/COLUMNS` | n/a | **OBS** | T-STRATA-META-IS |

---

## 2. `ADMIN.CATALOG` (offering / metric semantics)

| Snowflake object | pretium-ai-dbt build | Upstream (summary) | Target |
|-------------------|----------------------|--------------------|--------|
| `BRIDGE_PRODUCT_TYPE_METRIC` | `admin/catalog/bridge_product_type_metric.sql` | catalog seeds / dims | **ADM** / **RC** seeds |
| `BRIDGE_TENANT_TYPE_OFFERING` | `admin/catalog/bridge_tenant_type_offering.sql` | offering dims | **ADM** |
| `DIM_AI_PROMPT_CONFIG` | `admin/catalog/dim_ai_prompt_config.sql` | seeds | **ADM** |
| `DIM_ASSET_CLASS` | `admin/catalog/dim_asset_class.sql` | seeds | **ADM** |
| `DIM_OFFERING` | `admin/catalog/dim_offering.sql` | seeds + staging | **ADM** |
| `DIM_OFFERING_SIGNAL_RELEVANCE` | `admin/catalog/dim_offering_signal_relevance.sql` | signals registry | **ADM** |
| `OFFERING_ASSET_TYPE_MAP` | `admin/catalog/offering_asset_type_map.sql` | dims | **ADM** |
| `OFFERING_PRODUCT_TYPE_MAP` | `admin/catalog/offering_product_type_map.sql` | dims | **ADM** |

**Task:** `T-STRATA-ADMIN-CATALOG` (cluster with `T-ADMIN-CATALOG`).

---

## 3. County-grain **facts** (strata may say `ANALYTICS.FACTS.*` — correct target is **`TRANSFORM.DEV`**)

dbt sources live under `dbt/models/analytics/facts/` for historical layout only. **Physical objects:** **`TRANSFORM.DEV.FACT_*`** (not `ANALYTICS.DBT_DEV`). Update **strata_backend** FQNs to **`TRANSFORM.DEV`** (or thin **`MODEL_*`** views in **`ANALYTICS.DBT_DEV`** that `SELECT` from **`TRANSFORM.DEV`** if the API must stay under `ANALYTICS` until cutover).

| Strata / Snowflake name | dbt model | Primary upstream |
|-------------------------|-----------|-------------------|
| `ACS_DEMOGRAPHICS_COUNTY` | `analytics/facts/fact_acs_demographics_county.sql` | `source('census', …)` / `TRANSFORM.CENSUS.ACS5`, `bridge_cbsa_county`, `dim_geo_county_cbsa` |
| `BH_PROPERTY_SNAPSHOT` | `analytics/facts/bh/fact_bh_property_snapshot.sql` | Yardi/BH cleansed sources |
| `BLS_LAUS_CBSA_MONTHLY` | `analytics/facts/fact_bls_laus_cbsa_monthly.sql` | `SOURCE_PROD.BLS` / transform BLS |
| `BLS_LAUS_COUNTY_MONTHLY` | `analytics/facts/fact_bls_laus_county_monthly.sql` | BLS LAUS + geo |
| `CHERRE_MF_COUNTY_SNAPSHOT` | `analytics/facts/fact_cherre_mf_county_snapshot.sql` | `source('cherre', …)` / `TRANSFORM.CHERRE` |
| `CHERRE_RECORDER_SFR_COUNTY_MONTHLY` | `analytics/facts/fact_cherre_recorder_sfr_county_monthly.sql` | Cherre recorder |
| `CHERRE_MLS_H3_R8_MONTHLY` | `analytics/facts/fact_cherre_mls_h3_r8_monthly.sql` | MLS + H3 polyfill |
| `MARKERR_MF_PIPELINE_COUNTY_MONTHLY` | `analytics/facts/fact_markerr_mf_pipeline_county_monthly.sql` | `TRANSFORM.MARKERR` / `SOURCE_PROD.MARKERR` |
| `MARKERR_RENT_COUNTY_MONTHLY` | `analytics/facts/fact_markerr_rent_county_monthly.sql` | Markerr rent |
| `PROGRESS_PROPERTY_SNAPSHOT` | `analytics/facts/progress/fact_progress_property_snapshot.sql` | Progress / Yardi |
| `RCA_MF_CONSTRUCTION_COUNTY_MONTHLY` | `analytics/facts/fact_rca_mf_construction_county_monthly.sql` | `TRANSFORM.RCA` / RCA share |
| `RCA_MF_TRANSACTIONS_COUNTY_MONTHLY` | `analytics/facts/fact_rca_mf_transactions_county_monthly.sql` | RCA |
| `RCA_MF_TRANSACTIONS_H3_R8_MONTHLY` | `analytics/facts/fact_rca_mf_transactions_h3_r8_monthly.sql` | RCA + H3 |
| `ZONDA_BTR_COUNTY_MONTHLY` | `analytics/facts/fact_zonda_btr_county_monthly.sql` | `TRANSFORM.ZONDA` / `SOURCE_PROD` |

**Task:** `T-STRATA-ANALYTICS-FACTS-COUNTY` → **`TD`** `FACT_*`; vendor reads follow baseline doc (**`TRANSFORM.<v>`** first).

---

## 4. H3 map **facts** (strata list — physical **`TRANSFORM.DEV.FACT_*`**, not `ANALYTICS`)

| Strata path | dbt model | Primary upstream |
|-------------|-----------|------------------|
| `FACTS.CENSUS_ACS5_H3_R8_SNAPSHOT` | `analytics/facts/fact_census_acs5_h3_r8_snapshot.sql` | `TRANSFORM.CENSUS.ACS5`, BG demos, `source('reference_geography','bridge_bg_h3_r8_polyfill')` → **`BLOCKGROUP_H3_R8_POLYFILL`** |
| `FACTS.LODES_OD_H3_R8_ANNUAL` | `analytics/facts/fact_lodes_od_h3_r8_annual.sql` | `TRANSFORM.LODES`, H3 |
| `FACTS.MARKERR_SFR_RENT_H3_R8_MONTHLY` | `analytics/facts/fact_markerr_sfr_rent_h3_r8_monthly.sql` | Markerr + H3 |
| `FACTS.MARKERR_RENT_H3_R8_MONTHLY` | `analytics/facts/fact_markerr_rent_h3_r8_monthly.sql` | Markerr + H3 |
| `FACTS.MARKERR_MF_PIPELINE_H3_R8_MONTHLY` | `analytics/facts/fact_markerr_mf_pipeline_h3_r8_monthly.sql` | Markerr + H3 |
| `FACTS.ZONDA_BTR_H3_R8_MONTHLY` | `analytics/facts/fact_zonda_btr_h3_r8_monthly.sql` | Zonda BTR + H3 |
| `FACTS.CHERRE_RECORDER_SFR_H3_R8_MONTHLY` | `analytics/facts/fact_cherre_recorder_sfr_h3_r8_monthly.sql` | Cherre + H3 |
| `FACTS.CHERRE_SFR_H3_R8_SNAPSHOT` | `analytics/facts/fact_cherre_sfr_h3_r8_snapshot.sql` | Cherre + H3 |
| `FACTS.CHERRE_MF_H3_R8_SNAPSHOT` | `analytics/facts/fact_cherre_mf_h3_r8_snapshot.sql` | Cherre + H3 |

**Task:** `T-STRATA-ANALYTICS-FACTS-H3-MAP` → **`TD`**; depends **`T-STRATA-REFERENCE-GEO`** for polyfills / `ZCTA_CBSA_XWALK` patterns.

---

## 5. `ANALYTICS.FEATURES` — H3 features (strata list)

| Strata path | dbt model | Upstream (summary) |
|-------------|-----------|---------------------|
| `FEATURES.FEATURE_BTR_SIGNALS_H3_R8` | `analytics/features/corridor/feature_btr_signals_h3_r8.sql` | `fact_zonda_*_h3_r8_*`, `fact_census_acs5_h3_r8_snapshot`, other corridor facts |
| `FEATURES.FEATURE_RCA_MF_CAPITAL_SIGNALS_H3_R8` | `analytics/features/corridor/feature_rca_mf_capital_signals_h3_r8.sql` | `fact_rca_mf_transactions_h3_r8_monthly`, `fact_rca_mf_construction_h3_r8_monthly`, `fact_rca_mf_debt_h3_r8_monthly` |
| `FEATURES.FEATURE_CHERRE_MFR_TIER_H3_R8` | `analytics/features/corridor/feature_cherre_mfr_tier_h3_r8.sql` | Cherre MF / assessor facts at H3 |

**Task:** `T-STRATA-ANALYTICS-FEATURES-H3-MAP` → **`AD`** `FEATURE_*`.

---

## 6. `ANALYTICS.MODELS` — corridor rankings marts

| Strata name | dbt model | Upstream (summary) |
|-------------|-----------|---------------------|
| `MART_CBSA_RANKINGS_MONTHLY` | `analytics/models/corridor/mart_cbsa_rankings_monthly.sql` | `ref('model_market_scorecard_cbsa_monthly')`, `fact_bls_laus_cbsa_monthly`, `fact_bls_oes_cbsa_annual`, Zonda BTR context |
| `MART_CBSA_RANKINGS_GARDEN_MONTHLY` | `analytics/models/corridor/mart_cbsa_rankings_garden_monthly.sql` | garden scorecard + same labor pattern |
| `MART_COUNTY_RANKINGS_MONTHLY` | `analytics/models/corridor/mart_county_rankings_monthly.sql` | county scorecard stack |
| `MART_COUNTY_RANKINGS_GARDEN_MONTHLY` | `analytics/models/corridor/mart_county_rankings_garden_monthly.sql` | county garden |

**Task:** `T-STRATA-ANALYTICS-MODELS-CORRIDOR-MARTS` → **`AD`** `MODEL_*`; ensure **`model_market_scorecard_*`** migrated with them (`analytics/models/market_scorecard/`).

---

## 7. `ANALYTICS.REFERENCE`

| Strata name | dbt model | Upstream |
|-------------|-----------|----------|
| `DIM_GEO_COUNTY_CBSA` | `analytics/reference/dim_geo_county_cbsa.sql` | `REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK`, `COUNTY`, `CBSA`, `cbsa_state_xwalk`, `source('census','pep_county')` |

**Task:** `T-STRATA-ANALYTICS-REF-DIM-GEO` → split: spine from **`RG`**; compatibility view/table in **`AD`** if required for Prism during transition.

---

## 8. `ANALYTICS_PROD`

| Strata name | dbt (typical) | Target |
|-------------|---------------|--------|
| `FEATURES.FEATURE_MARKERR_RENT_ABSORPTION_ZIP` | `analytics_prod/features/absorption/feature_markerr_rent_absorption_zip.sql` | **AD** |
| `SANDBOX.IC_FEATURES_H3_6` | sandbox models | **AS** / **skipped** internal |

**Task:** `T-STRATA-ANALYTICS-PROD` (pairs with `T-PROD-FEATURES`, `T-PROD-SANDBOX`).

---

## 9. `DEV.JAKAR.GEORGIA_ALL_SCHOOLS`

| Lineage | Target |
|---------|--------|
| Not built by pretium-ai-dbt core pipeline | **EXT** / dev demo — **exclude** from prod migration |

**Task:** `T-STRATA-DEV-JAKAR` → **skipped** (document in `MIGRATION_LOG` if referenced).

---

## 10. `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACQUISITION__C`

| Lineage | Target |
|---------|--------|
| Salesforce datashare; not Alex `FACT_` | **blocked** CRM / `SOURCE_ENTITY` pattern |

**Task:** `T-STRATA-DS-SFDC-ACQUISITION`.

---

## 11. `EDW_PROD` — delivery, mart, reference, AI

### 11a. `EDW_PROD.DELIVERY`

| View / table | dbt | Upstream (pattern) |
|--------------|-----|---------------------|
| `V_AI_RISK_CBSA`, `V_ECONOMIC_MOMENTUM_CBSA`, `V_MF_*`, `V_NEWS_*`, `V_PROPERTY_*`, `V_RATES_*`, `V_REGRID_PARCEL`, `V_RENTAL_FORECAST_SIGNALS_MF_CBSA`, `V_HOUSING_ACTIVITY_MONTHLY` | `edw_prod/delivery/views/*.sql` | `ref()` to **EDW marts**, **dims**, **facts** |
| `FCT_PROPERTY_RENT_ESTIMATE_CYCLE_ADJ`, `FCT_PROPERTY_VALUE_ESTIMATE_CYCLE_ADJ` | delivery / mart property stack | property estimates pipeline |

**Task:** `T-STRATA-EDW-DELIVERY-STRATA` → **`EDW`** until **SERVING.MART** / contract; thin **`SD`** only for agreed demo mirrors.

### 11b. `EDW_PROD.MART` (strata-listed)

Each `mart_*` → `edw_prod/mart/**/*.sql`; upstreams are **facts**, **features**, **dims**, **other marts** (use `dbt ls --select +mart_name+` in old repo for full DAG).

**Task:** `T-STRATA-EDW-MART-STRATA` → **`EDW`** / partner **blocked** for Alex body migration.

### 11c. `EDW_PROD.REFERENCE` dims

| Object | dbt | Target |
|--------|-----|--------|
| `DIM_CBSA`, `DIM_COUNTY`, `DIM_ZIP`, `DIM_GEO_CROSSWALK`, `DIM_GLOSSARY_BUSINESS_DEFINITIONS`, `DIM_TEARSHEET_SOURCE_CATALOG` | `edw_prod/reference/dim_*.sql` | **EDW** short term → **RC** long term where catalog-owned |

**Task:** `T-STRATA-EDW-REF-DIMS`.

### 11d. `EDW_PROD.AI`

| Object | dbt | Target |
|--------|-----|--------|
| `V_GLOSSARY_MARKET_METRICS` | `edw_prod/ai/*.sql` (glossary) | **EDW** / **RC** |

**Task:** `T-STRATA-EDW-AI-GLOSSARY`.

---

## 12. Overture CARTO

| Object | Lineage | Target |
|--------|---------|--------|
| `OVERTURE_MAPS__PLACES.CARTO.PLACE`, `…TRANSPORTATION.CARTO.SEGMENT` | `sources.yml` + optional cleaned | **EXT** + license **OBS** |

**Task:** `T-STRATA-OVERTURE-CARTO`.

---

## 13. `RAW.CENSUS.ACS5_RAW`

| Lineage | Target |
|---------|--------|
| Legacy raw mirror; prefer **`TRANSFORM.CENSUS`** / **`SOURCE_PROD`** for ACS | **SP** / **JON** consolidation per baseline doc |

**Task:** `T-STRATA-RAW-CENSUS-ACS5`.

---

## 14. `REFERENCE.GEOGRAPHY` (strata-listed)

| Table | Built by | Target |
|-------|----------|--------|
| `BLOCKGROUPS`, `CBSA`, `COUNTY_CBSA_XWALK`, `TRACTS`, `ZCTA_CBSA_XWALK` | Reference pipeline / SnowSQL scripts in pretium-ai-dbt | **`RG`** |

**Task:** `T-STRATA-REFERENCE-GEO-STRATA` (align with **`T-ANALYTICS-REF`** for bridges built in dbt).

---

## 15. `SOURCE_ENTITY` (BH / Progress)

| Object | Target |
|--------|--------|
| `BH.MATRIX_*`, `PROGRESS.SFDC_*` | **blocked** CRM — not `TRANSFORM.DEV` |

**Task:** `T-STRATA-SOURCE-ENTITY-CRM`.

---

## 16. `SOURCE_PROD.EDUCATION.EDGE_SCHOOL_CHARACTERISTICS_2324`

| dbt | `sources.yml` → `source_prod.education` | Target **SP** |

**Task:** `T-STRATA-SOURCE-PROD-EDUCATION-EDGE`.

---

## 17. `TRANSFORM` vendor (strata-selected)

| Schema.table (examples) | Role | Alex migration |
|-------------------------|------|----------------|
| `TRANSFORM.APARTMENTIQ.PROPERTY_KPI` | Jon **PROD** vendor | **JON** read; Alex **`FACT_*`** in **TD** only when wrapping for Prism |
| `TRANSFORM.CENSUS.ACS5` | Jon **PROD** / platform | **JON** / **SP** read |
| `TRANSFORM.CHERRE.*` | Jon **PROD** | **JON** |
| `TRANSFORM.MARKERR.*`, `REDFIN.*`, `ZONDA.*`, `FIRST_STREET.*`, `LODES.*`, `OVERTURE.PLACES`, `REGRID.*`, `COSTAR.SCENARIOS`, `YARDI*`, `BLS`, `BPS` | Jon **PROD** vendor / platform | **JON** `source()` |
| `TRANSFORM.DEV.FACT_CHERRE_STOCK_COUNTY` | Alex fact | **TD** — `analytics/facts/fact_cherre_stock_county.sql` |
| `TRANSFORM.ROLLUPS.*` | Internal rollups | TBD owner |

**Task:** `T-STRATA-TRANSFORM-VENDOR-READS` (documentation + `source()` registration only).

---

## 18. `TRANSFORM_PROD` (strata-listed)

| Object | dbt | Alex action |
|--------|-----|--------------|
| `CLEANED.*` (BPS, JBREC, REGGRID, Overture retailers, Zonda projects, Cherre assessor, …) | `transform_prod/cleaned/*.sql` | **skip** — **JON** |
| `FACT.FACT_BPS_COUNTY_PERMITS`, `FACT_CHERRE_MLS_LISTING_EVENTS_ALL_TS`, `FACT_CPS_LABOR_TS`, `FACT_HOUSEHOLD_LABOR_QCEW_COUNTY` | `transform_prod/fact/*.sql` | Per-object: **`TD`** if Alex-owned duplicate of analytics facts, else **JON** |
| `REF.CITY_SPINE` | `transform_prod/ref/*.sql` | **TD** `REF_*` seed/table if vendor |

**Task:** `T-STRATA-TRANSFORM-PROD-STRATA`.

---

## 19. Dynamic **`${prefix}_*`** facts (`market.service.ts`; legacy `ANALYTICS.FACTS` prefix)

| Lineage | Target |
|---------|--------|
| Prefix allowlisted in **`ADMIN.CATALOG`** (or successor); each prefix maps to a **`TD`** **`FACT_*`** (or **`CONCEPT_*`**) in dbt | App may use a **`MODEL_*`** shim in **`ANALYTICS.DBT_DEV`** that selects from **`TRANSFORM.DEV`** — **never** materialize base facts in **`ANALYTICS`** |

**Task:** `T-STRATA-MARKET-SERVICE-DYNAMIC` — catalog-driven prefix list + **`TRANSFORM.DEV`** **`FACT_*`** per vendor.

---

## 20. Task ID crosswalk (register in `MIGRATION_TASKS.md`)

| Task ID | Scope |
|---------|--------|
| `T-STRATA-META-IS` | §1 Information_schema |
| `T-STRATA-ADMIN-CATALOG` | §2 |
| `T-STRATA-ANALYTICS-FACTS-COUNTY` | §3 |
| `T-STRATA-ANALYTICS-FACTS-H3-MAP` | §4 |
| `T-STRATA-ANALYTICS-FEATURES-H3-MAP` | §5 |
| `T-STRATA-ANALYTICS-MODELS-CORRIDOR-MARTS` | §6 + `model_market_scorecard_*` |
| `T-STRATA-ANALYTICS-REF-DIM-GEO` | §7 |
| `T-STRATA-ANALYTICS-PROD` | §8 |
| `T-STRATA-DEV-JAKAR` | §9 skip |
| `T-STRATA-DS-SFDC-ACQUISITION` | §10 blocked |
| `T-STRATA-EDW-DELIVERY-STRATA` | §11a |
| `T-STRATA-EDW-MART-STRATA` | §11b |
| `T-STRATA-EDW-REF-DIMS` | §11c |
| `T-STRATA-EDW-AI-GLOSSARY` | §11d |
| `T-STRATA-OVERTURE-CARTO` | §12 |
| `T-STRATA-RAW-CENSUS-ACS5` | §13 |
| `T-STRATA-REFERENCE-GEO-STRATA` | §14 |
| `T-STRATA-SOURCE-ENTITY-CRM` | §15 blocked |
| `T-STRATA-SOURCE-PROD-EDUCATION-EDGE` | §16 |
| `T-STRATA-TRANSFORM-VENDOR-READS` | §17 |
| `T-STRATA-TRANSFORM-PROD-STRATA` | §18 |
| `T-STRATA-MARKET-SERVICE-DYNAMIC` | §19 |

---

*Maintainer: when `strata_backend` adds a relation, append a row to §3–§11 tables and add / extend a `T-STRATA-*` task; run static analysis the user described for deduped machine-readable export.*
