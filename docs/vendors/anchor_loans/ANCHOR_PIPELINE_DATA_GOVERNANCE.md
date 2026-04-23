# Anchor Deal Screener Pipeline – Data Governance & Vetting

**Purpose**: Govern and vet all data in the Anchor screener pipeline: keep metrics within reasonable bounds and maintain a single list of functions used.  
**Related**: [ANCHOR_SCREENER_DATA_MAP.md](ANCHOR_SCREENER_DATA_MAP.md), [QUALITY_FRAMEWORK](../../snowflake/07_QUALITY_FRAMEWORK.md), [QUALITY_SCHEMA_CONTRACT](../../rules/metrics/QUALITY_SCHEMA_CONTRACT.md).

---

## 1. Pipeline scope (models to govern)

All models upstream of `v_anchor_deal_screener` and the delivery view itself:

| Layer | Models |
|-------|--------|
| **SOURCE_ENTITY** | `anchor_loans.deals` (source) |
| **TRANSFORM_PROD.CLEANED** | Progress/Yardi/Funnel/Cherre/Redfin/Zillow/Parcllabs/Markerr/Cotality/Education cleaned views and incrementals feeding fact |
| **TRANSFORM_PROD.FACT** | `housing_hou_pricing_all_ts`, `housing_hou_inventory_all_ts`, `housing_hou_demand_all_ts`, `household_hh_demographics_all_ts`, `household_hh_labor_all_ts`, `household_hh_labor_qcew_naics`, `fact_place_plc_education_all_ts`, `fact_place_plc_safety_all_ts`; `source('fact','capital_cap_economy_all_ts')` |
| **TRANSFORM_PROD.REF** | `unified_portfolio`, `ref_anchor_deal_builders_within_5mi`, `ref_builder_locations` |
| **EDW_PROD.DELIVERY** | `v_anchor_deal_screener`, `v_anchor_deal_screener_retailers`, `v_anchor_school_score_by_zip`, `v_anchor_crime_score_by_zip`, etc. |

---

## 2. Definition of success (content, not just row count)

A run is **successful** only when both (a) dbt completes without error and (b) **content** criteria are met. “All columns could have null” is not success; we define what “good” looks like.

### 2.1 Per-deal success (e.g. Liberty Hill)

For a given deal (e.g. `DEAL_ID = 'LIBERTY_HILLS'`) in `EDW_PROD.DELIVERY.V_ANCHOR_DEAL_SCREENER`:

| Criterion | Requirement | Why |
|-----------|-------------|-----|
| **Row exists** | Exactly one screener row for the deal | Pipeline built the view and joined the deal. |
| **Geography** | At least one of `zip_code` or `cbsa_code` is non-null (and valid format) | Joins to fact/ref are by ZIP or CBSA; without either, location/demographics/housing stay null. |
| **Portfolio** | `portfolio_closed_deals` and `portfolio_sum_peak_upb` are numeric (≥ 0); may be 0. | From DEALS; 0 is valid. |
| **At least one location metric** | At least one of `location_hbf_market_score`, `location_school_district_rank`, `location_crime_rating_range` is non-null **when** deal has zip_code. | Proves place facts are joined. |
| **At least one demographics metric** | At least one of `demographics_population`, `demographics_median_hh_income`, `demographics_employment`, `demographics_unemployment` is non-null **when** deal has zip_code (ZIP) or cbsa_code (CBSA). | Proves demographics facts are joined. |
| **At least one housing metric** | At least one of `housing_median_sale_price`, `housing_months_of_supply`, `housing_median_dom` is non-null **when** deal has zip_code. | Proves housing facts are joined. |
| **Bounds** | When non-null, numeric columns fall within §3 reasonable bounds (e.g. sale price 1e4–1e8, months supply 0–120). | Data is plausible, not corrupt. |

So: **success = deal row exists + (zip_code or cbsa_code) + at least one non-null metric per section (portfolio, location, demographics, housing) where geography allows + numerics in bounds.**

### 2.2 Pipeline run success

- **dbt**: `dbt run --select +v_anchor_deal_screener` (or `run_liberty_hill_full_pipeline.sh`) completes with **0 errors** (SKIP/NO-OP are acceptable for optional models).
- **Validation script**: `scripts/anchor/validate_anchor_liberty_hill.py` exits **0** only when the per-deal content criteria above are satisfied for the target deal (e.g. LIBERTY_HILLS).

If the script only checked “screener row count = 1”, that would not guarantee content; the script must check geography and “at least one non-null per section” (and optionally bounds).

---

## 3. Reasonable bounds (vetting rules)

Use these to flag outliers, add dbt tests, or drive QUALITY-layer validation. Values outside bounds should be flagged (e.g. `quality_flag = 'OUTLIER'`) or tested (e.g. `dbt_utils.accepted_range`).

### 2.1 Deal source (SOURCE_ENTITY.ANCHOR_LOANS.DEALS)

| Column / concept | Type | Reasonable bounds | Enforcement |
|------------------|------|-------------------|-------------|
| `deal_id` | Identifier | Not null, unique | `not_null`, `unique` |
| `zip_code` | VARCHAR | 5-digit US ZIP or NULL (pre-geocode) | `dbt_utils.expression_is_true`: `zip_code IS NULL OR (LENGTH(TRIM(zip_code)) = 5 AND zip_code REGEXP '^[0-9]+$')` |
| `id_cbsa` | VARCHAR | Valid CBSA code or NULL | Optional: relationship to `dim_geography` when not null |
| `latitude` | FLOAT | -90 ≤ lat ≤ 90 | `dbt_utils.accepted_range`: min=-90, max=90 |
| `longitude` | FLOAT | -180 ≤ lon ≤ 180 | `dbt_utils.accepted_range`: min=-180, max=180 |
| `loan_amount` | Numeric | ≥ 0 (allow NULL) | `expression_is_true`: `loan_amount IS NULL OR loan_amount >= 0` |
| `decision_status` | VARCHAR | Enum (e.g. funded, declined, …) | `accepted_values` if list is fixed |

### 2.2 Portfolio (screener output)

| Output column | Type | Reasonable bounds | Enforcement |
|---------------|------|-------------------|-------------|
| `portfolio_closed_deals` | Integer | ≥ 0 | ≥ 0 |
| `portfolio_sum_peak_upb` | Numeric | ≥ 0 | ≥ 0 |
| `portfolio_progress_homes_10mi` | Integer | ≥ 0 | ≥ 0 |

### 2.3 Location (screener output)

| Output column | Source metric | Reasonable bounds | Enforcement |
|---------------|----------------|-------------------|-------------|
| `location_hbf_market_score` | HBF / market score | 0–100 or 0–1 (document scale) | `accepted_range` once scale is fixed |
| `location_school_district_rank` | School/Cotality score | 0–100 or 1–10 (document scale) | `accepted_range` |
| `location_crime_rating_range` | Crime score | 0–100 or 1–5 (document scale) | `accepted_range` |

### 2.4 Demographics (screener output)

| Output column | Source metric | Reasonable bounds | Enforcement |
|---------------|----------------|-------------------|-------------|
| `demographics_population` | Population (ZIP) | 0 ≤ value ≤ 2e7 (per ZIP) | `accepted_range` min=0, max=2e7 |
| `demographics_median_hh_income` | Median HH income (ZIP) | 1e3 ≤ value ≤ 5e6 (USD) | `accepted_range` min=1000, max=5000000 |
| `demographics_employment` | Employment (CBSA) | ≥ 0 | `expression_is_true`: `value >= 0` |
| `demographics_unemployment` | Unemployment (CBSA) | 0 ≤ value ≤ 1e7 (count) or 0–100 (rate %) | Document unit; then `accepted_range` |
| `demographics_top3_industries` | NAICS list | Text, pipe-separated | No numeric bound; not_null optional |

### 2.5 Housing market (screener output)

| Output column | Source metric | Reasonable bounds | Enforcement |
|---------------|----------------|-------------------|-------------|
| `housing_median_sale_price` | REDFIN_MEDIAN_SALE_PRICE (ZIP) | 1e4 ≤ value ≤ 1e8 (USD) | `accepted_range` min=10000, max=1e8 |
| `housing_months_of_supply` | Months of supply (ZIP) | 0 ≤ value ≤ 120 | `accepted_range` min=0, max=120 |
| `housing_median_dom` | Days on market (ZIP) | 0 ≤ value ≤ 3650 (~10 years) | `accepted_range` min=0, max=3650 |
| `housing_builders_within_5mi` | Count of builders | ≥ 0 | ≥ 0 |

### 2.6 Fact-layer inputs (upstream of screener)

Fact tables already apply filters in SQL (e.g. `value > 0`, `value >= 0`) where applicable. Additional vetting:

| Fact / concept | Bounds already in pipeline | Suggested test |
|----------------|---------------------------|----------------|
| `housing_hou_pricing_all_ts` | `value > 0` in sources | `dbt_utils.accepted_range` on `value` per metric_id (e.g. REDFIN_MEDIAN_SALE_PRICE 1e4–1e8) |
| `housing_hou_inventory_all_ts` | `value >= 0`, date &lt;= 1 year future | Same; exclude far-future `date_reference` |
| `housing_hou_demand_all_ts` | Numeric cast, filters in union | accepted_range for DOM-like metrics (0–3650) |
| `household_hh_demographics_all_ts` | — | Population 0–2e7, income 1e3–5e6 |
| `household_hh_labor_all_ts` | — | Employment ≥ 0; unemployment 0–100 if rate |
| `fact_place_plc_education_all_ts` | — | Score 0–100 or 1–10 per vendor |
| `fact_place_plc_safety_all_ts` | — | Score 0–100 or 1–5 per vendor |

---

## 4. List of functions used in the pipeline

### 4.1 Snowflake SQL functions (in screener and Anchor ref models)

| Function | Usage |
|----------|--------|
| **ACOS** | Haversine distance: `ACOS(LEAST(1, GREATEST(-1, ...)))` |
| **CAST** | Empty CTE: `CAST(NULL AS VARCHAR)` |
| **COS** | Haversine: cos(lat), cos(lon diff) |
| **COALESCE** | Defaults: `COALESCE(decision_status,'')`, `COALESCE(SUM(loan_amount),0)`, `COALESCE(pn.portfolio_progress_homes_10mi,0)` |
| **COUNT** | `COUNT(*)`, `COUNT(DISTINCT property_id)`, `COUNT(DISTINCT builder_id/builder_name)` |
| **GREATEST** | Clamp for ACOS: `GREATEST(-1, dot_product)` |
| **GROUP BY** | Aggregation by deal_id, geo_id, cbsa_code |
| **ILIKE** | Metric pattern match: `metric_id ILIKE '%HBF%'`, `'%POPULATION%'`, `'%INCOME%'`, etc. |
| **LEAST** | Clamp for ACOS: `LEAST(1, ...)` |
| **LEFT JOIN / INNER JOIN / CROSS JOIN** | Joins deals to CTEs and refs |
| **LOWER** | `LOWER(COALESCE(p.entity_id,'')) = 'progress'`, `LOWER(decision_status) = 'funded'` |
| **LISTAGG** | `LISTAGG(naics_code, ' | ') WITHIN GROUP (ORDER BY value DESC)` (top3 industries) |
| **MAX** | Latest date: `MAX(date_reference)`; labor: `MAX(CASE WHEN ... THEN value END)` |
| **NOT** | `metric_id NOT ILIKE '%UNEMPLOYMENT%'` |
| **ORDER BY** | In QUALIFY and LISTAGG: `ORDER BY date_reference DESC`, `ORDER BY value DESC NULLS LAST` |
| **PARTITION BY** | `ROW_NUMBER() OVER (PARTITION BY geo_id ORDER BY date_reference DESC)` |
| **QUALIFY** | Dedupe: `QUALIFY ROW_NUMBER() OVER (...) = 1` |
| **RADIANS** | Haversine: convert degrees to radians |
| **ROW_NUMBER** | Dedupe latest per geo: `ROW_NUMBER() OVER (PARTITION BY geo_id ORDER BY date_reference DESC)` |
| **SELECT / FROM / WHERE** | Standard SQL |
| **SIN** | Haversine: sin(lat) |
| **SUM** | `SUM(loan_amount)` for portfolio_sum_peak_upb |
| **WITHIN GROUP** | With LISTAGG: `WITHIN GROUP (ORDER BY value DESC)` |

### 4.2 dbt / Jinja functions (in pipeline models)

| Function / construct | Usage |
|----------------------|--------|
| **config()** | `config(materialized='view', tags=['delivery','canonical','anchor_screener'])` |
| **ref()** | Reference dbt models: `ref('housing_hou_pricing_all_ts')`, `ref('unified_portfolio')`, `ref('fact_place_plc_education_all_ts')`, `ref('fact_place_plc_safety_all_ts')`, `ref('household_hh_demographics_all_ts')`, `ref('housing_hou_inventory_all_ts')`, `ref('housing_hou_demand_all_ts')`, `ref('household_hh_labor_all_ts')`, `ref('household_hh_labor_qcew_naics')`, `ref('ref_anchor_deal_builders_within_5mi')`, `ref('ref_builder_locations')` |
| **source()** | `source('anchor_loans','deals')`, `source('fact','capital_cap_economy_all_ts')` |
| **var()** | `var('anchor_use_qcew_top3', false)` for optional QCEW top3 CTE |

### 4.3 Functions in upstream fact/cleaned (representative)

Used in transform_prod fact/cleaned models that feed the screener:

- **TRY_CAST / CAST**: Type coercion (e.g. demand fact numeric columns).
- **DATEADD / DATEDIFF**: Date bounds (e.g. `date_reference <= DATEADD('year',1,CURRENT_DATE())`).
- **MAX / MIN / SUM / COUNT / AVG**: Aggregations in unions and rollups.
- **COALESCE / NULLIF**: Null handling and division safety.
- **QUALIFY ROW_NUMBER()**: Dedupe by geo/date.
- **CASE WHEN / ILIKE**: Metric selection and filters.
- **value &gt; 0, value &gt;= 0**: In-model data quality filters (housing_hou_pricing_all_ts, housing_hou_inventory_all_ts, fact_redfin_inventory, etc.).

---

## 5. How to enforce governance

### 5.1 dbt tests (recommended)

- **Deals source**: On `anchor_loans.deals`: `not_null` on `deal_id`; `accepted_range` on `latitude` (-90, 90), `longitude` (-180, 180); `expression_is_true` for `loan_amount >= 0` and ZIP format when present.
- **Fact value bounds**: Add `dbt_utils.accepted_range` (or custom test) for fact tables used by the screener, per metric_id where appropriate (see §2).
- **Delivery view**: Optional singular test on `v_anchor_deal_screener`: e.g. “no row has housing_median_sale_price &lt; 0” or “portfolio_* columns &gt;= 0”.

### 5.2 Quality layer (optional)

Per [QUALITY_SCHEMA_CONTRACT](../../rules/metrics/QUALITY_SCHEMA_CONTRACT.md): validated views can add `QUALITY_FLAG`, `P01`/`P99`, and mark `OUTLIER` when `value < P01 OR value > P99`. Stale rule: `DATEDIFF('day', date_reference, CURRENT_DATE()) > 90` → STALE.

### 5.3 Monitoring (existing framework)

- **Completeness**: Demographics &gt;95%, Market Intelligence &gt;90% (see [07_QUALITY_FRAMEWORK.md](../../snowflake/07_QUALITY_FRAMEWORK.md)).
- **Timeliness**: Time series &lt;7 days since `MAX(date_reference)`.
- **Consistency**: e.g. unemployment ≤ employment at same geo/date when both are counts.

### 5.4 Run validation

- After pipeline run: `scripts/anchor/validate_anchor_liberty_hill.py` enforces **§2 content success**: deal present, exactly one screener row, geography (zip_code or cbsa_code), ≥1 non-null per section (location, demographics, housing when geography allows), portfolio numeric ≥0, and bounds (e.g. sale price 10k–100M, months supply 0–120). Exit 0 only when all pass.
- Optional: dbt singular test on `v_anchor_deal_screener` for additional bounds (e.g. no row with housing_median_sale_price &lt; 0).

---

## 6. Summary

| Goal | Action |
|------|--------|
| **Keep data in bounds** | Apply §3 reasonable bounds as dbt `accepted_range` / `expression_is_true` tests on source and fact; optionally QUALITY layer with P01/P99 and OUTLIER flag. |
| **List all functions** | §4: Snowflake (ACOS, COALESCE, COUNT, ILIKE, MAX, QUALIFY, ROW_NUMBER, SIN/COS/RADIANS, LISTAGG, etc.) and dbt (ref, source, config, var). |
| **Vet pipeline** | Run `dbt test --select tag:anchor_screener + tag:fact + source:anchor_loans` (and fact models feeding screener); run `validate_anchor_liberty_hill.py` (must pass content criteria in §2); use QUALITY_FRAMEWORK thresholds for completeness/timeliness. |
