# Tall concept observation row contract (TRANSFORM.DEV)

**Owner:** Alex  
**Status:** design authority for replacing wide `CONCEPT_*` slot columns with one row per measure.

## Purpose

Wide `CONCEPT_*` tables use `macros/semantic/concept_metric_slot.sql` (`rent_current`, `rent_historical`, …), which **bundle concept + temporality** and collapse vendors into a few columns. Tall stores emit **one row per observation** with an explicit **`metric_code`** FK to **`REFERENCE.CATALOG.METRIC`** and **`dataset_code`** FK to **`REFERENCE.CATALOG.DATASET`**, so SERVING, parity tests, and MF ranker can join to a **single comparable measure**.

## Physical design (lock early)

| Option | When to use | `metric.table_path` |
|--------|-------------|------------------------|
| **Single table** (e.g. `CONCEPT_OBSERVATION_TALL` or `CONCEPT_MEASURE_OBSERVATION`) partitioned by `concept_code` / time | Default for Iceberg retention, uniform QA, one enforcement story | Points at that table; optional `snowflake_column = 'VALUE'` |
| **Per-concept tables** (`CONCEPT_RENT_OBSERVATION_TALL`, …) | Only if partition pruning or ownership boundaries require isolation | One MET row per table or document multi-table spine |

**Recommendation:** one physical tall table under **TRANSFORM.DEV**, **Iceberg**-friendly partitioning on **`concept_code`** + **`date_start`** (or month surrogate), unless IC mandates split tables.

### Narrow warehouse / Iceberg fact (storage + query)

For **very large** observation stores (CBSA × month × metric at 100M+ rows), avoid repeating full catalog dimensionality on every row at rest:

- **Prefer** a physically narrow fact keyed by **`metric_code`** (FK to **`REFERENCE.CATALOG.METRIC`**) plus **`geo_level_code`**, **`geo_id` as TEXT** (leading zeros matter for FIPS), and a **single period anchor** **`date_reference`** (e.g. first-of-month) when the series is point-in-time. Join **`METRIC`** (and through it **`concept_code`**, **`vendor_code`**, **`dataset_code`**, **`frequency_code`**, unit, direction) in SERVING or gold marts instead of denormalizing all of them on each row.
- **`date_start` / `date_end`** pairs in this contract remain valid when the upstream series is **explicitly ranged**; for typical monthly levels, **`date_reference`** alone is clearer and avoids redundant **`frequency_code`** on the row when it is implied by **`METRIC.frequency_code`**.
- Optional **`vendor_code` / `dataset_code`** on the fact row is acceptable as **partition / clustering hints** or audit lineage if IC requires it — not as a substitute for **`metric_code`** semantics.

## Column contract

| Column | Role |
|--------|------|
| `concept_code` | FK → `REFERENCE.CATALOG.CONCEPT` |
| `vendor_code` | FK → `REFERENCE.CATALOG.VENDOR` (display names live on vendor, not on the row) |
| `dataset_code` | FK → `REFERENCE.CATALOG.DATASET` |
| `metric_code` | FK → **`REFERENCE.CATALOG.METRIC.metric_code`** (**unique** in built catalog) |
| `geo_level_code` | FK → `REFERENCE.CATALOG.GEO_LEVEL` |
| `geo_id` | Spine-aligned id (see `docs/rules/ARCHITECTURE_RULES.md` § geography) |
| `date_start` / `date_end` | Observation period for the **value** — document **inclusive** vs **exclusive** in model YAML when first table ships |
| `date_publish` | As-of / release date when distinct from period |
| `frequency_code` | FK → `REFERENCE.CATALOG.FREQUENCY` — **one** code per row |
| `value` | Numeric (or agreed typed) measure |

### Grain uniqueness (default)

Uniqueness is evaluated at least at:

`(concept_code, vendor_code, dataset_code, metric_code, geo_level_code, geo_id, date_start, date_end, frequency_code)`  

If temporality is **not** folded into `metric_code`, add **`temporality_code`** (new dimension) and include it in the key.

### Temporality (pick one rule)

**Rule in this repo until a temporality dimension exists:** encode **current / historical / forecast** (and similar) in **`metric_code`** where wide slots today use `concept_metric_slot('rent', 'current')`, etc. That increases the number of **`METRIC`** rows and tall rows, which is acceptable and simplifies migration off `rent_*` slots.

When a **`temporality`** dimension is introduced, either migrate codes to neutral measure + `temporality_code` or keep suffixed codes as deprecated aliases.

### `metric_code` semantics

**Unique `metric_code` means one comparable measure**, not merely one physical column name per vendor table. Vendor-specific fingerprints may coexist during migration; publish a **`legacy_metric_code` → canonical_metric_code`** map in `docs/migration/CONCEPT_METRIC_WIDE_TO_TALL_MIGRATION_MAP.md` until harmonization completes.

### Versioning when methodology changes

Prefer **new `metric_code`** (suffix `_v2` or explicit semantic name) **plus** retiring the old row (`is_active = FALSE`, clear `definition` / intake log) over silently redefining an active code. SERVING and ACF consumers depend on stable semantics.

### Revision / restatement policy (P0 measures)

Document per vendor dataset in **`dataset.csv`** / model YAML: whether vintages restate in place, append-only series, or revision tables. Tall rows inherit the same **`date_publish`** semantics as the upstream FACT.

## P0 measure definitions (priority — contaminate downstream if wrong)

Illustrative **canonical** `metric_code` targets (harmonize to existing `MET_*` / vendor fingerprints in **`metric_raw.csv`** during migration; do not invent duplicate rows for the same semantics).

### Rent / housing demand (split the umbrella)

| Target `metric_code` (illustrative) | Unit | Geo / frequency | Temporality | Notes |
|-------------------------------------|------|-----------------|-------------|-------|
| `rent_market_effective_median_usd` | USD | cbsa / zip / county; monthly | encode in code or period columns | Markerr-style effective series |
| `rent_market_asking_median_usd` | USD | same | same | Asking / advertised |
| `rent_market_index_level` | index | as vendor defines | same | Only if never mixed with USD in the same column |
| `rent_growth_yoy_pct` | pct | explicit horizon in definition | n/a | State revision handling |
| `rent_concession_weeks_free` | weeks | as observed | n/a | If observed |
| `housing_cost_rent_burden_30_plus_share` | share | county / tract; ACS vintages | annual | **Not** “rent level” — do **not** keep under loose `rent` theme long-term |
| `housing_renter_occupied_units_count` | count | county+ | annual | Same — fix `concept_code` if today tagged `rent` |

### Macro labor (BLS family)

| Target code (illustrative) | Unit | Notes |
|----------------------------|------|-------|
| `unemployment_rate_laus_pct` | pct | County/CBSA; document LAUS vs OMB CBSA join |
| `employment_level_qcew_count` | count | Or CES — **one primary** per geo program |
| `employment_growth_yoy_pct` | pct | Define base period + revision handling |

### Prices / collateral

| Target code (illustrative) | Unit | Notes |
|----------------------------|------|-------|
| `home_price_index_level` | index | FHFA HPI-style |
| `home_price_median_usd` | USD | Deed / comp medians — not an “index” |
| `avm_point_estimate_median_usd` | USD | Cherre MA snapshot — document **as-of** |
| `avm_point_estimate_avg_usd` | USD | Only if mean vs median both required |
| `valuation_zhvi_level` / `valuation_zhvi_forecast_level` | index / level | Zillow paths; separate from HPI if both exist |
| `fhfa_uad_attribute_value` | varies | Never mix with index measures without filter allowlist |

### P1 / P2 (shorthand)

Liquidity (`for_sale_listings_count`, `days_on_market_median`, …), credit/rates (`mortgage_rate_30y_fixed_pmms_pct`, …), and slower annual quality (`migration_net_households`, `population_total_count`, …) follow the same unit / geo / frequency / revision columns once P0 is stable.

## Catalog registry

**`REFERENCE.CATALOG.METRIC`** is the sole metric object; **`metric_code`** is the cross-layer FK. **No `CONCEPT_METRIC` bridge** unless many-to-many or concept-specific aliases are proven necessary (`METRIC.concept_code` + observation grain is default).

## Related

- Build pipeline: [`METRIC_CSV_BUILD_SPEC.md`](./METRIC_CSV_BUILD_SPEC.md)  
- Wide → tall mapping inventory: [`../migration/CONCEPT_METRIC_WIDE_TO_TALL_MIGRATION_MAP.md`](../migration/CONCEPT_METRIC_WIDE_TO_TALL_MIGRATION_MAP.md)  
- dbt materialization plan: [`../migration/DBT_TALL_CONCEPT_OBSERVATION_PLAN.md`](../migration/DBT_TALL_CONCEPT_OBSERVATION_PLAN.md)  
- Architecture + gates: [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md)
