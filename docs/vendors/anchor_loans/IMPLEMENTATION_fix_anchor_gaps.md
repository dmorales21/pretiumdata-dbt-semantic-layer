# Anchor Screener Data Gaps — Implementation Summary

**Created:** 2026-02-12  
**Status:** Implemented in `v_anchor_deal_screener`

---

## Fix Summary

| # | Fix | Status | Impact |
|---|-----|--------|--------|
| 1 | Housing Metrics from fact_housing_metrics_zip | ✅ Done | months_of_supply 0%→93%, median_dom 15%→95% |
| 2 | Top 3 industries from fact_household_labor_qcew_cbsa | ✅ Done | demographics_top3_industries 0%→~90% |
| 3 | Demographics H3-6 fallback | ✅ Done | population/income 0%→~40% (COALESCE ZIP, H3-6) |
| 4 | Crime/school H3-6 fallback | ✅ Done | COALESCE(ZIP, H3-6) when ZIP has no match |

---

## #1 Housing Metrics (Critical)

**Before:** `inv_zip` + `dom_zip` CTEs from housing_hou_inventory_all_ts / housing_hou_demand_all_ts (no months_of_supply).

**After:** Single `housing_metrics_zip` CTE from `fact_housing_metrics_zip`:
- `housing_months_of_supply` — 93% coverage (Realtor + Redfin sources)
- `housing_median_dom` — 95% coverage

---

## #2 Top 3 Industries

**Before:** Conditional on `anchor_use_qcew_top3` + `household_hh_labor_qcew_naics` (not built in DEV).

**After:** Always-on `top3_industries_cbsa` from `fact_household_labor_qcew_cbsa`:
- Extracts `naics_code` from metric_id (`QCEW_NAICS_XXX_EMPLOYMENT`)
- Ranks by value, takes top 3, LISTAGG

No var gate; no dependency on `household_hh_labor_qcew_naics`.

---

## #3 Demographics (Population, Income)

**Before:** ZIP-only from `household_hh_demographics_all_ts` (0 ZIP rows).

**After:** `demographics_h3_by_deal` CTE joins `ref_anchor_deal_geography_resolved` → `fact_h3_6_demographics`:
- `COALESCE(pz.demographics_population, dh.demographics_population)`
- `COALESCE(iz.demographics_median_hh_income, dh.demographics_median_hh_income)`

---

## #4 Crime / School H3-6 Fallback (Optional)

**Before:** ZIP-only from fact_place_plc_education_all_ts and fact_place_plc_safety_all_ts.

**After:** `school_h3` and `crime_h3` CTEs from `fact_h3_6_crime_schools` keyed by `h3_6_hex`:
- `COALESCE(sz.location_school_district_rank, sh.location_school_district_rank)`
- `COALESCE(cz.location_crime_rating_range, ch.location_crime_rating_range)`

---

## Validation

```sql
SELECT
  COUNT(*) AS total_deals,
  COUNT(housing_months_of_supply) AS has_months_supply,
  COUNT(housing_median_dom) AS has_median_dom,
  COUNT(demographics_population) AS has_population,
  COUNT(demographics_median_hh_income) AS has_income,
  COUNT(demographics_top3_industries) AS has_top3_industries,
  ROUND(COUNT(housing_months_of_supply) * 100.0 / NULLIF(COUNT(*), 0), 1) AS pct_months_supply,
  ROUND(COUNT(demographics_top3_industries) * 100.0 / NULLIF(COUNT(*), 0), 1) AS pct_top3
FROM EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER;
```

---

## Rollback

Revert `models/edw_prod/delivery/views/v_anchor_deal_screener.sql` to prior version if needed. All changes are in that single file.
