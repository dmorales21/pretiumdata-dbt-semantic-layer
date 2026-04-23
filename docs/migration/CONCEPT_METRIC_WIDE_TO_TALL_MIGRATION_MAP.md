# Wide `CONCEPT_*` slots → tall `metric_code` migration map

**Owner:** Alex  
**Purpose:** Inventory how **`concept_metric_slot`** wide columns and vendor-specific FACT columns map to **canonical `metric_code` values** for **`CONCEPT_OBSERVATION_TALL`** (see [`../reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md`](../reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md)).

## P0 — Rent (`concept_rent_market_monthly`)

Wide columns today (macro): `{{ concept_metric_slot('rent', 'current') }}` → `rent_current`, `rent_historical`, `rent_forecast`.

| Wide slot | Intended semantics (target) | Notes / existing FACT pattern |
|-----------|----------------------------|--------------------------------|
| `rent_current` | **Effective** vs **asking** must split — use distinct `metric_code` per vendor series, harmonize over time to `rent_market_effective_median_usd` / `rent_market_asking_median_usd` | Markerr already exposes separate FACT metrics (e.g. `…median_rent_effective` vs `…median_rent_asking`); Zillow / CoStar / Matrix need explicit mapping rows |
| `rent_historical` | Same split + **temporality** in code or column | Union precedence today is not a join key — replace with tall vendor branches |
| `rent_forecast` | Forecast scenario filter (CoStar) → dedicated **`metric_code`** per scenario family | Align `metric.table_path` + filters in MET definition |

**Category hygiene:** ACS / demographics fields (rent burden, renter share, renter-occupied counts) tagged `concept_code=rent` in **`metric_raw`** should move to **`housing_cost_*`** / **`housing_*`** style concepts and codes (see contract § P0 rent).

## P0 — Unemployment / employment

Map from `concept_unemployment_*` / `concept_employment_*` (and employment FACT registrations) to illustrative canonicals:

| Theme | Target `metric_code` (illustrative) | Existing inventory |
|-------|-------------------------------------|--------------------|
| LAUS unemployment rate | `unemployment_rate_laus_pct` | Align to BLS LAUS FACT + `MET_*` in raw |
| QCEW / CES levels | `employment_level_qcew_count` (or chosen primary) | One primary program per geo |
| YoY growth | `employment_growth_yoy_pct` | Document base + revisions in MET `definition` |

## P0 — Home price / AVM / valuation

Map `concept_home_price_*`, `concept_avm_*`, `concept_valuation_*` wide slots to:

| Target | Semantics |
|--------|-----------|
| `home_price_index_level` | HPI-style index (FHFA / vendor index) |
| `home_price_median_usd` | Transaction / comp medians — never labeled as index |
| `avm_point_estimate_median_usd` | Cherre MA and similar — **as-of** in definition |
| `valuation_zhvi_level` / `valuation_zhvi_forecast_level` | Zillow ZHVI / forecast panels |

**UAD and appraisals:** keep `fhfa_uad_attribute_value` (or vendor equivalent) **separate** from index measures; enforce allowlist filters in dbt, not mixed `METRIC_VALUE` without `metric_id` / `metric_code`.

## P1 — Liquidity / clearing

`for_sale_listings_count`, `days_on_market_median`, `transactions_sale_count`, `transactions_sale_volume_usd`, `absorption_net_units`, `supply_pipeline_units_uc` — map from corridor FACT + FEATURE panels only when those panels emit the **same tall row shape** (otherwise keep as **`metric_derived`** / FEATURE-only per architecture rules).

## P1 — Credit / rates

`mortgage_rate_30y_fixed_pmms_pct`, `treasury_10y_yield_pct`, `delinquency_rate_90_plus_pct` — align to rates / delinquency concepts and existing `MET_*` rows in raw.

## P2 — Slower annual quality

Migration, population, income, crime, schools — follow P0 column contract once spine measures are stable.

## Next step for 1:1 legacy mapping

To tighten to **exact** strings matching current `metric_code` / `MET_*` for `concept_code=rent`, sample **`metric_raw.csv`** (filter `rent`) and add a machine-readable mapping table (dbt seed or YAML in `models/transform/dev/concept/`) when ready.

## Related

- dbt build plan: [`DBT_TALL_CONCEPT_OBSERVATION_PLAN.md`](./DBT_TALL_CONCEPT_OBSERVATION_PLAN.md)  
- Enforcement SQL: [`../../scripts/sql/validation/catalog_tall_metric_code_coverage.sql`](../../scripts/sql/validation/catalog_tall_metric_code_coverage.sql)
