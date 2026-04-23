# Anchor Deal Screener – Data Map

**Purpose**: Map each screener section/metric to source tables, metric IDs, and delivery views.  
**Template**: `ADMIN.CATALOG.DIM_TEMPLATE` row `ANCHOR_DEAL_SCREENER`.  
**Delivery**: `EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER`, `V_ANCHOR_DEAL_SCREENER_RETAILERS`, `V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL`, `V_ANCHOR_ZONDA_COMPS`, `V_ANCHOR_STARTS_CLOSINGS_CBSA`, `V_ANCHOR_SCHOOL_SCORE_BY_ZIP`, `V_ANCHOR_CRIME_SCORE_BY_ZIP`.  
**Governance**: Data bounds, vetting rules, and full function list → [ANCHOR_PIPELINE_DATA_GOVERNANCE.md](ANCHOR_PIPELINE_DATA_GOVERNANCE.md).

---

## Canonical pipeline alignment

This screener follows the [Canonical Data Architecture Contract](../../governance/CANONICAL_ARCHITECTURE_CONTRACT.yml):

- **Layers**: Deal source (SOURCE_ENTITY) + **TRANSFORM_PROD.CLEANED** → **TRANSFORM_PROD.FACT** → **TRANSFORM_PROD.REF** → **EDW_PROD.DELIVERY**. No PUBLIC or DBT_PROJECTS_* for fact/cleaned/ref; schema is set per model via `dbt_project.yml` (+schema: fact, cleaned, ref, delivery).
- **Geography**: Canonical metrics use **CBSA** where applicable (labor, top3 industries); ZIP is used for place/housing metrics that are ZIP-level in fact tables.
- **Fact source**: In `sources.yml`, the fact source uses `database: transform_prod`, `schema: fact`. Tables in that schema are read via `ref()` when built by this repo, or via `source('fact', 'table_name')` when the table is not a dbt model in this project (e.g. `capital_cap_economy_all_ts`).
- **Read pattern**: Delivery view `v_anchor_deal_screener` uses **ref()** for all dbt-built fact/ref models (so build order and DAG are correct) and **source()** only for: `anchor_loans.deals` (SOURCE_ENTITY) and `fact.capital_cap_economy_all_ts` (external fact table not built in this repo).
- **Build order**: Run upstream with `dbt run --select +v_anchor_deal_screener`. Cleaned → Fact → Ref models build first; then EDW delivery views. Liberty Hill script: `scripts/anchor/run_liberty_hill_full_pipeline.sh`.

---

## Deal source

| Source | Description |
|--------|-------------|
| `SOURCE_ENTITY.ANCHOR_LOANS.DEALS` | One row per deal. Key columns: `DEAL_ID`, `ZIP_CODE`, `ID_CBSA`, `LATITUDE`, `LONGITUDE`, `LOAN_AMOUNT`, `STATUS`, `DECISION_STATUS`; also `PROPERTY_ADDRESS`, `CITY`, `STATE`, `NAME_CBSA`, `H3_8_HEX`, `CREATED_AT`, etc. Geocoding via `PROCESS_NEW_DEALS()`. Discovery: `scripts/validation/get_anchor_screener_columns.py` → `anchor_screener_columns.json`. |
| **Geography from coordinates** | When `ZIP_CODE` or `ID_CBSA` are null, the screener uses **ref_anchor_deal_geography_resolved**: lat/lon → H3 cell (resolution 10) → parent 8 (meso), 6 (macro) → join to **H3 canon 6810** (`TRANSFORM_PROD.REF.H3_XWALK_6810_CANON`) for overlaying geographies (ZIP, CBSA, county, tract). See [GEOGRAPHY_RESOLUTION_FROM_COORDINATES.md](../../architecture/GEOGRAPHY_RESOLUTION_FROM_COORDINATES.md). |

---

## Portfolio

| Item | Label | Source table | Layer | Read via | Metric / logic | Delivery view |
|------|--------|--------------|-------|----------|----------------|----------------|
| 1.1 | Anchor Loans Closed Deals | SOURCE_ENTITY.ANCHOR_LOANS.DEALS | SOURCE_ENTITY | source('anchor_loans', 'deals') | Count where decision_status = funded (global) | V_ANCHOR_DEAL_SCREENER.portfolio_closed_deals |
| 1.2 | Anchor Sum of Peak UPB | SOURCE_ENTITY.ANCHOR_LOANS.DEALS | SOURCE_ENTITY | source('anchor_loans', 'deals') | Sum(loan_amount) where funded (global) | V_ANCHOR_DEAL_SCREENER.portfolio_sum_peak_upb |
| 1.3 | Progress Owned Homes within 10 mi | TRANSFORM_PROD.REF.UNIFIED_PORTFOLIO | REF | ref('unified_portfolio') | Haversine count where entity_id = Progress | V_ANCHOR_DEAL_SCREENER.portfolio_progress_homes_10mi |

---

## Location

| Item | Label | Source table | Layer | Read via | Metric / pattern | Geo | Delivery view |
|------|--------|--------------|-------|----------|------------------|-----|----------------|
| 2.1 | Pretium HBF Market Score | TRANSFORM_PROD.FACT.CAPITAL_CAP_ECONOMY_ALL_TS | FACT | source('fact', 'capital_cap_economy_all_ts') | metric_id ILIKE '%HBF%' OR '%MARKET%SCORE%' | ZIP | V_ANCHOR_DEAL_SCREENER.location_hbf_market_score |
| 2.2 | School District Rank / Score | TRANSFORM_PROD.FACT.FACT_PLACE_PLC_EDUCATION_ALL_TS | FACT | ref('fact_place_plc_education_all_ts') | SCHOOL / COTALITY | ZIP | V_ANCHOR_DEAL_SCREENER.location_school_district_rank |
| 2.3 | Crime Rating Range | TRANSFORM_PROD.FACT.FACT_PLACE_PLC_SAFETY_ALL_TS | FACT | ref('fact_place_plc_safety_all_ts') | Latest value by ZIP | ZIP | V_ANCHOR_DEAL_SCREENER.location_crime_rating_range |
| 2.4 | Major Retailers | TRANSFORM_PROD.FACT.FACT_PLACE_MAJOR_RETAILERS | FACT | ref (when built) | Point-level lat/lon; 1/3/5 mi bands. Until spatial: list by ZIP only. | — | V_ANCHOR_DEAL_SCREENER_RETAILERS, V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL |

---

## Demographics

| Item | Label | Source table | Layer | Read via | Metric / pattern | Geo | Delivery view |
|------|--------|--------------|-------|----------|------------------|-----|----------------|
| 3.1 | Population | TRANSFORM_PROD.FACT.HOUSEHOLD_HH_DEMOGRAPHICS_ALL_TS | FACT | ref('household_hh_demographics_all_ts') | metric_id ILIKE '%POPULATION%' | ZIP | V_ANCHOR_DEAL_SCREENER.demographics_population |
| 3.2 | Median HH Income | TRANSFORM_PROD.FACT.HOUSEHOLD_HH_DEMOGRAPHICS_ALL_TS | FACT | ref('household_hh_demographics_all_ts') | metric_id ILIKE '%INCOME%' | ZIP | V_ANCHOR_DEAL_SCREENER.demographics_median_hh_income |
| 3.3 | Top 3 Industries by Employer | TRANSFORM_PROD.FACT.HOUSEHOLD_HH_LABOR_QCEW_NAICS | FACT | ref('household_hh_labor_qcew_naics') | Top 3 NAICS by employment (CBSA) | CBSA | V_ANCHOR_DEAL_SCREENER.demographics_top3_industries |
| 3.4 | Employment | TRANSFORM_PROD.FACT.HOUSEHOLD_HH_LABOR_ALL_TS | FACT | ref('household_hh_labor_all_ts') | metric_id ILIKE '%EMPLOYMENT%' | CBSA | V_ANCHOR_DEAL_SCREENER.demographics_employment |
| 3.5 | Unemployment | TRANSFORM_PROD.FACT.HOUSEHOLD_HH_LABOR_ALL_TS | FACT | ref('household_hh_labor_all_ts') | metric_id ILIKE '%UNEMPLOYMENT%' | CBSA | V_ANCHOR_DEAL_SCREENER.demographics_unemployment |

---

## Housing market

| Item | Label | Source table | Layer | Read via | Metric ID / pattern | Geo | Delivery view |
|------|--------|--------------|-------|----------|----------------------|-----|----------------|
| 4.1 | Median Sale Price | TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS | FACT | ref('housing_hou_pricing_all_ts') | REDFIN_MEDIAN_SALE_PRICE | ZIP | V_ANCHOR_DEAL_SCREENER.housing_median_sale_price |
| 4.2 | Months of Supply | TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS | FACT | ref('housing_hou_inventory_all_ts') | %MONTHS%SUPPLY% or PARCLLABS% | ZIP | V_ANCHOR_DEAL_SCREENER.housing_months_of_supply |
| 4.3 | Median Days on Market | TRANSFORM_PROD.FACT.HOUSING_HOU_DEMAND_ALL_TS | FACT | ref('housing_hou_demand_all_ts') | %DAYS%MARKET% / %DOM% / ZILLOW% | ZIP | V_ANCHOR_DEAL_SCREENER.housing_median_dom |
| 4.4 | # Builders within 5 miles | REF (Zonda-derived) | REF | ref('ref_anchor_deal_builders_within_5mi') | COUNT(DISTINCT builder) spatial 5 mi when Zonda has lat/lon. | — | V_ANCHOR_DEAL_SCREENER.housing_builders_within_5mi (currently 0 until Zonda spatial) |

---

## Maps & charts

| Item | Label | Source table | Layer | Read via | Notes | Delivery view |
|------|--------|--------------|-------|----------|--------|----------------|
| 5.1 | Major Retailers Map 1/3/5 mi | TRANSFORM_PROD.FACT.FACT_PLACE_MAJOR_RETAILERS | FACT | ref (when built) | Distance bands 1, 3, 5 mi (0 rows until point-level data) | V_ANCHOR_DEAL_SCREENER_RETAILERS, V_ANCHOR_DEAL_SCREENER_RETAILERS_DETAIL |
| 5.2 | Comps Zonda | DS_TPANALYTICS.ZONDA.ZONDA_BTR_COMPARABLES | DS_TPANALYTICS | source('zonda', 'zonda_btr_comparables') | UNIT_SQFT, MEDIAN_SALE_PRICE, BUILDER_NAME; stub until table exists | V_ANCHOR_ZONDA_COMPS |
| 5.3 | Annual Starts vs Closings | ANALYTICS_PROD.FEATURES.FEATURE_MARKET_SPOT_CBSA | FEATURES | source('features', …) / ref when in repo | SFR_STARTS, SFR_CLOSINGS; CBSA grain; stub until table exists | V_ANCHOR_STARTS_CLOSINGS_CBSA |
| 5.4 | School Score by Zip Map | TRANSFORM_PROD.FACT.FACT_PLACE_PLC_EDUCATION_ALL_TS | FACT | ref('fact_place_plc_education_all_ts') | Same as 2.2; app filters by cbsa_code | V_ANCHOR_SCHOOL_SCORE_BY_ZIP |
| 5.5 | Crime Score by Zip Map | TRANSFORM_PROD.FACT.FACT_PLACE_PLC_SAFETY_ALL_TS | FACT | ref('fact_place_plc_safety_all_ts') | Same as 2.3; app filters by cbsa_code | V_ANCHOR_CRIME_SCORE_BY_ZIP |

---

## Build order and refresh

Canonical order: **Cleaned** → **Fact** → **Ref** → **EDW Delivery**. One-command upstream + screener:

- **Liberty Hill (one deal)**: `./scripts/anchor/run_liberty_hill_full_pipeline.sh` — full-refresh `housing_hou_demand_all_ts` then `dbt run --select +v_anchor_deal_screener`.
- **All delivery**: `dbt run --select +tag:delivery` (e.g. `scripts/run_tethering_edw.sh`). Anchor-only: `dbt run --select +v_anchor_deal_screener` or `tag:anchor_screener`.
- **FACT_PLACE_MAJOR_RETAILERS**: Built in TRANSFORM_PROD.FACT (stub until point-level source wired).
- **Template**: `dbt run --select dim_template`; tests: `dbt test --select dim_template`.

---

## Notes

- **unified_portfolio**: Built by dbt in **TRANSFORM_PROD.REF** from cleaned Progress/Yardi views (e.g. `progress_properties`). Columns used by screener: `entity_id`, `latitude`, `longitude`, `property_id`. If source column names differ (e.g. `OPCO`, `LAT`, `LON`), update the `progress_nearby` CTE in `v_anchor_deal_screener.sql`.
- **FACT_PLACE_MAJOR_RETAILERS**: Currently stub (0 rows). Populate from Overture (`ovt_places_classified`) or CARTO when column mapping is confirmed. Until then, 2.4 is list-by-ZIP only if a fact provides it; otherwise use V_ANCHOR_DEAL_SCREENER_RETAILERS when spatial is available.
- **Top 3 industries**: Delivered as `demographics_top3_industries` (pipe-separated NAICS codes from HOUSEHOLD_HH_LABOR_QCEW_NAICS). Industry labels can be added via NAICS ref if needed.
- **ZONDA_BTR_COMPARABLES**: Confirm database/schema and column names (CBSA, ID_ZIP, UNIT_SQFT, MEDIAN_SALE_PRICE, BUILDER_NAME) in Snowflake. housing_builders_within_5mi remains NULL until Zonda has coordinates for spatial join. **V_ANCHOR_ZONDA_COMPS** is currently a stub (0 rows) until the source table exists; then replace the stub SQL with the real `source('zonda', 'zonda_btr_comparables')` query.
- **FEATURE_MARKET_SPOT_CBSA**: Confirm table name and columns (date_reference, geo_id, SFR_STARTS, SFR_CLOSINGS) and grain (annual vs monthly) in ANALYTICS_PROD.FEATURES. **V_ANCHOR_STARTS_CLOSINGS_CBSA** is currently a stub (0 rows) until the table exists; then replace with the real source query.
- **Top 3 industries**: Set `vars.anchor_use_qcew_top3: true` in dbt_project.yml when `household_hh_labor_qcew_naics` is built and populated; otherwise the screener uses an empty CTE and `demographics_top3_industries` is NULL.
