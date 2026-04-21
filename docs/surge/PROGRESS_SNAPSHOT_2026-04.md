# Progress snapshot — April 2026

**Scope:** Counts and inventory are **repo-local** snapshots (files on disk in **pretiumdata-dbt-semantic-layer**) as of the surge start. Snowflake row counts and task **`T-*`** status live in migration logs and Snowflake.

**Do not treat this file as a second task register.** Authoritative disposition remains [`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md) and [`../migration/MIGRATION_LOG.md`](../migration/MIGRATION_LOG.md).

## 1. Reference catalog (governed seeds)

| Artifact | Location | Approx. rows (excl. header) |
|----------|----------|-----------------------------|
| **Vendors** | `seeds/reference/catalog/vendor.csv` | 53 |
| **Datasets** | `seeds/reference/catalog/dataset.csv` | 89 |
| **Concepts** | `seeds/reference/catalog/concept.csv` | 31 |
| **Metrics** | `seeds/reference/catalog/metric.csv` | ~4,969 |
| **Product type ↔ metric bridge** | `seeds/reference/catalog/bridge_product_type_metric.csv` | ~648 |
| **Derived analytics metrics (registry)** | `seeds/reference/catalog/metric_derived.csv` | 7 rows (mix of active / planned) |

Supporting dimension seeds (frequency, geo_level, tiers, bridges, wishlist, Cybersyn map, …) live alongside under `seeds/reference/catalog/` — see [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md).

## 2. Transform DEV — facts and concepts (dbt models)

| Pattern | Approx. count | Notes |
|---------|----------------|-------|
| **`FACT_*.sql`** under `models/transform/dev/` | **106** files | Multiple grains / vendors; includes government, Zillow research stack, fund/OpCo, labor automation risk, corridor helpers, etc. |
| **`CONCEPT_*.sql`** under `models/transform/dev/` | **27** files | Market-monthly unions and OpCo progress concepts |

**Migration log signal:** [`../migration/MIGRATION_LOG.md`](../migration/MIGRATION_LOG.md) summary table (FACT cluster from pretium-ai-dbt inventory) shows **57 migrated** of **81** tracked legacy FACT paths, with **24 pending** — use the log for **named** model lineage, not only counts.

## 3. Analytics layer — features, models, estimates, QA

| Pattern | Approx. count | Notes |
|---------|----------------|-------|
| **`FEATURE_*.sql`** | **10** | Rent spine, listings velocity, employment deltas, AI replacement risk surfaces, etc. |
| **`MODEL_*.sql`** | **4** | Includes disposition / signal composites under `model/` |
| **`ESTIMATE_*.sql`** | **0** in `models/analytics/estimate/` | **ESTIMATE_** contract is defined (seeds + playbook); physical models not shipped yet in this tree slice |
| **`QA_*.sql`** | **25** | STAGE governance: catalog coverage, collinearity, geography integrity, staleness, etc. |

**`metric_derived`** documents a few **FEATURE** / **MODEL** / **ESTIMATE** placeholders and active spines (for example rent and listings velocity) — see `seeds/reference/catalog/metric_derived.csv`.

## 4. Portfolio breadth (legacy dataset lens)

The rollup **[`../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`](../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md)** §3 cites **pretium-ai-dbt** `dim_dataset_config.csv`: **147 dataset rows** across **63 vendor IDs**. That is the widest **business** inventory; **this repo’s** `dataset.csv` is the **governed** subset aligned to **`REFERENCE.CATALOG`**.

## 5. What “good” looks like next

1. Close remaining **`T-VENDOR-*-READY`** tasks with smoke SQL + catalog rows (see vendor docs).
2. Grow **`metric.csv`** with gates in [`../rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md) — task **`T-CATALOG-METRIC-VENDOR-ROLLOUT`** is **`in_progress`** in [`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md).
3. Land first **`ESTIMATE_*`** objects under `models/analytics/estimate/` when **`metric_derived`** rows promote from `under_review` to active implementations (see [`../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`](../migration/MODEL_FEATURE_ESTIMATION_PLAYBOOK.md)).
