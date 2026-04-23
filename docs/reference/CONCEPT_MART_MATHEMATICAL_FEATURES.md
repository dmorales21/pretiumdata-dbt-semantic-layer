# Mathematical feature engineering by `CONCEPT_*` mart

**Canonical copy:** Synced from **analytics-engine** (`analytics-engine/docs/reference/CONCEPT_MART_MATHEMATICAL_FEATURES.md`). Feature-registry paths (`registry/features/*.yaml`) refer to that repo unless an equivalent exists here.

**Audience:** Engineers building **`2_feature`** off governed **`CONCEPT_*`** marts (`models/transform/dev/concept/`), Presley MI surfaces, and dbt semantic consumers.

**Principles:** Same spine keys across marts (`concept_code`, `vendor_code`, `month_start`, `geo_level_code`, `geo_id`, …). Prefer **declarable** transforms (`identity`, `log`, `ratio`, `zscore`, lags, rolling) in `registry/features/*.yaml` per `guide_features.md`. Residuals and composites need **`metric_derived_id`** / model version + `as_of` metadata.

**Cross-ref:** Slot pattern `{prefix}_current` / `_historical` / `_forecast` — engineer features per slot role: **levels** from current/historical, **horizon paths** from forecast + `forecast_month_start`.

---

## Tier 1 — contract-complete market unions

### `concept_rent_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels & scale** | `log1p(rent)` per `metric_id_observe`; **psf** if sqft-backed metric exists (`ratio` with documented denominator). |
| **Time dynamics** | `pct_change` / log-diff **MoM, QoQ, YoY** on aligned series; **lag_1m, lag_3m, lag_12m** on level and on growth. |
| **Cross-section** | **zscore** within `(geo_level_code, month_start)` cohort; **percentile_rank** within CBSA for sub-geos. |
| **Vendor / metric** | **Within-vendor** z-score then **blend** via documented weights; `metric_id_observe` one-hot or embedding hash for GBM (optional). |
| **Forecast use** | Spread **forecast vs current** at fixed horizons from `forecast_month_start`; **fan width** (forecast high − low) if vendor supplies bands. |
| **Affordability bridge** | Joined **`ratio(rent_median, income_median)`** only in `metric_derived` with both vintages tagged — not silent in rent mart. |

### `concept_valuation_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | `log1p(valuation_level)`; separate tracks for **index vs USD** if both exist (never one `metric_code`). |
| **Growth** | YoY / QoQ **log returns**; **momentum** (e.g. 3m annualized) with rolling windows. |
| **Relatives** | **zscore** within metro-month; **value residual** = level − metro OLS or ridge prediction from fundamentals (versioned baseline). |
| **Rates linkage** | **`cap_rate_implied`** style `ratio(noi_proxy, value)` only when numerator is same-grain or documented join; else keep in derived mart. |
| **Forecast** | Path features: **h-step ahead** level, **revision** = new_forecast − old_forecast at same `as_of`. |

### `concept_avm_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | `log1p(avm)`; **MoM change** with vendor revision flag as feature. |
| **Uncertainty** | If confidence interval exists: **relative_width** = `(high−low)/point`; **zscore(confidence)**. |
| **Cross-market** | CBSA **zscore**; **corridor rollup** = mean/sum with explicit weights in upstream join, not silent in slot. |
| **Consistency** | **Crosswalk** to `home_price` / `valuation` via ratio or residual only when contract allows; document **stub** rows as missingness indicators, not zeros. |

---

## Tier 1b — strong market unions (no separate CONTRACT file)

### `concept_transactions_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Counts / volume** | `log1p(sale_count)`; `log1p(sale_volume_usd)`; **ratio(count, stock)** when stock denominator exists. |
| **Dynamics** | **YoY** growth; **3m / 6m rolling sum** for SA noise reduction; **lag_12m** for seasonality alignment. |
| **Liquidity MI** | **`absorption_score`-style**: `log(sales_24m+1) − log(dom_proxy+1)` when DOM from listings mart joined at same grain. |
| **Vendor** | Vendor-level z-score then **stack** or **max** per policy; **coverage** = active_vendor_count / expected. |

### `concept_listings_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Flow** | `log1p(active_listings)`; **new_listings** MoM; **withdrawal rate** as ratio. |
| **DOM / cuts** | `log1p(dom_median)`; **price_cut_share**; **DOM trend** = rolling_mean_3m − rolling_mean_12m. |
| **Tightness bridge** | **MOS-style** = inventory / sales rate when both present; else **listings_per_capita** with `population` join. |
| **Seasonality** | STL residual or **month-of-year** fixed effects encoded as 11 dummies in feature spec (not in mart). |

### `concept_supply_pipeline_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Stock / flow** | **pipeline_to_stock** = `uc_units / stock`; **stage weights** as explicit columns then **weighted pipeline**. |
| **Burndown** | **`pipeline_burndown_ratio`** family; **months_to_clear** = pipeline / max(ε, absorption_rate). |
| **Dynamics** | **Δpipeline** MoM; **stale_flag** = months_since_stage_change > threshold. |
| **Cross-check** | **Permits vs pipeline** ratio at county when both exist — QA feature, not merged slot. |

### `concept_home_price_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Returns** | **log return** 1m / 3m / 12m; **momentum decile** within nation-month. |
| **Mix** | **mix-adjustment** residuals when medians used — version in `metric_derived`. |
| **Affordability** | **price_to_income** as joined derived only. |
| **Forecast** | Same as valuation: **fan width**, **revision**, **h-step** path features. |

---

## Tier 2 — usable with caveats

### `concept_permits_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | `log1p(permit_units)`; **YoY %** with zero guards. |
| **Stock ratios** | **permits_to_stock**; **3m / 12m rolling sum** for volatility reduction. |
| **Structural breaks** | **step_function** or **post_2020** regime dummy (policy explicit). |

### `concept_rates_national_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | **First differences**; **WoW / MoM** change for weekly-fed monthly spine. |
| **Curve** | **spread_30y_10y**; **mortgage_minus_ust** when both series exist. |
| **Stress** | Precomputed **+100bps** shock features for downstream DSCR grids (in `metric_derived` keyed to scenario_id). |

### `concept_employment_market_monthly` / `concept_unemployment_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Growth** | **YoY** employment change; **3m annualized** for noisy series. |
| **Slack** | **u_rate** level + **Δu** 3m; **u − u_natural`** only with documented natural-rate series. |
| **Spatial** | **County-to-CBSA** rollup check features (dispersion within CBSA). |
| **Caveat** | **LAUS AREA_CODE ≠ OMB CBSA** — ship **`geo_join_quality`** flag as feature, not silent remap. |

### `concept_income_market_annual` / `concept_labor_market_annual` / `concept_population_market_annual`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Growth** | **YoY** and **CAGR** over 3y / 5y where sample length allows. |
| **Real** | **deflate** with `inflation` spine — only in derived layer with matching `month_start` / vintage. |
| **Shares** | **working_age_share**, **renter_share** — compositional; use **log-ratio** or **ilr** if multi-share vector. |

### `concept_migration_market_annual` / `concept_school_quality_market_annual` / `concept_crime_market_annual`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Rates** | **per_capita** crime; **migration_rate** = net / population. |
| **Smoothing** | **Empirical Bayes** shrink for small geos (precompute table → join as feature). |
| **Ranks** | **percentile_within_metro** for school/crime MI screens. |

### `concept_delinquency_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Buckets** | **30/60/90+** as separate columns; **roll_rate** = Δbucket with sign discipline. |
| **Stock** | Balance-weighted if available; **YoY** change in serious DQ. |
| **Macro** | Join **national rates** as relative stress feature. |

### `concept_occupancy_market_monthly` / `concept_vacancy_market_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | **complement check** feature `abs(occupancy + vacancy − 1)` when both from same source. |
| **Dynamics** | **3m / 12m rolling mean**; **QoQ delta**. |
| **Supply interaction** | **vacancy × pipeline** interaction only in derived MI layer with explicit definition. |

---

## Tier 3 — property / special-purpose

### `concept_rent_property_monthly`

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Market rel** | **property_rent / cbsa_median_rent** ratio with `month_start` alignment. |
| **Time** | **lease_roll** seasonality if lease dates exist; else **lag_12m** on in-place rent. |
| **Sparse** | **is_stub_vendor** indicator from zero-row stub rows — use as **missingness** feature, not numeric zero. |

### `concept_multifamily_market_monthly` (legacy / special-purpose)

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Policy** | Prefer **decomposing** into canonical concepts (`rent`, `absorption`, `income`, …) in new work; if this mart remains, treat **wide MoM fields** as **pre-engineered** — validate each column maps to a **`metric_id`** or `metric_derived_id`. |
| **Rank stability** | Any composite score: **rolling OOS Spearman** metadata in model card, not silent in mart. |

---

## Shared spine features (all market `CONCEPT_*`)

| Feature | Formula / rule |
|---------|------------------|
| **`months_since_refresh`** | `as_of_date − vendor_last_refresh` if available. |
| **`vendor_coverage_count`** | Count distinct `vendor_code` non-null per `(geo_id, month_start)`. |
| **`geo_hierarchy_enrichment`** | Binary flags: `has_cbsa_id`, `has_county_fips`. |
| **`forecast_horizon_months`** | `months_between(month_start, forecast_month_start)` when forecast slots populated. |

---

## Part B — Remaining canonical `concept_code` families (`concepts_by_domain.csv`)

These are **semantic measure families** that may span **multiple `CONCEPT_*` unions**, **`metric_derived`**, or **property / pool** layers not named in Tier 1–3. For each: **where to source**, then **math features** to engineer in `2_feature`.

Cross-walk to Tier sections above: `rent`, `home_price`, `value_avm`, `transactions` / `transactions_sale_volume`, `supply_pipeline`, `permits`, `occupancy`, `vacancy`, `rates`, `employment`, `unemployment`, `income`, `population`, `migration`, `crime`, `school_quality`, `delinquency` are already partially covered in Tier 1–2 marts — Part B **extends** them with concept-specific composites and gaps. **`inflation`** is spelled out under **capital** in Part B (national deflator / wedge) even when it ships beside rates.

---

### `housing` domain

#### `absorption`

| Source | Primary `CONCEPT_*` / data path |
|--------|----------------------------------|
| **Preferred** | Vendor **net absorption** (e.g. CoStar-style) as its own tall `metric_id` joined to market spine when a dedicated union exists; else **`metric_derived`** from **inventory identity** or **leases − move-outs** with published error term. |
| **Often joined** | `concept_transactions_market_monthly` (flow) + `concept_supply_pipeline_market_monthly` (stock) — only with explicit denominators. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Rates** | `absorption_rate = flow / max(ε, stock)`; `log1p(net_units)`; **YoY** change in net units. |
| **Clearing** | **months_of_supply** when inventory + sales align; **absorption_score** = `log(sales_24m+1) − log(dom+1)` when listings mart joined. |
| **Lags** | **lag_1m, lag_3m** on rate; **lead** pipeline 12–24m for stress alignment. |

#### `absorption_tightness`

| Field | Detail |
|-------|--------|
| **Nature** | **Derived-only composite** (do not store as silent overwrite of `absorption`). |
| **Inputs** | `vacancy`, `absorption` / transactions flow, `supply_pipeline`, optional `listings` / DOM from `concept_listings_market_monthly`. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Composite** | **z**-normalize each input then **weighted sum** (weights versioned); **`tightness_alt`** = `1 − vacancy` when definition matches. |
| **Nonlinear** | **Winsor** tails at metro-month p1/p99 before z; **interaction** `pipeline × absorption_rate` with ε denominator. |
| **Stability** | **Rolling 6m** composite for MI rankers; **OOS Spearman** tracked in model card. |

#### `concession`

| Field | Detail |
|-------|--------|
| **Primary source** | `concept_rent_market_monthly` (effective vs asking spread), lease/MF vendor columns, or **`concept_multifamily_market_monthly`** wide fields — map each to **`metric_id`**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | `concession_weeks_free`; **NER drag** = `ratio(rent_asking − rent_effective, rent_asking)` with ε. |
| **Competition** | **Join `vacancy`** → `concession × vacancy` interaction in derived layer only. |
| **Seasonality** | **month-of-year** interaction with concession depth. |

#### `construction_feasibility`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_permits_market_monthly`** + external **cost / regulatory** indices (when in FACT); else **`metric_derived`** from permits + time-to-permit proxies. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Ratios** | **permits_to_stock**; **real permits** = deflated by construction cost index when available. |
| **Friction** | **regulatory_index** z-score within state; **interaction** `permits × regulatory` for supply-response MI. |

#### `liquidity`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_transactions_market_monthly`** + **`concept_listings_market_monthly`** (DOM, inventory). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Core** | `log1p(sales)`; `log1p(dom)`; **liquidity_score** = `log(sales_24m+1) − log(dom+1)` (document window). |
| **Cross** | **turnover** = sales / stock; **new_listings / sales** imbalance ratio. |

#### `occupancy_operations`

| Field | Detail |
|-------|--------|
| **Primary source** | **Property / ops** feeds (Yardi, REIT ops) — often **`concept_rent_property_monthly`**-adjacent or separate property mart; not the same row semantics as `concept_occupancy_market_monthly` (HUD survey). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Ops gap** | **`economic_occupancy − market_occupancy`** join at `(property_id, month_start)` with geo rollup for MI. |
| **Collections** | **collections_rate**, **bad_debt_ratio** when available — `logit` bounded transforms. |

#### `product_structure`

| Field | Detail |
|-------|--------|
| **Primary source** | **ACS / Census** shares in `concept_population_market_annual` or **`concept_multifamily_market_monthly`** segment columns — treat as **compositional vector**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Shares** | **log-ratio** vs baseline segment; **HHI** across product types within market. |
| **Stability** | **YoY Δshare**; **ilr** transform if ≥3 categories in one vector. |

#### `supply_elasticity`

| Field | Detail |
|-------|--------|
| **Primary source** | **`metric_derived`** from long panel: response of **permits or starts** to **price or rent** shocks — rarely a single CONCEPT slot. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Regression** | **Local β** from rolling 10y panel (CBSA): `Δpermits ~ Δrent_lag` with **FE**; publish **SE** or bucket (high/med/low elasticity). |
| **Proxy** | **z(inverse_regulatory)** × **z(land_supply_proxy)** when indices exist. |

*Already covered in Tier sections but extended here:* **`home_price`**, **`rent`**, **`supply_pipeline`**, **`permits`**, **`occupancy`**, **`vacancy`**, **`transactions`**, **`transactions_sale_volume`**, **`value_avm`** — add **cross-concept ratios** only in `metric_derived` (e.g. `rent_to_value`, `gross_yield`) with explicit `metric_id` lineage.

---

### `household` domain

#### `affordability_ceiling`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_income_market_annual`** + **`concept_rent_market_monthly`** (or rent annual rollup) — **`metric_derived` only**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Core** | **`rent_to_income`** = `ratio(rent_median, income_median)`; **payment_stress** when mortgage + income available (RESI MI). |
| **Nonlinear** | **Spline or threshold flags** above metro-specific RTI quantile; **real RTI** using `inflation`. |

#### `household_demographics_demand`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_population_market_annual`** + ACS-derived share columns (renter, age cohorts) where present in union or sidecar. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Growth** | **YoY** `hh_count`, **renter_share** Δ; **working_age_share**. |
| **Interaction** | **`hh_growth × migration_rate`** for demand-pressure MI (document ε on rates). |

#### `household_formation`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_population_market_annual`** (household series) or derived **`Δhouseholds`**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Flow** | **YoY** and **CAGR**; **ratio to population growth** to detect divergence. |

#### `wages`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_labor_market_annual`** (QCEW-style wage slots) when present; else county wage index from ACS sidecar. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Growth** | **YoY wage_growth**; **wage − inflation** real growth. |
| **Spread** | **`wage_growth − rent_growth`** for ops / affordability MI (join at geo-year). |

#### `income`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_income_market_annual`** (Tier 2). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Growth** | **YoY** and **3y CAGR**; **real income** via `concept_rates_national_monthly` / CPI spine in `metric_derived` only. |
| **Distribution** | **p20 / p50 / p80** when ACS supports multiple percentiles — separate `metric_id` per percentile. |
| **MI cross** | **`income_rent_growth_spread`** vs `concept_rent_market_monthly` (annualized rent growth join). |

#### `migration`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_migration_market_annual`** (Tier 2). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Rates** | **`net_migration / population`** with consistent denominator vintage. |
| **Flows** | **gross in** + **gross out** when available — `log1p` on flows; **net** as level. |
| **MI** | **3y average** migration to damp annual noise; **origin concentration** HHI when OD table exists. |

#### `population`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_population_market_annual`** (Tier 2). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Growth** | **YoY** and **CAGR**; **boundary-event** adjustment flags. |
| **Structure** | **working_age_share**, **dependency_ratio** — compositional transforms as in Tier 2 `labor` / demographics row. |

---

### `place` domain

#### `accessibility_commute`

| Field | Detail |
|-------|--------|
| **Primary source** | **Gravity / LODES** precomputes → FACT joined by `geo_id`; often **not** a single `CONCEPT_*` union — ship as **`FEATURE_*`** from frozen OD tables. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Core** | **`log1p(jobs_within_30min)`**; **decay-weighted** access sum; **zscore** within CBSA. |
| **Spatial** | **Neighbor mean** on H3 k-ring when `W` explicit. |

#### `automation`

| Field | Detail |
|-------|--------|
| **Primary source** | **County annual** task exposure (O*NET × employment) — FACT or small union; align ontology `workforce_task_automation` if renamed. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Exposure** | **index level**; **× employment_share** interaction; **YoY Δexposure** when SOC mix shifts. |

#### `climate_hazard_exposure`

| Field | Detail |
|-------|--------|
| **Primary source** | **Vendor hazard scores** (First Street, FEMA flags) at ZIP/county — FACT; join to market spine. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | **max(flood, fire, wind)** or **weighted sum** (weights versioned); **`log1p(insurance_cost_index)`** when linked. |
| **Rank** | **percentile_within_state** for regulatory comparability. |

#### `economic_growth`

| Field | Detail |
|-------|--------|
| **Primary source** | **Composite** of `concept_employment_market_monthly`, `concept_income_market_annual`, `migration` — **`metric_derived`** with fixed formula version. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Score** | **`z(job_growth) + z(income_growth) + z(migration)`** (weights documented); **3y rolling** for smooth MI. |

#### `employment`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_employment_market_monthly`** (Tier 2; see LAUS vs QCEW caveats in Tier 2 employment/unemployment row). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **MI extensions** | **3m annualized** growth; **employment / population** ratio; **place-of-work** vs **residence** split only as separate `metric_id`s, never merged. |

#### `unemployment`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_unemployment_market_monthly`** (Tier 2). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **MI extensions** | **Δu** 3m and 12m; **u × employment** interaction for slack narratives; **`geo_join_quality`** when LAUS CBSA ≠ OMB CBSA. |

#### `crime`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_crime_market_annual`** (Tier 2). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **MI extensions** | **Violent vs property** sub-index z-scores; **NIBRS transition** dummy; **3y rolling mean** for stable location screens. |

#### `school_quality`

| Field | Detail |
|-------|--------|
| **Primary source** | **`concept_school_quality_market_annual`** (Tier 2). |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **MI extensions** | **Enrollment-weighted** composite where sub-scores exist; **district–ZIP mismatch** flag; **YoY Δscore** with scale-change guard. |

#### `labor`

| Field | Detail |
|-------|--------|
| **Primary source** | **BLS participation / hours** — may live in **`concept_labor_market_annual`** or separate tall metrics; **do not double-count** `employment` / `unemployment`. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Slack** | **LFPR**, **hours_per_worker**; **participation_gap** vs national. |

#### `labor_growth_access`

| Field | Detail |
|-------|--------|
| **Primary source** | **`metric_derived`** combining **`concept_employment_market_monthly`** growth + **accessibility** table + optional wage growth. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Composite** | **`z(job_growth) + z(access_index)`**; **rolling 12m** employment growth for noise reduction. |

#### `location_amenity_access`

| Field | Detail |
|-------|--------|
| **Primary source** | **POI / walk / transit** composites — FACT or licensed index; join to `geo_id`. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Core** | **index z-score** within metro; **YoY Δindex** when vendor refreshes. |
| **Urban** | **urban_dummy × index** interaction for calibration. |

#### `spatial_spillover`

| Field | Detail |
|-------|--------|
| **Primary source** | **`FEATURE_*`** built from neighbor aggregation of any market mart column — **not** a CONCEPT slot. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Neighbors** | **`mean_neighbor(rent_growth)`**, **`mean_neighbor(hpa)`** on H3 or contiguity `W`. |
| **Lag** | **spatial_lag_1** vs **spatial_lag_2** for robustness. |

---

### `capital` domain (often property / pool / `MODEL_*`)

These frequently **do not** appear as CBSA monthly `CONCEPT_*` market unions in the Tier list; engineer from **loan tape + property marts + AVM** or publish as **`ESTIMATE_*` / `MODEL_*`**.

#### `noi`

| Field | Detail |
|-------|--------|
| **Primary source** | Property GL / UW (`concept_noi_property_*` pattern when exists); else **`MODEL_*`**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Levels** | **T3 / T12 rolling**; **YoY** growth; **margin** = `ratio(NOI, EGI)` with defined EGI. |
| **Bridge** | **stabilized − in_place** spread; **scenario** NOI shocks (+/− rent, opex). |

#### `dscr`

| Field | Detail |
|-------|--------|
| **Primary source** | **NOI + debt schedule** → derived; stress grids in `metric_derived` with `scenario_id`. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Core** | **`ratio(NOI, debt_service)`**; **IO flag** × DSCR interaction feature. |
| **Stress** | **DSCR at +100bps** from precomputed payment shock. |

#### `ltv`

| Field | Detail |
|-------|--------|
| **Primary source** | **Loan balance / value**; value from **`concept_avm_market_monthly`** or property AVM with **`value_source`**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Dynamics** | **mark-to-market LTV** path; **ΔLTV** vs **HPA** correlation feature. |
| **Severity** | **cltv** when subordinate debt exists — separate `metric_id`. |

#### `cap_rate`

| Field | Detail |
|-------|--------|
| **Primary source** | **Transaction-implied** from deals + **`concept_valuation_market_monthly`** / rent; or **`metric_derived`**. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Spread** | **`cap_rate − rate_index`** (`cap_rate_real_spread` family); **YoY Δcap**. |
| **Decomp** | **ΔNOI / V** attribution vs **NOI × Δ(1/V)** when both move. |

#### `arbitrage`

| Field | Detail |
|-------|--------|
| **Primary source** | **`4_estimate` / score bundle** — not a raw CONCEPT column; inputs from rent, value, liquidity, risk concepts. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Score** | **`z(rent_growth) + z(rent_residual) − z(value_residual) + z(liquidity) − z(risk)`** (signs fixed per version, `guide_translation`). |

#### `capital_structure_ownership`

| Field | Detail |
|-------|--------|
| **Primary source** | **Entity / fund aggregates** — REF or portfolio mart, not housing CONCEPT. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Shares** | **institutional_share**; **HHI** across owners; **Δshare** YoY. |

#### `risk`

| Field | Detail |
|-------|--------|
| **Primary source** | **Volatility + liquidity + credit** composite — `metric_derived` with versioned weights. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Vol** | **rolling std** of returns (rent or HPA); **drawdown** max over 24m. |
| **Composite** | **`z(vol) + z(dq) + z(liquidity_inverse)`** with documented direction. |

#### `inflation`

| Field | Detail |
|-------|--------|
| **Primary source** | **National** CPI/PCE (FRED/BLS) — often co-located with **`concept_rates_national_monthly`** or a dedicated national spine; do not duplicate series under two `metric_id`s without a bridge table. |

| Category | Recommended mathematical features |
|----------|-----------------------------------|
| **Core** | **MoM** and **YoY** log changes; **core vs headline** wedge as its own column family. |
| **Deflator use** | **Real cuts** of `income`, `rent`, `wages` only in `metric_derived` with **matched vintage** and `as_of` on both numerator and index. |

*Covered in Tier 2:* **`delinquency`**, **`rates`** — add **curve + real rate** interactions for capital MI; pair with **`inflation`** row above for breakeven / real-wage MI.

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial mapping: mathematical feature engineering requests per `CONCEPT_*` tier list (rent, valuation, AVM, transactions, listings, supply_pipeline, home_price, Tier 2 gov stacks, property rent, legacy MF panel). |
| **0.2** | Part B: remaining **`concept_code`** families from `concepts_by_domain.csv` — absorption, tightness, concession, construction_feasibility, liquidity, occupancy_operations, product_structure, supply_elasticity; household composites; place composites (accessibility, automation, climate, economic_growth, labor, labor_growth_access, location, spillover); capital property/pool features (noi, dscr, ltv, cap_rate, arbitrage, capital_structure, risk). |
| **0.3** | Part B: explicit **`income` / `migration` / `population`** and **`employment` / `unemployment` / `crime` / `school_quality`** subsections; fixed `Field \| Detail` source tables; typo fixes in hazard / risk / labor-access formulas. |
