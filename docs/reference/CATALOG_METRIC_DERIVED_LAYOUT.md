# `REFERENCE.CATALOG.metric_derived` — recommended layout

**Purpose:** Register **analytics-layer** metrics (outputs of **`FEATURE_*`**, **`MODEL_*`**, or **`ESTIMATE_*`** objects in **`ANALYTICS`**) with a stable code, human label, and **typed link** to the existing dimension seeds **`function`**, **`model_type`**, and **`estimate_type`**.  

**Relationship to `metric`:** `seeds/reference/catalog/metric.csv` remains the registry for **observable measures** on **`TRANSFORM.DEV`** / vendor FACT paths (`is_derived` there flags transforms that are still *warehouse-measurable*). **`metric_derived`** is for **derived / composite / scenario** metrics whose authoritative grain lives in **analytics or serving**, not for duplicating every long-form FACT column.

**Authority:** `docs/rules/ARCHITECTURE_RULES.md` (FACT/CONCEPT vs ANALYTICS), `docs/CATALOG_SEED_ORDER.md` (seed waves).

**Future ladder (design-only):** [CATALOG_SIGNALS_LAYOUT.md](./CATALOG_SIGNALS_LAYOUT.md), [CATALOG_MODELS_LAYOUT.md](./CATALOG_MODELS_LAYOUT.md). **Backlog / blocked work:** [CATALOG_WISHLIST.md](./CATALOG_WISHLIST.md) (`catalog_wishlist` seed). **End-to-end playbook:** [migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md).

---

## 1. Grain rules

| Rule | Detail |
|------|--------|
| **One row** | One **logical** derived metric (one `metric_derived_code`). Multiple physical tables (e.g. point + interval) use **separate rows** tied to different `estimate_type_code` values, or a child bridge table in a later phase. |
| **Layer** | Each row belongs to exactly **one** analytics family: **feature**, **model**, or **estimate** (`analytics_layer_code`). |
| **Dimension link** | Exactly **one** of `function_code`, `model_type_code`, or `estimate_type_code` is non-null and must match `analytics_layer_code` (see §4 tests). |
| **Upstream metrics** | Optional `primary_metric_code` → `ref('metric')` when the derived metric is **predominantly** a transform of one registered base metric; use **`definition`** + future **`metric_derived_input`** seed for multi-input lineage. |

---

## 2. CSV columns (recommended)

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `metric_derived_id` | string | yes | Surrogate PK, e.g. **`MDV_001`**. |
| `metric_derived_code` | string | yes | Stable snake_case identifier; unique; used in joins from analytics YAML/docs. |
| `metric_derived_label` | string | yes | Short display name. |
| `definition` | string | yes | Plain-language formula, source dbt models (`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`), and grain (geo × time). |
| `analytics_layer_code` | string | yes | **`feature`** \| **`model`** \| **`estimate`** — aligns with **`ANALYTICS.DBT_*`** object prefixes. |
| `function_code` | string | conditional | Required when `analytics_layer_code = feature`. FK → **`REFERENCE.CATALOG.function.function_code`**. |
| `model_type_code` | string | conditional | Required when `analytics_layer_code = model`. FK → **`REFERENCE.CATALOG.model_type.model_type_code`**. |
| `estimate_type_code` | string | conditional | Required when `analytics_layer_code = estimate`. FK → **`REFERENCE.CATALOG.estimate_type.estimate_type_code`**. |
| `primary_metric_code` | string | no | FK → **`REFERENCE.CATALOG.metric.metric_code`** when a single base metric drives the derivation. |
| `concept_code` | string | no | FK → **`concept`** — thematic grouping for UI/registry filters. |
| `geo_level_code` | string | no | Output grain FK → **`geo_level`**. |
| `frequency_code` | string | no | Output cadence FK → **`frequency`**. |
| `data_status_code` | string | yes | Same vocabulary as **`metric`** / **`dataset`** (`active`, `under_review`, …). |
| `is_active` | boolean | yes | Soft-disable without deleting history. |

**Optional later columns (not required for v1):** `snowflake_column`, `table_path` (physical ANALYTICS relation), `sort_order`, `vertical_codes`, `is_opco_metric` — mirror **`metric.csv`** only when you wire Presley/Strata to physical columns.

---

## 3. Seed files (implemented)

**Derived outputs:** `seeds/reference/catalog/metric_derived.csv` · `seeds/reference/catalog/schema_metric_derived.yml`  
**N:1 inputs:** `seeds/reference/catalog/metric_derived_input.csv` · `seeds/reference/catalog/schema_metric_derived_input.yml`  
**Load order:** Wave **6c** then **6c-input** in `docs/CATALOG_SEED_ORDER.md` (after **`metric`**).

Starter rows include **`rent_market_monthly_spine`** (maps to dbt model `feature_rent_market_monthly_spine`; Snowflake **`ANALYTICS.DBT_DEV.FEATURE_RENT_MARKET_MONTHLY`** via `alias`) plus two **placeholder** rows for model/estimate patterns; replace placeholders when production **`MODEL_*` / `ESTIMATE_*`** ship.

---

## 4. `dbt` seed config & tests (implemented)

| Artifact | Path |
|----------|------|
| Seed | `seeds/reference/catalog/metric_derived.csv` |
| Column + model tests | `seeds/reference/catalog/schema_metric_derived.yml` |
| Source list | `seeds/reference/catalog/_catalog.yml` → `catalog.metric_derived` |

**Tests:** `not_null` / `unique` on ids; `accepted_values` on `analytics_layer_code`; conditional **`relationships`** on optional FK columns with `where` so empty CSV cells skip; seed-level **`dbt_utils.expression_is_true`** enforces exactly one of `function_code` / `model_type_code` / `estimate_type_code` per layer.

---

## 5. Seed load order

1. `function`, `model_type`, `estimate_type` (Wave 2)  
2. `metric` (Wave 6)  
3. **`metric_derived`** — **Wave 6c** in `docs/CATALOG_SEED_ORDER.md`

---

## 6. `metric_derived_input` (implemented — WL_040)

**Canonical CSV:** `seeds/reference/catalog/metric_derived_input.csv`  
**Tests:** `seeds/reference/catalog/schema_metric_derived_input.yml`  
**Load order:** **Wave 6c-input** in `docs/CATALOG_SEED_ORDER.md` (after **`metric_derived`**).

| Column | Description |
|--------|-------------|
| `metric_derived_input_id` | Surrogate PK (`MDI_*`). |
| `metric_derived_code` | FK → `metric_derived.metric_derived_code` |
| `input_metric_code` | FK → `metric.metric_code` |
| `input_role` | `primary` \| `control` \| `interaction` \| `denominator` |
| `sort_order` | Documentation / join hint order |

Keep **`metric_derived`** one-row-per-logical-output; use this bridge for N:1 inputs.
