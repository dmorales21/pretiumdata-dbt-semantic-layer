# FEATURE development guardrails

Companion to [`SEMANTIC_VALIDATION_SLUGS.md`](./SEMANTIC_VALIDATION_SLUGS.md) (market `CONCEPT_*` QA views). This page tracks **feature-specific** slugs: materialized **ANALYTICS.DBT_DEV** views under `models/analytics/qa/`, **singular tests** under `tests/qa/`, and **CI scripts** under `scripts/ci/`.

**Rent / AVM / valuation concept contracts** (grain, `month_start` semantics, Cherre overlap, FEATURE vs CONSUME routing, `equal_rowcount` drift policy): [`CONTRACT_RENT_AVM_VALUATION.md`](./CONTRACT_RENT_AVM_VALUATION.md).

**Thin spine parity backlog** (P0–P2 concept → `FEATURE_*`, SERVING / Iceberg first, v1 top-5): [`FEATURE_SPINE_PARITY_BACKLOG.md`](./FEATURE_SPINE_PARITY_BACKLOG.md).

## Implemented (repo)

| # | Slug | Artifact | Purpose |
|---|------|----------|---------|
| 1 | `feature_lineage_graph` | [`FEATURE_LINEAGE_GRAPH.md`](./FEATURE_LINEAGE_GRAPH.md) | Manual lineage table; manifest diff backlog. |
| 2 | `transform_contract_linter` | *Doc-only here* | Allowed transforms: prefer dbt macros / documented `pct_change`, `lag`, `rolling`; forbid ad-hoc `UNBOUNDED FOLLOWING` (see #3). Extend with SQLFluff / custom parser when ready. |
| 3 | `window_leakage_audit` | `scripts/ci/check_feature_window_leakage.sh` | Grep gate on risky `ROWS`/`RANGE` … `FOLLOWING` in `models/analytics/feature/*.sql`. |
| 4 | `as_of_snapshot_enforcement` | `QA_AS_OF_SNAPSHOT_ENFORCEMENT` + `dbt_utils.expression_is_true` on `feature_rent_market_monthly_spine.month_start` | No `month_start` in the future; immutability under late facts still needs versioned FACT + audit. |
| 5 | `train_label_horizon_spec` | `meta.train_label_horizon` on `feature_rent_market_monthly_spine` in `_feature_rent_market.yml` | Frozen horizon / embargo / label column contract (extend per model). |
| 6 | `null_and_sparse_profile` | `QA_NULL_AND_SPARSE_PROFILE_FEATURE_RENT` | Null rate, zero-variance, `<24m` cold-start flags on rent FEATURE spine. |
| 7 | `distribution_shift_monitor` | `QA_DISTRIBUTION_SHIFT_MONITOR_RENT` | MoM median/mean relative shift by vendor × grain (PSI/KS backlog). |
| 8 | `cross_feature_collinearity` | `QA_CROSS_FEATURE_COLLINEARITY_RENT` | Within-geo `rent_current` vs `rent_historical` correlation distribution. |
| 9 | `outlier_treatment_registry` | `meta.outlier_treatment` on rent FEATURE (see `_feature_rent_market.yml`) | Document winsor / log policy; wire tests when transforms land. |
| 10 | `segment_stability` | *Backlog* | Needs explicit `SFR`/`MF` / urban segment columns in FEATURE outputs. |
| 11 | `geo_rollup_sensitivity` | `QA_GEO_ROLLUP_SENSITIVITY_RENT_ZILLOW` | ZIP vs CBSA rent alignment when `cbsa_id` present on ZIP rows. |
| 12 | `vendor_blend_ablation` | `QA_VENDOR_BLEND_ABLATION_RENT` | Per-key vendor means for leave-one-out workflows. |
| 13 | `feature_concept_parity_diff` | `QA_FEATURE_CONCEPT_PARITY_DIFF` | MAE / MAPE% by month × vendor × grain vs concept. |
| 14 | `cold_start_geo_report` | `QA_COLD_START_GEO_REPORT` | Months of history since first ZILLOW non-null rent. |
| 15 | `schema_evolution_guard` | `tests/qa/assert_feature_rent_output_schema_contract.sql` | Column contract vs `INFORMATION_SCHEMA` for `FEATURE_RENT_MARKET_MONTHLY`. |
| 16 | `synthetic_fixture_replay` | `seeds/analytics/qa/synthetic_golden_feature_rent_keys.csv` + `tests/qa/assert_synthetic_golden_feature_rent_keys_match.sql` | Golden keys (`use_in_test=true`) vs FEATURE spine. |
| 17 | `serving_latency_budget` | *Doc-only* | Prefer **views** for interactive Snowflake; **tables / incremental** when Presley/SERVING pulls large windows — document per FEATURE in model header. |
| 18 | `iceberg_partition_compatibility` | *Doc-only* | When landing to Iceberg, partition on **`as_of_date` / `month_start` + geo bucket** matching filter predicates in SERVING playbooks. |

## Commands

```bash
# Materialize feature QA views (same target as other QA_* views)
dbt run -s path:models/analytics/qa

# Golden seed (ANALYTICS.DBT_DEV after seed config)
dbt seed -s synthetic_golden_feature_rent_keys

# Singular tests (require FEATURE + seed present in warehouse)
dbt test -s assert_feature_rent_output_schema_contract assert_synthetic_golden_feature_rent_keys_match

# Window-frame grep (no Snowflake)
./scripts/ci/check_feature_window_leakage.sh
```

## CI

Workflow **Semantic layer — parse & catalog smoke** (`.github/workflows/semantic_layer_catalog_and_quality.yml`) runs `scripts/ci/check_feature_window_leakage.sh` on every job start (grep-only, no Snowflake). That closes slug **3** at merge time for any change that triggers the workflow (including `models/analytics/feature/**` under the existing `models/**` path filter).

## Highest-leverage sequence (feature teams)

1. **`window_leakage_audit`** + **`as_of_snapshot_enforcement`** + **`month_start` expression test** on spines.  
2. **`null_and_sparse_profile`** + **`cold_start_geo_report`**.  
3. **`feature_concept_parity_diff`** (and row-level `QA_FEATURE_CONCEPT_ALIGNMENT`).  
4. **`schema_evolution_guard`** + **`synthetic_fixture_replay`** in CI after FEATURE is built.
