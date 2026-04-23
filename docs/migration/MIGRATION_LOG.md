# Migration Log — pretium-ai-dbt → pretiumdata-dbt-semantic-layer
# Updated by Cursor after each migration batch
# Format: append-only. Never delete rows. Update status in place.

Full column semantics and rules: **pretium-ai-dbt** `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md` → *Logging requirement* / *MIGRATION_LOG.md — what Cursor puts in each section*.

## Cursor field guide (quick reference)

| Section | What to record |
|---------|----------------|
| **Summary counters** | Running totals after each batch (not per-batch only). Update *Total found / Migrated / Skipped / Pending* by category. |
| **Model registry** | One row per model **touched** in pretium-ai-dbt. `old_path` = full relative path; `old_target_schema` = old write target; `new_path` / `new_target_schema` = landing in this repo; `status` = `migrated` \| `skipped` \| `pending` \| `blocked`; `skip_reason` only if skipped; `geo_corrections` = short comma-separated fixes (e.g. `ZIP_COUNTY_XWALK→ZCTA_CBSA_XWALK`); `batch` = id from Batch history. |
| **Geo corrections applied** | One row per join fix: `model`, `correction` (what changed), `old_reference`, `new_reference`. |
| **Type fixes applied** | One row per column cast: `model`, `column`, `old_type`, `fix_applied`. |
| **Skipped models** | Every non-migrated model. `reason` must be one of: `writes to TRANSFORM.[VENDOR] (Jon's space)` · `no downstream consumers` · `duplicate of existing migrated model` · `legacy cleaned_* layer`. `owner` = `Jon` or `Alex`. Alex reviews before cleanup. |
| **Source declarations added** | Each new `sources_transform.yml` row: `vendor`, `table`, `source_name` (dbt source id), `batch`. |
| **Deprecation candidates** | **Legacy Snowflake names** (e.g. `TRANSFORM_PROD.*`, old `EDW_PROD.*`, compat **views** for `ANALYTICS.FACTS.*`) droppable **after** consumers use the **canonical** name only. In **`reason`**, always record **semantic purpose** (why the object exists — business / analytic intent) and **how to recreate** in the new contract (`FACT_*` / `CONCEPT_*` / `FEATURE_*` / `REFERENCE.*`, catalog keys, grain) so nothing is retired without a rebuild story. `confirmed_drop` blank until Alex signs off on **`DROP`**. |
| **Batch history** | One row per Cursor session: `batch` increments `001`, `002`, …; `models_processed` = count touched; `notes` = scope (e.g. `Zillow FACT models pass 1`). |
| **Alex handoff (cross-repo)** | After each migration **task batch** in **pretiumdata-dbt-semantic-layer**, the agent **asks Alex** to run **`dbt compile` / `dbt build` / `dbt test`** in **pretium-ai-dbt** on the affected downstream selection and confirm pass/fail before merge. Logged batch **006**; detail: **`MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md`**. |

---

## Summary Counters
<!-- Cursor updates these after each batch -->

| Category | Total Found | Migrated | Skipped | Pending |
|----------|-------------|----------|---------|---------|
| RAW_ models | | | | |
| FACT_ models (T-TRANSFORM-DEV cluster) | 81 | 57 | 0 | 24 |
| REF_ seeds | | | | |
| Macro migrations | | | | |
| Source declarations | | | | |

---

## Model Registry

<!-- One row per model discovered in pretium-ai-dbt -->
<!-- Status: migrated | skipped | pending | blocked -->

| old_path | old_target_schema | new_path | new_target_schema | status | skip_reason | geo_corrections | batch |
|----------|-------------------|----------|-------------------|--------|-------------|-----------------|-------|
| dbt/models/transform/dev/zillow_research/fact_zillow_affordability.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_affordability.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_days_on_market_and_price_cuts.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_days_on_market_and_price_cuts.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_for_sale_listings.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_for_sale_listings.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_home_values.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_home_values.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_home_values_forecasts.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_home_values_forecasts.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_market_heat_index.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_market_heat_index.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_new_construction.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_new_construction.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_rental_forecasts.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_rental_forecasts.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_rentals.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_rentals.sql | TRANSFORM.DEV | migrated | | | 001 |
| dbt/models/transform/dev/zillow_research/fact_zillow_sales.sql | TRANSFORM.DEV | models/transform/dev/zillow/fact_zillow_sales.sql | TRANSFORM.DEV | migrated | | | 001 |
| pretium-ai-dbt `dbt/models/sources.yml` (`transform_bps.permits_county`) + Jon `TRANSFORM.BPS.PERMITS_COUNTY` | TRANSFORM.BPS | models/transform/dev/bps/fact_bps_permits_county.sql | TRANSFORM.DEV | migrated | | | 003 |
| pretium-ai-dbt `dbt/models/sources.yml` (`bls_transform.laus_county`) + Jon `TRANSFORM.BLS.LAUS_COUNTY` | TRANSFORM.BLS | models/transform/dev/bls/fact_bls_laus_county.sql | TRANSFORM.DEV | migrated | | | 004 |
| pretium-ai-dbt `dbt/models/sources.yml` (LEHD/LODES banner) + Jon `TRANSFORM.LODES.OD_BG` | TRANSFORM.LODES | models/transform/dev/lodes/fact_lodes_od_bg.sql | TRANSFORM.DEV | migrated | | | 005 |
| GLOBAL_GOVERNMENT.CYBERSYN `housing_urban_development_*` | GLOBAL_GOVERNMENT.CYBERSYN | models/transform/dev/hud/fact_cybersyn_hud_timeseries.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX | 007 |
| SOURCE_SNOW.US_REAL_ESTATE `irs_migration_by_characteristic_*` | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/irs/fact_cybersyn_irs_migration_by_characteristic_timeseries.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX | 007 |
| SOURCE_SNOW.US_REAL_ESTATE `irs_origin_destination_migration_timeseries` | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/irs/fact_cybersyn_irs_origin_destination_migration_timeseries.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX ×2 (from/to) | 007 |
| pretium-ai-dbt `materialize_ref_oxford_metro_cbsa_dev.sql` (CTAS) → dbt port | TRANSFORM_PROD.REF | models/transform/dev/oxford/ref_oxford_metro_cbsa.sql | TRANSFORM.DEV | migrated | | OXFORD_CBSA_CROSSWALK → DEV column names | 008 |
| SOURCE_ENTITY.PRETIUM.AMREG + ref | SOURCE_ENTITY.PRETIUM | models/transform/dev/oxford/fact_oxford_amreg_quarterly.sql | TRANSFORM.DEV | migrated | | MSA × ref join; metric_id AMREG_+code | 008 |
| SOURCE_ENTITY.PRETIUM.WDMARCO | SOURCE_ENTITY.PRETIUM | models/transform/dev/oxford/fact_oxford_wdmarco_quarterly.sql | TRANSFORM.DEV | migrated | | national USA grain | 008 |
| SOURCE_SNOW.US_REAL_ESTATE `fhfa_house_price_*` | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/fhfa/fact_cybersyn_fhfa_house_price_timeseries.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX | 009c |
| SOURCE_SNOW.US_REAL_ESTATE `freddie_mac_housing_*` | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/freddie_mac/fact_freddie_mac_housing_timeseries.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX | 009 |
| GLOBAL_GOVERNMENT.CYBERSYN `housing_urban_development_*` (county / CBSA FACT split) | GLOBAL_GOVERNMENT.CYBERSYN | models/transform/dev/hud/fact_hud_housing_series_county.sql · models/transform/dev/hud/fact_hud_housing_series_cbsa.sql (superset: fact_hud_housing_series.sql) | TRANSFORM.DEV | migrated | | GEO_LEVEL_CODE slice | 010 |
| SOURCE_SNOW.US_REAL_ESTATE `irs_migration_by_characteristic_*` (county / CBSA FACT split) | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/irs/fact_irs_soi_migration_by_characteristic_annual_county.sql · fact_irs_soi_migration_by_characteristic_annual_cbsa.sql (superset: fact_irs_soi_migration_by_characteristic_annual.sql) | TRANSFORM.DEV | migrated | | GEO_LEVEL_CODE slice | 010 |
| SOURCE_SNOW.US_REAL_ESTATE `irs_origin_destination_migration_timeseries` (county / CBSA-attributed FACT split) | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/irs/fact_irs_soi_origin_destination_migration_annual_county.sql · fact_irs_soi_origin_destination_migration_annual_cbsa.sql + int_irs_soi_origin_destination_migration_annual.sql | TRANSFORM.DEV | migrated | | GEOGRAPHY_LATEST CBSA on endpoints | 010 |
| SOURCE_SNOW.US_REAL_ESTATE `fhfa_house_price_*` (canonical FACT rename batch 010) | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/fhfa/fact_fhfa_house_price.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX | 010 |
| SOURCE_SNOW.US_REAL_ESTATE `freddie_mac_housing_*` (canonical FACT batch 010) | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/freddie_mac/fact_freddie_mac_housing_national_weekly.sql | TRANSFORM.DEV | migrated | | REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX | 010 |
| SOURCE_SNOW.US_REAL_ESTATE `fhfa_mortgage_performance_*` + `fhfa_uniform_appraisal_*` (batch 011) | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/fhfa/fact_fhfa_mortgage_performance*.sql · fact_fhfa_uniform_appraisal*.sql | TRANSFORM.DEV | migrated | | GEO_LEVEL_CODE slice + geography_index | 011 |
| SOURCE_SNOW.US_REAL_ESTATE `fhfa_house_price_*` (HPI county/CBSA slices batch 011) | SOURCE_SNOW.US_REAL_ESTATE | models/transform/dev/fhfa/fact_fhfa_house_price_county.sql · fact_fhfa_house_price_cbsa.sql | TRANSFORM.DEV | migrated | | filter on GEO_LEVEL_CODE | 011 |
| pretium-ai-dbt `dbt/models/transform/dev/fund_opco/*` (Yardi OPCO FACT port batch 012) | TRANSFORM.YARDI + legacy BH share | models/transform/dev/fund_opco/fact_progress_yardi_property.sql … fact_bh_yardi_ledger.sql | TRANSFORM.DEV | migrated | | transform_yardi silver + yardi_bh.TRANS for BH ledger | 012 |
| pretium-ai-dbt `dbt/models/transform_prod/cleaned/cleaned_qcew_county_naics.sql` (logic parity) | TRANSFORM.DEV (via cleaned in legacy) | models/transform/dev/bls/fact_bls_qcew_county_naics_quarterly.sql | TRANSFORM.DEV | migrated | | LPAD county FIPS for INTEGER VARIANT `area_fips`; vendor/dataset bls/qcew | 025 |
| pretium-ai-dbt `dbt/models/transform_prod/cleaned/cleaned_onet_gwa_activity_risk.sql` | TRANSFORM.DEV | models/transform/dev/dol_onet/fact_dol_onet_soc_gwa_activity_risk.sql | TRANSFORM.DEV | migrated | | `source_prod_onet`; alias FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK | 026 |
| pretium-ai-dbt `dbt/models/transform_prod/cleaned/cleaned_onet_context_friction.sql` | TRANSFORM.DEV | models/transform/dev/dol_onet/fact_dol_onet_soc_context_friction.sql | TRANSFORM.DEV | migrated | | `work_context` | 026 |
| pretium-ai-dbt `dbt/models/transform_prod/cleaned/cleaned_onet_soc_ai_exposure.sql` | TRANSFORM.DEV | models/transform/dev/dol_onet/fact_dol_onet_soc_ai_exposure.sql | TRANSFORM.DEV | migrated | | refs vendor FACT names + Epoch refs | 026 |
| pretium-ai-dbt `dbt/models/transform_prod/ref/ref_epoch_to_gwa_crosswalk.sql` | TRANSFORM.DEV | models/transform/dev/pretium_epoch/ref_epoch_to_gwa_crosswalk.sql | TRANSFORM.DEV | migrated | | Pretium pilot CTE port | 026 |
| pretium-ai-dbt `dbt/models/transform_prod/ref/ref_epoch_capability_taxonomy.sql` | TRANSFORM.DEV | models/transform/dev/pretium_epoch/ref_epoch_capability_taxonomy.sql | TRANSFORM.DEV | migrated | | | 026 |
| pretium-ai-dbt `dbt/models/transform/dev/ref_onet_soc_to_naics.sql` (dbt read-through model) | TRANSFORM.DEV | *(none — vendor ref only)* | TRANSFORM.DEV | migrated | | **Bridge:** `source('transform_dev_vendor_ref','ref_onet_soc_to_naics')` → physical **`REF_ONET_SOC_TO_NAICS`**; land via `docs/migration/sql/create_ref_onet_soc_to_naics_transform_dev.sql`; dbt model removed | 026 |
| pretium-ai-dbt `dbt/models/transform_prod/fact/fact_county_soc_employment.sql` | TRANSFORM.DEV | models/transform/dev/bls/fact_county_soc_employment.sql | TRANSFORM.DEV | migrated | | QCEW via `fact_bls_qcew_*`; bridge via vendor ref source | 026 |
| pretium-ai-dbt `dbt/models/transform_prod/fact/fact_county_ai_replacement_risk.sql` | TRANSFORM.DEV | models/transform/dev/bls/fact_county_ai_replacement_risk.sql | TRANSFORM.DEV | migrated | | QCEW trend from `fact_bls_qcew_*`; geo via REFERENCE.GEOGRAPHY | 026 |
| pretium-ai-dbt `dbt/models/analytics_prod/features/feature_ai_replacement_risk_county.sql` | ANALYTICS_PROD.FEATURES | models/analytics/feature/feature_ai_replacement_risk_county.sql | ANALYTICS.DBT_DEV | migrated | | Reads `fact_county_ai_replacement_risk`; not CBSA-allocated from old QCEW stack | 027 |
| pretium-ai-dbt `dbt/models/analytics_prod/features/feature_ai_replacement_risk_cbsa.sql` | ANALYTICS_PROD.FEATURES | models/analytics/feature/feature_ai_replacement_risk_cbsa.sql | ANALYTICS.DBT_DEV | migrated | | Synthetic `naics_code=ALL` from county fact | 027 |
| pretium-ai-dbt `dbt/models/analytics_prod/features/feature_ai_replacement_risk_cbsa_rollup.sql` | ANALYTICS_PROD.FEATURES | models/analytics/feature/feature_ai_replacement_risk_cbsa_rollup.sql | ANALYTICS.DBT_DEV | migrated | | | 027 |
| pretium-ai-dbt `dbt/models/analytics_prod/features/feature_structural_unemployment_risk_county.sql` | ANALYTICS_PROD.FEATURES | models/analytics/feature/feature_structural_unemployment_risk_county.sql | ANALYTICS.DBT_DEV | migrated | | 0.5/0.7 tiers vs fact percentile `risk_tier` — document in YAML | 027 |

---

## Geo Corrections Applied

<!-- Log every join fix made during migration -->

| model | correction | old_reference | new_reference |
|-------|-----------|---------------|---------------|
| fact_county_ai_replacement_risk | County name, state, primary CBSA for labels | `source('ref','h3_canon_block_group')` (modal CBSA from BG spine) | `source('reference_geography','county')` + `state` + `county_cbsa_xwalk` with **`reference_geography_year()`** tie-break (aligned with `dim_geo_county_cbsa` ordering) |

---

## Type Fixes Applied

| model | column | old_type | fix_applied |
|-------|--------|----------|-------------|
| REFERENCE.CATALOG.dataset | product_type_codes | manual comma authoring | **Frozen** — derived only from **dataset_product_type** via `scripts/reference/catalog/sync_dataset_product_type_from_bridge.py` (see `DATASET_PRODUCT_TYPE_CODES_FROZEN.txt`); drop column in follow-up PR. |
| REFERENCE.CATALOG.product_type | bedroom_type_codes | manual comma authoring | **Frozen** — derived only from **bridge_product_type_bedroom_type** via `scripts/reference/catalog/sync_product_type_bedroom_codes_from_bridge.py`; drop column in follow-up PR. |
| REFERENCE.CATALOG.metric / metric_raw | unit | duplicated YAML accepted_values | **unit** seed + `dbt_utils.relationships_where` to **unit.unit_code** for active rows. |

---

## Skipped Models

<!-- Full list with reason — reviewed by Alex before any cleanup -->

| old_path | reason | owner | notes |
|----------|--------|-------|-------|
| | | | |

---

## Source Declarations Added

<!-- New entries added to sources_transform.yml -->

| vendor | table | source_name | batch |
|--------|-------|-------------|-------|
| transform_bps | PERMITS_COUNTY | transform_bps | 003 |
| bls_transform | LAUS_COUNTY | bls_transform | 004 |
| transform_lodes | OD_BG | transform_lodes | 005 |
| transform_census | ACS5 | transform_census | 005 |
| global_government_cybersyn | HOUSING_URBAN_DEVELOPMENT_TIMESERIES / _ATTRIBUTES | global_government_cybersyn | 007 |
| source_snow_us_real_estate | IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES / _ATTRIBUTES | source_snow_us_real_estate | 007 |
| source_snow_us_real_estate | IRS_ORIGIN_DESTINATION_MIGRATION_TIMESERIES | source_snow_us_real_estate | 007 |
| transform_prod_ref | OXFORD_CBSA_CROSSWALK | transform_prod_ref | 008 |
| source_entity_pretium | AMREG / WDMARCO | source_entity_pretium | 008 |
| source_snow_us_real_estate | FHFA_HOUSE_PRICE_TIMESERIES / _ATTRIBUTES | source_snow_us_real_estate | 009c |
| source_snow_us_real_estate | FREDDIE_MAC_HOUSING_TIMESERIES / _ATTRIBUTES | source_snow_us_real_estate | 009 |
| source_snow_us_real_estate | FHFA_MORTGAGE_PERFORMANCE_TIMESERIES / _ATTRIBUTES | source_snow_us_real_estate | 011 |
| source_snow_us_real_estate | FHFA_UNIFORM_APPRAISAL_TIMESERIES / _ATTRIBUTES | source_snow_us_real_estate | 011 |
| transform_apartmentiq | PROPERTYKPI_BH, BHCOMP_BH, PROPERTY_BH, UNITKPI_BH, UNIT_BH | transform_apartmentiq | 009 |
| transform_yardi_matrix | SUBMARKETMATCHZIPZCTA_BH, MARKETPERFORMANCE_BH | transform_yardi_matrix | 009 |
| transform_yardi | PROPERTY_* / TENANT_* / UNIT_* / UNIT_STATUS_* / UNITTYPE_* / TRANS_* (full list in `sources_transform_yardi_opco.yml`; **TRANS_BH**, **UNITTYPE_BH** added batch **012b**) | transform_yardi_opco | 012b |
| yardi_bh | TRANS (legacy share) | yardi_bh_legacy | 012 |
| source_prod_bls | QCEW_COUNTY_RAW | source_prod_bls | 025 |
| source_prod_onet | OCCUPATION_BASE / WORK_ACTIVITIES_GENERAL / WORK_CONTEXT | source_prod_onet | 025 |
| transform_dev_vendor_ref | REF_ONET_SOC_TO_NAICS | transform_dev_vendor_ref | 026 |
| transform_dev_legacy_pretium_ai | FACT_COUNTY_SOC_EMPLOYMENT (parity target) | transform_dev_legacy_pretium_ai | 026 |

---

## Deprecation Candidates

<!-- TRANSFORM.DEV objects that can be dropped after migration validates -->
<!-- Alex must confirm before any DROP -->
<!-- Each `reason` must include semantic purpose + recreation hint (see field guide). -->

| snowflake_object | reason | depends_on_migrated_model | confirmed_drop |
|-----------------|--------|--------------------------|----------------|
| TRANSFORM.DEV.RAW_ZILLOW_AFFORDABILITY | Duplicate of `SOURCE_PROD.ZILLOW.RAW_AFFORDABILITY` per `MIGRATION_BASELINE_RAW_TRANSFORM.md` §3; facts now `source('zillow','raw_affordability')` | fact_zillow_affordability | |
| TRANSFORM.DEV.RAW_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS | Duplicate of `SOURCE_PROD.ZILLOW.RAW_DAYS_ON_MARKET_AND_PRICE_CUTS` | fact_zillow_days_on_market_and_price_cuts | |
| TRANSFORM.DEV.RAW_ZILLOW_FOR_SALE_LISTINGS | Duplicate of `SOURCE_PROD.ZILLOW.RAW_FOR_SALE_LISTINGS` | fact_zillow_for_sale_listings | |
| TRANSFORM.DEV.RAW_ZILLOW_HOME_VALUES | Duplicate of `SOURCE_PROD.ZILLOW.RAW_HOME_VALUES` | fact_zillow_home_values | |
| TRANSFORM.DEV.RAW_ZILLOW_HOME_VALUES_FORECASTS | Duplicate of `SOURCE_PROD.ZILLOW.RAW_HOME_VALUES_FORECASTS` | fact_zillow_home_values_forecasts | |
| TRANSFORM.DEV.RAW_ZILLOW_MARKET_HEAT_INDEX | Duplicate of `SOURCE_PROD.ZILLOW.RAW_MARKET_HEAT_INDEX` | fact_zillow_market_heat_index | |
| TRANSFORM.DEV.RAW_ZILLOW_NEW_CONSTRUCTION | Duplicate of `SOURCE_PROD.ZILLOW.RAW_NEW_CONSTRUCTION` | fact_zillow_new_construction | |
| TRANSFORM.DEV.RAW_ZILLOW_RENTALS | Duplicate of `SOURCE_PROD.ZILLOW.RAW_RENTALS` | fact_zillow_rentals | |
| TRANSFORM.DEV.RAW_ZILLOW_RENTAL_FORECASTS | Duplicate of `SOURCE_PROD.ZILLOW.RAW_RENTAL_FORECASTS` | fact_zillow_rental_forecasts | |
| TRANSFORM.DEV.RAW_ZILLOW_SALES | Duplicate of `SOURCE_PROD.ZILLOW.RAW_SALES` | fact_zillow_sales | |
| TRANSFORM.DEV.FACT_CYBERSYN_HUD_TIMESERIES | Superseded by **`FACT_HUD_HOUSING_SERIES`** + grain slices **`FACT_HUD_HOUSING_SERIES_COUNTY`** / **`FACT_HUD_HOUSING_SERIES_CBSA`** | fact_hud_housing_series_county | |
| TRANSFORM.DEV.FACT_CYBERSYN_IRS_MIGRATION_BY_CHARACTERISTIC_TIMESERIES | Superseded by **`FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL`** + **`_ANNUAL_COUNTY`** / **`_ANNUAL_CBSA`** | fact_irs_soi_migration_by_characteristic_annual_county | |
| TRANSFORM.DEV.FACT_CYBERSYN_IRS_ORIGIN_DESTINATION_MIGRATION_TIMESERIES | Superseded by **`FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY`** / **`_ANNUAL_CBSA`** | fact_irs_soi_origin_destination_migration_annual_county | |
| TRANSFORM.DEV.FACT_CYBERSYN_FHFA_HOUSE_PRICE_TIMESERIES | Superseded by **`FACT_FHFA_HOUSE_PRICE`** | fact_fhfa_house_price | |
| TRANSFORM.DEV.FACT_FREDDIE_MAC_HOUSING_TIMESERIES | Superseded by **`FACT_FREDDIE_MAC_HOUSING_NATIONAL_WEEKLY`** (canonical Freddie read) | fact_freddie_mac_housing_national_weekly | |
| TRANSFORM.DEV.FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL | Removed single umbrella OD fact; use **`FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY`** / **`_ANNUAL_CBSA`** | fact_irs_soi_origin_destination_migration_annual_county | |
| TRANSFORM_PROD.CLEANED — legacy Redfin (`CLEANED_REDFIN_ZIPCODE`, `CLEANED_REDFIN_ZIPCODE_METRICS`, `CLEANED_REDFIN_CBSA`) | **Semantic purpose:** Normalize Redfin ZIP (`REDFIN_ZIPCODE`) and CBSA (`REDFIN_MSA`) into canonical grains for housing market / inventory / absorption facts; derive **months_of_supply** when the source column is null (inventory ÷ (homes_sold/3)); ZIP metrics model fed **quality pilot** hooks into `fact_quality_cleaned_redfin_zipcode`. **Recreation:** One typed **`FACT_*`** (or vendor silver pass-through) per grain from `cleaned_redfin_market_tracker_*` / `SOURCE_PROD.REDFIN`, with `metric_id` + `REFERENCE.GEOGRAPHY` join keys; centralize MOS rule once in dbt docs or a single macro. **Drop gate:** dbt `enabled=false`, but Snowflake **`OBJECT_DEPENDENCIES`** still show inbound refs from `FACT_REDFIN_ZIPCODE`, `FACT_REDFIN_CBSA`, `CLEANED.REDFIN_ZIP_METRICS`, `FACT_HOUSING_METRICS_ZIP` — **no DROP** until those stubs retarget (artifact **022**). | `cleaned_redfin_market_tracker_*` + downstream FACT port | |
| ANALYTICS_PROD.SANDBOX — 55 object names (see artifact **022** §3) | **Semantic purpose:** Non-contract **experimentation** surface — Cincinnati **IC** scoring panels and stats (`IC_*`), BPS coverage sandboxes, DDS / proto dashboards, feature–IC univariate and bivariate stats, Zonda unit-mix and deeds experiments, **Progress** vs market benchmarks, institutional-market VW slices, and `_MIGRATION_LOG_EXPERIMENTS` — i.e. “try geography × metric logic before promoting to `FEATURE_*` / `MODEL_*` / EDW delivery.” **Recreation:** Promote anything retained as **`FEATURE_*` or `MODEL_*` on `ANALYTICS.DBT_DEV`** with `metric` / `concept` / `dataset` catalog rows and tests; do not treat SANDBOX as Polaris contract. **Drop gate:** **55** names have **zero** inbound `OBJECT_DEPENDENCIES` rows (graph leaves); **29** other SANDBOX rows *are* referenced (internal view chains + `ADMIN.GOVERNANCE` ← `SBOX_T_*`). Triage with **`ACCESS_HISTORY`** FQN `ILIKE 'ANALYTICS_PROD.SANDBOX.%'` (watch versioned workspace names). | n/a | |
| *(no Snowflake object)* — pretium-ai-dbt `enabled=false` / placeholders (batch **022** IS vet) | **Semantic purpose (per model):** **`FACT_HOUSEHOLD_INCOME_ACS_LEGACY`** — legacy ACS household income at CBSA/ZIP from old `cleaned_acs_income_*` path; superseded by **`fact_household_income_acs`** (blockgroup → ZIP rollup). **`V_ECONOMIC_PROJECTIONS_ZIP` / `V_ECONOMIC_PROJECTIONS_CBSA`** — roll CBSA economic **scenario forecasts** down to ZIP using population/household weights for BI. **`MART_RENT_SIGNALS_CBSA`** — obsolete name; canonical intent is **`MART_RENT_AFFORDABILITY_CBSA`** (AMI-tier rent context, Prism / REQ / IC — see `mart_rent_affordability_cbsa.sql` header). **`ADHOC_PLACEHOLDER`** — intentional no-op. **Recreation:** Income → **`TRANSFORM.DEV` `FACT_*`** from ACS5 spine; projections → **`MODEL_*`/`ESTIMATE_*`** with explicit scenario grain; rent context → affordability mart + catalog bridges. **Drop gate:** objects **not** present in prod `INFORMATION_SCHEMA` — repo-only; gated delete removes dbt files, **no** Snowflake `DROP`. | See replacement models in pretium-ai-dbt paths above | |

---

## Batch History

**Verbose notes, Snowflake evidence, and artifact paths:** **[MIGRATION_BATCH_INDEX.md](./MIGRATION_BATCH_INDEX.md)**. **New metric intake:** **[METRIC_INTAKE_CHECKLIST.md](./METRIC_INTAKE_CHECKLIST.md)**. **Analytics features playbook:** **[PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](./PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md)**.

<!-- Cursor appends one row per session (keep notes ≤ ~200 chars; spill to BATCH_INDEX). -->

| batch | date | models_processed | operator | notes |
|-------|------|-----------------|----------|-------|
| 001 | 2026-04-19 | 10 | Cursor | Zillow pilot (10 `FACT_*`) + Oxford `REF_OXFORD_METRO_CBSA` count 302; artifact batch001 CSV. |
| 002 | 2026-04-19 | 0 | Cursor | BPS/Census/BLS/LODES phase-1 inventory; batch002 CSV; ACS5 full workbook deferred. |
| 003 | 2026-04-19 | 1 | Cursor | BPS `fact_bps_permits_county` view + describe artifact. |
| 004 | 2026-04-19 | 1 | Cursor | BPS build OK; BLS LAUS county view + row parity 5,548,860. |
| 005 | 2026-04-19 | 1 | Cursor | LODES `fact_lodes_od_bg`; ACS5 describe + source only. |
| 006 | 2026-04-19 | 0 | Alex + Cursor | Concept-methods FACT priorities doc (`MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md`). |
| 007 | 2026-04-19 | 3 | Cursor | Cybersyn HUD + IRS facts; catalog MET_008–010 / DS_079–081. |
| 007b | 2026-04-19 | 2 | Cursor | IRS read path → `source_snow_us_real_estate`. |
| 008 | 2026-04-19 | 3 | Cursor | Oxford AMREG/WDMARCO quarterly facts; DS_049–050. |
| 009 | 2026-04-19 | 2 | Cursor | FHFA + Freddie facts; ApartmentIQ/Yardi Matrix source YAML. |
| 009c | 2026-04-19 | 1 | Cursor | FHFA read path → `source_snow_us_real_estate`. |
| 010 | 2026-04-18 | 9 | Cursor | HUD/IRS grain splits; Cybersyn dedupe; MET_013–015. |
| 011 | 2026-04-18 | 8 | Cursor | FHFA tier-3 + county/CBSA HPI slices; MET_016–020 / DS_084–085. |
| 012 | 2026-04-18 | 6 | Cursor | Fund OPCO Yardi facts; sources + vars. |
| 012b | 2026-04-19 | 0 | Cursor | Yardi §1.5 artifacts under `artifacts/batch012_yardi/`. |
| 012c | 2026-04-19 | 2 | Cursor | BPS/LODES equal_rowcount warn tests; BPS/LODES doc downstream subsection. |
| 013 | 2026-04-19 | 1 | Cursor | Canonical completion doc + `feature_rent_market_monthly_spine`. |
| 014 | 2026-04-19 | 0 | Cursor | Catalog seed read + Snowflake vetting; Cybersyn TSV vs vendor map; METRIC row drift pre-seed (see INDEX). |
| 014b | 2026-04-19 | 0 | Cursor | `metric.csv` RFC4180 quoting; `frequency.varies` + schema accepted_values. |
| 014c | 2026-04-19 | 0 | Cursor | `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`; FACT playbook Wave G; EF rent doc physical-home note. |
| 015 | 2026-04-19 | 0 | Cursor | Dimensional validation SQL; catalog FK 0 failures; 64,145 `unmapped` geo rows — see `VENDOR_CONCEPT_COVERAGE_MATRIX.md` §7–8. |
| 016 | 2026-04-19 | 0 | Cursor | `VENDOR_CONCEPT_COVERAGE_MATRIX.md` (vendor×concept×dataset + source_schema vet). |
| 017 | 2026-04-19 | 1 | Cursor | `metric_derived` seed + schema + catalog wave; bridge_product_type_metric still empty. |
| 018 | 2026-04-19 | 0 | Cursor | **Catalog-only vendors — `snowsql -c pretium`:** `VENDOR_CATALOG_ONLY_SNOWSQL_VET.md` + `scripts/sql/migration/vet_catalog_only_vendors_pretium.sql`. RAW 13 schemas (no BEA/CFPB/FBI/USPS/NOAA); GLOBAL_GOVERNMENT.CYBERSYN 106 objects; FBI_CRIME_TIMESERIES 21,232 rows / 52 GEO_ID / 10 variables / 1979–2023 / 0 null VALUE; FDIC/USPS/NOAA/CFPB Cybersyn views not SELECT-authorized on vet role; SOURCE_PROD.FDIC.CONSTRUCTION_LOANS_RAW 0 rows; SOURCE_ENTITY.PROGRESS 0 tables visible; CYBERSYN_DATA_CATALOG has no BEA/HMDA name hit in filter. Matrix §G links vet. |
| 019 | 2026-04-19 | 1 | Cursor | **Playbook v5 implementation:** `PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md` (§§A–O); `CATALOG_SIGNALS_LAYOUT.md` + `CATALOG_MODELS_LAYOUT.md` (design-only); `ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md`; `scripts/sql/validation/README.md` + `feature_rent_market_spine_vs_concept_reconciliation.sql` (Pilot A Q); `feature_rent_market_monthly_spine` tests (`equal_rowcount` vs concept, not_null keys); hub links + pretium-ai-dbt `SEMANTIC_LAYER_PLAYBOOK_LINK.md`. See **MIGRATION_BATCH_INDEX** batch 019. |
| 020 | 2026-04-18 | 2 | Cursor | **Cybersyn grants (blocked) + vet artifact + CRM + bridge:** Re-ran `vet_catalog_only_vendors_pretium.sql`; row counts in `docs/migration/artifacts/2026-04-18_vet_catalog_only_vendors_rowcounts.md`. FDIC/USPS/CFPB Cybersyn `SELECT` and `GRANT SELECT` fail (`002003`) — share provisioning, not local role grant. Salesforce: `DS_SOURCE_PROD_SFDC.SFDC_SHARE` 283 tables; `SOURCE_ENTITY.PROGRESS` 381 tables. **`bridge_product_type_metric.csv`:** nine rows (`bridge_product_type_metric_id` 1–9; Snowflake column type) binding each `product_type_code` to **`cybersyn_fhfa_house_price_timeseries_value`** (MET_011); `dbt seed --select bridge_product_type_metric --full-refresh` + tests pass. |
| 021 | 2026-04-19 | 0 | Cursor | **Quality gates enforced:** `.github/workflows/semantic_layer_catalog_and_quality.yml` (`dbt deps`, `dbt parse`, `dbt ls` for `path:seeds/reference/catalog`); `ci/profiles.yml` parse target; `scripts/ci/run_catalog_quality_checks.sh`. **`dbt_utils.equal_rowcount`** YAML: nest `compare_model` under `arguments:` in **`models/transform/dev/bps/schema.yml`** + **`lodes/schema.yml`**. Docs: **`METRIC_INTAKE_CHECKLIST.md`**, **`PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md` §D**, **`scripts/sql/validation/README.md`**, **`MIGRATION_RULES.md`** — link CI + local script. **Vet:** `dbt test --select path:seeds/reference/catalog` PASS (**801** data tests, **803** total with hooks); `dimensional_reference_catalog_and_geography.sql` — catalog/geo FK checks **0** failures; **`GEOGRAPHY_INDEX` unmapped** = **64,145** (backlog signal). Artifact: **`docs/migration/artifacts/2026-04-19_semantic_layer_quality_gate_results.md`**. |
| 022 | 2026-04-19 | 0 | Cursor | **`snowsql -c pretium`:** `pretium-ai-dbt/scripts/sql/migration/inventory_deprecation_candidates_batch022.sql` — `ANALYTICS_PROD.SANDBOX` **89** rels; **`OBJECT_DEPENDENCIES`** inbound to SANDBOX **29** rows; **55** SANDBOX names with **0** inbound dep edges; legacy Redfin **CLEANED_REDFIN_*** still referenced by **4** edges (`FACT_REDFIN_*`, `REDFIN_ZIP_METRICS`, `FACT_HOUSING_METRICS_ZIP`). IS vet: disabled dbt models **not** materialized in prod. Evidence: **`docs/migration/artifacts/2026-04-19_batch022_deprecation_governance_snowsql.md`**. |
| 023 | 2026-04-19 | 1 | Cursor | **Sources + LODES hex:** `sources_redfin.yml` (`redfin` + `source_redfin`), `sources_cherre_share.yml` (`cherre.tax_assessor_v2`), `transform_lodes.od_h3_r8`; **`fact_lodes_od_h3_r8_annual`** view + equal_rowcount warn test; **`catalog_wishlist`** WL_047/WL_048 → `in_progress`. `dbt run` + targeted `dbt test` PASS. |
| 024 | 2026-04-19 | 30 | Cursor | **Fund modeling — SOURCE_ENTITY.PROGRESS:** `models/sources/sources_source_entity_progress.yml` + **15** `fact_sfdc_*` + **15** `fact_se_yardi_*` (purpose-named Yardi entity read-through **views**; gated `transform_dev_enable_source_entity_progress_facts`, default false). `fund_opco/README.md` + `_source_entity_progress_facts.yml`. `dbt parse` PASS. |
| 024b | 2026-04-19 | 15 | Cursor | **Rename Yardi SOURCE_ENTITY read-throughs:** `fact_entity_yardi_*` → **`fact_se_yardi_*`** (`se` = SOURCE_ENTITY lineage); suffixes by object purpose (e.g. **YARDI_GLTOTAL** → **`fact_se_yardi_gl_period_total`**). |
| 024c | 2026-04-19 | 6 | Cursor | **Fund modeling concepts:** **`concept_progress_*`** TRANSFORM.DEV **tables** over SOURCE_ENTITY facts (`concept_progress_property`, `fund_allocation`, `market_submarket`, `acquisition_uw`, `acquisition_velocity`, `disposition_bpo`); tag **`source_entity_progress_concept`**, selector **`source_entity_progress_concepts`**; join-key vars `concept_progress_sfdc_yardi_property_code_column` / `concept_progress_yardi_propattr_property_code_column`; `_source_entity_progress_concepts.yml`. `dbt parse` PASS. |
| 024d | 2026-04-19 | 14 | Cursor | **Catalog — Progress fund spine:** `concept.csv` **CON_022** `fund_property_spine`, **CON_023** `acquisition_underwriting`; `metric.csv` **MET_029–MET_040** (12 starter columns on `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` / `CONCEPT_PROGRESS_ACQUISITION_UW`). Vet SQL: **`scripts/sql/validation/describe_concept_progress_catalog_shortlist.sql`**. No **`metric_derived`** rows (defer PR2). |
| 024e | 2026-04-19 | 2 | Cursor | **Progress fund canvas — TRANSFORM runbook + market gap:** `concept_progress_rent` (see 024c family); **`docs/migration/PROGRESS_FUND_CANVAS_TRANSFORM_RUNBOOK_AND_MARKET_GAP.md`** — ordered ops (grants → `source_entity_progress_facts` → `source_entity_progress_concepts` → join vet → **`T-VENDOR-YARDI-READY`**); **`concept_rent_*` / labor / vendor task** gap table vs rent–market calculator spine. Link from **`models/transform/dev/fund_opco/README.md`**. |
| 025 | 2026-04-19 | 1 | Cursor | **BLS/QCEW + O*NET vet; FACT:** `vet_source_prod_bls_qcew_onet_for_workforce_facts.sql` (213M raw; O*NET row counts); `fact_bls_qcew_county_naics_quarterly` + `sources_source_prod_bls_onet.yml` + schema tests. Artifact **`artifacts/2026-04-19_batch025_bls_qcew_onet_vet_and_fact.md`**. `dbt parse` PASS. |
| 026 | 2026-04-19 | 8 | Cursor | **Labor automation FACT spine:** DOL/O*NET GWA + friction + SOC AI exposure; Epoch refs; `fact_county_soc_employment` + `fact_county_ai_replacement_risk`; vendor ref **`transform_dev_vendor_ref.ref_onet_soc_to_naics`** + landing SQL; legacy parity source + warn tests; **`LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`**. Task **T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK** partial — FEATURE/MART/model still open. Artifact **`artifacts/2026-04-19_batch026_labor_automation_risk_stack.md`**. |
| 027 | 2026-04-19 | 4 | Cursor | **Labor FEATURE views (P1):** `feature_ai_replacement_risk_county`, `feature_ai_replacement_risk_cbsa`, `feature_ai_replacement_risk_cbsa_rollup`, `feature_structural_unemployment_risk_county` under **`models/analytics/feature/`**; read **`ref('fact_county_ai_replacement_risk')`**; `onet_soc_naics_enabled` var + schema tests (enabled when var true); runbook FEATURE section. **T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK** — MART/model/AIGE still open. Artifact **`artifacts/2026-04-19_batch027_labor_automation_feature_views.md`**. |
| 028 | 2026-04-20 | 7 | Cursor | **Wave-gap metric registration (non-duplicative):** attempted interim `metric.csv` rows; superseded by batch **029** full catalog rebuild (repo previously tracked header-only `metric.csv`). |
| 029 | 2026-04-20 | 2 | Cursor | **Catalog metric seed rebuild + FACT gap closure:** regenerated `seeds/reference/catalog/metric.csv` (**MET_001–MET_079**) to satisfy **`bridge_product_type_metric`** FK coverage (**72** distinct `metric_code`s) and register additional Wave 1/2 **`TRANSFORM.DEV.FACT_*`** surfaces (Oxford, remaining Zillow research panels, `FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL`, `FACT_AIGE_COUNTIES`, `FACT_TRANSFORM_CONCEPT_EMPLOYMENT_*`, plus observe-only umbrella/crosswalk rows). Added generator: `scripts/_gen_metric_csv.py`. |
| 030 | 2026-04-20 | 0 | Cursor | **REFERENCE.CATALOG (Alex):** added **`concept.csv`** rows **CON_024–CON_028** (`rates`, `inflation`, `wages`, `labor`, `transactions`); retagged **39** `metric.csv` rows (SOURCE_PROD.RATES bundle, Oxford `average_weekly_wages_*`, CPS LFPR pair); removed **`CONCEPT_REMAP`** from **`scripts/sync_metric_csv_from_pretium_ai_dbt.py`** (geo remaps only). Mirrored **`concept.csv`** + **`metric.csv`** to **pretium-ai-dbt** catalog seeds. `dbt seed --select concept metric --full-refresh` → **28** concepts, **4969** metrics. |
| 031 | 2026-04-20 | 0 | Cursor | **Snowflake operator objects (Alex):** `snowsql -c pretium -f docs/migration/sql/land_oxford_cbsa_crosswalk_transform_dev.sql` → **`TRANSFORM.DEV.OXFORD_CBSA_CROSSWALK`** (**302** rows). **`sync_bridge_zip_h3_r8_polyfill_reference_geography.sql`** (new) clone **`ANALYTICS.REFERENCE.BRIDGE_ZIP_H3_R8_POLYFILL`** → **`REFERENCE.GEOGRAPHY.BRIDGE_ZIP_H3_R8_POLYFILL`** (~11.7M rows). **`GRANT SELECT`** to **`STRATA_ADMIN_APP`** on crosswalk + bridge + **`REF_SCHOOL_DISTRICT_H3_XWALK`**. `dbt run --select ref_school_district_h3_xwalk` + **`ref_oxford_metro_cbsa`**, **`fact_lodes_nearest_center_h3_r8_annual`**, **`fact_stanford_seda_h3_r8_snapshot`**, **`fact_oxford_amreg_quarterly`** — OK. `grant_select_transform_dev_oxford_cbsa_crosswalk.sql` added for repeatability. |
| 032 | 2026-04-20 | 2 | Cursor | **Nearest-center hex spine → BG:** `fact_lodes_nearest_center_h3_r8_annual` uses **`BLOCKGROUP_H3_R8_POLYFILL`** (was ZIP bridge); **pretium-ai-dbt** + semantic-layer; DS_089 + corridor docs/lineage/QA. |
| 033 | 2026-04-21 | 4 | Cursor | **Corridor concepts + catalog + physical home:** `concept_transactions_market_monthly` / `concept_supply_pipeline_market_monthly` — `dbt_project.yml` **`transform.dev.concept`** forces **TRANSFORM.DEV** (fixes mistaken **ANALYTICS.DBT_DEV** builds). **`metric.csv`** **MET_127–MET_132** for observe rows; `schema.yml` union-semantics notes; singular vendor allowlist tests under **`tests/concept_corridor/`**; **`SERVING_DEMO_RELEASE_BUNDLE_ICEBERG_GATE.md`** §1a drop/rebuild; vet SQL header; **`CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md`** dedupe + MET cross-ref. |
| 034 | 2026-04-23 | 60+ | Cursor | **REFERENCE.CATALOG enum consolidation:** merged ~57 small-enum CSVs into **`seeds/reference/catalog/catalog_enum_source.csv`**; **`catalog_enum`** reads that seed + **`frequency`** / **`asset_type`** / **`tenant_type`**; added **`models/reference/catalog/enum_refs/erf__*.sql`** for **`relationships`** tests; **`build_catalog_enum_source_seed.py`** (full rebuild vs erf-only); removed per-enum CSVs; dropped empty schema YAMLs (**`schema_financial_tiers`**, **`schema_hazard_environmental`**, **`schema_market_analytics`**, **`schema_property_attributes`**); slimmed **`_catalog.yml`**, **`CATALOG_SEED_ORDER.md`**, **`ENUM_CONSOLIDATION_DBT_REFS.md`**. `dbt parse` PASS. |
| 035 | 2026-04-23 | 0 | Cursor | **Catalog unblock (`CURSOR_CATALOG_UNBLOCK_PROMPT.md`):** **`bridge_product_type_bedroom_type`** + **`unit`** seeds; **`sync_dataset_product_type_from_bridge.py`**; singular hard gates Q6/Q7/Q11/Q19 + **`selector:catalog_hard_gates`** + CI **`dbt compile --select tag:catalog_hard_gate`**; **`DATASET_PRODUCT_TYPE_CODES_FROZEN.txt`**; removed YAML unit parity script. `dbt parse` / compile PASS. |
