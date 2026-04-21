# QA — `REFERENCE.CATALOG.metric` statistical inventory & tests

**Purpose:** Single inventory of **all active `MET_*` rows** in `seeds/reference/catalog/metric.csv` (as of this doc) and the **statistical / parity checks** that enforce them in this repo.

**Canon:** Bounds are **pragmatic screening rules** (catch bad joins, unit mistakes, exploded imputations)—not econometric proof. Tune thresholds in `tests/catalog_metric_statistical/assert_metric_bounds_registered_in_catalog.sql` when Jon silver contracts change.

## 1) Full metric register (72 rows)

| `metric_id` | `metric_code` | `unit` | `snowflake_column` | `table_path` (abbrev.) |
|-------------|---------------|--------|--------------------|-------------------------|
| MET_001 | bps_permits_measure_value | varies | VALUE | …FACT_BPS_PERMITS_COUNTY |
| MET_002 | bls_laus_unemployment_rate_county | pct | VALUE | …FACT_BLS_LAUS_COUNTY |
| MET_003 | bls_laus_unemployed_persons_county | count | VALUE | …FACT_BLS_LAUS_COUNTY |
| MET_004 | bls_laus_employment_persons_county | count | VALUE | …FACT_BLS_LAUS_COUNTY |
| MET_005 | bls_laus_labor_force_persons_county | count | VALUE | …FACT_BLS_LAUS_COUNTY |
| MET_006 | lehd_lodes_od_bg_jobs_total | count | JOBS_TOTAL | …FACT_LODES_OD_BG |
| MET_007 | cybersyn_hud_timeseries_value | varies | VALUE | …FACT_HUD_HOUSING_SERIES_COUNTY |
| MET_008 | cybersyn_hud_timeseries_value_cbsa | varies | VALUE | …FACT_HUD_HOUSING_SERIES_CBSA |
| MET_009 | cybersyn_irs_migration_by_characteristic_value | varies | VALUE | …FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL_COUNTY |
| MET_010 | cybersyn_irs_od_migration_value | varies | VALUE | …FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_COUNTY |
| MET_011 | cybersyn_irs_migration_by_characteristic_value_cbsa | varies | VALUE | …FACT_IRS_SOI_MIGRATION_BY_CHARACTERISTIC_ANNUAL_CBSA |
| MET_012 | cybersyn_irs_od_migration_value_cbsa | varies | VALUE | …FACT_IRS_SOI_ORIGIN_DESTINATION_MIGRATION_ANNUAL_CBSA |
| MET_013 | cybersyn_fhfa_house_price_timeseries_value | varies | VALUE | …FACT_FHFA_HOUSE_PRICE_COUNTY |
| MET_014 | cybersyn_fhfa_house_price_timeseries_value_cbsa | varies | VALUE | …FACT_FHFA_HOUSE_PRICE_CBSA |
| MET_015 | cybersyn_fhfa_mortgage_performance_value_county | varies | VALUE | …FACT_FHFA_MORTGAGE_PERFORMANCE_COUNTY |
| MET_016 | cybersyn_fhfa_mortgage_performance_value_cbsa | varies | VALUE | …FACT_FHFA_MORTGAGE_PERFORMANCE_CBSA |
| MET_017 | cybersyn_fhfa_uniform_appraisal_value_county | varies | VALUE | …FACT_FHFA_UNIFORM_APPRAISAL_COUNTY |
| MET_018 | cybersyn_fhfa_uniform_appraisal_value_cbsa | varies | VALUE | …FACT_FHFA_UNIFORM_APPRAISAL_CBSA |
| MET_019 | freddie_mac_housing_timeseries_value | varies | VALUE | …FACT_FREDDIE_MAC_HOUSING_NATIONAL_WEEKLY |
| MET_020 | bls_qcew_county_naics_employment | count | employment | …FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY |
| MET_021 | bls_qcew_county_naics_total_wages | usd | total_wages | …FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY |
| MET_022 | bls_qcew_county_naics_establishments | count | establishments | …FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY |
| MET_023 | bls_qcew_county_naics_avg_weekly_wage | usd | avg_weekly_wage | …FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY |
| MET_024 | pretium_epoch_gwa_crosswalk_exposure_weight | index | exposure_weight | …REF_EPOCH_TO_GWA_CROSSWALK |
| MET_025 | dol_onet_soc_gwa_activity_risk_score | index | gwa_activity_risk_score | …FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK |
| MET_026 | dol_onet_soc_work_context_friction_index | index | friction_index | …FACT_DOL_ONET_SOC_CONTEXT_FRICTION |
| MET_027 | dol_onet_soc_ai_friction_adjusted_exposure | index | friction_adjusted_exposure | …FACT_DOL_ONET_SOC_AI_EXPOSURE |
| MET_028 | bls_qcew_allocated_county_soc_estimated_employment | count | estimated_employment | …FACT_COUNTY_SOC_EMPLOYMENT |
| MET_029 | progress_fund_spine_property_number | varies | sf_properties__PROPERTYNUMBER__C | …CONCEPT_PROGRESS_PROPERTY |
| MET_030 | progress_fund_spine_cap_rate | pct | sf_properties__CAP_RATE__C | …CONCEPT_PROGRESS_PROPERTY |
| MET_031 | progress_fund_spine_gross_yield | pct | sf_properties__GROSS_YIELD__C | …CONCEPT_PROGRESS_PROPERTY |
| MET_032 | progress_fund_spine_home_condition_score | index | sf_properties__HOME_CONDITION_SCORE__C | …CONCEPT_PROGRESS_PROPERTY |
| MET_033 | progress_fund_spine_yardi_tier | varies | yardi_propattr__TIER | …CONCEPT_PROGRESS_PROPERTY |
| MET_034 | progress_fund_spine_yardi_property_status | varies | yardi_propattr__PROPERTY_STATUS | …CONCEPT_PROGRESS_PROPERTY |
| MET_035 | progress_acquisition_uw_acquisition_purchase_price | usd | acquisition__PURCHASE_PRICE__C | …CONCEPT_PROGRESS_ACQUISITION_UW |
| MET_036 | progress_acquisition_uw_acquisition_cap_rate | pct | acquisition__CAP_RATE__C | …CONCEPT_PROGRESS_ACQUISITION_UW |
| MET_037 | progress_acquisition_uw_acquisition_net_yield | pct | acquisition__NET_YIELD__C | …CONCEPT_PROGRESS_ACQUISITION_UW |
| MET_038 | progress_acquisition_uw_fdd_purchase_price | usd | fdd__PURCHASE_PRICE__C | …CONCEPT_PROGRESS_ACQUISITION_UW |
| MET_039 | progress_acquisition_uw_fdd_closing_date | varies | fdd__CLOSING_DATE__C | …CONCEPT_PROGRESS_ACQUISITION_UW |
| MET_040 | progress_acquisition_uw_fdd_stabilized | varies | fdd__STABILIZED__C | …CONCEPT_PROGRESS_ACQUISITION_UW |
| MET_041 | zillow_rentals_metric_value | varies | METRIC_VALUE | …FACT_ZILLOW_RENTALS |
| MET_042 | zillow_days_on_market_and_price_cuts_metric_value | varies | METRIC_VALUE | …FACT_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS |
| MET_043 | zillow_for_sale_listings_metric_value | varies | METRIC_VALUE | …FACT_ZILLOW_FOR_SALE_LISTINGS |
| MET_044 | markerr_rent_property_cbsa_avg_rent_effective | usd | AVG_RENT_EFFECTIVE | …FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY |
| MET_045 | markerr_rent_property_cbsa_avg_rent_asking | usd | AVG_RENT_ASKING | …FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY |
| MET_046 | yardi_matrix_marketperformance_bh_datavalue | varies | DATAVALUE | …FACT_YARDI_MATRIX_MARKETPERFORMANCE_BH |
| MET_047 | costar_scenarios_market_effective_rent_per_unit | usd | MARKET_EFFECTIVE_RENT_PER_UNIT | …FACT_COSTAR_SCENARIOS |
| MET_048 | costar_scenarios_market_asking_rent_per_unit | usd | MARKET_ASKING_RENT_PER_UNIT | …FACT_COSTAR_SCENARIOS |
| MET_049 | county_ai_replacement_risk_combined_score | index | combined_risk_score | …FACT_COUNTY_AI_REPLACEMENT_RISK |
| MET_050 | realtor_inventory_cbsa_observe | varies | VALUE | …FACT_REALTOR_INVENTORY_CBSA |
| MET_051 | markerr_rent_sfr_observe | varies | MULTI_COLUMN | …FACT_MARKERR_RENT_SFR |
| MET_052 | costar_mf_market_cbsa_monthly_observe | varies | MULTI_COLUMN | …FACT_COSTAR_MF_MARKET_CBSA_MONTHLY |
| MET_053 | oxford_amreg_quarterly_observe | varies | VALUE | …FACT_OXFORD_AMREG_QUARTERLY |
| MET_054 | oxford_wdmarco_quarterly_observe | varies | VALUE | …FACT_OXFORD_WDMARCO_QUARTERLY |
| MET_055 | zillow_home_values_observe | varies | METRIC_VALUE | …FACT_ZILLOW_HOME_VALUES |
| MET_056 | zillow_sales_observe | varies | METRIC_VALUE | …FACT_ZILLOW_SALES |
| MET_057 | zillow_affordability_observe | varies | METRIC_VALUE | …FACT_ZILLOW_AFFORDABILITY |
| MET_058 | zillow_home_values_forecasts_observe | varies | METRIC_VALUE | …FACT_ZILLOW_HOME_VALUES_FORECASTS |
| MET_059 | zillow_market_heat_index_observe | varies | METRIC_VALUE | …FACT_ZILLOW_MARKET_HEAT_INDEX |
| MET_060 | zillow_new_construction_observe | varies | METRIC_VALUE | …FACT_ZILLOW_NEW_CONSTRUCTION |
| MET_061 | zillow_rental_forecasts_observe | varies | METRIC_VALUE | …FACT_ZILLOW_RENTAL_FORECASTS |
| MET_062 | fhfa_house_price_observe | varies | VALUE | …FACT_FHFA_HOUSE_PRICE_COUNTY |
| MET_063 | fhfa_uniform_appraisal_observe | varies | VALUE | …FACT_FHFA_UNIFORM_APPRAISAL_COUNTY |
| MET_064 | yardi_matrix_submarketmatch_zipzcta_bh_observe | varies | MULTI_COLUMN | …FACT_YARDI_MATRIX_SUBMARKETMATCH_ZIPZCTA_BH |
| MET_065 | cherre_vacant_h3_r8_mf_vacant_parcels | count | MULTI_COLUMN | …FACT_CHERRE_VACANT_H3_R8_MF |
| MET_066 | rent_median_psf_zip_monthly_planned | usd | MULTI_COLUMN | …FACT_RENT_MEDIAN_PSF_ZIP_MONTHLY_PLANNED |
| MET_067 | cybersyn_acs5_median_household_income_county_planned | usd | VALUE | …FACT_ACS5_MEDIAN_HOUSEHOLD_INCOME_COUNTY_PLANNED |
| MET_068 | supply_pipeline_under_construction_units_county_planned | count | MULTI_COLUMN | …FACT_SUPPLY_PIPELINE_UNDER_CONSTRUCTION_UNITS_COUNTY_PLANNED |
| MET_069 | cherre_recorder_sale_transactions_county_planned | count | MULTI_COLUMN | …FACT_CHERRE_RECORDER_SALE_TRANSACTIONS_COUNTY_PLANNED |
| MET_070 | markerr_rent_listings_county_cnt_multi_family | count | MULTI_COLUMN | …FACT_MARKERR_RENT_LISTINGS_COUNTY_CNT_MULTI_FAMILY_PLANNED |
| MET_071 | census_pep_cbsa_annual_observe | count | MULTI_COLUMN | …FACT_CENSUS_PEP_CBSA_ANNUAL |
| MET_072 | census_pep_county_annual_observe | count | MULTI_COLUMN | …FACT_CENSUS_PEP_COUNTY_ANNUAL |

**WL_020 read-through parity (pretium-ai-dbt alignment):** `dbt_utils.equal_rowcount` in `schema.yml` is **off by default** (`semantic_layer_qa_transform_dev_bound_tests: false`) until `dbt run` has created the DEV views. **MET_*** for wide CoStar MF export columns remains **deferred** until column inventory closes (`MIGRATION_TASKS_COSTAR.md` §1.5).

## 2) Automated tests (this repo)

| Mechanism | Path | What it covers |
|-----------|------|----------------|
| **Singular — bounded numeric sanity** | `tests/catalog_metric_statistical/assert_metric_bounds_registered_in_catalog.sql` | **MET_001–MET_028**, **MET_041–MET_043** (core). **MET_029–MET_040** deferred (`CONCEPT_PROGRESS_*`). |
| **Singular — WL_020 read-throughs** | `tests/catalog_metric_statistical/assert_metric_bounds_wl020_readthrough_metrics.sql` | **MET_044–MET_048** only; **`enabled`** when `semantic_layer_qa_transform_dev_bound_tests: true` (see `dbt_project.yml`). |
| **Model + `equal_rowcount` + `expression_is_true`** | `models/transform/dev/{costar,markerr,yardi_matrix}/schema.yml` | Same var **`semantic_layer_qa_transform_dev_bound_tests`** (default **false**). Run `dbt run` for the four WL_020 views, set var **true**, then `dbt test`. |
| **Snowflake catalog registration** | `scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql` | Object exists + column exists for registered `table_path` / `snowflake_column`. |

## 3) How to run

```bash
# Core catalog-metric singular (MET_001–028, 041–043): runs by default with tag.
dbt test --select tag:catalog_metric_statistical

# Build WL_020 read-through views, then enable parity + bounds tests:
dbt run --select fact_costar_scenarios fact_costar_mf_market_cbsa_monthly fact_markerr_rent_property_cbsa_monthly fact_yardi_matrix_marketperformance_bh
dbt test --select tag:catalog_metric_statistical --vars '{"semantic_layer_qa_transform_dev_bound_tests": true}'
```

**dbt_utils:** do not put the column name at the start of `expression_is_true` when the test lives under **`columns:`** — the macro prepends `column_name`.

**Concept Progress (`MET_029`–`MET_040`):** add **dbt column tests** after `enabled` defaults flip and `DESCRIBE` artifacts lock **SFDC / Yardi** prefixed column names; until then rely on **fund_opco** model tests and manual QA.

## 4) Related

- [`METRIC_INTAKE_CHECKLIST.md`](./METRIC_INTAKE_CHECKLIST.md)
- [`QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md`](./QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md)
- [`MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md`](./MIGRATION_TASKS_EF_RENT_PREBAKED_METRICS.md) (`bridge_product_type_metric`, WL_020)
- **Concept → `MET_*` statistical hints + FEATURE autocorrelation (ACF):** [`../reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md`](../reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md)
