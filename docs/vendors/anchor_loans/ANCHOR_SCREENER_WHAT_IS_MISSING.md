# Anchor Deal Screener – What Is Missing to Complete the Memo

**Purpose:** One-to-one map of the [Anchor Screener Guide](#anchor-screener-guide) to implementation status and what is missing.  
**Main view:** `EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER` (one row per deal).  
**Data map:** `docs/vendors/anchor_loans/ANCHOR_SCREENER_DATA_MAP.md`.

---

## Anchor Screener Guide (checklist)

### 1. Portfolio

| # | Memo item | Status | What’s missing / notes |
|---|----------|--------|-------------------------|
| 1.1 | **Anchor Loans Closed Deals** | ✅ Implemented | Column `portfolio_closed_deals`. Source: DEALS where `decision_status = 'funded'`. No action. |
| 1.2 | **Anchor Sum of Peak UPB** | ✅ Implemented | Column `portfolio_sum_peak_upb`. Source: DEALS. No action. |
| 1.3 | **Progress Owned Homes (within 10 miles)** | ✅ Implemented | Column `portfolio_progress_homes_10mi`. Uses `ref('unified_portfolio')` from `progress_properties`; lat/lon from `admin_catalog.dim_geography` ZIP centroid. **If 0:** ensure `dim_geography` has rows for Progress ZIPs with `centroid_lat`/`centroid_lon` populated. |

---

### 2. Location

| # | Memo item | Status | What’s missing / notes |
|---|----------|--------|-------------------------|
| 2.1 | **Pretium HBF Market Score** | ⚠️ Depends on fact | Column `location_hbf_market_score`. Source: `capital_cap_economy_all_ts` where `metric_id ILIKE '%HBF%' OR '%MARKET%SCORE%'` at ZIP. **If NULL:** ensure that fact is built and contains an HBF/market score metric at ZIP. |
| 2.2 | **School District Rank** | ✅ Implemented | Column `location_school_district_rank`. Source: `fact_place_plc_education_all_ts` (now fed by EDUCATION.EDGE_PUBLIC_SCHOOLS + cleaned). No action unless you want Cotality school score (set `place_cotality_available` when Cotality exists). |
| 2.3 | **Crime Rating Range** | ✅ Implemented | Column `location_crime_rating_range`. Source: `fact_place_plc_safety_all_ts` (Markerr + cleaned). No action. |
| 2.4 | **Major Retailers** | ⚠️ Transform CARTO | Views: `V_ANCHOR_DEAL_SCREENER_RETAILERS`, `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL`. **Fact** `FACT_PLACE_MAJOR_RETAILERS` reads from `ref('cleaned_carto_major_retailers')`. **To complete:** Discover CARTO `carto_place_layer` schema; replace stub in `cleaned_carto_major_retailers.sql` with SELECT mapping id, name, lat/lon (or ST_X/Y(geom)), address, zip, cbsa, category; then retailers list and 1/3/5 mi map will fill. |

---

### 3. Demographics

| # | Memo item | Status | What’s missing / notes |
|---|----------|--------|-------------------------|
| 3.1 | **Population** | ⚠️ Depends on fact | Column `demographics_population`. Source: `household_hh_demographics_all_ts` at ZIP, `metric_id ILIKE '%POPULATION%'`. **If NULL:** ensure that fact is built and has population metric at ZIP. |
| 3.2 | **Median HH Income** | ⚠️ Depends on fact | Column `demographics_median_hh_income`. Source: `household_hh_demographics_all_ts` at ZIP, `metric_id ILIKE '%INCOME%'`. **If NULL:** ensure that fact has income metric at ZIP. |
| 3.3 | **Top 3 Industries by Employer** | ⚠️ Off by default | Column `demographics_top3_industries`. Source: `household_hh_labor_qcew_naics` (CBSA). **Currently:** `anchor_use_qcew_top3: false` → column is NULL. **To complete:** Set `anchor_use_qcew_top3: true` in `dbt_project.yml` and ensure QCEW cleaned/fact are populated (or keep false if no QCEW data). |
| 3.4 | **Employment** | ✅ In-repo | Column `demographics_employment`. Source: `ref('household_hh_labor_all_ts')` (model unions `fact_cps_labor_ts`). **If NULL:** ensure `fact_cps_labor_ts` and upstream `bls_cps_cbsa` are populated. |
| 3.5 | **Unemployment** | ✅ In-repo | Column `demographics_unemployment`. Same source as 3.4. |

---

### 4. Housing Market (Product Type)

| # | Memo item | Status | What’s missing / notes |
|---|----------|--------|-------------------------|
| 4.1 | **Median Sale Price** | ✅ Implemented | Column `housing_median_sale_price`. Source: `housing_hou_pricing_all_ts`, `metric_id = 'REDFIN_MEDIAN_SALE_PRICE'` at ZIP. No action. |
| 4.2 | **Months of Supply** | ⚠️ Depends on fact | Column `housing_months_of_supply`. Source: `housing_hou_inventory_all_ts` at ZIP, `metric_id ILIKE '%MONTHS%SUPPLY%' OR '%PARCLLABS%'`. **If NULL:** ensure that fact has months-of-supply (or Parcl Labs) metric at ZIP. |
| 4.3 | **Median Days on Market** | ⚠️ Depends on fact | Column `housing_median_dom`. Source: `housing_hou_demand_all_ts` at ZIP, `metric_id ILIKE '%DAYS%MARKET%' OR '%DOM%' OR '%ZILLOW%'`. **If NULL:** ensure `housing_hou_demand_all_ts` builds and has a DOM-like metric at ZIP (Yardi/Cherre/Funnel feeds). |
| 4.4 | **# of Builders within 5 miles** | ✅ In-repo (stub) | Column `housing_builders_within_5mi` is **hardcoded NULL** in the screener. **Missing:** Zonda (or other) source with builder locations (lat/lon) to do a 5 mi spatial count. **To complete:** Add source for Zonda BTR/comps with coordinates; add logic (or a small view) that counts distinct builders within 5 mi of each deal and join into the main screener (or document as “future” until Zonda has coords). |

---

### 5. Maps & Charts

| # | Memo item | Status | What’s missing / notes |
|---|----------|--------|-------------------------|
| 5.1 | **Major Retailers Map (1 / 3 / 5 mi)** | ⚠️ Transform CARTO | Same as 2.4 – fact reads from `cleaned_carto_major_retailers`. Transform CARTO place layer to populate that cleaned model; then these views return rows with `distance_miles` and bands. |
| 5.2 | **Comps (Zonda)** – X=sqft, Y=median price, color=builder | ✅ Wired | View: `V_ANCHOR_ZONDA_COMPS` selects from `source('zonda', 'zonda_btr_comparables')` (CBSA, ID_ZIP, UNIT_SQFT, MEDIAN_SALE_PRICE, BUILDER_NAME). **If 0 rows:** confirm Zonda table exists in Snowflake and column names match (or add `identifier` in sources.yml). |
| 5.3 | **Annual Starts vs Closings line chart** | ❌ Stub (0 rows) | View: `V_ANCHOR_STARTS_CLOSINGS_CBSA`. **Missing:** Source table (e.g. `ANALYTICS_PROD.FEATURES.FEATURE_MARKET_SPOT_CBSA`) with `date_reference`, `cbsa_code`, `sfr_starts`, `sfr_closings` (or equivalent). **To complete:** Confirm table name and columns in Snowflake; add source if needed; replace stub in `v_anchor_starts_closings_cbsa.sql` with real query. |
| 5.4 | **School Score by Zip map** | ✅ Implemented | View: `V_ANCHOR_SCHOOL_SCORE_BY_ZIP`. Fed by `fact_place_plc_education_all_ts`. No action. |
| 5.5 | **Crime Score by Zip map** | ✅ Implemented | View: `V_ANCHOR_CRIME_SCORE_BY_ZIP`. Fed by `fact_place_plc_safety_all_ts`. No action. |

---

## Summary: What you must do to “complete” the memo

| Priority | Item | Action |
|----------|------|--------|
| **1** | **Major Retailers (2.4, 5.1)** | Follow **`ANCHOR_CARTO_RETAILERS_DISCOVERY.md`**: discover CARTO schema in Snowflake, then replace stub in `cleaned_carto_major_retailers.sql`. Fact already reads from that cleaned model. |
| **2** | **Zonda Comps (5.2)** | Done: `v_anchor_zonda_comps` reads from `source('zonda', 'zonda_btr_comparables')`. If 0 rows, confirm table/columns in Snowflake. |
| **3** | **Starts vs Closings (5.3)** | Confirm feature table (e.g. `FEATURE_MARKET_SPOT_CBSA`) and columns; add source if needed; replace stub in `v_anchor_starts_closings_cbsa.sql`. |
| **4** | **Builders within 5 mi (4.4)** | In-repo: `ref_builder_locations` (stub) + `ref_anchor_deal_builders_within_5mi`. Populate `ref_builder_locations` from Zonda (or other) when builder lat/lon available. |
| **5** | **Top 3 Industries (3.3)** | Set `anchor_use_qcew_top3: true` and ensure QCEW pipeline is populated if you want this field. |
| **6** | **Everything else** | Ensure upstream facts are built and contain the expected metric_ids (HBF, population, income, employment, unemployment, months of supply, DOM). If a metric is NULL for a deal, check that the corresponding fact has data for that deal’s ZIP/CBSA and date. |

---

## Quick reference: delivery views and stubs

| View | Purpose | Stub? |
|------|---------|--------|
| `V_ANCHOR_DEAL_SCREENER` | Main screener (one row per deal) | No – all columns wired; some values NULL where upstream missing. |
| `V_ANCHOR_DEAL_SCREENER_RETAILERS` | Retailers list (e.g. by deal or ZIP) | No – logic present; 0 rows until `FACT_PLACE_MAJOR_RETAILERS` has data. |
| `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL` | Deal × retailer + distance (map pins) | No – logic present; 0 rows until fact has lat/lon. |
| `V_ANCHOR_ZONDA_COMPS` | Zonda comps scatter (sqft, price, builder) | No – wired to Zonda source; 0 rows if table missing or empty. |
| `V_ANCHOR_STARTS_CLOSINGS_CBSA` | Starts vs closings line chart | **Yes – 0-row stub** until feature table exists. |
| `V_ANCHOR_SCHOOL_SCORE_BY_ZIP` | School score map | No – fed by place education fact. |
| `V_ANCHOR_CRIME_SCORE_BY_ZIP` | Crime score map | No – fed by place safety fact. |

---

## Run and validate

**Env vars required:** The dbt profile uses `env_var('DBT_DB')`. Set them before running dbt (or use the script, which sets defaults):

```bash
# One-liner (tag only, no upstream deps)
DBT_DB=TRANSFORM_PROD DBT_SCHEMA=DEV dbt run --select tag:anchor_screener --vars '{anchor_household_labor_from_cps: false}'

# Or use the script (builds upstream + anchor_screener, loads .env if present)
export DBT_DB=TRANSFORM_PROD DBT_SCHEMA=DEV
./scripts/anchor/run_anchor_pipeline.sh
```

- **With CPS labor:** Omit `--vars '{anchor_household_labor_from_cps: false}'` (or set `true`) once `fact_cps_labor_ts` exists.
- **Liberty Hill (one deal, full pipeline):** `./scripts/anchor/run_liberty_hill_full_pipeline.sh` — builds `+v_anchor_deal_screener` then runs `validate_anchor_liberty_hill.py`. Ensures deal `LIBERTY_HILLS` is in source and has one row in screener.
- Validate only: `scripts/anchor/validate_anchor_liberty_hill.sql` / `validate_anchor_liberty_hill.py` (deal_id = LIBERTY_HILLS)
