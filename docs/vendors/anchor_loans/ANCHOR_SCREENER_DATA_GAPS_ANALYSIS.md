# Anchor Screener Data Gaps — Source Analysis & Fix Strategy

**Date:** 2026-02-12  
**Scope:** All Anchor Screener Guide metrics; source availability; fix strategies.  
**Related:** [ANCHOR_SCREENER_DATA_GAPS_2026-02.md](ANCHOR_SCREENER_DATA_GAPS_2026-02.md), [ANCHOR_SCREENER_DATA_MAP.md](ANCHOR_SCREENER_DATA_MAP.md)

---

## Source Availability Summary (Validated)

| Source | Total Rows | Unique Geos | Date Range | With Coords |
|--------|------------|-------------|------------|-------------|
| zonda_deed_closings | 492,927 | 8,988 ZIPs | 2025-01-03 to 2025-12-11 | 492,927 (100%) |
| fact_housing_construction_activity | 12,008 | 646 geos | 2020-01-01 to 2026-01-01 | — |
| fact_place_major_retailers | 166,441 | 166,441 places | — | 166,441 (100%) |

---

## Issue #1: Housing Metrics (months_of_supply, median_dom) — FIXED

**Previous:** Queried `housing_hou_inventory_all_ts` and `housing_hou_demand_all_ts`, which lacked months_of_supply.

**Available:** `fact_housing_metrics_zip` — 10.4M rows, 93.1% months_of_supply, 94.7% median_dom.

**Fix applied:** Replaced `inv_zip` and `dom_zip` CTEs with `housing_metrics_zip` CTE in `v_anchor_deal_screener.sql` reading from `fact_housing_metrics_zip`.

**Status:** Implemented.

---

## Issue #2: HBF Market Score — Wired, Limited by Design

**Current:** Uses `fact_market_health_score` (CBSA level only).

**Coverage:** 907 CBSAs, 100% populated; scores ~15.97–27.97.

**Issue:** CBSA-level only; deals without CBSA get NULL.

**Data quality:** Many component metrics NULL; `employment_growth_yoy` most consistently populated; scores are proxy-based.

**Fix:** Already wired; gap is source sparsity, not pipeline.

**Strategy:** Improve `fact_market_health_score` inputs or accept as CBSA-only metric.

---

## Issue #3: Demographics — Severe Gap at ZIP Level

**Problem:** `household_hh_demographics_all_ts` has 0 ZIP-level rows.

**Current coverage:**
- `household_hh_demographics_all_ts` (ZIP): 0 rows
- `fact_blockgroup_demographics`: 11,495 blockgroups
- `fact_h3_6_demographics`: 3,908 H3-6 hexes
- `fact_h3_8_demographics`: 10,520 H3-8 hexes

**Root cause:** ACS at blockgroup level; no aggregation to ZIP.

**Fix strategy:**

| Option | Approach | Effort |
|--------|----------|--------|
| A (Spatial) | Join deals → H3-6/H3-8 → demographics | Low — H3 already built |
| B (ZIP agg) | Aggregate blockgroup → ZIP via population weights | Medium |
| C (Blockgroup) | Deal lat/lon → blockgroup → demographics | Medium |

**Recommendation:** Option A — join screener to H3-6 demographics (already built, 3.9K hexes).

---

## Issue #4: Crime/School Scores — Good Coverage

**Crime at ZIP:**
- `fact_place_crime_zip`: 867K rows, 24K ZIPs
- `fact_place_plc_safety_all_ts`: 364K rows, 24K ZIPs

**Schools at ZIP:**
- `fact_place_plc_education_all_ts`: 45K rows, 22K ZIPs

**Alternative:** `fact_place_crime_school_blockgroup` — 575K rows, 289K blockgroups.

**Status:** Wired correctly; good coverage.

**Optional:** Add H3 fallback when ZIP match fails.

---

## Issue #5: Builders Within 5 Miles — Working

**Source:** `zonda_btr_projects` (CLEANED).

**Coverage:** 2,787 projects, 434 builders; 100% with lat/lon.

**Status:** Screener queries this; behavior correct.

**Limitation:** BTR builders only (not all residential).

---

## Issue #6: Retailers (1/3/5 mi) — Working

**Source:** `fact_place_major_retailers` (from Overture).

**Coverage:** 166,441 retailers; 100% with lat/lon.

**Status:** Screener computes distances; no gap.

---

## Issue #7: Starts vs Closings Chart — Limited

**Sources and coverage:**

| Source | Rows | Geos | Date Range |
|--------|------|------|------------|
| zonda_deed_closings | 493K | 9K ZIPs | 2025 only |
| fact_housing_construction_activity | 12K | 646 geos | 2020–2026 |
| hou_starts_all_ts | 164 | sparse | — |

**Issue:**
- Zonda deeds = closings only (no starts)
- Construction activity = limited geography
- Insufficient data for a comprehensive starts vs closings chart

**Fix strategy:**
- Use `fact_housing_construction_activity` where available
- Accept limited coverage, or disable this chart

---

## Issue #8: Top 3 Industries — Conditional

**Source:** `household_hh_labor_qcew_naics` — 63M rows, CBSA level.

**Current:** CTE empty unless `anchor_use_qcew_top3: true`.

**Fix:** Set `anchor_use_qcew_top3: true` in dbt vars to enable.

---

## Priority Fix Order

### Immediate (high impact)

1. ~~Wire fact_housing_metrics_zip~~ — Done.
2. ~~Fix demographics join~~ — Done (H3-6 fallback via `demographics_h3_by_deal`).
3. Enable QCEW top 3 industries — Set `anchor_use_qcew_top3: true` **only after** `household_hh_labor_qcew_naics` is built (table must exist; build fails otherwise).

### Medium priority

4. Add H3 fallback for crime/schools when ZIP match fails.
5. Document HBF score limitations (CBSA only, proxy-based).

### Low priority / accept limitations

6. Builders within 5 mi — BTR-only; acceptable.
7. Starts vs closings — limited data; accept or disable feature.

---

## Summary Table

| Metric | Source Table | Coverage | Status | Fix |
|--------|--------------|----------|--------|-----|
| Months of supply | fact_housing_metrics_zip | 93.1% (9.7M rows) | Fixed | CTE replaced |
| Median DOM | fact_housing_metrics_zip | 94.7% (9.9M rows) | Fixed | CTE replaced |
| HBF score | fact_market_health_score | 907 CBSAs | Wired | Accept CBSA-only |
| Demographics | fact_h3_6_demographics (H3 fallback) | 3.9K H3-6 hexes | Fixed | COALESCE ZIP, H3-6 |
| Crime | fact_place_plc_safety_all_ts | 24K ZIPs | Wired | Optional H3 fallback |
| Schools | fact_place_plc_education_all_ts | 22K ZIPs | Wired | Optional H3 fallback |
| Retailers | fact_place_major_retailers | 166K points | Wired | None |
| Builders | zonda_btr_projects | 2,787 projects | Wired | Accept BTR-only |
| Top 3 industries | household_hh_labor_qcew_naics | 63M rows CBSA | Disabled | Enable dbt var |
| Starts/closings | fact_housing_construction_activity | 646 geos | Limited | Accept or disable |

---

## Validation Queries

```sql
-- Housing metrics (after fix)
SELECT COUNT(*), COUNT(housing_months_of_supply), COUNT(housing_median_dom)
FROM EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER;

-- Source availability
SELECT 'zonda_deed_closings' AS source, COUNT(*) AS rows,
  COUNT(DISTINCT zip_code) AS zips, MIN(sale_date) AS min_dt, MAX(sale_date) AS max_dt
FROM TRANSFORM_PROD.CLEANED.ZONDA_DEED_CLOSINGS
UNION ALL
SELECT 'fact_housing_construction', COUNT(*), COUNT(DISTINCT geo_id),
  MIN(date_reference), MAX(date_reference)
FROM TRANSFORM_PROD.FACT.FACT_HOUSING_CONSTRUCTION_ACTIVITY
UNION ALL
SELECT 'fact_place_major_retailers', COUNT(*), COUNT(DISTINCT place_id),
  NULL, NULL
FROM TRANSFORM_PROD.FACT.FACT_PLACE_MAJOR_RETAILERS;
```
