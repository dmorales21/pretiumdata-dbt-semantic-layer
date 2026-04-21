# SQL validation scripts (`scripts/sql/validation/`)

**Purpose:** Snowflake-runnable checks referenced from [PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../../docs/migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) §E / §H. Each script documents **pass criteria** (expected `failure_rows` or tolerance).

| Script | Pass criteria | Notes |
|--------|----------------|-------|
| [dimensional_reference_catalog_and_geography.sql](./dimensional_reference_catalog_and_geography.sql) | `failure_rows = 0` for each catalog FK-style check; `GEOGRAPHY_INDEX` `unmapped` count is a **backlog signal**, not a hard catalog failure | Run after catalog seed changes |
| [feature_rent_market_spine_vs_concept_reconciliation.sql](./feature_rent_market_spine_vs_concept_reconciliation.sql) | **Tolerance T = 0:** `abs_delta = 0` on row counts; `failure_rows = 0` on key overlap check | **Pilot A** (Q); defaults **`TRANSFORM.DEV`** + **`ANALYTICS.DBT_DEV`**; edit literals if your profile resolves different DB names |
| [describe_concept_progress_catalog_shortlist.sql](./describe_concept_progress_catalog_shortlist.sql) | `DESCRIBE` both concept tables; non-null counts for **MET_029–MET_040** starter aliases | Run after `dbt run` of `concept_progress_*` (semantic-layer). Same path exists under **pretium-ai-dbt** for `snowsql` from that repo. |
| [acf_lag1_concept_rent_zillow_cbsa.sql](./acf_lag1_concept_rent_zillow_cbsa.sql) | **Exploratory:** **C** = ZILLOW non-null rent row/geo counts by normalized `geo_level_code`; **A** = pooled lag-1 Pearson per grain (`cbsa`, `county`, `place`, `zip`); **B** = per-geo ACF summary per grain (≥24 pairs; **zip** is high-**N**) | `snowsql -c pretium -f …`; see [`CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md`](../../docs/reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md) §3 |
| [acf_lag1_all_transform_dev_concepts.sql](./acf_lag1_all_transform_dev_concepts.sql) | Same **C / A / B** across **implemented** `TRANSFORM.DEV.CONCEPT_*` market tables in `models/transform/dev/concept/` (`*_current`; `series_id` = `metric_id_observe`; migration **≥5** pairs in **B**). **`FHFA_UAD` omitted** on home price / valuation (metric explosion) | `snowsql -c pretium -f …`; edit `TRANSFORM.DEV` if needed; run after `dbt run` of concepts |
| [fund4_pricing_api_data_presence.sql](./fund4_pricing_api_data_presence.sql) | **Data smoke:** rowcounts for Cherre county AVM / geo AVM / Markerr rent facts (+ optional EDW IHPM & disposition yield blocks) | `snowsql -c pretium -f …`; see [`FUND4_COMPS_PRICING_DATA_UNDERPINNING.md`](../../docs/migration/FUND4_COMPS_PRICING_DATA_UNDERPINNING.md) |

**Materialized QA (ANALYTICS.DBT_DEV):** slug-indexed views under `models/analytics/qa/` — run `dbt run -s path:models/analytics/qa` after concepts + seeds; see [`SEMANTIC_VALIDATION_SLUGS.md`](../../docs/reference/SEMANTIC_VALIDATION_SLUGS.md). **FEATURE guardrails:** [`FEATURE_DEVELOPMENT_GUARDRAILS.md`](../../docs/reference/FEATURE_DEVELOPMENT_GUARDRAILS.md); window grep: [`scripts/ci/check_feature_window_leakage.sh`](../../scripts/ci/check_feature_window_leakage.sh).

**Adding a script:** append a row here + a subsection in the playbook with tolerance **T** and owner.

**Repo gates:** PR workflow **`.github/workflows/semantic_layer_catalog_and_quality.yml`** (parse + catalog `dbt ls`). After catalog edits, also run **`scripts/ci/run_catalog_quality_checks.sh`** locally with **`RUN_SNOWFLAKE_CHECKS=1`** when credentials are available.
