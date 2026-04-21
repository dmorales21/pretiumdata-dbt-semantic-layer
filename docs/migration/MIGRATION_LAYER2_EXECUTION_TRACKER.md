# Layer 2 (ANALYTICS) — execution tracker vs `MIGRATION_PLAN.md`

**Purpose:** Prioritize **`MIGRATE:`** rows from [`MIGRATION_PLAN.md`](./MIGRATION_PLAN.md) by **upstream readiness** in this repo (no **`TRANSFORM_PROD` / `ANALYTICS_PROD` / `EDW_PROD`** in dbt — [`MIGRATION_RULES.md`](./MIGRATION_RULES.md)).

## Priority tiers

| Tier | Rule | Examples |
|------|------|----------|
| **P0 — Done** | Shipped under `models/analytics/` + labor / rent stack docs | `feature_ai_replacement_risk_*`, `feature_structural_unemployment_risk_county`, `feature_ai_risk_county_bivariate`, `model_county_ai_risk_dual_index`, `feature_rent_market_monthly_spine`, `feature_home_price_delta_zip_monthly`, `feature_supply_pressure_cbsa_monthly` |
| **P1 — FACT in repo** | FEATURE can be built from **`ref('fact_*')`** + **`REFERENCE.GEOGRAPHY`** / **`SOURCE_PROD`** only | **`feature_employment_delta_cbsa_monthly`** ← `fact_bls_laus_county` + county→CBSA xwalk (**shipped**); next candidates need **`fact_realtor_*`**, **`fact_pep_*`**, **`fact_crime_*`**, QCEW CBSA household labor, etc. |
| **P2 — Dim / seed deps** | Needs **`dim_strategy_asset_type_weights`** or other catalog dims not yet in semantic layer | `feature_market_score_cbsa_monthly`, `feature_market_pillar_cbsa_monthly` |
| **P3 — REWRITE first** | Plan marks **`REWRITE:`** before migrate | strategy scores, offering universe, BKFS, mf_rent cluster |
| **P4 — ARCHIVE / partner** | Jon **`TRANSFORM.[VENDOR]`** only, or Spencer **`SERVING`**, or explicit **DROP** | `edw_prod/mart/*`, `analytics_prod/sandbox/*` |

## `MIGRATE:` FEATURE rows (snapshot)

| Legacy (pretium-ai-dbt) | Target (semantic layer) | Status |
|-------------------------|---------------------------|--------|
| `feature_economic_momentum_cbsa.sql` | `feature_employment_delta_cbsa_monthly.sql` | **v1 shipped** (LAUS-only; wages TODO) |
| `feature_supply_pressure_cbsa.sql` | `feature_supply_pressure_cbsa_monthly.sql` | **v1 shipped** — **`ref('fact_realtor_inventory_cbsa')`** (SOURCE_PROD.REALTOR landings) |
| `feature_population_growth_cbsa.sql` | `feature_population_growth_cbsa_annual.sql` | **Blocked** — `fact_pep_population`, `cbsa_xref` |
| `feature_cbsa_pillar_scores_monthly.sql` | `feature_market_pillar_cbsa_monthly.sql` | **Blocked** — upstream pillar facts + dims |
| `feature_cbsa_score_monthly.sql` | `feature_market_score_cbsa_monthly.sql` | **Blocked** — pillar + weights |
| `feature_crime_by_county.sql` | `feature_crime_index_county_annual.sql` | **Blocked** — `fact_crime_index_all_ts` |
| `feature_crime_by_zip.sql` | `feature_crime_index_zip_annual.sql` | **Blocked** — crime fact at ZIP |
| `feature_school_quality_by_zip.sql` | `feature_school_quality_index_zip_annual.sql` | **Blocked** — school vendor fact |
| `feature_place_risk_county.sql` | `feature_hazard_risk_county_annual.sql` | **Blocked** — First Street / hazard facts |
| `feature_demo_migration_county.sql` | `feature_migration_net_county_annual.sql` | **Blocked** — `fact_household_migration_county_all_ts` |
| `feature_price_momentum_zip.sql` | `feature_home_price_delta_zip_monthly.sql` | **v1 shipped** — **`FACT_ZILLOW_HOME_VALUES`** ZIP; var ``feature_home_price_delta_metric_id_pattern`` |
| `feature_redfin_metrics.sql` | `feature_home_price_index_zip_monthly.sql` | **Candidate** — Redfin path TBD |
| `feature_rent_own_cbsa.sql` | `feature_tenancy_index_cbsa_annual.sql` | **Blocked** — tenancy inputs |
| `feature_ai_replacement_risk_cbsa.sql` | `feature_employment_ai_risk_cbsa_annual.sql` | **Policy** — keep canonical name **`feature_ai_replacement_risk_cbsa`** until rename wave; already migrated with synthetic NAICS |
| `feature_ai_replacement_risk_county.sql` | `feature_employment_ai_risk_county_annual.sql` | **Policy** — same; canonical **`feature_ai_replacement_risk_county`** exists |

## Next three executions (recommended order)

1. **Population growth** — `fact_pep_*` + CBSA xwalk for `feature_population_growth_cbsa_annual.sql`.
2. **Pillar / score stack** — after `dim_strategy_asset_type_weights` (or equivalent) exists in **`REFERENCE.CATALOG`** / dbt models.
3. **Crime index** — `fact_crime_index_all_ts` (or Cybersyn FBI county) for `feature_crime_index_county_annual.sql`.

**Done here:** **`fact_realtor_inventory_cbsa`** + **`feature_supply_pressure_cbsa_monthly`** read **SOURCE_PROD.REALTOR.REALTOR_INVENTORY_MSA** (same contract as legacy ``fact_realtor_inventory_cbsa``). Optional follow-up: Jon **`TRANSFORM.FACT`** read-through if org standardizes on silver-only reads.

Update this table whenever a row moves from **Blocked** → **Shipped**.
