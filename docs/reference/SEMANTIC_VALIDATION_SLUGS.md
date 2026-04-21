# Semantic validation slugs

Canonical tokens for **ANALYTICS.DBT_DEV** QA views (`models/analytics/qa/`), CI job ids, and runbooks. Physical relation names use `QA_*` aliases (Snowflake uppercase).

| # | Slug | Primary view (alias) |
|---|------|-------------------------|
| 1 | `autocorrelation` | `QA_AUTOCORRELATION_RENT_ZILLOW_CBSA_SUMMARY` |
| 2 | `partial_autocorrelation` | `QA_PARTIAL_AUTOCORRELATION_RENT_ZILLOW_CBSA` |
| 3 | `seasonal_decomposition` | `QA_SEASONAL_DECOMPOSITION_RENT_ZILLOW_CBSA` |
| 4 | `structural_break_detection` | `QA_STRUCTURAL_BREAK_DETECTION_RENT_ZILLOW_CBSA` |
| 5 | `cross_series_coherence` | `QA_CROSS_SERIES_COHERENCE` |
| 6 | `geography_referential_integrity` | `QA_GEOGRAPHY_REFERENTIAL_INTEGRITY` |
| 7 | `series_collision_detection` | `QA_SERIES_COLLISION_DETECTION` |
| 8 | `geography_join_audit` | `QA_GEOGRAPHY_JOIN_AUDIT` |
| 9 | `catalog_coverage_matrix` | `QA_CATALOG_COVERAGE_MATRIX` |
| 10 | `metric_observe_lint` | `QA_METRIC_OBSERVE_LINT` |
| 11 | `uad_isolation_validation` | `QA_UAD_ISOLATION_VALIDATION` |
| 12 | `opco_autocorrelation` | `QA_OPCO_AUTOCORRELATION` (disabled unless Progress facts var is true) |
| 13 | `freshness_staleness_report` | `QA_FRESHNESS_STALENESS_REPORT` |
| 14 | `partition_rowcount_regression` | `QA_PARTITION_ROWCOUNT_REGRESSION` |
| 15 | `feature_concept_alignment` | `QA_FEATURE_CONCEPT_ALIGNMENT` |
| 16 | `serving_crosswalk_assertions` | `QA_SERVING_CROSSWALK_ASSERTIONS` |
| 17 | `mortgage_index_autocorrelation` | `QA_MORTGAGE_INDEX_AUTOCORRELATION` (stub) |

**Build (dev target → `ANALYTICS.DBT_DEV`):**

```bash
dbt run -s path:models/analytics/qa
```

- **`qa_opco_autocorrelation`:** requires `transform_dev_enable_source_entity_progress_facts: true` (same as fund_opco concepts).
- **`qa_serving_crosswalk_assertions`:** requires `analytics_qa_serving_crosswalk_enabled: true` after `dbt run -s path:models/serving/demo` so `DEMO_REF_*` relations exist.

Ad hoc SQL equivalents for full-market ACF sweeps remain under `scripts/sql/validation/` (`acf_lag1_*`).

**FEATURE development** (parity, sparsity, schema CI, golden fixtures, window grep): [`FEATURE_DEVELOPMENT_GUARDRAILS.md`](./FEATURE_DEVELOPMENT_GUARDRAILS.md).

**Rent / AVM / valuation** — concept contracts, freshness exclusions, bridge QA: [`CONTRACT_RENT_AVM_VALUATION.md`](./CONTRACT_RENT_AVM_VALUATION.md).

See also: [`CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md`](./CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md) §3.
