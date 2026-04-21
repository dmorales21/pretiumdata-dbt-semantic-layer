# Runbook — CONCEPT productionalization, FEATURE enhancement, pipeline compliance

| Field | Value |
|-------|--------|
| **Owner** | Alex (data science) — semantic-layer dbt + catalog governance in **pretiumdata-dbt-semantic-layer** |
| **Audience** | **Alex** (primary: concept design, FEATURE contracts, catalog alignment); **DE / analytics engineering** (dbt CI, Snowflake grants, job selectors); **Jon** (read-only: `TRANSFORM.[VENDOR]` / `TRANSFORM.FACT` parents); **Spencer** (only where `SERVING.MART` / delivery endpoints are touched) |
| **Where this lives** | `docs/migration/RUNBOOK_CONCEPT_PRODUCTIONALIZATION_AND_FEATURES.md` |
| **Canonical rules** | [`docs/rules/ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md), [`docs/rules/SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) |
| **QA order** | [`QA_METRIC_LAYER_VALIDATION.md`](./QA_METRIC_LAYER_VALIDATION.md) — FACT → CONCEPT → FEATURE → MODEL → ESTIMATE |

**Purpose:** One internal runbook for **productionalizing** `CONCEPT_*` objects in **`TRANSFORM.DEV`**, **enhancing** **`ANALYTICS.DBT_*`.`FEATURE_*`** read surfaces (including **ML prep**), and staying **pipeline-compliant** (layer boundaries, catalog gates, CI).

---

## 0. Layer contract — CONCEPT vs FEATURE (non-negotiable)

**Alex (data science)** owns the *meaning* of market/domain quantities and how vendors align to one grain. **ML prep and learned representations belong in FEATURE**, not in CONCEPT.

| Belongs in **`TRANSFORM.DEV`** `CONCEPT_*` | Belongs in **`ANALYTICS.DBT_DEV`** `FEATURE_*` (or `MODEL_*` / `ESTIMATE_*`) |
|---------------------------------------------|-----------------------------------------------------------------------------|
| Vendor-normalized **observable** fields at agreed grain (e.g. **rent**, **price**, **units**, **levels**) | **PCA**, embeddings, **scaling** / z-scores for model consumption, **basis expansions** for ML |
| **Structural** unit math that is still a *defined economic quantity* (e.g. **PPSF** = price ÷ sqft when both are concept-level observables) | **Interaction features**, **cohort deciles**, **rolling model inputs**, **tightness scores** unless purely definitional |
| Union / slot policy across vendors (`concept_metric_slot`, shared `geo_id` / `month_start`) | Anything whose **primary consumer** is a training pipeline or notebook **feature matrix** |
| Joins to **REFERENCE.GEOGRAPHY** / census spine for *alignment* | **Train/val splits**, **sample weights**, **leakage-prone** windowing for ML |

**Examples**

- **PPSF** — If defined as `price ÷ square_feet` from governed concept/fact columns at market grain, implement in **CONCEPT** (or upstream FACT enrichment then CONCEPT). Consumers read one canonical column.
- **PCA** — Lives in **`models/analytics/feature/`** as **`FEATURE_*`**, reading **`ref('concept_*')`** or **`ref('fact_*')`**; never embed PCA loadings inside **`models/transform/dev/concept/`**.

**Checklist — before merging any PR**

- [ ] **Owner (Alex)** confirmed: no PCA / embedding / scaler-only outputs in `concept/*.sql`.
- [ ] **Owner (Alex)** confirmed: new ML-oriented columns land under `analytics/feature/` (or `model/` / `estimate/` per playbook), not `transform/dev/concept/`.
- [ ] **Reviewer** verified: `FEATURE_*` uses `ref('concept_*')` for vendor unions, not re-unioned FACT logic ([`MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`](./MODEL_FEATURE_ESTIMATION_PLAYBOOK.md)).

---

## 1. Roles (RACI-style)

| Workstream | **Alex (DS)** | **DE / analytics** | **Jon** | **Spencer** |
|------------|---------------|--------------------|---------|-------------|
| CONCEPT SQL + YAML tests | **R / A** | C | I | I |
| FACT read-throughs + sources | **R** | C | **R** (silver ownership) | I |
| FEATURE / MODEL for ML prep | **R / A** | C | I | I |
| `REFERENCE.CATALOG` seeds (`MET_*`, `MDV_*`) | **R / A** | C | I | I |
| CI workflows (`dbt parse`, selective test) | C | **R / A** | I | I |
| `SERVING.DEMO` / delivery views | **R** | C | I | **C** (prod serving patterns) |

**A** = accountable for merge quality in this repo; **R** = responsible for delivery; **C** = consulted; **I** = informed.

---

## 2. Phase A — CONCEPT productionalization (`TRANSFORM.DEV`)

**Goal:** Stable `CONCEPT_*` tables: grain invariants, documented stubs/geo caveats, green `dbt run` + `dbt test` on the concept path.

### A1. Tests and contracts

- [ ] **Alex:** Align **`schema.yml`** on `path:models/transform/dev/concept` — `not_null` + `accepted_values` on `concept_code`, `month_start` / period, `geo_level_code`, `geo_id` where the model claims a fixed grain (match strictness across concepts).
- [ ] **Alex:** For optional vendor branches (HUD, Cherre stub), use **`enabled:`** on tests or document **0-row** expectation in model `description`.
- [ ] **Alex:** Employment / unemployment — document **LAUS `AREA_CODE` vs OMB CBSA**; add coverage test or scope filter before “national CBSA panel” claims.

### A2. Upstream compliance (FACT / sources)

- [ ] **Alex + DE:** [`QA_METRIC_LAYER_VALIDATION.md`](./QA_METRIC_LAYER_VALIDATION.md) §0 — geography xwalks and vendor parents exist for concepts under test (checkbox matrix: [`QA_CONCEPT_PREFLIGHT_CHECKLIST.md`](./QA_CONCEPT_PREFLIGHT_CHECKLIST.md)).
- [ ] **DE:** Run `dbt run --selector catalog_metric_transform_dev_surface` (or equivalent) when FACT parents change.
- [ ] **Alex:** `snowsql` / §1e — `scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql` → **`failure_rows = 0`** for claimed `TRANSFORM.DEV` **`metric.table_path`** rows.

### A3. Exit criteria (Phase A)

- [ ] `dbt run --select path:models/transform/dev/concept` — **SUCCESS** on target env.
- [ ] `dbt test --select path:models/transform/dev/concept` — **PASS** (or waived tests documented in YAML).

---

## 3. Phase B — FEATURE enhancement (`ANALYTICS.DBT_DEV`)

**Goal:** Thin, governed read surfaces; **all ML prep** (PCA, scaling, etc.) lives here.

**Concept `MET_*` stats + lag-1 ACF (for ML prep):** [`../reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md`](../reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md).

### B1. New FEATURE spine

- [ ] **Alex:** Add `models/analytics/feature/feature_<concept>_<function>_<geo>_<frequency>.sql` (naming per [`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) tokens + catalog rows).
- [ ] **Alex:** `SELECT` from **`{{ ref('concept_*') }}`** only — no duplicate vendor unions in FEATURE.
- [ ] **Alex:** Register **`metric_derived`** / **`metric_derived_input`** when the surface is a named composite ([`CATALOG_METRIC_DERIVED_LAYOUT.md`](../reference/CATALOG_METRIC_DERIVED_LAYOUT.md)).

### B2. ML prep (PCA, etc.)

- [ ] **Alex:** Implement PCA / SVD / embeddings **input tables** under **`FEATURE_*`** (or **`MODEL_*`** if the repo treats fitted scores as model outputs — document choice in PR).
- [ ] **Alex:** Ensure **no PROD** object reads **`SERVING.DEMO`** ([`SCHEMA_RULES.md`](../rules/SCHEMA_RULES.md) enforcement §6).

### B3. Reconciliation (optional but recommended)

- [ ] **Alex:** Pilot A style — rowcount / key overlap vs concept (see `scripts/sql/validation/feature_rent_market_spine_vs_concept_reconciliation.sql` pattern).

### B4. Exit criteria (Phase B)

- [ ] `dbt run --select path:models/analytics/feature` — **SUCCESS** for touched nodes.
- [ ] `dbt test --select path:models/analytics/feature` — **PASS**.

---

## 4. Phase C — Catalog and metric registration (`REFERENCE.CATALOG`)

**Goal:** Only **measurable** columns registered; **four gates** before `active` ([`ARCHITECTURE_RULES.md`](../rules/ARCHITECTURE_RULES.md) §Metric Registration Gates).

### C1. Seeds and gates

- [ ] **Alex:** Edit **`seeds/reference/catalog/metric.csv`** (and bridges) only in this repo — not a second copy elsewhere.
- [ ] **Alex:** Per metric: **>80% non-null**, **≥12 months history**, **`geo_level_code` / `frequency_code` / `concept_code` / `vendor_code`** valid, **≥95%** join to census spine when applicable.
- [ ] **Alex:** Run `dbt build --select path:seeds/reference/catalog` after CSV edits.

### C2. Lineage QA

- [ ] **DE:** `dbt run --select qa_catalog_metric_transform_dev_lineage` — **`qa_status = 'OK'`** for active rows you promote.
- [ ] **Alex:** Re-run §1e SQL after DDL or `table_path` changes.

### C3. Prioritization

- [ ] **Alex:** Pull next **`MET_*` / `MDV_*`** work from [`METRIC_BUILD_BACKLOG_BY_CONCEPT.md`](./METRIC_BUILD_BACKLOG_BY_CONCEPT.md) and [`CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md`](./CONCEPT_VENDOR_METRIC_INTEGRATION_BACKLOG.md).

### C4. Exit criteria (Phase C)

- [ ] Catalog tests pass; §1e / §1f clean for in-scope `table_path` rows.

---

## 5. Phase D — CI/CD and change control

- [ ] **DE:** Merge gate — `dbt parse` (e.g. target `parse` in CI profile).
- [ ] **DE:** Scheduled job — `dbt build` on agreed selectors (`path:models/transform/dev/concept`, `path:models/analytics/feature`, catalog seeds) when Snowflake secrets available.
- [ ] **Alex:** Grain or vendor mix change — file ADR using [`ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md`](./ADR_TEMPLATE_CATALOG_GRAIN_CHANGE.md).

---

## 6. Phase E — Serving (optional, after B + C stable)

- [ ] **Alex:** `dbt run --select path:models/serving/demo` — see [`SERVING_DEMO_ICEBERG_TARGETS.md`](../reference/SERVING_DEMO_ICEBERG_TARGETS.md).
- [ ] **Spencer + Alex:** Any **`SERVING.MART`** / prod delivery stays governed by matrix rows Jon/Spencer own — do not bypass **`REFERENCE.CATALOG`** token rules.

---

## 7. Quick command reference

```bash
# Concepts
dbt run  --select path:models/transform/dev/concept
dbt test --select path:models/transform/dev/concept

# Features (ML prep belongs here)
dbt run  --select path:models/analytics/feature
dbt test --select path:models/analytics/feature

# Catalog
dbt build --select path:seeds/reference/catalog
```

Full sequencing and Snowflake preflight: [`QA_METRIC_LAYER_VALIDATION.md`](./QA_METRIC_LAYER_VALIDATION.md).

---

## 8. Changelog

| Version | Date | Notes |
|---------|------|--------|
| 0.1 | 2026-04-20 | Initial runbook: owners, audience, CONCEPT vs FEATURE (PPSF vs PCA), phased checklists, links to QA and architecture rules. |
