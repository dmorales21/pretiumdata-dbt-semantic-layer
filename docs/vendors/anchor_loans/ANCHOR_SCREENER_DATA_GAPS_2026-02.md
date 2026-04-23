# Anchor Screener – Data Gaps Analysis

**Date:** 2026-02-12  
**Scope:** Anchor Screener Guide → implementation status; identifies missing or miswired data.  
**Related:** [ANCHOR_SCREENER_WHAT_IS_MISSING.md](ANCHOR_SCREENER_WHAT_IS_MISSING.md), [ANCHOR_SCREENER_DATA_MAP.md](ANCHOR_SCREENER_DATA_MAP.md)

---

## Screener Guide Checklist vs. Data Status

### 1. Portfolio

| # | Guide Item | Status | Notes |
|---|------------|--------|-------|
| 1.1 | Anchor Loans Closed Deals | ✅ | `portfolio_closed_deals` from DEALS where funded. |
| 1.2 | Anchor Sum of Peak UPB | ✅ | `portfolio_sum_peak_upb` from DEALS. |
| 1.3 | Progress Owned Homes (within 10 mi) | ⚠️ | `portfolio_progress_homes_10mi` from `unified_portfolio`. Depends on Progress properties having lat/lon. |

---

### 2. Location

| # | Guide Item | Status | Notes |
|---|------------|--------|-------|
| 2.1 | Pretium HBF Market Score | ⚠️ | `location_hbf_market_score` from `fact_market_health_score` (CBSA). Proxy; external HBF table not used. |
| 2.2 | School District Rank | ✅ | `location_school_district_rank` from `fact_place_plc_education_all_ts`. |
| 2.3 | Crime Rating Range | ⚠️ | `location_crime_rating_range` from `fact_place_plc_safety_all_ts`. Often NULL if `place_ai_sources_available` / Cotality disabled. |
| 2.4 | Major Retailers | ⚠️ | `fact_place_major_retailers` uses **Overture** (`overture_places_us_retailers`). Data depends on `OVERTURE_MAPS__PLACES.CARTO.PLACE` source. 0 rows if source missing. |

---

### 3. Demographics

| # | Guide Item | Status | Notes |
|---|------------|--------|-------|
| 3.1 | Population | ⚠️ | `demographics_population` from `household_hh_demographics_all_ts`, metric_id ILIKE '%POPULATION%'. Requires fact built + ZIP rows. |
| 3.2 | Median HH Income | ⚠️ | `demographics_median_hh_income` from `household_hh_demographics_all_ts`, metric_id ILIKE '%INCOME%'. Same dependency. |
| 3.3 | Top 3 Industries by Employer | ⚠️ | `demographics_top3_industries` from QCEW. **Off by default** (`anchor_use_qcew_top3: false`). Set `true` + populate QCEW pipeline. |
| 3.4 | Employment | ✅ | `demographics_employment` from `household_hh_labor_all_ts` (CBSA). |
| 3.5 | Unemployment | ✅ | `demographics_unemployment` from same. |

---

### 4. Housing Market (Product Type)

| # | Guide Item | Status | Notes |
|---|------------|--------|-------|
| 4.1 | Median Sale Price | ✅ | `housing_median_sale_price` from `housing_hou_pricing_all_ts` (Redfin, Cherre, Realtor). |
| 4.2 | Months of Supply | ✅ **FIXED** | Now reads from `fact_housing_metrics_zip` (93% coverage). Was miswired to `housing_hou_inventory_all_ts` which had no months_of_supply. |
| 4.3 | Median Days on Market | ✅ **FIXED** | Now reads from `fact_housing_metrics_zip` (94.7% coverage). Was from `housing_hou_demand_all_ts` (sparse). |
| 4.4 | # Builders within 5 miles | ⚠️ | `housing_builders_within_5mi` from `zonda_btr_projects` (lat/lon). 0 if Zonda projects lack coordinates. |

---

### 5. Maps & Charts

| # | Guide Item | Status | Notes |
|---|------------|--------|-------|
| 5.1 | Major Retailers Map (1/3/5 mi) | ⚠️ | Same as 2.4. `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL` needs `fact_place_major_retailers` with lat/lon. Overture source must exist. |
| 5.2 | Comps (Zonda) – X=sqft, Y=price, color=builder | ⚠️ | `V_ANCHOR_ZONDA_COMPS` from `source('zonda', 'zonda_btr_comparables')`. 0 rows if table missing or empty. |
| 5.3 | Annual Starts vs Closings Line Chart | ⚠️ | `V_ANCHOR_STARTS_CLOSINGS_CBSA`. **Requires** `anchor_starts_closings_from_zonda: true` (uses `fact_zonda_starts_closings_all_ts`). Default: 0-row stub. |
| 5.4 | School Score by H3-6 within 1,3,5 mi | ⚠️ | View uses **H3-8** (`v_anchor_school_score_by_h3`). Guide says H3-6; implementation is H3-8. No distance rings (1/3/5 mi)—returns all H3 cells in CBSA. |
| 5.5 | Crime Score by H3-6 within 1,3,5 mi | ⚠️ | Same as 5.4—H3-8, CBSA filter, no distance rings. |

---

## Housing Metrics Fix (2026-02-12) — Implemented

The screener now reads **months_of_supply** and **median_dom** directly from `fact_housing_metrics_zip` (single `housing_metrics_zip` CTE). Replaced the previous inv_zip/dom_zip CTEs that queried `housing_hou_inventory_all_ts` / `housing_hou_demand_all_ts` (which lacked months_of_supply).

**Previous state** — screener used a different pipeline than `fact_housing_metrics_zip`:

| Screener Source | What It Has | fact_housing_metrics_zip (Not Used) |
|-----------------|-------------|-------------------------------------|
| `housing_hou_inventory_all_ts` | ParclLabs DOM, active listings; Redfin inventory, homes_sold, DOM | **93% months_of_supply** (Redfin calculated + Realtor + ParclLabs) |
| `housing_hou_demand_all_ts` | Yardi/Cherre/Funnel demand | **94.7% median_dom** |
| `housing_hou_pricing_all_ts` | Redfin, Cherre, Realtor pricing | **95.9% median_sale_price** (partially aligned) |

**Resolution applied:** Option 1 — replaced `inv_zip` and `dom_zip` with `housing_metrics_zip` CTE reading `fact_housing_metrics_zip` directly.

---

## Summary: Missing or At-Risk Data

| Priority | Item | Action |
|----------|------|--------|
| ~~**P0**~~ | ~~Months of Supply (4.2)~~ | ✅ Done — wired `fact_housing_metrics_zip` into screener. |
| ~~**P1**~~ | ~~Median DOM (4.3)~~ | ✅ Done — same `housing_metrics_zip` CTE supplies median_dom. |
| **P1** | **Starts vs Closings (5.3)** | Set `anchor_starts_closings_from_zonda: true` and ensure `fact_zonda_starts_closings_all_ts` is populated. |
| **P2** | **Major Retailers (2.4, 5.1)** | Confirm Overture source exists; validate `overture_places_us_retailers` row count. |
| **P2** | **Population, Income (3.1, 3.2)** | Validate `household_hh_demographics_all_ts` has ZIP rows with POPULATION and INCOME metric_ids. |
| **P2** | **Top 3 Industries (3.3)** | Set `anchor_use_qcew_top3: true` if QCEW pipeline is ready. |
| **P3** | **Builders within 5 mi (4.4)** | Requires Zonda BTR projects with lat/lon. |
| **P3** | **School/Crime by distance (5.4, 5.5)** | Guide specifies H3-6 within 1/3/5 mi; current views use H3-8 and CBSA only. Add distance-ring logic if required. |

---

## Quick Validation Queries

```sql
-- Months of supply: does housing_hou_inventory_all_ts have it?
SELECT metric_id, COUNT(*), COUNT(DISTINCT geo_id)
FROM transform_prod.fact.housing_hou_inventory_all_ts
WHERE geo_level_code = 'ZIP'
  AND (metric_id ILIKE '%MONTHS%SUPPLY%' OR metric_id ILIKE '%PARCLLABS%')
GROUP BY 1;

-- fact_housing_metrics_zip (the improved source not wired to screener)
SELECT COUNT(*), COUNT(months_of_supply), COUNT(median_dom)
FROM transform_prod.fact.fact_housing_metrics_zip;

-- Retailers
SELECT COUNT(*) FROM transform_prod.fact.fact_place_major_retailers;
```
