# `REFERENCE.CATALOG.signals` — design-only layout (future seed)

**Status:** **Design document only.** Do not add a Snowflake seed or `signals.csv` until Alex approves gate **(c)** in [PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md](../migration/PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG.md) §0.

**Purpose:** Register **reusable interpretable transforms** built on top of **`metric`** / **`metric_derived`** (z-scores, ranks, regime flags) that multiple **`MODEL_*`** or **`ESTIMATE_*`** consumers share—without duplicating logic in every feature SQL.

---

## 1. Relationship to other catalog objects

| From | To | Rule |
|------|-----|------|
| Signal | `metric_derived` and/or `metric` | At least one parent FK |
| Signal | `concept`, `geo_level`, `frequency` | Optional thematic / grain filters |
| `MODEL_*` / catalog ladder | Signals | Consumes; **acyclic** (see §5) |

---

## 2. Recommended columns (v1 sketch)

| Column | Required | Description |
|--------|----------|-------------|
| `signal_id` | yes | Surrogate PK, e.g. `SIG_001` |
| `signal_code` | yes | Stable snake_case; unique |
| `signal_label` | yes | Short display name |
| `definition` | yes | Transform + inputs + grain; RFC4180 quoting for commas |
| `parent_metric_derived_code` | conditional | FK → `metric_derived` when parent is derived |
| `parent_metric_code` | conditional | FK → `metric` when parent is base metric |
| `transformation_code` | yes | e.g. `zscore`, `rank_cohort`, `regime_flag` |
| `concept_code` | no | FK → `concept` |
| `geo_level_code` | no | Output grain |
| `frequency_code` | no | Output cadence |
| `horizon_code` | no | e.g. `t_plus_12` — explicit horizon for forward-safe transforms |
| `data_status_code` | yes | Same vocabulary as `metric` |
| `is_active` | yes | boolean |

---

## 3. Primary key and cardinality (choose one before seeding)

**Option A — surrogate PK:** `signal_id` only; uniqueness enforced on `(signal_code)` or composite business key in tests.

**Option B — composite logical key:** `(parent_metric_derived_code OR parent_metric_code, transformation_code, geo_level_code, frequency_code, horizon_code)` — at most **one** active row per combination unless versioned (`signal_code` suffix `_v2`).

Document the chosen option in `schema_signals.yml` when seeds ship.

---

## 4. Foreign keys (future tests)

- `parent_metric_derived_code` → `metric_derived.metric_derived_code` where not null  
- `parent_metric_code` → `metric.metric_code` where not null  
- `concept_code` → `concept.concept_code`  
- `geo_level_code` → `geo_level.geo_level_code`  
- `frequency_code` → `frequency.frequency_code`

Use `relationships` with `where:` clauses for optional columns (same pattern as `schema_metric_derived.yml`).

---

## 5. Cycle prevention

Signals **must not** depend on **`MODEL_*` / `ESTIMATE_*` outputs** that themselves consume that signal. Validation: **manual DAG review** on first N rows; future **lint or dbt test** on a `metric_derived_input`-style bridge if the graph grows.

---

## 6. Seed load order (when implemented)

After **`metric_derived`** (Wave 6c+); before or in parallel with **`MODELS`** seed depending on whether models reference signals only via YAML vs catalog.

---

*Update this layout when the first `signals` seed is approved; link from the playbook §I.*
