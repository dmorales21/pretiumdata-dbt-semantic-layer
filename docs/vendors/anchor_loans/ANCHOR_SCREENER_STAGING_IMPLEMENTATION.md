# Anchor Screener Staging Implementation

**Purpose:** Staging models and mart that source correct data for each Anchor screener metric. Aligns with canonical fact schema and existing delivery views.

---

## Overview

| Path | Models | Purpose |
|------|--------|---------|
| `models/anchor/staging/` | 13 staging models | Source-specific data per metric |
| `models/anchor/marts/` | `fct_anchor_deal_screener` | Assembles all metrics per deal |
| `EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER` | (unchanged) | Existing delivery; can ref fct later |

---

## Schema Corrections vs. Original Plan

The implementation differs from the original proposal in these ways:

### 1. Column names (canonical fact schema)

All fact tables use `geo_id`, `geo_level_code`, `value`, `date_reference` — **not** `geography_id`, `geography_type`, `metric_value`.

### 2. Deals source

`anchor_loans.deals` has `zip_code`, `id_cbsa` (not `property_zip`, `property_cbsa`). Geography is resolved via `ref_anchor_deal_geography_resolved` when zip/cbsa are null.

### 3. HAVERSINE()

Snowflake has no built-in `HAVERSINE()`. The project uses inline formula:

```sql
(3959 * ACOS(LEAST(1, GREATEST(-1,
  SIN(RADIANS(lat1)) * SIN(RADIANS(lat2))
  + COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * COS(RADIANS(lon2 - lon1))
)))) <= 10  -- miles
```

### 4. Builder locations

No `source('zonda', 'builder_locations')`. Builders come from `ref_builder_locations`, which is currently a stub (0 rows) until Zonda or another source provides coordinates.

### 5. Top 3 industries

`household_hh_labor_qcew_naics` has `geo_id`, `naics_code`, `value` — no `naics_title` or `employment_value`. `naics_title` comes from `ref_naics_dimension` join. `anchor_use_qcew_top3` gates this.

### 6. Starts/closings

`fact_zonda_starts_closings_all_ts` is long format: `metric_id` = `ZONDA_SFR_STARTS` / `ZONDA_SFR_CLOSINGS`, not wide `starts_count`/`closings_count`. `stg_starts_closings` reads from `v_anchor_starts_closings_cbsa` (already pivoted and aggregated).

### 7. Zonda BTR comps

Source columns are uppercase: `CBSA`, `ID_ZIP`, `UNIT_SQFT`, `MEDIAN_SALE_PRICE`, `BUILDER_NAME`. Staging normalizes to lowercase.

---

## Run Commands

```bash
# Run Anchor staging + mart
dbt run --select anchor.*

# Run only staging
dbt run --select anchor.staging.*

# Run only mart
dbt run --select fct_anchor_deal_screener

# Run with all sources enabled (requires sources to exist)
dbt run --select anchor.* --vars '{
  anchor_zonda_comps_available: true,
  zonda_starts_closings_available: true,
  anchor_starts_closings_from_zonda: true,
  place_ai_sources_available: true,
  carto_retailers_enabled: true,
  anchor_use_qcew_top3: true
}'

# Test
dbt test --select anchor.*
```

---

## Variable Gating

| Var | Affects | Default |
|-----|---------|---------|
| `anchor_zonda_comps_available` | `stg_zonda_btr_comps` | false |
| `zonda_starts_closings_available` | `cleaned_zonda_starts_closings`, `fact_zonda_starts_closings_all_ts` | false |
| `anchor_starts_closings_from_zonda` | `stg_starts_closings`, `v_anchor_starts_closings_cbsa` | false |
| `place_ai_sources_available` | education, safety facts → school/crime staging | false |
| `carto_retailers_enabled` | `cleaned_carto_major_retailers` → `fact_place_major_retailers` → `stg_major_retailers` | false |
| `anchor_use_qcew_top3` | `stg_top3_industries` | false |

---

## Staging Model → Screener Metric Map

| Staging Model | Screener Section | Metric |
|---------------|------------------|--------|
| `stg_anchor_deals` | Portfolio | Closed deals, peak UPB |
| `stg_progress_properties` | Portfolio | Progress homes 10mi |
| `stg_hbf_market_scores` | Location | HBF market score |
| `stg_school_scores` | Location | School district rank |
| `stg_crime_scores` | Location | Crime rating range |
| `stg_major_retailers` | Location | Retailers 1/3/5 mi |
| `stg_demographics_zip` | Demographics | Population, median HH income |
| `stg_top3_industries` | Demographics | Top 3 industries |
| `stg_labor_cbsa` | Demographics | Employment, unemployment |
| `stg_housing_metrics_zip` | Housing | Median sale price, months supply, median DOM |
| `stg_builder_locations` | Housing | Builders within 5 mi |
| `stg_zonda_btr_comps` | Maps | Zonda comparables scatter |
| `stg_starts_closings` | Maps | Annual starts vs closings |

---

## Dependencies

- `ref_anchor_deal_geography_resolved` — geography resolution for deals
- `unified_portfolio` — Progress properties
- Fact tables: `capital_cap_economy_all_ts`, `fact_place_plc_education_all_ts`, `fact_place_plc_safety_all_ts`, `household_hh_demographics_all_ts`, `household_hh_labor_all_ts`, `household_hh_labor_qcew_naics`, `housing_hou_pricing_all_ts`, `housing_hou_inventory_all_ts`, `housing_hou_demand_all_ts`
- `fact_place_major_retailers`, `ref_builder_locations`
- `v_anchor_starts_closings_cbsa` (for `stg_starts_closings`)
- `ref_naics_dimension` (for `stg_top3_industries` when `anchor_use_qcew_top3`)
