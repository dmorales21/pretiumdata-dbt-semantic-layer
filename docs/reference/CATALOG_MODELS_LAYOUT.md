# `REFERENCE.CATALOG.models` — design-only layout (future seed)

**Status:** **Design document only.** Do not add a Snowflake seed or `models.csv` until Alex approves gate **(c)** in [PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) §0.

**Purpose:** Register **learned or composite model artifacts** (`MODEL_*`, scored outputs) with a stable **`model_id`**, dependency manifest, and links to **pretium-ai-dbt** `registry/models/*.yaml` model cards where they exist.

---

## 1. Relationship to signals and metrics

| From | To | Rule |
|------|-----|------|
| Model | `signal` rows (optional) | Many-to-many via future bridge or JSON manifest |
| Model | `metric_derived` / `metric` | Direct inputs for simple stacks |
| Model | `model_type` | FK → existing dimension seed (align `metric_derived.analytics_layer_code = model`) |

---

## 2. Recommended columns (v1 sketch)

| Column | Required | Description |
|--------|----------|-------------|
| `model_id` | yes | Surrogate PK, e.g. `MDL_001` |
| `model_code` | yes | Stable identifier; unique |
| `model_label` | yes | Short display name |
| `definition` | yes | Objective, training grain, horizon, output type; RFC4180 quoting |
| `model_type_code` | yes | FK → `model_type` |
| `output_type_code` | yes | e.g. `score`, `probability`, `class`, `level`, `growth` |
| `training_geo_level_code` | no | Grain used for fit |
| `training_frequency_code` | no | Cadence used for fit |
| `registry_yaml_path` | no | Repo-relative path to `registry/models/*.yaml` in pretium-ai-dbt or analytics-engine |
| `concept_code` | no | Primary thematic `concept_code` |
| `data_status_code` | yes | |
| `is_active` | yes | boolean |

---

## 3. Primary key and manifest

- **PK:** `model_id` (surrogate).  
- **Input manifest:** Either (a) child table **`model_input`** with (`model_id`, `input_kind`, `input_code`) or (b) documented JSON column in a later phase—**do not** overload a single CSV column without a parser story.

---

## 4. Cycle prevention (DAG)

**Directed acyclic graph:** A model **must not** consume a signal or derived metric whose dependency graph includes **that model’s output** (including via another estimate). Enforce via:

1. PR checklist + architecture review for new rows  
2. Future automated check if `model_input` / signal bridge exists

---

## 5. Foreign keys (future tests)

- `model_type_code` → `model_type.model_type_code`  
- Optional FKs to `concept`, `geo_level`, `frequency` as for `metric_derived`

---

## 6. Seed load order (when implemented)

After **`metric_derived`** and (if present) **`signals`**; coordinated with **`metric_derived`** rows that reference the same **`MODEL_*`** physical object names.

---

## 7. Example (documentation only)

**`arbitrage_score`** — composite **`4_estimate`** consuming **`corridor_model`** feature set; see pretium-ai-dbt [guide_models.md](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_models.md) and [guide_real_estate.md](../../../../pretium-ai-dbt/docs/analytics_engine/docs/guide_real_estate.md). **Resolve canonical `registry/models/arbitrage_score.yaml` path** before first catalog row references it.

---

*Update when first `models` seed is approved; link from playbook §I.*
