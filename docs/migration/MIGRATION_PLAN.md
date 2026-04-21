# Migration Decision: pretium-ai-dbt → pretiumdata-dbt-semantic-layer
# Date: 2026-04-18
# Owner: Alex
# Rule: Only objects that conform to SCHEMA_RULES.md migrate. Everything else stays
# in pretium-ai-dbt (which becomes a read-only archive) or gets dropped from Snowflake.

## DECISION FRAMEWORK
# MIGRATE   → Conforms to rules; moves to new repo under correct path
# REWRITE   → Valuable logic; needs rename/restructure before migrating
# ARCHIVE   → Stays in old repo; valid but not yet ready (Jon/David domain)
# DROP      → Non-canonical, orphaned, superseded, or TRANSFORM.DEV only

## ============================================================
## LAYER 1: REFERENCE.CATALOG (seeds)
## ============================================================
## STATUS: COMPLETE — 67 seed CSVs already in new repo
## No migration needed from old repo

## ============================================================
## LAYER 2: ANALYTICS.DBT_DEV → ANALYTICS.DBT_PROD (Alex owns)
## Source: dbt/models/analytics_prod/
## ============================================================

### MIGRATE — these follow FEATURE_/MODEL_/ESTIMATE_ naming and read from
### TRANSFORM.FACT or TRANSFORM.CONCEPT (canonical sources)

MIGRATE: analytics_prod/features/feature_cbsa_score_monthly.sql
  → models/analytics/feature/feature_market_score_cbsa_monthly.sql
  → RENAME: add geo_level + frequency suffix to comply with naming rule

MIGRATE: analytics_prod/features/feature_cbsa_pillar_scores_monthly.sql
  → models/analytics/feature/feature_market_pillar_cbsa_monthly.sql

MIGRATE: analytics_prod/features/feature_supply_pressure_cbsa.sql
  → models/analytics/feature/feature_supply_pressure_cbsa_monthly.sql

MIGRATE: analytics_prod/features/feature_population_growth_cbsa.sql
  → models/analytics/feature/feature_population_growth_cbsa_annual.sql

MIGRATE: analytics_prod/features/feature_economic_momentum_cbsa.sql
  → models/analytics/feature/feature_employment_delta_cbsa_monthly.sql
  → STATUS (semantic-layer): **v1 shipped** — LAUS county → OMB CBSA roll-up + 12-mo employment YoY; CBSA UR from ∑unemployed/∑LF. **`wage_growth_yoy_pct` null** until QCEW / CONCEPT wage path is ported.

MIGRATE: analytics_prod/features/feature_multifamily_health_cbsa.sql
  → models/analytics/feature/feature_occupancy_index_cbsa_monthly.sql

MIGRATE: analytics_prod/features/feature_crime_by_county.sql
  → models/analytics/feature/feature_crime_index_county_annual.sql

MIGRATE: analytics_prod/features/feature_crime_by_zip.sql
  → models/analytics/feature/feature_crime_index_zip_annual.sql

MIGRATE: analytics_prod/features/feature_school_quality_by_zip.sql
  → models/analytics/feature/feature_school_quality_index_zip_annual.sql

MIGRATE: analytics_prod/features/feature_place_risk_county.sql
  → models/analytics/feature/feature_hazard_risk_county_annual.sql

MIGRATE: analytics_prod/features/feature_demo_migration_county.sql
  → models/analytics/feature/feature_migration_net_county_annual.sql

MIGRATE: analytics_prod/features/feature_price_momentum_zip.sql
  → models/analytics/feature/feature_home_price_delta_zip_monthly.sql

MIGRATE: analytics_prod/features/feature_redfin_metrics.sql
  → models/analytics/feature/feature_home_price_index_zip_monthly.sql

MIGRATE: analytics_prod/features/feature_rent_own_cbsa.sql
  → models/analytics/feature/feature_tenancy_index_cbsa_annual.sql

MIGRATE: analytics_prod/features/feature_ai_replacement_risk_cbsa.sql
  → models/analytics/feature/feature_employment_ai_risk_cbsa_annual.sql

MIGRATE: analytics_prod/features/feature_ai_replacement_risk_county.sql
  → models/analytics/feature/feature_employment_ai_risk_county_annual.sql

MIGRATE: analytics_prod/models/signals/ (composite signal models)
  → models/analytics/model/ (after prefix rename to MODEL_)

MIGRATE: analytics_prod/intel/intel_market_investment_score.sql
  → models/analytics/model/model_market_score_cbsa_monthly.sql

MIGRATE: analytics_prod/intel/intel_corridor_scores_monthly.sql
  → models/analytics/model/model_market_corridor_cbsa_monthly.sql

MIGRATE: analytics_prod/intel/model_market_cycle_phase.sql
  → models/analytics/model/model_market_cycle_cbsa_monthly.sql

MIGRATE: analytics_prod/rent_forecast/fact_rent_forecast_series.sql
  → models/analytics/estimate/estimate_rent_forecast_point_cbsa_monthly.sql

### REWRITE — valuable logic but wrong prefix, non-canonical name, or reads
### from non-canonical source; fix before migrating

REWRITE: analytics_prod/features/feature_strategy_scores_zip.sql
  ISSUE: reads from non-canonical signal tables; remap to TRANSFORM.CONCEPT

REWRITE: analytics_prod/features/feature_strategy_scores_cbsa.sql
  ISSUE: same

REWRITE: analytics_prod/features/feature_offering_market_universe_monthly.sql
  ISSUE: reads from admin.dims which is non-canonical

REWRITE: analytics_prod/signals/composite/ (all composite signals)
  ISSUE: prefix is neither FEATURE_ nor MODEL_; need MODEL_ prefix + canonical name

REWRITE: analytics_prod/features/bkfs/ (BKFS features)
  ISSUE: depends on transform_prod.fact.* — verify canonical source before migrating

REWRITE: analytics_prod/features/mf_rent/ (MF rent features)
  ISSUE: source path unclear; needs discovery query to confirm canonical source

### DROP — sandbox, exploratory, or admin/monitoring only

DROP: analytics_prod/sandbox/ (all)
DROP: analytics_prod/intel/intel_data_quality_diagnostics.sql
DROP: analytics_prod/intel/intel_signal_development_tracking.sql
DROP: analytics_prod/intel/intel_gap_remediation_tracking.sql
DROP: analytics_prod/intel/v_signal_summary_dashboard.sql
DROP: analytics_prod/intel/v_signal_opportunity_dashboard.sql
DROP: analytics_prod/features/v_signal_feature_registry*.sql  (v_ prefix = views; rebuild in BI_)

## ============================================================
## LAYER 3: TRANSFORM_PROD (Jon owns — ARCHIVE, do not migrate)
## Source: dbt/models/transform_prod/
## ============================================================
## These are Jon's domain. They stay in pretium-ai-dbt.
## New repo references them via source() declarations only.
## DO NOT copy cleaned_* or fact_* models to new repo.

ARCHIVE: transform_prod/cleaned/* → Jon owns; source() refs in new repo
ARCHIVE: transform_prod/fact/*    → Jon owns; source() refs in new repo
ARCHIVE: transform_prod/ref/*     → Jon owns; source() refs in new repo

## ============================================================
## LAYER 4: EDW_PROD (mixed ownership — partial migration)
## Source: dbt/models/edw_prod/
## ============================================================

### REWRITE as BI_ objects (Alex owns BI_ prefix in ANALYTICS)
REWRITE: edw_prod/delivery/ → models/analytics/bi/
  Pattern: BI_[business_team]_[concept]_[geo_level]_[frequency]
  Example: v_progress_bi_rent_cbsa_monthly → bi_progress_bi_rent_cbsa_monthly

ARCHIVE: edw_prod/mart/ → Spencer owns SERVING.MART; stays in old repo
ARCHIVE: edw_prod/portfolio/ → David/OpCo domain
ARCHIVE: edw_prod/system/ → admin/monitoring; not analytical

## ============================================================
## LAYER 5: ADMIN.CATALOG seeds (old repo)
## Source: dbt/seeds/catalog/
## ============================================================
## Already superseded by new repo's REFERENCE.CATALOG seeds.
## Old admin.catalog seeds are retired — do not migrate.

DROP (from Snowflake): ADMIN.CATALOG.* → replaced by REFERENCE.CATALOG.*

## ============================================================
## LAYER 6: SOURCES declarations (semantic-layer policy — updated)
## ============================================================
## **Do not** register **`TRANSFORM_PROD`**, **`ANALYTICS_PROD`**, or **`EDW_PROD`** in the dbt graph.
## See **`MIGRATION_RULES.md`** — PROD database ban + `scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh`.

## Canonical pattern today:
## - **`models/sources/sources_transform.yml`** — `source('bls_transform', …)`, `source('transform_bps', …)`, … under **`TRANSFORM.*`** (Jon silver) where Alex owns read-only **FACT_** views in **`TRANSFORM.DEV`**.
## - **`models/sources/sources_source_prod_*.yml`** — **`SOURCE_PROD.[VENDOR]`** landings.
## - **`models/sources/sources_global_government.yml`** / **`sources_reference_geography*.yml`** — **`REFERENCE.GEOGRAPHY`**, Cybersyn **`SOURCE_SNOW`**, etc.
## - Operator-landed **`TRANSFORM.DEV`** bridges (e.g. **`REF_ONET_SOC_TO_NAICS`**, **`OXFORD_CBSA_CROSSWALK`**) — SQL under **`docs/migration/sql/`**, then **`source('transform_dev_*', …)`** only.

## ============================================================
## SNOWFLAKE CLEANUP — objects to DROP after migration
## ============================================================

DROP FROM SNOWFLAKE:
  TRANSFORM_PROD.DEV.*          (non-canonical schema; Alex DEV only)
  ADMIN.CATALOG.*               (replaced by REFERENCE.CATALOG)
  ANALYTICS_PROD.*              (replaced by ANALYTICS.DBT_PROD)
  EDW_PROD.*                    (replaced by ANALYTICS.DBT_PROD.BI_ + SERVING.MART)
  ANALYTICS.DBT_DEV.v_*         (v_ prefix not a valid analytics prefix; rebuild as BI_)

RETAIN IN SNOWFLAKE (Jon/David own):
  TRANSFORM.*                   (all vendor schemas + FACT + CONCEPT + REF)
  REFERENCE.GEOGRAPHY.*
  SOURCE_ENTITY.*
  RAW.*
  SERVING.MART.*
  SERVING.COLLECTION.*

## ============================================================
## MIGRATION ORDER
## ============================================================
# 1. Ensure **`models/sources/*.yml`** covers every Snowflake read (**`SOURCE_PROD`**, **`TRANSFORM.*`** silver,
#    **`REFERENCE.GEOGRAPHY`**, **`SOURCE_SNOW`**, operator-landed **`TRANSFORM.DEV`** — never **`TRANSFORM_PROD`**
#    in dbt graph; see **`MIGRATION_RULES.md`**).
# 2. Ship **`TRANSFORM.DEV` `FACT_*` / `CONCEPT_*`** required by the next FEATURE (see **`MIGRATION_LAYER2_EXECUTION_TRACKER.md`**).
# 3. Migrate **FEATURE_** models (ref only canonical facts + refs above).
# 4. Migrate **MODEL_** (depend on FEATURE_).
# 5. Migrate **ESTIMATE_** (depend on MODEL_).
# 6. Migrate **BI_** views (depend on MODEL_ + FEATURE_).
# 7. `dbt test` + **`scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh`**.
# 8. Promote to staging after QA gate; log batches in **`MIGRATION_LOG.md`** / **`MIGRATION_BATCH_INDEX.md`**.
# 9. Drop or retire legacy Snowflake objects in batches (§ SNOWFLAKE CLEANUP above).
