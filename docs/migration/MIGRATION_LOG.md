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
| **Deprecation candidates** | **Legacy Snowflake names** (e.g. `TRANSFORM_PROD.*`, old `EDW_PROD.*`, compat **views** for `ANALYTICS.FACTS.*`) droppable **after** consumers use the **canonical** name only. `confirmed_drop` blank until Alex signs off on **`DROP`**. |
| **Batch history** | One row per Cursor session: `batch` increments `001`, `002`, …; `models_processed` = count touched; `notes` = scope (e.g. `Zillow FACT models pass 1`). |
| **Alex handoff (cross-repo)** | After each migration **task batch** in **pretiumdata-dbt-semantic-layer**, the agent **asks Alex** to run **`dbt compile` / `dbt build` / `dbt test`** in **pretium-ai-dbt** on the affected downstream selection and confirm pass/fail before merge. Logged batch **006**; detail: **`MIGRATION_TASKS_CONCEPT_METHOD_FACT_PRIORITIES.md`**. |

---

## Summary Counters
<!-- Cursor updates these after each batch -->

| Category | Total Found | Migrated | Skipped | Pending |
|----------|-------------|----------|---------|---------|
| RAW_ models | | | | |
| FACT_ models (T-TRANSFORM-DEV cluster) | 81 | 20 | 0 | 61 |
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

---

## Geo Corrections Applied

<!-- Log every join fix made during migration -->

| model | correction | old_reference | new_reference |
|-------|-----------|---------------|---------------|
| | | | |

---

## Type Fixes Applied

| model | column | old_type | fix_applied |
|-------|--------|----------|-------------|
| | | | |

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

---

## Deprecation Candidates

<!-- TRANSFORM.DEV objects that can be dropped after migration validates -->
<!-- Alex must confirm before any DROP -->

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
