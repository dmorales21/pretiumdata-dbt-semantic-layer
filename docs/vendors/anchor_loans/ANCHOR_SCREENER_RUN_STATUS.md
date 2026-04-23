# Anchor Screener Run Status

**Run:** `dbt run --select +tag:anchor_screener`  
**Vars:** `zonda_starts_closings_available: true`, `anchor_starts_closings_from_zonda: true`, `anchor_starts_closings_from_mf_fact: false`  
**Source:** `/tmp/anchor_screener_run.log` (2026-02-11)

---

## Succeeding Models (67)

| # | Model |
|---|-------|
| 1 | cleaned_carto_major_retailers |
| 2 | cleaned_cherre_recorder_pricing |
| 3 | cleaned_cherre_recorder_sales |
| 4 | cleaned_cherre_rent_roll |
| 5 | cleaned_cherre_tax_assessor_pricing |
| 6 | cleaned_cotality_crime_school_tract_ts_tall |
| 7 | cleaned_education_public_k12_schools |
| 8 | cleaned_markerr_crime_zip_long |
| 9 | cleaned_markerr_realrent_listing |
| 10 | cleaned_realtor_zip_metrics |
| 11 | cleaned_redfin_zipcode |
| 12 | zillow_zhvi_zip |
| 13 | funnel_client_funnel |
| 14 | funnel_lease_transaction_history |
| 15 | funnel_listing_history_daily |
| 16 | parcllabs_comps |
| 17 | parcllabs_rent_listings |
| 18 | ref_anchor_deal_geography_resolved |
| 19 | ref_builder_locations |
| 20 | ref_cherre_mls_bedrooms_mapping |
| 21 | ref_cherre_mls_product_type_mapping |
| 22 | ref_cherre_mls_status_mapping |
| 23 | fact_cps_labor_ts |
| 24 | household_hh_demographics_acs_age_bins |
| 25 | household_hh_demographics_cps_age_bins |
| 26 | household_hh_demographics_household_formation |
| 27 | v_anchor_zonda_comps |
| 28 | yardi_progress_property_attributes |
| 29 | fact_place_major_retailers |
| 30 | sfdc_account_leases |
| 31 | yardi_lease_history |
| 32 | yardi_prospect |
| 33 | yardi_tenant |
| 34 | yardi_tenant_history |
| 35 | fact_cherre_recorder_pricing |
| 36 | fact_place_plc_education_all_ts |
| 37 | fact_place_plc_safety_all_ts |
| 38 | fact_zillow_zhvi_pricing |
| 39 | yardi_unit |
| 40 | fact_cherre_tax_assessor_pricing |
| 41 | fact_markerr_realrent_listing |
| 42 | fact_housing_pricing_cherre_rent_roll |
| 43 | fact_realtor_pricing |
| 44 | housing_hou_demand_funnel_bh |
| 45 | housing_hou_inventory_funnel_bh |
| 46 | household_hh_labor_all_ts |
| 47 | ref_anchor_deal_builders_within_5mi |
| 48 | fact_redfin_inventory |
| 49 | cleaned_cherre_mls_inventory_zip |
| 50 | household_hh_demographics_all_ts |
| 51 | fact_parcllabs_inventory |
| 52 | fact_parcllabs_pricing |
| 53 | cleaned_cherre_mls_pricing_zip |
| 54 | v_anchor_deal_screener_retailers |
| 55 | v_anchor_deal_screener_retailers_detail |
| 56 | housing_hou_demand_yardi_sfdc |
| 57 | housing_hou_pricing_yardi |
| 58 | v_anchor_crime_score_by_zip |
| 59 | v_anchor_school_score_by_zip |
| 60 | housing_hou_inventory_yardi |
| 61 | fact_housing_demand_cherre_recorder |
| 62 | sfdc_properties |
| 63 | yardi_progress_properties |
| 64 | cleaned_cherre_mls_rent_t3_change |
| 65 | progress_properties |
| 66 | unified_portfolio |
| 67 | housing_hou_demand_all_ts |

*Log truncated; models 68–76 (e.g. housing_hou_inventory_cherre_mls, housing_hou_pricing_cherre_mls, v_anchor_deal_screener) may have completed after.*

---

## Failing Models (2)

| # | Model | Cause |
|---|-------|-------|
| 1 | cleaned_zonda_starts_closings | Schema 'SOURCE_PROD.ZONDA' did not exist (Zonda now configured for DS_TPANALYTICS.ZONDA) |
| 2 | v_anchor_tear_sheet_coverage_summary | (See dbt logs for error) |

---

## Skipped Models (2)

*Skipped due to upstream failure.*

| # | Model | Upstream failure |
|---|-------|------------------|
| 1 | fact_zonda_starts_closings_all_ts | cleaned_zonda_starts_closings |
| 2 | v_anchor_starts_closings_cbsa | fact_zonda_starts_closings_all_ts |

---

## Summary

| Status | Count |
|--------|-------|
| SUCCESS | 67+ |
| ERROR | 2 |
| SKIP | 2 |
| **Total** | **76** |
