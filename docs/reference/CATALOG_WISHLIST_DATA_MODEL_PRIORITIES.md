# Catalog wishlist — data and model priorities (semantic layer)

**Source of truth:** [`seeds/reference/catalog/catalog_wishlist.csv`](../../seeds/reference/catalog/catalog_wishlist.csv) (mirrored in [CATALOG_WISHLIST.md](./CATALOG_WISHLIST.md)).  
**This page:** execution order for **data** (seeds, Snowflake objects, grants) and **models** (`models/`, `registry/`) so in-flight rows move to **done** without thrash.

---

## Tier 0 — ship first (already `in_progress`; smallest unblockers)

| Order | ID | Focus | Concrete next steps |
|------:|----|--------|---------------------|
| 0.1 | **WL_020** | `bridge_product_type_metric` | **Shipped in-repo:** [`metric.csv`](../../seeds/reference/catalog/metric.csv) **`MET_041`–`MET_048`** (Zillow **`MET_041`–`MET_043`** plus **Markerr MF CBSA** **`MET_044`–`MET_045`**, **Yardi Matrix** **`MET_046`**, **CoStar SCENARIOS** **`MET_047`–`MET_048`**); read-through **`FACT_*`** in `models/transform/dev/{costar,markerr,yardi_matrix}/`; [`bridge_product_type_metric.csv`](../../seeds/reference/catalog/bridge_product_type_metric.csv) extends sort orders **8–12** for the five new metrics × nine product types; FK test unchanged. **Still open:** per-metric **`MET_*`** for wide Jon **`TRANSFORM.FACT.COSTAR_MF_MARKET_CBSA_MONTHLY`** after §1.5 column inventory; optional ZORI-specific MET if product splits **`MET_041`**. |
| 0.2 | **WL_047** | Redfin semantic sources | [`models/sources/sources_redfin.yml`](../../models/sources/sources_redfin.yml) shipped. **Next:** complete **RF-A** inventory + `cleaned_redfin_*` / `FACT_*` in `models/transform/dev/` per [`MIGRATION_TASKS_STANFORD_REDFIN.md`](../migration/MIGRATION_TASKS_STANFORD_REDFIN.md) / **`T-VENDOR-REDFIN-READY`**; register metrics in `metric.csv` as tables exist. |
| 0.3 | **WL_048** | Cherre share path | [`models/sources/sources_cherre_share.yml`](../../models/sources/sources_cherre_share.yml) shipped. **Next:** share grants + **corridor FACT smoke** (inventory SQL + one compile path); document `--vars` for `cherre_database` / `cherre_schema` overrides. |

**Rule:** finish **WL_020** seed + tests before expanding **§P** feature work that assumes a full bridge matrix.

---

## Tier 1 — catalog spine that unlocks composites (blocked but small design surface)

| Order | ID | Focus | Why before Polaris |
|------:|----|--------|---------------------|
| 1.1 | **WL_040** | `metric_derived_input` | **Done (2026-04):** `seeds/reference/catalog/metric_derived_input.csv` + `schema_metric_derived_input.yml` + **Wave 6c-input** in [`CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md). Expand rows as new **`metric_derived`** composites land. |
| 1.2 | **WL_030** / **WL_031** | `signals` / `models` seeds | Blocked on layout gates ([`CATALOG_SIGNALS_LAYOUT.md`](./CATALOG_SIGNALS_LAYOUT.md), [`CATALOG_MODELS_LAYOUT.md`](./CATALOG_MODELS_LAYOUT.md)). **After** layout approval: add seeds + CI wave; do **not** hand-maintain parallel registries in `mart/`. |

---

## Tier 2 — FACT / CONCEPT slices toward §P chains (partial today)

Ship **facts and thin concepts** that exist independently of full ontology names (`CONCEPT_absorption_*`, …). These align with wishlist **partial** rows and pretium-ai-dbt surfaces already referenced in playbooks.

| Wishlist anchor | Prioritize these repo directions |
|-----------------|-----------------------------------|
| **WL_002** construction | Keep **`fact_bps_permits_county`** healthy; add CBSA rollups / docs only until regulatory/cost scenario hooks are specified. |
| **WL_003** transactions | Cherre read surfaces + corridor inventory from [`MIGRATION_TASKS_CHERRE.md`](../migration/MIGRATION_TASKS_CHERRE.md); **no** `CONCEPT_transactions_*` until recorder MLS facts at corridor grain + naming in `concept.csv`. |
| **WL_004** affordability | Stabilize **`concept_rent_market_monthly`**, **`concept_rent_property_monthly`**, valuation / AVM market concepts + [`feature_rent_market_monthly_spine.sql`](../../models/analytics/feature/feature_rent_market_monthly_spine.sql); **WL_045** (RTI dataset) remains the explicit catalog gap for “ceiling”. |
| **WL_001** absorption | Zillow DOM / listings and corridor features stay in pretium-ai-dbt until **`CONCEPT_*`** taxonomy (**WL_043**) lands. |

---

## Tier 3 — registry infra (blocked; repo SoT)

| Order | ID | Deliverable |
|------:|----|-------------|
| 3.1 | **WL_021** | Single **`registry/features/corridor_model.yaml`** (or documented ADR: analytics-engine vs this repo). Link from FEATURE / concept bridge docs. |
| 3.2 | **WL_022** | **`registry/models/arbitrage_score.yaml`** + optional `metric_derived` row for `arbitrage_score_v1_h3_r8_snapshot` once composite spec is frozen. |

**Note:** [`registry/lineage/corridor_lodes_h3_r8_lineage.yml`](../../registry/lineage/corridor_lodes_h3_r8_lineage.yml) covers **lineage**, not WL_021 model contract.

---

## Tier 4 — Polaris program rows (**WL_041–WL_046**)

Follow [`MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md`](../migration/MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md): **R0–R2** reference and catalog, **C1–C2** spine, then clearing / liquidity catalog (**WL_043** unblocks **WL_001–WL_004** ontology). Do **not** start **WL_044** catalog-only vendor waves without **VENDOR_CATALOG_ONLY_SNOWSQL_VET** completion.

---

## Tier 5 — optional / committee (**WL_010**, **WL_011**)

Explicit **household_demographics** and **occupancy_operations** chains — only after product call on overlap with **WL_004** / **WL_001** (see wishlist `blocked_by` / `priority` 9–10).

---

## Agent checklist (minimal)

1. **Claim** a wishlist row in PR description; link this doc section.  
2. **Land** seeds/models in **this** repo per [CANONICAL_COMPLETION_DEFINITION.md](../migration/CANONICAL_COMPLETION_DEFINITION.md).  
3. **Flip** `catalog_wishlist.status` to **done** (or delete row) **in the same PR** as the deliverable; append **MIGRATION_LOG.md** if batch-sized.  
4. **Run** `scripts/ci/run_catalog_quality_checks.sh` (and Snowflake dimensional SQL when touching `metric` / geography).

---

## Related

- [CATALOG_WISHLIST.md](./CATALOG_WISHLIST.md)  
- [MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md](../migration/MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md) (**WL_047–WL_048**)  
- [PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) **§P / §Q**
