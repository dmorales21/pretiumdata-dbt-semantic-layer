# Anchor Screener – Upstream Dependencies and Failures

**Purpose:** Track failing models in the Anchor pipeline (`+tag:anchor_screener`) and what is required to fix them.  
**Run:** `dbt run --select +tag:anchor_screener` (or `./scripts/anchor/run_anchor_pipeline.sh`).

---

## 1. Dependency chain (Anchor delivery)

```
SOURCE_ENTITY.ANCHOR_LOANS.DEALS
SOURCE_PROD (ai_capabilities: cotality, markerr, education – discover via scripts/discovery)
TRANSFORM_PROD.CLEANED (cleaned_cotality_crime_school_tract_ts_tall, cleaned_education_public_k12_schools, cleaned_markerr_crime_zip_long, qcew_*)
TRANSFORM_PROD.REF (unified_portfolio, h3_xwalk_6810_canon, cbsa_zip_weights)
TRANSFORM_PROD.FACT (housing_hou_*, household_hh_*, fact_place_plc_*, capital_cap_economy, etc.)
  ↑
  fact_place_plc_education_all_ts   [refs cleaned + ref; set place_ai_sources_available – see §2.1]
  fact_place_plc_safety_all_ts       [refs cleaned + ref – see §2.2]
  household_hh_labor_qcew_naics      [refs cleaned QCEW – see §2.3]
  housing_hou_demand_all_ts          [refs + optional dim_dataset – see §2.4]
  ↑
EDW_PROD.DELIVERY (v_anchor_deal_screener, v_anchor_school_score_by_zip, v_anchor_crime_score_by_zip)
```

---

## 2. Failing models and requirements

### 2.1 fact_place_plc_education_all_ts

| Item | Detail |
|------|--------|
| **Path** | `models/30_fact/fact_place_plc_education_all_ts.sql` |
| **Materialization** | incremental |
| **Refs** | `cleaned_cotality_crime_school_tract_ts_tall`, `cleaned_education_public_k12_schools`, `ref.h3_xwalk_6810_canon`; optionally `admin_catalog.dim_metric` when `admin_catalog_available` is true |
| **Required** | Cleaned views read from **SOURCE_PROD** (see discovery): |
| | • **cleaned_cotality_crime_school_tract_ts_tall** ← source `ai_capabilities.cotality_crime_school_tract_ts_tall` (DATE_REFERENCE, ID_TRACT, VALUE, META_METRIC) |
| | • **cleaned_education_public_k12_schools** ← source `ai_capabilities.education_public_k12_schools` (ZIP_CODE, SCHOOL_ID) |
| **Fix** | Run `scripts/discovery/discover_source_prod_schema.sql` in Snowflake to find schemas/tables. Set `place_ai_sources_available: true` and `ai_capabilities_database` / `ai_capabilities_schema` (or table `identifier`s) so the cleaned views resolve. If column names differ, alias in the cleaned models. |

---

### 2.2 fact_place_plc_safety_all_ts

| Item | Detail |
|------|--------|
| **Path** | `models/30_fact/fact_place_plc_safety_all_ts.sql` |
| **Materialization** | incremental |
| **Refs** | `cleaned_markerr_crime_zip_long`, `cleaned_cotality_crime_school_tract_ts_tall`, `ref.h3_xwalk_6810_canon`; optionally `admin_catalog.dim_metric` when `admin_catalog_available` is true |
| **Required** | Cleaned views read from **SOURCE_PROD** (see discovery): |
| | • **cleaned_markerr_crime_zip_long** ← source `ai_capabilities.markerr_crime_zip_long` (DATE_REFERENCE, ID_ZIP, METRIC, METRIC_VALUE) |
| | • **cleaned_cotality_crime_school_tract_ts_tall** ← source `ai_capabilities.cotality_crime_school_tract_ts_tall` (DATE_REFERENCE, ID_TRACT, VALUE, META_METRIC; fact filters `cotality_%_risk`, excludes `cotality_school_score`) |
| **Fix** | Same as §2.1: run discovery, set `place_ai_sources_available: true` and point `ai_capabilities` vars/identifiers to the discovered objects. |

---

### 2.3 household_hh_labor_qcew_naics

| Item | Detail |
|------|--------|
| **Path** | `models/transform_prod/fact/household_hh_labor_qcew_naics.sql` |
| **Materialization** | incremental |
| **Sources** | `cleaned.qcew_naics_cbsa`, `cleaned.qcew_county`, `ref.h3_xwalk_6810_canon` |
| **Required** | **TRANSFORM_PROD.CLEANED**: tables/views **qcew_naics_cbsa** and **qcew_county** with columns: geo_id, geo_level_code, date_reference, metric_id, value, unit. |
| **Current** | Stub models exist: `models/transform_prod/cleaned/qcew_naics_cbsa.sql`, `qcew_county.sql` (0 rows, value as FLOAT). **household_hh_labor_qcew_naics** now uses **ref('qcew_naics_cbsa')** and **ref('qcew_county')** so dbt builds the cleaned stubs first. |
| **Fix** | Done. To get real data, replace the stub SQL in the cleaned models with a select from the raw QCEW source (add source in sources.yml and build the cleaned layer). |

---

### 2.4 housing_hou_demand_all_ts

| Item | Detail |
|------|--------|
| **Path** | `models/transform_prod/fact/housing_hou_demand_all_ts.sql` |
| **Materialization** | incremental |
| **Refs** | `housing_hou_demand_yardi_sfdc`, `fact_housing_demand_cherre_recorder`, `housing_hou_demand_funnel_bh` |
| **Source** | `admin_catalog.dim_dataset` (for access metadata) |
| **Required** | (1) All three refs must build and expose a compatible column set: date_reference, geo_id, geo_level_code, ID_CBSA (or NULL), metric_id, value, unit, frequency, domain, taxon, product_type_code, bedrooms, property_id, canonical_property_id, match_confidence, match_method, property_class_code, vendor_name, source, meta_source, meta_dataset, meta_frequency, created_at. (2) **ADMIN.CATALOG.DIM_DATASET** must exist with dataset_name (and optionally opco_access, team_access, access_tier, sensitivity_level). |
| **Likely failure** | Column mismatch in one of the three refs (e.g. missing or misnamed column), or **dim_dataset** missing/empty. Run the model in Snowflake and inspect the compile/run error. |

---

## 3. Run order to satisfy dependencies

To have the best chance of Anchor and its upstream building:

1. **Cleaned (QCEW and any other cleaned used by failing facts)**  
   `dbt run --select transform_prod.cleaned.qcew_naics_cbsa transform_prod.cleaned.qcew_county`  
   Or use ref() in the fact so these build automatically when the fact is selected.

2. **Ref / fact**  
   Build ref and fact in dependency order. Many scripts use:  
   `dbt run --select transform_prod.ref transform_prod.fact`  
   or tag-based selection.

3. **Anchor delivery**  
   `dbt run --select +tag:anchor_screener`

**Suggested single command (after fixing ref/source in §2.3):**  
`dbt run --select +tag:anchor_screener`  
This will still fail on **fact_place_plc_education_all_ts**, **fact_place_plc_safety_all_ts**, and **housing_hou_demand_all_ts** until their sources/refs exist and match the expected schema.

---

## 4. What to create or fix

| # | Action | Status / Purpose |
|---|--------|------------------|
| 1 | **Use ref() in household_hh_labor_qcew_naics** | **Done.** Fact now refs `qcew_naics_cbsa` and `qcew_county` so dbt builds cleaned stubs first; fact runs with 0 rows. |
| 2 | **Discover and wire place AI sources** | Run `scripts/discovery/discover_source_prod_schema.sql` in Snowflake. Set `place_ai_sources_available: true` and `ai_capabilities_database` / `ai_capabilities_schema` (or table `identifier`s in sources.yml) so **cleaned_cotality_crime_school_tract_ts_tall**, **cleaned_education_public_k12_schools**, **cleaned_markerr_crime_zip_long** read from the correct objects. See `scripts/discovery/README_SOURCE_PROD_DISCOVERY.md`. |
| 3 | **Inspect housing_hou_demand_all_ts error** | Run `dbt run --select housing_hou_demand_all_ts` and fix column name/type or dim_dataset from the error message. |
| 4 | **Optional: stub place facts** | Not needed: cleaned views stub when `place_ai_sources_available` is false so place facts build with 0 rows. |

---

## 5. Source definitions (sources.yml)

- **ai_capabilities:** database `source_prod`, schema `ai_capabilities` (or as configured). Tables: cotality_crime_school_tract_ts_tall, education_public_k12_schools, markerr_crime_zip_long.
- **cleaned:** database `transform_prod`, schema `cleaned`. Tables qcew_naics_cbsa, qcew_county are built by dbt models of the same name; use ref() in the fact so they build first.
- **admin_catalog:** database `admin`, schema `catalog`. Tables: dim_metric, dim_dataset.
