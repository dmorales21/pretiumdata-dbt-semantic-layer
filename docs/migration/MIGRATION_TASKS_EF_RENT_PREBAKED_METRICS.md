# Migration plan — **Effective rent & pre-baked metrics (Snowflake-only)**

**Owner:** Alex  
**Governs:** `MIGRATION_RULES.md` (layer contract), `MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`, `REFERENCE.CATALOG` (`concept`, `dataset`, `metric`).  
**Scope:** Estimation, **scoring**, **sorting**, **forecasting** implemented as **dbt models in Snowflake** (no required Python feature engine). Optional downstream extract to S3/analytics-engine stays **out of scope** for this checklist.

---

## 1. Model types (Snowflake / dbt) — **do not mix layers**

| Purpose | dbt model prefix | Canonical Snowflake home | Reads (via `ref` / `source`) | Produces |
|---------|------------------|---------------------------|------------------------------|----------|
| **Vendor-typed or long-form facts** | `fact_*` | **`TRANSFORM.DEV`** | `source('transform_*', …)`, `source('source_snow_*', …)`, Jon `TRANSFORM.[VENDOR]` | Normalized **FACT_*** tables (grain + `metric_id` / EAV columns as designed). |
| **Domain compositions from FACT** | `concept_*` | **`TRANSFORM.DEV`** (`models/transform/dev/concept/` — same lineage rules) | `ref('fact_*')` | **CONCEPT_*** — e.g. lease × concession spine, rent roll panels, cohort bases. **No** scoring or z-scores here unless purely structural. |
| **Feature engineering (pre-baked metrics)** | `feature_*` | **`ANALYTICS.DBT_DEV`** | `ref('fact_*')`, `ref('concept_*')` | **FEATURE_*** — `effective_rent`, rolling medians, **z-scores**, ranks-within-window, flags. **All SQL** (windows, `QUALIFY`, joins to `REFERENCE.GEOGRAPHY`). |
| **Scoring / sort keys / indices** | `model_*` | **`ANALYTICS.DBT_DEV`** | `ref('feature_*')` | **MODEL_*** — deciles, composite scores, **sort_key** for portfolios, tier assignments. |
| **Forecasts & estimates** | `estimate_*` | **`ANALYTICS.DBT_DEV`** | `ref('feature_*')`, `ref('fact_*')` | **ESTIMATE_*** — point/interval **predictions**, forward series. Prefer **Snowflake-native** patterns: window-based trend, `REGR_SLOPE` / `REGR_INTERCEPT` over history, or **Snowflake ML** functions if account policy allows; document algorithm in model YAML. |

**Hard rules (from `MIGRATION_RULES.md`):**

- **`FACT_*` / `CONCEPT_*` never physical in `ANALYTICS`.**  
- **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*` never physical in `TRANSFORM.DEV` as base tables** — they live in **`ANALYTICS.DBT_DEV`**.

---

## 2. SQL feature engineering plan — **effective rent** and **z-scores**

Implement as a **directed acyclic graph** of dbt models (lowest → highest layer).

### Stage 0 — Inputs (already migrating elsewhere)

| Input | Typical `FACT_*` / source | Notes |
|-------|-----------------------------|--------|
| Asking / list / market rent | `FACT_*` from Markerr, Zillow, Matrix, ApartmentIQ, CoStar, Yardi ops | Align **grain** (property, unit, ZIP, CBSA) before join. |
| Concessions (free rent, $ off, %) | Same vendors or `CONCEPT_*` lease spine | Normalize to **$/month equivalent** or **% of term** with one documented convention. |
| Occupancy / leased % | Markerr, Yardi, ApartmentIQ | Use for **economic** or **physical** occupancy per product doc. |
| Geo spine | `REFERENCE.GEOGRAPHY.*` | `CBSA_ID`, `COUNTY_FIPS`, `ZCTA` / `ZIP` per `MIGRATION_RULES` §6–7. |

### Stage 1 — **`CONCEPT_*` (optional but recommended)**

| Model idea | Grain | SQL role |
|------------|-------|----------|
| `concept_rent_roll_monthly` | `(property_id or unit_id, month)` | Union/normalize asks + concessions onto one timeline; output **gross_rent**, **concession_value_monthly**, **lease_term_months**. |

### Stage 2 — **`FEATURE_*` — pre-baked metrics (core deliverable)**

| Feature column | Definition (SQL) | Window / cohort for z-score |
|----------------|------------------|-------------------------------|
| `effective_rent_monthly` | `gross_rent - amortized_monthly_concession` (or `(1 - concession_pct) * gross_rent`) | — |
| `effective_rent_vs_market_ratio` | `effective_rent / nullif(market_rent_median_same_geo,0)` | Market rent from aligned `FACT_*` at same grain. |
| `effective_rent_cohort_median` | `median(effective_rent)` | `PARTITION BY` **geo** (e.g. `cbsa_id`, `zip_code`), **product_type_code**, **`date_month`** (and bedroom band if needed). |
| `effective_rent_cohort_stddev` | `stddev_samp(effective_rent)` | Same partition. |
| `effective_rent_zscore` | `(effective_rent - cohort_median) / nullif(cohort_stddev, 0)` | Use **population** vs **sample** std consistently; document `ddof`. |
| `effective_rent_zscore_3m_roll` | rolling avg of z-score | Optional smoothing for noisy small-N ZIPs. |
| `cohort_n` | `count(*)` over partition | **Expose** for gating (suppress z-score when `cohort_n < k`). |

**Implementation patterns in Snowflake SQL**

- Two-pass: CTE with `effective_rent`, then `QUALIFY` + window `median`/`stddev` over partition.  
- Or single `SELECT` with nested windows if stable under Snowflake optimizer.  
- **Sparse cohorts:** coalesce ZIP → CBSA median via `COALESCE` window or join to parent geo.  
- **Time alignment:** `date_trunc('month', …)` on all inputs before join.

### Stage 3 — **`MODEL_*` — scoring & sorting**

| Output | SQL role |
|--------|----------|
| `effective_rent_decile` | `ntile(10)` over `ORDER BY effective_rent` within `(cbsa_id, product_type_code, month)`. |
| `rent_value_score` | Weighted combo of z-score, vs-market ratio, cohort depth — **document weights** in YAML. |
| `sort_key_rent_value` | Monotonic transform of score for **stable sort** (e.g. `100 - decile` + tie-breaker). |

### Stage 4 — **`ESTIMATE_*` — forecasting (still Snowflake)**

| Output | Methods (pick per product) |
|--------|----------------------------|
| `estimate_effective_rent_forward_3m` | Rolling **OLS** via `REGR_SLOPE` / `REGR_INTERCEPT` on last N months; or **Snowflake ML** forecast if enabled. |
| Prediction interval | Residual std × critical value — document assumptions. |

---

## 3. Catalog & registry work (**REFERENCE.CATALOG**)

| Artifact | Action |
|----------|--------|
| **`concept.csv`** | Ensure **`rent`** and **`concession`** (and if needed **`effective_rent`** as derived concept) align with definitions. |
| **`dataset.csv`** | Each vendor slice used in the chain: `pipeline_status`, `source_schema`, `concept_code`, `geo_level_code`. |
| **`metric.csv`** | One row per **published warehouse column** (typically **`TRANSFORM.DEV.FACT_*`**) with `table_path`, `snowflake_column`, `concept_code`. |
| **`metric_derived.csv`** | One row per **logical analytics output** (`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`): `metric_derived_code`, `analytics_layer_code`, exactly one of `function_code` / `model_type_code` / `estimate_type_code`, optional `primary_metric_code` → `metric`. See **`docs/reference/CATALOG_METRIC_DERIVED_LAYOUT.md`**. |
| **`bridge_product_type_metric.csv`** | Populate **`product_type_code`** × **`metric_code`** (and later **`metric_derived_code`** if product bridges extend) × `is_required` for tearsheet / UW packs (currently empty — **blocking** product-type-specific UW if not filled). |

---

## 4. dbt / engineering checklist (migration execution)

- [ ] **Sources:** register all vendor tables used in `models/sources/*.yml` (no hardcoded FQNs).  
- [ ] **`FACT_*`:** land or ref vendor facts on **`TRANSFORM.DEV`**; PK + `not_null` + `relationships` to geo seeds where applicable.  
- [ ] **`CONCEPT_*`:** if lease/concession normalization is non-trivial, isolate here.  
- [ ] **`FEATURE_*`:** implement **effective_rent** + cohort stats + **z-scores**; document window keys in model YAML.  
- [ ] **`MODEL_*`:** deciles / scores / **sort keys**; tests on monotonicity or bounds if policy requires.  
- [ ] **`ESTIMATE_*`:** forecast models; version suffix or `version` config if multiple algorithms coexist.  
- [ ] **Performance:** cluster / incremental on `(cbsa_id, date_month)` or property key per volume.  
- [ ] **Governance:** `tags`, `meta` for PII / sensitivity (Yardi, lease-level).  
- [ ] **`MIGRATION_LOG.md`:** batch entry + catalog diff.  
- [ ] **Consumers:** Strata / tearsheet / internal SQL — point reads to **`ANALYTICS.DBT_DEV`** objects only for features+.

---

## 5. Task ID (register in `MIGRATION_TASKS.md`)

| Task ID | Scope | Status |
|---------|--------|--------|
| **T-ANALYTICS-FEATURE-EFFECTIVE-RENT-STACK** | `FEATURE_*` / `MODEL_*` / `ESTIMATE_*` for effective rent, z-scores, sort keys, forecasts; catalog bridges | `pending` |

**Dependencies:** `T-VENDOR-MARKERR-READY`, `T-VENDOR-YARDI-MATRIX-READY`, `T-VENDOR-APARTMENTIQ-READY`, `T-VENDOR-COSTAR-READY`, `T-TRANSFORM-CENSUS-ACS5-READY` (for cohort covariates), and **`REFERENCE.GEOGRAPHY`** bridges — **partial OK** if scoped to one vendor pilot.

---

## 6. Explicit non-goals (still “Snowflake-only” but wrong layer)

- Do **not** put z-scores or deciles on **`TRANSFORM.DEV.FACT_*`** — those are **features / models**.  
- Do **not** require **analytics-engine** `feature_spec.py` for production truth — it may **consume** the same metrics via extract later; **Snowflake tables are canonical** for this plan.
