# REFERENCE.CATALOG — objects and the value they provide

This note inventories **objects that live in (or are intended for) `REFERENCE.CATALOG`** in this repo: dbt **seeds** materialized as tables under that schema, plus the **unified enum** model built from those seeds. It answers: *what is each object for, and who benefits?*

**Load order and CLI:** see [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md).  
**Source registry (for `source('catalog', …)`):** [`../../seeds/reference/catalog/_catalog.yml`](../../seeds/reference/catalog/_catalog.yml).

---

## How to read this

| Kind | Meaning |
|------|---------|
| **Seed** | Rows ship from CSV in `seeds/reference/catalog/`; `dbt seed` loads into `REFERENCE.CATALOG.<name>`. |
| **Model** | Built by `dbt run`; still catalog semantics, but not a CSV. |

**Primary value themes:**

1. **Governance** — codes used in facts, concepts, APIs, and docs must exist here first (FK tests, `relationships`, singular gates).
2. **Discoverability** — humans and tools resolve “what does this code mean?” without reading SQL.
3. **Lineage** — datasets and metrics point at real Snowflake paths; bridges express many-to-many scope without comma-in-column hacks.

---

## Core dimensions and enumerations (Wave 1)

| Object | Value provided |
|--------|----------------|
| **`vertical`** | Canonical investment verticals (e.g. RED / REQ / RESI). Aligns portfolio and product language across vendors and internal reporting. |
| **`domain`** | Concept **domain** vocabulary (capital, housing, household, place, portfolio). Drives `CONCEPT.domain` policy and cross-cutting analytics groupings. |
| **`frequency`** | Canonical **time grain** (annual, monthly, etc.). Every dataset and metric declares frequency in the same code set. |
| **`geo_level`** | Canonical **geography grain** (property through national, tract, H3, etc.). Powers concept/dataset grain rules and geo join expectations. |
| **`unit`** | Canonical **measurement unit** codes for `metric` / `metric_raw`. Lets consumers render axes, units, and unit-aware transforms consistently. |
| **`asset_type`** | Whether an **offering** is scoped to property/portfolio vs geography-first analytics. Used in tearsheet / access modeling. |
| **`tenant_type`** | **B2B consumer class** (IC, DS, OpCo, demo, etc.) for governed access to offerings. |
| **`catalog_enum_source`** | **Tall merged file** of dozens of small enumerations (statuses, tiers, directions, etc.) so one seed + build pipeline replaces many tiny CSVs. Feeds tests via `erf__*` ephemerals and the unified **`ENUM`** table. |

---

## Product, bedroom, and concept scaffolding (Wave 2)

| Object | Value provided |
|--------|----------------|
| **`product_type`** | Investment **product type** (SFR, MF tower, BTR, …) with vertical linkage and flags. Bridges datasets and metrics to “what building / strategy shape?” |
| **`bedroom_type`** | **Bedroom band** vocabulary for rent and supply semantics. |
| **`bridge_product_type_bedroom_type`** | **Authoring bridge** product type ↔ bedroom band (+ sort, active). Machine-syncs legacy `product_type.bedroom_type_codes` until that column is dropped. |
| **`concept`** | Canonical **semantic concept** codes (rent, unemployment, …). The spine of the semantic layer: concept models and metric assignment hang off these rows. |
| **`concept_geo_level`** | Which **geo grains** each concept supports (replaces comma-delimited `CONCEPT.geo_level_codes`). |
| **`concept_frequency`** | Which **frequencies** each concept supports (replaces `CONCEPT.frequency_codes`). |
| **`concept_vertical`** | Which **verticals** each concept applies to (replaces `CONCEPT.vertical_codes`). |
| **`concept_explanation`** | **Curated prose** (description, definition, explanation) per concept for UI, docs, and analyst onboarding. |

---

## Organization and access (Waves 3–4)

| Object | Value provided |
|--------|----------------|
| **`opco`** | **Operating company** registry (Progress, BH, Anchor, …). Ties datasets to OpCo-sourced landings and clarifies multi-tenant data ownership. |
| **`business_team`** | **Internal consumer team** registry (Snowflake role hooks, MotherDuck flags). Connects catalog governance to who may consume which reference data. |

---

## Vendors, datasets, and metrics (Wave 6)

| Object | Value provided |
|--------|----------------|
| **`vendor`** | **Data vendor / agency** registry. Required before datasets: every pipeline is attributed to a vendor row. |
| **`dataset`** | **Dataset** registry: one row per vendor × concept × geo × frequency (and pipeline status, MotherDuck flags, refresh metadata). The operational index of “what exists in the warehouse and at what grain.” |
| **`dataset_product_type`** | **Bridge** dataset ↔ product type (authoring source for machine-synced `dataset.product_type_codes`). Expresses product scope without editing comma columns by hand. |
| **`dataset_vertical`** | **Bridge** dataset ↔ vertical (same idea for vertical scope vs legacy `vertical_codes`). |
| **`metric_raw`** | **Bulk / backlog** metric definitions (including FACT and non-FACT paths). Source file from which the built **`metric`** seed is generated. |
| **`metric`** | **Promoted metric registry**: stable `metric_code`, `table_path`, `snowflake_column`, status, concept linkage. Powers catalog QA (`qa_catalog_metric_transform_dev_lineage`), Presley, and “what column do I read?” contracts. |
| **`metric_derived`** | **Analytics-layer metrics** (FEATURE / MODEL / ESTIMATE style outputs). Registers logical outputs that are not necessarily one physical FACT column. |
| **`metric_derived_input`** | **N:1 lineage** from a derived metric to one or more upstream **`metric_code`** rows. Documents composition for ranking, panels, and composite scores. |
| **`concept_definition_package`** | **Per-concept contract**: canonical grain, vendor priority, QA bounds, slot policy, required keys. Reduces ambiguity when multiple vendors implement the same concept. |
| **`catalog_wishlist`** | **Backlog / wishlist** (not yet deliverable): concept chains, infra, catalog gaps. Keeps demand visible without polluting active `concept` / `metric` rows. |

---

## Cybersyn mapping (Wave 6b)

| Object | Value provided |
|--------|----------------|
| **`cybersyn_catalog_table_vendor_map`** | Maps **Cybersyn `GLOBAL_GOVERNMENT` table names** to Pretium **`vendor_code`**. Speeds up bring-in matrices and avoids ad hoc string matching when wiring new Cybersyn feeds. |

---

## Offerings and tearsheet pack (Wave 7)

| Object | Value provided |
|--------|----------------|
| **`offering`** | **Commercial analytics offering** (distinct from “dataset”): a productized bundle for a client or internal use case. |
| **`bridge_offering_product_type`** | Which **product types** an offering applies to. |
| **`bridge_offering_asset_type`** | How an offering scopes to **asset_type** modes. |
| **`bridge_tenant_type_offering`** | Which **tenant types** get access to which offerings (and default tier). |
| **`bridge_product_type_metric`** | **Product type ↔ metric** linkage: “this metric is relevant for these product shapes in this offering context.” |
| **`offering_signal_relevance`** | **Concept-level** signal relevance per offering when metric-level grain is not yet authoritative. |
| **`concept_offering_weight`** | **Numeric weights** (e.g. Presley 0–5) for concept × offering routing; generated from matrix YAML + sync script. |

---

## Derived catalog table (model, not a seed)

| Object | Value provided |
|--------|----------------|
| **`ENUM`** (`catalog_enum` model, alias **`enum`**) | **Single wide-ish lookup** of small enumerations: merges **`catalog_enum_source`** with **frequency**, **asset_type**, and **tenant_type** so applications and tests can query `(enum_table, code)` in one place instead of dozens of tables. |

Build after Wave 1 seeds: `dbt run --select catalog_enum` (see [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md)).

**Deployment note:** Catalog **seeds** are pinned to **`REFERENCE.CATALOG`** via `dbt_project.yml`. The **`catalog_enum`** model does not hard-code database/schema in SQL; it follows your **active dbt target’s** default `database` / `schema` (for example `ci` / `parse` in [`../../ci/profiles.yml`](../../ci/profiles.yml) default to `REFERENCE` / `CATALOG`). Confirm the built relation’s FQN in your environment before wiring BI to **`ENUM`**.

---

## What this schema does *not* aim to be

- **Not operational fact storage** — row-level observations live under `TRANSFORM.*`, `SOURCE_*`, etc.; catalog holds **registries and bridges**.
- **Not a full data dictionary of every column** — it registers **metrics** and **datasets** at the grain needed for lineage and product semantics; deep column docs may live elsewhere.
- **Not `REFERENCE.DRAFT`** — in-progress definitions are promoted into catalog only after the documented approval path.

---

## Related docs

- [`CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md) — seed waves and commands  
- [`CATALOG_ENTITY_SEMANTICS_AND_ENFORCEMENT.md`](./CATALOG_ENTITY_SEMANTICS_AND_ENFORCEMENT.md) — semantics and enforcement  
- [`../migration/ENUM_CONSOLIDATION_DBT_REFS.md`](../migration/ENUM_CONSOLIDATION_DBT_REFS.md) — enum consolidation and `erf__*` tests  
- [`./METRIC_CSV_BUILD_SPEC.md`](./METRIC_CSV_BUILD_SPEC.md) — building **`metric.csv`** from **`metric_raw`**
