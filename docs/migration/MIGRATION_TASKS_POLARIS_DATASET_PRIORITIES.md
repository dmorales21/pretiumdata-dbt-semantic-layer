# Polaris / Iceberg — prioritized migration tasks (datasets + marts)

**Owner:** Alex  
**Canonical repo:** pretiumdata-dbt-semantic-layer (inner dbt project).  
**Plan source:** pretium-ai-dbt `.cursor/plans/polaris_population_priority_668fdf8c.plan.md`  
**Wishlist SoT:** `seeds/reference/catalog/catalog_wishlist.csv` + [`../reference/CATALOG_WISHLIST.md`](../reference/CATALOG_WISHLIST.md)

This doc **orders migration work** for Polaris population. It does **not** duplicate every `T-*` row in `MIGRATION_TASKS.md`; it ties **Polaris tiers** to **existing chains** and to **new wishlist rows** where backlog was missing.

---

## Priority order (do first → do later)

| Order | Polaris tier | Migration focus | Existing wishlist / task anchors |
|------:|----------------|-----------------|----------------------------------|
| **P0** | R0 | Geography dictionary + `geo_level` / `GEOGRAPHY_*` contracts stable for export | `T-CORRIDOR-REFERENCE-H3-SPINE-READY`; seeds `geo_level.csv`; validation SQL |
| **P1** | R1 | **`reference.geo_h3_parent_child`** — single SoT object, PK, partitions, `as_of` | **New `WL_041`**; pretium-ai-dbt H3 pipelines vs semantic read-through (plan risk) |
| **P2** | R2 | Metric dictionary + **product × metric** bridge for Presley / offerings | **`WL_020`** (reconcile status vs actual `bridge_product_type_metric.csv`); `metric.csv` / `concept.csv` |
| **P3** | C1–C2 | Spine **`CONCEPT_*`** (geo + time) exportable before macro chains | **New `WL_042`** calendar; Pilot spine playbook §E; pretium-ai-dbt mart builds |
| **P4** | C3–C5 | Gov / macro **FACT_*` + `dataset`** already largely in `dataset.csv` — close **source_prod_only → `TRANSFORM.DEV` FACT** where Polaris reads DEV only | `T-TRANSFORM-BPS-*`, `T-TRANSFORM-*-LODES`, `MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`; Cybersyn `T-CYBERSYN-GLOBAL-GOVERNMENT-READY` |
| **P5** | C6–C7 | Clearing / liquidity **ontology + facts at mart grain** | **`WL_001`–`WL_003`**; **New `WL_043`** (taxonomy); **New `WL_044`** only if gov/CRM/postal exports required; corridor liquidity detail stays **`WL_003`** |
| **P6** | C8–C10 | Rent / value / affordability — vendor precedence + **`CONCEPT_*`** | Playbook §O/§P; **`WL_004`**; **New `WL_045`** (explicit RTI / stress dataset) |
| **P7** | Ops / blocked landings | Repair or formally retire blocked datasets that block OpCo marts | **New `WL_046`** (`DS_066` Funnel); `MIGRATION_TASKS_YARDI_BH_PROGRESS.md` |
| **P8** | Catalog / layout infra | `signals` / `models` seeds; `metric_derived_input` | **`WL_030`–`WL_031`**, **`WL_040`** |

---

## How work should populate **`catalog_wishlist.csv`**

Use one row per **independently unblockable** backlog item. Follow existing columns:

| Column | Rule |
|--------|------|
| **`wishlist_id`** | Monotonic `WL_NNN` (never reuse ids). |
| **`wishlist_code`** | `snake_case` stable slug (grep-friendly); prefix **`polaris_`** for Iceberg/export contract items so they sort with program work. |
| **`category`** | `concept_chain` = multi-model ontology chain (like WL_001–004). `catalog_gap` = missing seed/dataset/bridge/export contract. `infra` = YAML / seed layout (WL_021–022, WL_030–031). |
| **`ontology_concept_code`** | Use real `concept.concept_code` when one exists; else leave empty until taxonomy adds it (**`WL_043`** drives splits). |
| **`ontology_model_role`** | `driver` \| `constraint` \| `liquidity_proxy` for concept chains; empty for catalog_gap/infra. |
| **`headline` / `next_action` / `blocked_by`** | One sentence each; **`blocked_by`** names the **smallest** upstream (person, task id, or gate doc). |
| **`priority`** | **1 = highest** (same scale as existing WL rows). Polaris **P0–P2** map to priority **1–2** on the wishlist. |
| **`status`** | `blocked` (cannot start), `scoped` (design done), `in_progress`, `done`. When work ships, set **`done`** or **delete** the row per `CATALOG_WISHLIST.md`. |

**Do not duplicate:** If **`WL_001`–`WL_004`** already describe the chain, add **only** net-new gaps (**`WL_041`–`WL_046`** in the table below, or non-Polaris infra rows such as **`WL_047`–`WL_048`** in `MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md`) or **edit** an existing row (e.g. **`WL_020`**) when the headline/status is wrong—**same PR** as the seed or bridge change.

**Link to migration audit:** When a wishlist row closes, append **`MIGRATION_LOG.md`** and (if verbose) **`MIGRATION_BATCH_INDEX.md`**.

---

## New wishlist rows added with this doc

| id | code | Purpose |
|----|------|---------|
| WL_041 | `polaris_geo_h3_parent_child_iceberg` | R1 export contract |
| WL_042 | `polaris_calendar_spine_shared` | C2 calendar spine |
| WL_043 | `polaris_ontology_clearing_concepts` | Unblock WL_001–004 taxonomy |
| WL_044 | `polaris_catalog_only_vendor_datasets` | Optional vendor `dataset` registration |
| WL_045 | `polaris_affordability_rti_dataset` | Explicit affordability / RTI FACT path |
| WL_046 | `polaris_funnel_bh_ops_remediation` | `DS_066` Funnel blocked |

Cherre **corridor liquidity** remains **`WL_003`** (do not add a parallel row unless you split “recorder vs MLS” into two tickets).

---

## Reconcile **`WL_020`** (bridge)

**Current seed state:** `bridge_product_type_metric.csv` has **nine** rows — every **`product_type_code`** from `product_type.csv` × **`cybersyn_fhfa_house_price_timeseries_value`** (**MET_013** / `homeprice`). **`WL_020`** is set to **`status = in_progress`**, **`priority = 1`**, **`primary_catalog_concept_code = homeprice`**, **`primary_catalog_metric_code = cybersyn_fhfa_house_price_timeseries_value`**.

Set **`WL_020`** to **`done`** only after rent/value metrics are added to the bridge (or product policy explicitly scopes “HPI-only” as complete). Update **`VENDOR_CATALOG_ONLY_SNOWSQL_VET.md`** / matrix copy in the same PR whenever **`WL_020`** status changes.
