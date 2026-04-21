# SERVING.DEMO — first metrics / features vs **`REFERENCE.CATALOG`** (this repo)

**Purpose:** Map the **population list** (raw `metric_id` slugs, engineered `engineered_metric_id` names, `corridor_model` columns, estimate) to what **exists today** in `seeds/reference/catalog/` (`concept.csv`, `metric.csv`, `metric_derived.csv`). Long definitions stay in product docs; this file is a **registry alignment** for `pretiumdata-dbt-semantic-layer`.

**Not in this repo:** `guide_offerings_market.md`, `guide_snowflake_architecture.md`, `guide_ducklake.md` (those live in **pretium-ai-dbt** or elsewhere). Use **`docs/reference/PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md`**, **`DUCKLAKE_CATALOG_INVENTORY_PRIORITY.md`**, and **`CATALOG_METRIC_DERIVED_LAYOUT.md`** here.

**Concept codes:** This repo’s `concept.csv` uses codes like **`rent`**, **`income`**, **`absorption`** — not every **synthetic bundle** name from the population list (e.g. `labor_growth_access`). The **“closest concept”** column maps bundles to existing **`concept_code`** rows or **`—`** if you must add a `concept.csv` row first (per `SCHEMA_RULES` §1).

**Bundle names with no `concept_code` row today:** `labor_growth_access`, `household_demographics_demand`, `transactions_sale_volume`, `affordability_ceiling`, `location_amenity_access`, `national_macro` (treat as **playbook groupings**; register a `concept` only if you promote them as first-class governed concepts). Granular codes such as **`rent`**, **`employment`**, **`migration`**, **`home_price`**, **`transactions`** (**CON_028** — property sale counts/volumes) already exist.

**Related:** dev **`SERVING.DEMO`** object targets and Iceberg gaps — [`SERVING_DEMO_ICEBERG_TARGETS.md`](./SERVING_DEMO_ICEBERG_TARGETS.md). Wishlist / build order for new metrics — [`CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md`](./CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md).

**Execution plan (T0–T4 gaps):** [`SERVING_METRICS_GAP_MIGRATION_PLAN.md`](../migration/SERVING_METRICS_GAP_MIGRATION_PLAN.md).

---

## Quick reference — strong `metric.csv` matches (by area)

| Area (intent) | Example population slugs | `metric_code` (examples) |
|---------------|---------------------------|---------------------------|
| Rent (partial) | levels from vendor panels | **`MET_041`** `zillow_rentals_metric_value` (long-form `METRIC_VALUE`; medians are aggregates / filters); **`MET_044`–`MET_045`** Markerr MF CBSA; **`MET_046`** Yardi Matrix `DATAVALUE`; **`MET_047`–`MET_048`** CoStar SCENARIOS rent per unit |
| Labor / jobs | `unemployment_rate`, `job_growth` | **`MET_002`**, **`MET_003`–`MET_005`**, **`MET_006`** (CBSA observe), **`MET_021`–`MET_023`** (QCEW), **`MET_028`** (county × SOC employment) |
| Workforce / AI exposure (SOC / task) | automation / exposure stacks | **`MET_024`–`MET_027`** (Epoch crosswalk, O*NET GWA / friction / adjusted exposure on **`workforce_task_automation`**) |
| Migration / HH demand (partial) | `migration_net` | **`MET_009`–`MET_010`**, **`MET_014`–`MET_015`** |
| Absorption / listings velocity (partial) | `days_on_market_listings` | **`MET_042`** `zillow_days_on_market_and_price_cuts_metric_value` |
| Listings / volume proxy | transaction-adjacent demand | **`MET_043`** `zillow_for_sale_listings_metric_value` (`home_price` concept in seed — verify product fit vs “sale volume”) |
| Construction | `permit_volume` | **`MET_001`** `bps_permits_measure_value` |
| Transactions / sale counts (CBSA monthly) | `transaction_volume` (vendor observe) | **`MET_127`–`MET_129`** on **`TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY`** (Cherre SFR/MF + RCA MF); **`MET_130`** Zonda deeds **`under_review`** until FACT rows > 0 |
| Supply pipeline (CBSA monthly) | listings / UC | **`MET_131`** Markerr listings + **`MET_132`** RCA MF units under construction on **`TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY`** |
| Value / HPI / UAD | AVM / price stack | **`MET_011`**, **`MET_016`**, **`MET_019`–`MET_020`** |
| National rates | `rate_index_level` | **`MET_012`** `freddie_mac_housing_timeseries_value` (`cap_rate` concept in seed — verify product fit vs “national macro” / rates) |
| Delinquency / stress (partial) | `ltv_stress_proxy` adjacencies | **`MET_017`–`MET_018`** |
| HUD occupancy / vacancy (partial) | `vacancy_rate`, `occupancy_rate` | **`MET_008`**, **`MET_013`** (long-form; pick `VARIABLE` / grain) |
| Progress / fund spine (property) | cap rate, yield, identifiers | **`MET_029`–`MET_040`** (property / acquisition underwriting grain — not CBSA market panels) |

**Gaps / composites (not single `metric.csv` rows):** growth / CAGR / RTI / PSF / pipeline / UC / most engineered §12 scores → new **`metric`** rows and/or **`metric_derived`** (+ **`metric_derived_input`** where N:1). **`metric_derived`** today is **MDV_001–MDV_004** (see §12). **§13** `corridor_model` columns and **§12** engineered IDs → **not** in catalog seeds until registered (**WL_021** / feature playbook).

---

## Tests (catalog seeds)

```bash
cd pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
dbt parse
# Snowflake — use a profile target that points at REFERENCE.CATALOG (e.g. dev `reference` or org standard):
dbt seed  --select path:seeds/reference/catalog --target <reference_or_dev>
dbt test --select path:seeds/reference/catalog --target <reference_or_dev>
```

CI profile in `ci/profiles.yml` exposes **`parse`** and **`ci`** only; full catalog **`dbt test`** needs env-backed Snowflake (`SNOWFLAKE_*`) or `~/.dbt/profiles.yml`. See **`scripts/ci/run_catalog_quality_checks.sh`** (`RUN_SNOWFLAKE_CHECKS=1`).

---

## §0 Reference spine

| Artifact | In `REFERENCE.CATALOG`? | Notes |
|----------|-------------------------|--------|
| Geography bridge (CBSA ↔ H3) | Partial | **`REFERENCE.GEOGRAPHY`** dbt models + seeds; no single **`metric`** row. **`registry/lineage/corridor_lodes_h3_r8_lineage.yml`** documents LODES corridor lineage — not **`registry/features/corridor_model.yaml`** (**WL_021**). |
| `metric_id` dictionary | **Yes** | **`metric.csv`** (`metric_id`, `metric_code`, …). |
| `geo_level` enum | **Yes** | **`geo_level.csv`** — codes include `national`, `cbsa`, `county`, …; verify **`corridor_h3`** / **`place`** vs your **`GAME_RULES`** naming before SERVING.DEMO. |

---

## §1 `rent` — raw slugs → catalog

| Population `metric_id` | `metric_code` / `metric_id` (if registered) | `concept_code` | Status |
|--------------------------|-----------------------------------------------|------------------|--------|
| `rent_level_median` | **`MET_041`** `zillow_rentals_metric_value` (long-form `METRIC_VALUE`; median is aggregation) | `rent` | **Partial** — vendor long-form; other vendors live in **`concept_rent_market_monthly`**, not separate `metric` rows per statistic. |
| `rent_psf_median` | — | `rent` | **Not registered** — add `metric` + `table_path` when a FACT exposes PSF. |
| `rent_growth_yoy` / `rent_cagr_3y` / `rent_cagr_5y` | — | `rent` | **Derived** — use **`metric_derived`** + upstream metrics, or document as concept-level calc from `concept_rent_market_monthly`. |
| `effective_rent_index` | — | `rent` | **Not registered** as its own `metric_code` (may map to Zillow / Matrix HUD rows inside concept). |
| `concession_weeks_free` | — | `concession` | **Not registered** — `CON_020` exists; no dedicated MET_* for “weeks free” yet. |
| `rent_to_income_ratio` | — | `rent` / `income` | **Composite** — **`metric_derived`** / playbook; not a raw `metric.csv` row. |

---

## §2 `labor_growth_access` (bundle → existing concepts)

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `median_hh_income` | No ACS income **MET_** in `metric.csv` today; **`CON_014`** `income` exists. | **Gap** — add Cybersyn/ACS metric rows when FACT lands. |
| `income_growth_yoy` | — | **Derived / gap** |
| `unemployment_rate` | **`MET_002`** `bls_laus_unemployment_rate_county` (+ CBSA observe **`MET_006`**) | **Registered** (`unemployment`) |
| `job_growth` | **`MET_004`–`MET_005`**, **`MET_021`** (employment / LF / QCEW) | **Registered** (`employment`) |
| `employment_density` | — | **Derived / gap** |
| County AI replacement / SOC employment (automation risk stack) | **`MET_028`** QCEW-allocated county × SOC employment; **`MET_024`–`MET_027`** O*NET / Epoch exposure joins | **Registered** (`employment` / **`workforce_task_automation`**) — see also **`fact_county_ai_automation_risk`** / dual-index model in dbt |

---

## §3 `household_demographics_demand`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `median_hh_income` | See §2 | **Gap** |
| `renter_share` / `population_growth` / `hh_growth` | **`CON_008`** `population` exists; no **MET_*** split for renter share / HH growth in `metric.csv` | **Gap** |
| `migration_net` | **`MET_009`–`MET_010`**, **`MET_014`–`MET_015`** | **Registered** (`migration`) |
| `age_cohort_dependency` / `affordability_ratio` / `workforce_renter_share` | — | **Not registered** |

---

## §4 `absorption_tightness`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `vacancy_rate` | HUD long-form **`MET_008`/`MET_013`** (`occupancy` concept) — pick VARIABLE rows for vacancy | **Partial** |
| `absorption_pace` / `net_absorption` / `pipeline_burndown_ratio` / `inventory_months_supply` | — | **Not registered** — **`CON_010`** `absorption`, **`CON_011`** `supply_pipeline`; need **MET_*** or **`metric_derived`** when FACTs exist. |
| `uc_units` (MF construction tape) | **`MET_132`** `concept_supply_pipeline_rca_mf_uc_units_cbsa_monthly` on **`TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY`** | **Registered (vendor-specific)** — RCA MF UC only; other UC / pipeline slugs still **gap**. |
| DOM / listings velocity (related) | **`MET_042`** `zillow_days_on_market_and_price_cuts_metric_value` | **Registered** (`absorption`) |

---

## §5 `construction_feasibility`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `uc_units` | **`MET_132`** (RCA MF UC on **`CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY`**) | **Partial — registered** for RCA MF UC; broader UC / stock ratios still **gap** |
| `permit_volume` | **`MET_001`** `bps_permits_measure_value` | **Registered** (`permits`) |
| `permit_to_stock_ratio` / `regulatory_supply_index` / `construction_cost_index` | — | **Not registered** |

---

## §6 `transactions_sale_volume`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `transaction_volume` | **`MET_127`–`MET_129`** on **`TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY`** (`transactions` / **CON_028**); **`MET_130`** Zonda **`under_review`** (warehouse rollup **0** rows as of 2026-04-21) | **Registered** (Cherre SFR/MF + RCA MF observe); **Deferred** Zonda path until FACT populated |
| `days_on_market_listings` | **`MET_042`** (DOM) | **Registered** |
| `for_sale_listings_level` (proxy) | **`MET_043`** `zillow_for_sale_listings_metric_value` | **Registered** (`home_price` in seed — relabel or add sibling **`metric`** if product insists on absorption/supply concept) |

---

## §7 `value_avm`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `price_avm_level_change` / `avm_index_level` / `price_psf_median` | **`MET_011`**, **`MET_016`**, FHFA UAD **`MET_019`–`MET_020`**; AVM market concept mart | **Partial** — HPI / UAD registered; “AVM” naming may need extra **`metric`** rows for Cherre AVM stats. |
| `cap_rate_going_in` / spreads / `rent_to_value_ratio` | **`MET_012`** Freddie; **`MET_030`**–**`MET_031`** Progress spine (property grain) | **Partial** — mix of `cap_rate` / `fund_property_spine` |
| `hpa_trailing` / `hpa_cumulative` / `ltv_stress_proxy` | Derived / **`MET_017`–`MET_018`** delinquency | **Partial / derived** |

---

## §8 `occupancy_operations`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `occupancy_rate` | HUD **`MET_008`/`MET_013`** | **Partial** |
| `effective_rent_index` / `concession_weeks_free` | See §1 / §8 | **Gap** |
| `opex_escalation_proxy` | — | **Not registered** |

---

## §9 `affordability_ceiling`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `rent_to_income_ratio` / `affordability_ratio` / `workforce_renter_share` | Composite; **`CON_014`** + **`CON_001`** | **metric_derived** / new MET_* when RTI FACT ships (**WL_045**). |

---

## §10 `location_amenity_access`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `location_amenity_index` | — | **Not registered** — crime/school concepts **`CON_012`**, **`CON_013`** exist without a single “amenity index” MET_*. |

---

## §11 `national_macro`

| Population `metric_id` | Catalog mapping | Status |
|--------------------------|-----------------|--------|
| `rate_index_level` | **`MET_012`** `freddie_mac_housing_timeseries_value` (`national`, weekly) | **Registered** (`cap_rate` concept in seed — verify product mapping to “rates”) |

---

## §12 FEATURE — `engineered_metric_id`

| Engineered name | In `metric_derived.csv`? | Notes |
|-----------------|---------------------------|--------|
| `tightness_score`, `absorption_score`, `growth_score`, … (all §12) | **No** | Register as **`metric_derived`** (+ optional **`metric_derived_input`**, **WL_040**) when FEATURE models ship. |

**Registered today (`metric_derived.csv` + `metric_derived_input.csv`):**

| ID | Code | Role |
|----|------|------|
| **MDV_001** | `rent_market_monthly_spine` | **`FEATURE_RENT_MARKET_MONTHLY`** read surface from **`concept_rent_market_monthly`** (see model `feature_rent_market_monthly_spine.sql`). |
| **MDV_002** | `rent_value_score_cbsa_example` | Placeholder **MODEL_** composite (`under_review`). |
| **MDV_003** | `effective_rent_interval_lower_example` | Placeholder **ESTIMATE_** interval row. |
| **MDV_004** | `listings_velocity_monthly_spine` | **`FEATURE_LISTINGS_VELOCITY_MONTHLY`** union of **`fact_zillow_days_on_market_and_price_cuts`** + **`fact_zillow_for_sale_listings`** (`feature_listings_velocity_monthly_spine.sql`); aligns **MET_042** / **MET_043**. |

Layout and column contract: [`CATALOG_METRIC_DERIVED_LAYOUT.md`](./CATALOG_METRIC_DERIVED_LAYOUT.md).

---

## §13 `corridor_model` / v1 columns

| Column | In `metric.csv` / seeds? | Notes |
|--------|---------------------------|--------|
| `renter_share`, `median_hhi_wavg`, `job_inflow_log`, SFR / occupancy / sales / AVM columns | **No** | **`registry/features/corridor_model.yaml`** not in repo (**WL_021**). LODES / county inputs partially covered by **`MET_007`**, **`MET_021`**, LAUS metrics. |

---

## §14 ESTIMATE — `arbitrage_score`

| Object | In catalog? | Notes |
|--------|---------------|--------|
| `arbitrage_score_v1_h3_r8_snapshot` | **No** | **`registry/models/arbitrage_score.yaml`** + **`metric_derived`** row (**WL_022**) when corridor + inputs exist. |

---

## Summary counts (approximate)

| Category | Count |
|----------|------:|
| Population raw slugs listed (§1–11) | ~55 |
| Clear **`metric.csv`** match or strong proxy | ~26 (adds **MET_127**–**MET_132** transactions + supply-pipeline observe family; includes **MET_024–MET_028**, **MET_043**, Progress **MET_029–040** where relevant to §7) |
| Composite / concept-only / must add **`metric`** or **`metric_derived`** | remainder |

*Re-count when new **MET_*** rows ship (e.g. ACS income, Cherre transactions, corridor composites).*

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial map vs `concept.csv` / `metric.csv` / `metric_derived.csv` in **pretiumdata-dbt-semantic-layer**. |
| **0.2** | Quick-reference table by area; **MET_024–MET_028** + **MET_043** in §2/§6; bundle names without `concept` rows; **MDV_001–003** table; cross-links (`SERVING_DEMO_ICEBERG_TARGETS`, wishlist); fixed §3 markdown row; summary count bump. |
| **0.3** | **MDV_004** + **`metric_derived_input`** (WL_040); **bridge_product_type_metric** rows **64–108** for **MET_044–MET_048**; listings velocity FEATURE spine. |
| **0.4** | Linked **[SERVING_METRICS_GAP_MIGRATION_PLAN.md](../migration/SERVING_METRICS_GAP_MIGRATION_PLAN.md)** — T0–T4 work packages, milestones M0–M4, geography → catalog → delivery sequencing. |
| **0.5** | **M1 (partial) / M2:** §4 `uc_units` **RCA MF** path via **MET_132**; §5–§6 **`transaction_volume`** via **MET_127**–**MET_129** + Zonda **MET_130** deferred; quick-ref table + **CON_028** `transactions` note. Validated rollups 2026-04-21 (`snowsql -c pretium`, `vet_concept_cherre_rca_zonda_rollups_pretium.sql`). |
