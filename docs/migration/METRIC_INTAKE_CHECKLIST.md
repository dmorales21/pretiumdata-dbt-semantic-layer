# Metric intake — REFERENCE.CATALOG checklist

**Owner:** Alex  
**Status:** **canonical index** (single entry point; detailed gates below).

**Authoritative backlog:** **`seeds/reference/catalog/metric_raw.csv`** (hand edits + `scripts/sync_metric_csv_from_pretium_ai_dbt.py`). **Built `metric` seed:** **`seeds/reference/catalog/metric.csv`** — **generated** by **`scripts/reference/catalog/build_metric_csv_from_metric_raw.py`** before `dbt seed` / CI (`docs/reference/METRIC_CSV_BUILD_SPEC.md`). Do not edit **`metric.csv`** directly in PRs unless the generator output is intentional.

**Tall concept observations:** every emitted **`metric_code`** on a tall **TRANSFORM.DEV** table must exist on an active **`METRIC`** row; add the FACT/CONCEPT registration to **`metric_raw`**, re-run the generator, then ship the dbt model. Row contract: **`docs/reference/CONCEPT_OBSERVATION_TALL_ROW_CONTRACT.md`**.

Use this path before adding or renaming **`metric`**, **`metric_raw`**, **`metric_derived`**, **`dataset`**, or other **`REFERENCE.CATALOG`** seeds consumed by **`FACT_*` / `FEATURE_*` / `MODEL_*` / `ESTIMATE_*`**.

## Checklist (order)

1. **Classify** — Native vendor measure vs **derived** analytics output → layout in [reference/CATALOG_METRIC_DERIVED_LAYOUT.md](../reference/CATALOG_METRIC_DERIVED_LAYOUT.md).
2. **Gates** — All four gates in [rules/ARCHITECTURE_RULES.md](../rules/ARCHITECTURE_RULES.md) § **Metric Registration Gates** (null coverage, history, catalog compliance keys, census geography compliance).
3. **Seed order** — Load / dependency order: [CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md).
4. **Fact wave** — If the measure ships on a new **`FACT_*`**, follow [MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md](./MIGRATION_FACT_SYSTEMIZATION_PLAYBOOK.md) per-model checklist.
5. **Log** — Short row in [MIGRATION_LOG.md](./MIGRATION_LOG.md); evidence in [MIGRATION_BATCH_INDEX.md](./MIGRATION_BATCH_INDEX.md) when non-trivial.

## Related

- [MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md](./MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md) — **SoT**, column contract, gates, per-vendor execution template.
- [NAMING_RULES_INDEX.md](../rules/NAMING_RULES_INDEX.md) — how **`SCHEMA_RULES`**, **§4 / §7** in this migration doc, **ARCHITECTURE_RULES**, and lineage docs fit together (no duplicate policy).
- [MODEL_FEATURE_ESTIMATION_PLAYBOOK.md](./MODEL_FEATURE_ESTIMATION_PLAYBOOK.md) — catalog rows for **`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`** (§4.3 methods, checklist §4.3).
- [MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md](./MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md) — vendor × dataset × metric rollup.
