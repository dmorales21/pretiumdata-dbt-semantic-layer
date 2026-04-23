# Anchor Loans Pipeline: Source → EDW and Data Trust Challenges

**Purpose:** Restate the full Anchor deal screener pipeline, trace every metric from source to delivery, clarify intended vs. actual behavior, and enumerate data challenges. **Bottom line: do not trust any screener metric without validating its upstream source and row counts.**

---

## Pipeline Overview

```
SOURCE (raw) → CLEANED (normalize) → FACT (canonical) → REF (crosswalks) → EDW DELIVERY (app-facing)
```

Main view: `EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER` (one row per deal).  
Supporting views: `V_ANCHOR_DEAL_SCREENER_RETAILERS`, `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL`, `V_ANCHOR_ZONDA_COMPS`, `V_ANCHOR_STARTS_CLOSINGS_CBSA`, `V_ANCHOR_SCHOOL_SCORE_BY_ZIP`, `V_ANCHOR_CRIME_SCORE_BY_ZIP`.

---

## 1. Portfolio

### 1.1 Anchor Loans Closed Deals

| Aspect | Detail |
|--------|--------|
| **Goal** | Count of funded deals (global portfolio size). |
| **Source** | `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` |
| **Path** | `source('anchor_loans', 'deals')` → `portfolio_agg` CTE → `portfolio_closed_deals` |
| **Logic** | `COUNT(*) WHERE decision_status = 'funded'` |
| **What it shows now** | Whatever `decision_status` contains. If the deal source is stale, wrong, or uses different values than `'funded'`, the count is wrong. No validation that DEALS is the single source of truth. |

**Data challenges:** Deal source may be a share, staging table, or sync. Confirm DEALS is authoritative and `decision_status` values are consistent.

---

### 1.2 Sum of Peak UPB

| Aspect | Detail |
|--------|--------|
| **Goal** | Total loan amount across funded deals. |
| **Source** | `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` |
| **Path** | `source('anchor_loans', 'deals')` → `portfolio_agg` → `portfolio_sum_peak_upb` |
| **Logic** | `SUM(loan_amount) WHERE decision_status = 'funded'` |
| **What it shows now** | Same trust issues as 1.1. `loan_amount` may not be “peak” UPB—it could be initial or current. |

**Data challenges:** “Peak UPB” implies a time series; DEALS may only have current snapshot. Confirm metric definition vs. data.

---

### 1.3 Progress Owned Homes (within 10 miles)

| Aspect | Detail |
|--------|--------|
| **Goal** | Number of Progress properties within 10 miles of each deal (Haversine). |
| **Source** | `TRANSFORM_PROD.REF.UNIFIED_PORTFOLIO` (built from `progress_properties` ← Yardi/SFDC cleaned views) |
| **Path** | `ref('unified_portfolio')` + deal lat/lon → `progress_nearby` CTE |
| **Logic** | Haversine ≤10 mi, `entity_id = 'progress'` |
| **What it shows now** | Depends on `unified_portfolio` having Progress properties with valid lat/lon. If Progress data is missing/stale or uses ZIP centroids instead of property coordinates, counts are wrong or zero. |

**Data challenges:** `unified_portfolio` unions Progress/Yardi/SFDC. Requires lat/lon; some sources use ZIP centroids. Coverage and freshness unknown.

---

## 2. Location

### 2.1 Pretium HBF Market Score

| Aspect | Detail |
|--------|--------|
| **Goal** | ZIP-level market score for HBF (Home Builder Finance) strategy. |
| **Source** | `source('fact', 'capital_cap_economy_all_ts')` — **external fact table not built in this repo** |
| **Path** | `source('fact', 'capital_cap_economy_all_ts')` → `hbf_zip` CTE → `location_hbf_market_score` |
| **Logic** | `metric_id ILIKE '%HBF%' OR '%MARKET%SCORE%'`, latest `date_reference` by ZIP |
| **What it shows now** | Unknown. Table lives outside dbt; may not exist, be empty, or use different metric_ids. If no match, column is NULL. |

**Data challenges:** External dependency. No discovery in repo. Metric definition and update cadence undocumented. **Do not trust without confirming the table exists and has ZIP rows.**

---

### 2.2 School District Rank

| Aspect | Detail |
|--------|--------|
| **Goal** | Education/school score by ZIP for deal location quality. |
| **Source** | `fact_place_plc_education_all_ts` ← `cleaned_education_public_k12_schools` (EDUCATION.EDGE_PUBLIC_SCHOOLS) |
| **Path** | `place_ai_sources_available` gates cleaned → fact → `school_zip` → `location_school_district_rank` |
| **Logic** | `metric_id ILIKE '%SCHOOL%' OR '%COTALITY%'`, latest by ZIP |
| **What it shows now** | **Only if** `place_ai_sources_available: true` and EDUCATION source has data. Default: stub. If education fact is empty, all NULL. |

**Data challenges:** `place_ai_sources_available` default false. Cotality path requires `place_cotality_available`. School “rank” may be a score or index—definition unclear.

---

### 2.3 Crime Rating Range

| Aspect | Detail |
|--------|--------|
| **Goal** | Crime/safety score by ZIP (e.g., Low/Medium/High). |
| **Source** | `fact_place_plc_safety_all_ts` ← `cleaned_markerr_crime_zip_long` + `cleaned_cotality_crime_school_tract_ts_tall` |
| **Path** | Both cleaned models gated by `place_ai_sources_available` and `place_cotality_available` (default false) → fact unions them → `crime_zip` → `location_crime_rating_range` |
| **Logic** | Latest value by ZIP from safety fact |
| **What it shows now** | **Typically all NULL.** Both Markerr and Cotality cleaned models stub when vars are false. Section 5.5 validation states crime choropleth fails for this reason. |

**Data challenges:** Two sources, both disabled by default. No ZIP crime data unless both vars set and sources loaded. Even then, “rating range” mapping (e.g., index → Low/Medium/High) may be undocumented.

---

### 2.4 Major Retailers (1/3/5 mi map)

| Aspect | Detail |
|--------|--------|
| **Goal** | Retailer count and list within 1, 3, 5 miles of each deal. |
| **Source** | `fact_place_major_retailers` ← `cleaned_carto_major_retailers` ← CARTO `carto_place_layer` |
| **Path** | `carto_retailers_enabled` gates cleaned (default false) → fact → `V_ANCHOR_DEAL_SCREENER_RETAILERS`, `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL` |
| **Logic** | Point-level lat/lon, distance bands |
| **What it shows now** | **0 rows.** CARTO not wired; cleaned model is stub. Column and map empty. |

**Data challenges:** CARTO source schema/columns need discovery. `carto_col_id`, `carto_col_lat`, etc. may not match. Alternative (e.g., Overture) not implemented.

---

## 3. Demographics

### 3.1 Population

| Aspect | Detail |
|--------|--------|
| **Goal** | Population count by ZIP for deal geography. |
| **Source** | `household_hh_demographics_all_ts` ← ACS age bins, CPS age bins, household formation |
| **Path** | Demographics fact (union of feeders) → `pop_zip` CTE → `demographics_population` |
| **Logic** | `metric_id ILIKE '%POPULATION%'`, latest by ZIP |
| **What it shows now** | Only if one of the feeders (ACS, CPS, household formation) has a population metric at ZIP. Coverage and vintage unknown. |

**Data challenges:** Multiple feeders; which one wins is implicit. ACS/CPS/formation sources may be gated or empty. No explicit validation of coverage by ZIP.

---

### 3.2 Median HH Income

| Aspect | Detail |
|--------|--------|
| **Goal** | Median household income by ZIP. |
| **Source** | Same as 3.1: `household_hh_demographics_all_ts` |
| **Path** | Demographics fact → `income_zip` → `demographics_median_hh_income` |
| **Logic** | `metric_id ILIKE '%INCOME%'`, latest by ZIP |
| **What it shows now** | Same trust issues as 3.1. Income metric may come from ACS or other; definition and vintage unclear. |

**Data challenges:** Metric_id pattern may match multiple metrics; which one is used is implicit. Definition of “median HH income” (e.g., nominal, real, year) not documented.

---

### 3.3 Top 3 Industries by Employer

| Aspect | Detail |
|--------|--------|
| **Goal** | Top 3 NAICS industries by employment in deal CBSA. |
| **Source** | `household_hh_labor_qcew_naics` (QCEW BLS data) |
| **Path** | Gated by `anchor_use_qcew_top3` (default **false**) → `top3_industries_cbsa` → `demographics_top3_industries` |
| **Logic** | Top 3 by employment value, LISTAGG naics_code |
| **What it shows now** | **Always NULL.** Var is false; CTE is empty stub. |

**Data challenges:** Feature disabled by default. Even when enabled, QCEW pipeline must be populated. NAICS codes are raw—no industry labels unless joined to a ref.

---

### 3.4 Employment

| Aspect | Detail |
|--------|--------|
| **Goal** | Employment count/level by CBSA. |
| **Source** | `household_hh_labor_all_ts` ← `fact_cps_labor_ts` (BLS CPS) |
| **Path** | Gated by `anchor_household_labor_from_cps` (default true) → `labor_cbsa` → `demographics_employment` |
| **Logic** | `metric_id ILIKE '%EMPLOYMENT%' AND NOT '%UNEMPLOYMENT%'`, latest by CBSA |
| **What it shows now** | Only if `fact_cps_labor_ts` exists and has employment metric at CBSA. If CPS not loaded, labor fact stubs and this is NULL. |

**Data challenges:** CPS source may be missing or gated. CBSA grain requires geo alignment. Metric definition (employed, employed full-time, etc.) unclear.

---

### 3.5 Unemployment

| Aspect | Detail |
|--------|--------|
| **Goal** | Unemployment rate or count by CBSA. |
| **Source** | Same as 3.4: `household_hh_labor_all_ts` |
| **Path** | Same labor fact → `labor_cbsa` → `demographics_unemployment` |
| **Logic** | `metric_id ILIKE '%UNEMPLOYMENT%'`, latest by CBSA |
| **What it shows now** | Same as 3.4. |

**Data challenges:** Same as Employment.

---

## 4. Housing Market (Product Type)

### 4.1 Median Sale Price

| Aspect | Detail |
|--------|--------|
| **Goal** | Redfin median sale price by ZIP. |
| **Source** | `housing_hou_pricing_all_ts` ← Redfin, Cherre, ParclLabs, Markerr, Realtor, Zillow (union) |
| **Path** | Pricing fact → `price_zip` → `housing_median_sale_price` |
| **Logic** | `metric_id = 'REDFIN_MEDIAN_SALE_PRICE'` at ZIP |
| **What it shows now** | Only if Redfin feeder has data for that ZIP. Vendor priority and coverage undocumented. May be NULL for many ZIPs. |

**Data challenges:** Union of six vendors; Redfin may not be loaded or may have sparse coverage. Staleness and definition (e.g., SFR vs all) not documented.

---

### 4.2 Months of Supply

| Aspect | Detail |
|--------|--------|
| **Goal** | Housing months-of-supply inventory metric by ZIP. |
| **Source** | `housing_hou_inventory_all_ts` ← ParclLabs, Redfin, Cherre MLS, Yardi, Funnel BH, etc. |
| **Path** | Inventory fact → `inv_zip` → `housing_months_of_supply` |
| **Logic** | `metric_id ILIKE '%MONTHS%SUPPLY%' OR '%PARCLLABS%'`, latest by ZIP |
| **What it shows now** | Only if one of the feeders has months-of-supply or ParclLabs metric at ZIP. Pattern is fuzzy; multiple metrics could match. |

**Data challenges:** Metric_id pattern is loose. ParclLabs and months-of-supply are different concepts. Coverage and vendor mix undocumented.

---

### 4.3 Median Days on Market

| Aspect | Detail |
|--------|--------|
| **Goal** | Median DOM by ZIP. |
| **Source** | `housing_hou_demand_all_ts` ← Yardi SFDC, Cherre Recorder, Funnel BH (union) |
| **Path** | Demand fact → `dom_zip` → `housing_median_dom` |
| **Logic** | `metric_id ILIKE '%DAYS%MARKET%' OR '%DOM%' OR '%ZILLOW%'`, latest by ZIP |
| **What it shows now** | Only if demand feeders have DOM-like metric. Yardi/Cherre/Funnel may have different grains and definitions. |

**Data challenges:** Multiple metric_id patterns; which vendor/metric wins is implicit. Demand fact is a large union; coverage by ZIP unknown.

---

### 4.4 # of Builders within 5 miles

| Aspect | Detail |
|--------|--------|
| **Goal** | Count of distinct builders within 5 miles of each deal (spatial). |
| **Source** | `ref_anchor_deal_builders_within_5mi` ← `ref_builder_locations` (Zonda or other with lat/lon) |
| **Path** | Builder ref with coordinates → spatial join → `housing_builders_within_5mi` |
| **Logic** | COUNT(DISTINCT builder) within 5 mi |
| **What it shows now** | **Hardcoded 0 or NULL.** Zonda BTR comparables do not have lat/lon for spatial join. ref_builder_locations is stub. |

**Data challenges:** Zonda BTR data has CBSA, ZIP, sqft, price, builder—no coordinates. Cannot compute spatial count until builder locations with lat/lon exist.

---

## 5. Maps & Charts

### 5.1 Major Retailers Map (1/3/5 mi)

| Aspect | Detail |
|--------|--------|
| **Goal** | Map of retailers within 1, 3, 5 miles of deal. |
| **Source** | Same as 2.4: `fact_place_major_retailers` |
| **Path** | `V_ANCHOR_DEAL_SCREENER_RETAILERS`, `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL` |
| **What it shows now** | **0 rows.** Same as 2.4. |

**Data challenges:** Same as 2.4.

---

### 5.2 Comps (Zonda) – Scatter: X=sqft, Y=price, color=builder

| Aspect | Detail |
|--------|--------|
| **Goal** | BTR comparables for scatter: unit sqft (X), median sale price (Y), builder (color). |
| **Source** | `DS_TPANALYTICS.ZONDA.ZONDA_BTR_COMPARABLES` |
| **Path** | `source('zonda', 'zonda_btr_comparables')` when `anchor_zonda_comps_available: true` (default **false**) → `V_ANCHOR_ZONDA_COMPS` |
| **Logic** | SELECT CBSA, ID_ZIP, UNIT_SQFT, MEDIAN_SALE_PRICE, BUILDER_NAME |
| **What it shows now** | **0 rows.** Var false = stub. Even when true, table must exist and have data. Column names may differ (discovery needed). |

**Data challenges:** Database corrected to DS_TPANALYTICS. Table/schema not validated. Column mapping may need identifier/vars.

---

### 5.3 Annual Starts vs. Closings (Line Chart)

| Aspect | Detail |
|--------|--------|
| **Goal** | Annual SFR/BTR starts and closings by CBSA for construction pipeline view. |
| **Source (preferred)** | `DS_TPANALYTICS.ZONDA.ZONDA_STARTS_CLOSINGS` → `cleaned_zonda_starts_closings` → `fact_zonda_starts_closings_all_ts` |
| **Source (fallback)** | `fact_housing_hou_multifamily_all_ts` (JBRec MF_UNITS_STARTS) — **not SFR; closings null** |
| **Path** | Zonda: `zonda_starts_closings_available` + `anchor_starts_closings_from_zonda` (both default false). Fallback: `anchor_starts_closings_from_mf_fact: true` |
| **Logic** | Zonda: ZIP/CBSA grain, aggregate ZIP→CBSA via cbsa_zip_weights. Fallback: MF units starts only. |
| **What it shows now** | With JBRec fallback: MF units starts (wrong product). With Zonda: 0 rows until DS_TPANALYTICS.ZONDA exists and vars set. |

**Data challenges:** Preferred source (Zonda) gated and not validated. Fallback is MF, not SFR—misleading for SFR/BTR memo. Closings null in fallback.

---

### 5.4 School Score by Zip Map

| Aspect | Detail |
|--------|--------|
| **Goal** | Choropleth of school/education score by ZIP. |
| **Source** | Same as 2.2: `fact_place_plc_education_all_ts` |
| **Path** | `V_ANCHOR_SCHOOL_SCORE_BY_ZIP` |
| **What it shows now** | **Only Section 5 chart that “works”** per validation plan—but depends on place_ai_sources_available and EDUCATION source. |

**Data challenges:** Same as 2.2. “Works” means non-zero rows when sources are enabled; coverage and definition still uncertain.

---

### 5.5 Crime Score by Zip Map

| Aspect | Detail |
|--------|--------|
| **Goal** | Choropleth of crime/safety score by ZIP. |
| **Source** | Same as 2.3: `fact_place_plc_safety_all_ts` |
| **Path** | `V_ANCHOR_CRIME_SCORE_BY_ZIP` |
| **What it shows now** | **Fails.** Validation plan: crime choropleth empty. Markerr/Cotality not loaded. |

**Data challenges:** Same as 2.3.

---

## Summary: Metrics You Should Not Trust Without Validation

| Metric | Trust issue |
|--------|-------------|
| **Portfolio** | Deal source authority, decision_status values, loan_amount definition |
| **Progress 10mi** | unified_portfolio coverage, lat/lon source (property vs centroid) |
| **HBF Market Score** | External table; existence and content unknown |
| **School** | place_ai_sources_available; EDUCATION source coverage |
| **Crime** | Both place vars false; no crime data in practice |
| **Retailers** | CARTO not wired; always 0 |
| **Population, Income** | Demographics fact feeders; coverage and vintage undocumented |
| **Top 3 Industries** | anchor_use_qcew_top3 false; always NULL |
| **Employment, Unemployment** | CPS fact; may be empty or gated |
| **Median Sale Price** | Redfin coverage; vendor priority |
| **Months Supply** | Loose metric_id pattern; multiple vendors |
| **Median DOM** | Demand union; coverage and definition |
| **Builders 5mi** | No spatial data; always 0 |
| **Zonda Comps** | Var false; table not validated |
| **Starts vs Closings** | Zonda gated; fallback is MF not SFR |

---

## Recommended Actions

1. **Run discovery** on every source table and document: exists, row count, column names, sample, last update.
2. **Audit vars** in dbt_project.yml: which are true in prod, which sources they enable.
3. **Add row-count checks** (or tests) per delivery view and fact; fail or alert when 0 rows when data is expected.
4. **Document metric definitions**: HBF score, school rank, crime range, months of supply, DOM—what exactly is measured and at what grain/vintage.
5. **Validate DEALS** source: single source of truth, decision_status enum, loan_amount semantics.
6. **Fix Zonda path**: Confirm DS_TPANALYTICS.ZONDA.* exists, set vars, validate outputs.
