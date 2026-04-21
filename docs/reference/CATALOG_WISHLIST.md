# `REFERENCE.CATALOG.catalog_wishlist`

**Purpose:** Single place for **“needed but not doable yet”** — ontology-aligned **concept chains**, **catalog gaps** (e.g. empty bridges), and **infra** (canonical YAML paths, future `signals` / `models` seeds). Promote rows to real `concept` / `metric` / `metric_derived` / dbt models when unblocked; set **`status = done`** or delete the wishlist row. **WL_040** (`metric_derived_input`) is now implemented in seeds — see **`catalog_wishlist.csv`** row **`WL_040`** = **done**.

**Seed file:** [`catalog_wishlist.csv`](../../seeds/reference/catalog/catalog_wishlist.csv)  
**Tests:** [`schema_catalog_wishlist.yml`](../../seeds/reference/catalog/schema_catalog_wishlist.yml)  
**Load order:** [CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md) — **Wave 6d** (load after **`concept`** + **`metric`** so dimensional columns resolve).

**Dimensional alignment:** Optional **`primary_catalog_concept_code`** and **`primary_catalog_metric_code`** tie each row to **`REFERENCE.CATALOG.concept`** / **`metric`** (data-based spine). Chain-only ontology slugs remain in **`ontology_concept_code`** until **`concept.csv`** gains matching codes (see **`WL_043`**).

```bash
dbt seed --target reference --select reference.catalog.catalog_wishlist
dbt test --target reference --select catalog_wishlist
```

**Playbook cross-links:** Four central concept chains (absorption, construction, transactions, affordability) are spelled out in [migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) **§P**. **§Q** states when **“next”** means **segment stack models 1–4** (before `arbitrage_score`) vs **Part 2 upstream** macro/flow models — canonical detail in pretium-ai-dbt **`docs/analytics_engine/docs/guide_models.md` §4.7a**. Offerings / market vocabulary: pretium-ai-dbt **`docs/analytics_engine/docs/guide_offerings.md`** (there is no separate `guide_offerings_market.md`; use **guide_offerings** + **guide_signals**).

**Optional chains** in the wishlist CSV (`household_demographics_demand`, `occupancy_operations`) — same table structure as §P; prioritize with Alex if they should precede ceiling-only work.

**Polaris program:** Prioritized migration tasks and **rules for adding or editing wishlist rows** (P0–P8, `WL_041`–`WL_046`, **`WL_020`** hygiene) live in [`migration/MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md`](../migration/MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md). Source-YAML backlog **`WL_047`–`WL_048`** is indexed in [`migration/MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md`](../migration/MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md).

**Data / model execution order (wishlist → work):** [CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md](./CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md) — tiers **0–5** (`WL_020` / `WL_047` / `WL_048` first, then catalog spine, §P slices, registry YAML, Polaris, optional chains).

---

*Append new wishlist rows in the same PR as the RFC that explains why work is blocked; do not use this table as a second `metric` registry.*
