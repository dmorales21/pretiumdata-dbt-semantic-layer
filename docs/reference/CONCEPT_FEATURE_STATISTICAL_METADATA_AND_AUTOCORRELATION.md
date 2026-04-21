# Concept metrics — statistical metadata & FEATURE autocorrelation

**Owner:** Alex (DS) · **Audience:** anyone authoring **`ANALYTICS.DBT_DEV`.`FEATURE_*`** off **`TRANSFORM.DEV`.`CONCEPT_*`**  
**Purpose:** (1) Map each shipped **`CONCEPT_*`** object to **primary `MET_*` / slot columns** and **catalog statistical hints** (`unit`, `polarity`, frequency). (2) Standardize **lag-1 autocorrelation** (and differencing) checks for **monthly / annual** panels so ML prep in **`FEATURE_*`** does not confuse **levels** with **innovations**.

**Related:** [`QA_CATALOG_METRICS_STATISTICAL_INVENTORY.md`](../migration/QA_CATALOG_METRICS_STATISTICAL_INVENTORY.md) (bounds tests) · [`metric_derived.csv`](../../seeds/reference/catalog/metric_derived.csv) (`MDV_*`) · [`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`](../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) §2 (variance / leakage) · [`SERVING_DEMO_METRICS_CATALOG_MAP.md`](./SERVING_DEMO_METRICS_CATALOG_MAP.md).

---

## 1. Canonical statistical metadata (where it lives)

| Layer | Statistical bounds & units | Autocorrelation / dynamics |
|-------|------------------------------|----------------------------|
| **`REFERENCE.CATALOG.metric`** | `unit`, `polarity`, `frequency_code`, `geo_level_code`, `snowflake_column`, `table_path` — screening rules in `tests/catalog_metric_statistical/` | Not stored per metric today; **derive in Snowflake** or document in **`FEATURE_*` YAML `meta`** (see §4). |
| **`CONCEPT_*`** | Slot columns (`*_current`, `*_historical`, `*_forecast`) align to **`concept_metric_slot`** naming; upstream **`METRIC_ID`** / vendor columns in `metric_id_observe` | **High ACF(1)** on **levels** for smooth series (rent, HPI) within `(vendor_code, geo_id)`; **lower** on **YoY / MoM changes** if computed in FEATURE. |
| **`FEATURE_*`** | Add **`meta.statistical`** (optional, §4) + column descriptions for transforms (z-score, diff, log) | **Own** ACF / PACF here or in **ANALYTICS** worksheets — **not** in `CONCEPT_*`. |

**Rule:** [`ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md) — only **measurable** columns become **`MET_*`**; **keys** (`geo_id`, `month_start`, …) are never metrics. Autocorrelation is a **property of a time series column**, not a separate catalog row, unless you register a **derived** **`MDV_*`** for a published “acf_lag1_rent” FEATURE.

---

## 2. Inventory — `CONCEPT_*` → representative `MET_*` / slots → `FEATURE_*` / `MDV_*`

Use this table when writing **`FEATURE_*`** SQL, **`metric_derived_input`**, or **Snowflake QA** (join on `metric_id_observe` or `catalog_metric_code` where present).

| `CONCEPT_*` model | `concept_code` (grain) | Representative **`MET_*`** / notes | Slot columns (pattern) | Typical **unit** | **Polarity** (catalog) | **`FEATURE_*` / `MDV_*`** |
|-------------------|------------------------|-------------------------------------|-------------------------|------------------|-------------------------|----------------------------|
| `concept_rent_market_monthly` | `rent_market` (multi-geo) | **MET_041** Zillow long-form; **MET_044–048** Markerr / Yardi / CoStar; HUD **MET_007/008** long-form | `rent_*` | usd / varies | neutral | `feature_rent_market_monthly_spine` · **MDV_001** |
| `concept_rent_property_monthly` | `rent_property` (property) | ApartmentIQ (catalog intake TBD); stubs only | `rent_*` | usd | neutral | *(no `FEATURE_*` yet)* |
| `concept_listings_market_monthly` | `listings` (CBSA) | **MET_042**, **MET_043**; **MET_050** Realtor | `listings_*` | varies | varies | `feature_listings_velocity_monthly_spine` · **MDV_004** (reads FACT today — see checklist §C) |
| `concept_home_price_market_monthly` | `homeprice` (CBSA) | **MET_055**, **MET_058**, **MET_062** FHFA, etc. | `homeprice_*` | usd / index | neutral | `feature_home_price_delta_zip_monthly` (ZIP **FACT** — exception) |
| `concept_valuation_market_monthly` | `valuation_market` | Cherre + Zillow + FHFA paths (see model) | `valuation_*` | usd | neutral | *(extend FEATURE set)* |
| `concept_transactions_market_monthly` | `transactions` | **MET_056** | `transactions_*` | varies | neutral | *(extend FEATURE set)* |
| `concept_avm_market_monthly` | `avm_market` | Cherre `USA_AVM_GEO_STATS` (intake; dedicated **`MET_*`** TBD) | `avm_*` | usd / index | neutral | *(no `FEATURE_*` yet; **MDV_005** in `metric_derived.csv` is **rent PSF**, not AVM)* |
| `concept_employment_market_monthly` | `employment` | LAUS CBSA observe family | `employment_*` | count | positive | `feature_employment_delta_cbsa_monthly` (**county FACT** roll — exception) |
| `concept_unemployment_market_monthly` | `unemployment` | LAUS rates / counts | `unemployment_*` | pct / count | varies | *(same LAUS stack)* |
| `concept_occupancy_market_monthly` | `occupancy` | HUD **MET_007/008** CBSA | `occupancy_*` | pct | neutral | *(FEATURE tightness stack — **MDV_006** planned)* |
| `concept_migration_market_annual` | `migration` | **MET_009–012** IRS | `migration_*` | varies | neutral | *(annual → use **lag 1 year** ACF, not month)* |
| `concept_delinquency_market_monthly` | `delinquency` | **MET_015–016** FHFA mortgage performance | `delinquency_*` | varies | negative stress | *(FEATURE delinquency momentum TBD)* |

**Regenerate full MET ↔ concept counts:** [`CATALOG_METRICS_BY_CONCEPT_INVENTORY.md`](../migration/CATALOG_METRICS_BY_CONCEPT_INVENTORY.md) (`scripts/ci/print_catalog_metrics_by_concept_inventory.py`).

---

## 3. Autocorrelation for **`ANALYTICS.DBT_DEV`.`FEATURE_*`**

### 3.1 Definitions (monthly panel)

- **Lag-1 ACF proxy (Pearson):** correlation between \(x_t\) and \(x_{t-1}\) within each **stationarity group** `(vendor_code, geo_id)` (or `geo_id` only if single vendor).
- **Levels** (rent, price, listings): expect **ACF(1) ≫ 0** (often **0.85–0.99** for smooth CBSA series).
- **First difference** \(\Delta x_t = x_t - x_{t-1}\): expect **near-white** ACF(1) ≈ **0** (sometimes slightly negative).
- **Log-diff / returns:** similar to first diff; use when strictly positive levels.

### 3.2 Snowflake — exploratory QA (not a dbt test unless you promote it)

Run **after** `CONCEPT_*` / `FEATURE_*` materialize. Example: **rent** slot on **CBSA** + **ZILLOW** only:

```sql
WITH base AS (
    SELECT
        vendor_code,
        geo_id,
        month_start,
        rent_current AS x
    FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
    WHERE vendor_code = 'ZILLOW'
      AND geo_level_code = 'cbsa'
      AND rent_current IS NOT NULL
),
lagged AS (
    SELECT
        vendor_code,
        geo_id,
        month_start,
        x,
        LAG(x) OVER (PARTITION BY vendor_code, geo_id ORDER BY month_start) AS x_lag1
    FROM base
)
SELECT
    vendor_code,
    COUNT(*) AS n_pairs,
    CORR(x, x_lag1) AS acf_lag1_pearson
FROM lagged
WHERE x_lag1 IS NOT NULL
GROUP BY 1
ORDER BY 3 DESC
LIMIT 50;
```

**Runnable copy:** `scripts/sql/validation/acf_lag1_concept_rent_zillow_cbsa.sql` — **slice C** lists ZILLOW row/geo counts by normalized `geo_level_code` (use this to see whether **`place`** / **`county`** exist under those labels); **slice A** = pooled lag-1 Pearson **per grain** among `cbsa`, `county`, `place`, **`zip`**; **slice B** = per-geo ACF distribution **per grain** (≥24 month-pairs per geo). **`zip`** can mean **7k+** geos in **B** — longer wall time than CBSA/county. If a grain is absent from **A**/**B**, it has no qualifying rows. Run: `snowsql -c pretium -f scripts/sql/validation/acf_lag1_concept_rent_zillow_cbsa.sql`.

**Pooled vs per-geo:** Slice **A** pools all months × geos within a grain into one CORR (very high whenever levels co-move — sanity only). Slice **B** is the right object for **“distribution across geos”** decisions (repeat per grain).

**Example run (`snowsql -c pretium`, 2026-04-20, `TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY`):**

| Slice | Metric | Value (example: **cbsa** only, pretium 2026-04-20) |
|-------|--------|--------|
| A | `n_pairs` | 48,689 |
| A | `acf_lag1_pearson` (pooled) | **0.999** |
| B | `n_geos` | 516 |
| B | median ACF(1) per geo | **0.998** |
| B | p25 / p75 | 0.977 / 0.999 |
| B | min / max | 0.547 / 1.000 |

**PCA / FEATURE implication:** median **ACF(1) > 0.9** on **rent_current levels** (empirically **≈ 0.998** on **pretium** above) → expose **first-difference**, **log-difference**, or **within-market z-score** columns in **`FEATURE_*`** (not raw levels) before PCA / clustering ([`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`](../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) §2.1–2.3). Treat **min ≈ 0.55** as a **thin / noisy CBSA** cohort (inspect `geo_id` where ACF(1) < 0.85).

**All implemented market concepts (one shot):** `scripts/sql/validation/acf_lag1_all_transform_dev_concepts.sql` unions every `CONCEPT_*` table under `models/transform/dev/concept/`, runs **C / A / B** on each table’s **`*_current`** column, partitions lags by `(vendor_code, series_id, analysis_grain, geo_id)` with `series_id = COALESCE(metric_id_observe,'*')`, and uses **≥24** month-pairs in slice **B** except **`CONCEPT_MIGRATION_MARKET_ANNUAL`** (**≥5** year-pairs). **`FHFA_UAD`** is **excluded** on **home price** and **valuation** (thousands of narrow mix metrics — not a single level index). Catalog rows without a dbt concept model are out of scope until the object exists.

**Dashboards / recurring QA:** materialized views in **`ANALYTICS.DBT_DEV`** (`models/analytics/qa/`, slug index in [`SEMANTIC_VALIDATION_SLUGS.md`](./SEMANTIC_VALIDATION_SLUGS.md)) complement the ad hoc `acf_lag1_*` scripts.

### 3.3 FEATURE-specific patterns

| `FEATURE_*` | Autocorr note | Suggested prep in FEATURE (not CONCEPT) |
|-------------|---------------|----------------------------------------|
| `feature_rent_market_monthly_spine` | Pass-through of concept → **inherits** level ACF | Expose `rent_yoy`, `rent_mom`, or **within-CBSA z-score** columns here. |
| `feature_listings_velocity_monthly_spine` | DOM / inventory often **highly persistent** | Same: MoM / YoY in FEATURE; optional **seasonal** `MONTH()` FE later in `MODEL_*`. |
| `feature_employment_delta_cbsa_monthly` | Already **YoY / derived** from county roll | Expect **lower** ACF on deltas than on raw employment **levels**. |
| `feature_home_price_delta_zip_monthly` | **Delta** construction | ACF on output series **lower** than on `metric_value` levels. |

---

## 4. Optional — `meta.statistical` on **`FEATURE_*`** models (`schema.yml`)

Document expectations for **CI / humans** (dbt does not enforce `meta` automatically unless you add a custom test).

```yaml
models:
  - name: feature_rent_market_monthly_spine
    config:
      meta:
        statistical:
          source_concept: concept_rent_market_monthly
          primary_metric_codes: ["MET_041"]
          frequency: monthly
          expected_level_acf_lag1_range: [0.85, 0.99]
          ml_prep_recommendation: "First-diff or log-diff within (vendor_code, geo_id) before PCA."
```

---

## 5. Checklist — Alex, before merging a new **`FEATURE_*`**

- [ ] Joined **`MET_*`** row(s) identified in **`metric.csv`** for each published numeric column (or **`MDV_*`** in **`metric_derived.csv`**).
- [ ] **Bounds** — if reusing WL_020 stack, run with `semantic_layer_qa_transform_dev_bound_tests: true` per [`QA_CATALOG_METRICS_STATISTICAL_INVENTORY.md`](../migration/QA_CATALOG_METRICS_STATISTICAL_INVENTORY.md) §3.
- [ ] **ACF spot-check** — §3.2 SQL on **levels** vs **FEATURE output**; document in PR if **PCA** will use **differenced** columns only.
- [ ] **Leakage** — confirm no future `month_start` in joins ([`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`](../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) §2.1 item 8).

---

## 6. Changelog

| Ver | Date | Notes |
|-----|------|--------|
| 0.1 | 2026-04-20 | Initial inventory + ACF SQL + FEATURE `meta` template + checklist. |
| 0.2 | 2026-04-20 | Added `acf_lag1_concept_rent_zillow_cbsa.sql` (slice B); example **pretium** Snowflake run + PCA note. |
| 0.3 | 2026-04-20 | Same script: **slice C** (coverage by grain) + **cbsa / county / place** in slices A–B (`LOWER(TRIM(geo_level_code))`). |
| 0.4 | 2026-04-20 | Added **`zip`** as fourth market grain in slices A–B (high **N** for slice B). |
| 0.5 | 2026-04-20 | Added `acf_lag1_all_transform_dev_concepts.sql` (all implemented `CONCEPT_*` market tables; **`FHFA_UAD`** excluded on price/valuation). |
| 0.6 | 2026-04-20 | Linked **`ANALYTICS.DBT_DEV`** QA views (`SEMANTIC_VALIDATION_SLUGS.md`) as materialized complements to §3 scripts. |
