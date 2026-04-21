# Vendor onboarding roadmap + planned analytic / validation studies

## Part A — Vendor onboarding (priority queue)

**Source of truth for status:** [`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md) (`pending` / `in_progress` / `migrated` / `blocked`).

**Registry of clusters + checklists:** [`../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`](../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md) §2.

### A.1 High-touch vendor themes (explicit `T-*` + migration doc)

These have **dedicated** `MIGRATION_TASKS_*.md` files and are typical surge candidates:

| Theme | Representative tasks | Checklist |
|-------|------------------------|-----------|
| ApartmentIQ + Yardi Matrix | `T-VENDOR-APARTMENTIQ-READY`, `T-VENDOR-YARDI-MATRIX-READY` | [`../migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md`](../migration/MIGRATION_TASKS_APARTMENTIQ_YARDI_MATRIX.md) |
| Yardi operational (BH / Progress) | `T-VENDOR-YARDI-READY` | [`../migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md`](../migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md) |
| First Street + RCA / MSCI | `T-VENDOR-FIRST-STREET-READY`, `T-VENDOR-RCA-READY` | [`../migration/MIGRATION_TASKS_FIRST_STREET_RCA.md`](../migration/MIGRATION_TASKS_FIRST_STREET_RCA.md) |
| CoStar | `T-VENDOR-COSTAR-READY` | [`../migration/MIGRATION_TASKS_COSTAR.md`](../migration/MIGRATION_TASKS_COSTAR.md) |
| Cherre | `T-VENDOR-CHERRE-READY` (+ corridor) | [`../migration/MIGRATION_TASKS_CHERRE.md`](../migration/MIGRATION_TASKS_CHERRE.md) |
| Redfin + Stanford SEDA | `T-VENDOR-REDFIN-READY`, `T-VENDOR-STANFORD-READY` | [`../migration/MIGRATION_TASKS_STANFORD_REDFIN.md`](../migration/MIGRATION_TASKS_STANFORD_REDFIN.md) |
| BPS / Census ACS5 / BLS / LODES | `T-TRANSFORM-BPS-*`, `T-TRANSFORM-CENSUS-*`, … | [`../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md`](../migration/MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md) |
| Corridor pipeline | `T-CORRIDOR-*` | [`../migration/MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md`](../migration/MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md) |
| Cybersyn (SOURCE_SNOW / GLOBAL_GOVERNMENT) | `T-CYBERSYN-*` / matrix tasks | [`../migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md`](../migration/MIGRATION_TASKS_CYBERSYN_SOURCE_SNOW.md), [`../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`](../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md) |
| Zillow (research FACTs, SOURCE_PROD path) | `T-*` in Zillow doc | [`../migration/MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md`](../migration/MIGRATION_TASKS_ZILLOW_TRANSFORM_DEV.md) |

### A.2 Bulk “everything else” path

- **2,129** model paths in pretium-ai-dbt inventory (2026-04-19 snapshot in [`../migration/MIGRATION_TASKS.md`](../migration/MIGRATION_TASKS.md)) — use `MIGRATION_TASKS_INVENTORY_models.txt` for scoping.
- Wave-style fact gap queue: [`../migration/MIGRATION_FACT_GAP_WAVE_QUEUE.md`](../migration/MIGRATION_FACT_GAP_WAVE_QUEUE.md).

### A.3 Vendor context hub (methodology + dictionaries)

Per-vendor narrative and CSV/YAML dictionaries: [`../vendor/vendors.md`](../vendor/vendors.md) and [`../vendor/0_inventory/`](../vendor/0_inventory/).

---

## Part B — Planned studies (validation, governance, analytics)

These are **engineering and DS studies** (tests, audits, reconciliations) — not product roadmap epics. They map to the **GOV_*** taxonomy in [`../migration/QA_GOVERNANCE_TEST_TYPES.md`](../migration/QA_GOVERNANCE_TEST_TYPES.md).

### B.1 Catalog and metric integrity

| Study | Doc / artifact |
|-------|----------------|
| Metric layer validation (including geo xwalks) | [`../migration/QA_METRIC_LAYER_VALIDATION.md`](../migration/QA_METRIC_LAYER_VALIDATION.md) |
| Transform DEV objects vs catalog registrations | [`../migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md`](../migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md) |
| Metric intake gates (null %, history, geo compliance) | [`../migration/METRIC_INTAKE_CHECKLIST.md`](../migration/METRIC_INTAKE_CHECKLIST.md) |

### B.2 Feature / model statistical QA (implemented or planned in `QA_*`)

Representative `models/analytics/qa/` themes (run against STAGE targets per project policy):

- **Concept ↔ feature parity** — `qa_feature_concept_parity_diff.sql`, `qa_feature_concept_alignment.sql`
- **Collinearity / series collision** — `qa_cross_feature_collinearity_rent.sql`, `qa_series_collision_detection.sql`
- **Geography sensitivity / cold start** — `qa_geo_rollup_sensitivity_rent_zillow.sql`, `qa_cold_start_geo_report.sql`
- **Distribution shift / structural breaks** — `qa_distribution_shift_monitor_rent.sql`, `qa_structural_break_detection_rent_zillow_cbsa.sql`
- **Vendor blend ablation** — `qa_vendor_blend_ablation_rent.sql`

Use these as **templates** when onboarding new vendors into shared **CONCEPT_** spines.

### B.3 Cross-cutting migration studies

| Study | Doc |
|-------|-----|
| Vendor × concept coverage | [`../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md`](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) |
| Sources YAML gap analysis | [`../migration/MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md`](../migration/MIGRATION_TASKS_SOURCES_GAP_ANALYSIS.md) |
| Polaris / Iceberg population order | [`../migration/MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md`](../migration/MIGRATION_TASKS_POLARIS_DATASET_PRIORITIES.md) |
| Strata backend lineage | [`../migration/MIGRATION_TASKS_STRATA_BACKEND_LINEAGE.md`](../migration/MIGRATION_TASKS_STRATA_BACKEND_LINEAGE.md) |
| Tearsheet service objects | [`../migration/MIGRATION_TASKS_TEARSHEET_SERVICE.md`](../migration/MIGRATION_TASKS_TEARSHEET_SERVICE.md) |

### B.4 Labor / automation risk stack (example of end-to-end semantic slice)

Runbook + semantic stack: [`../migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`](../migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md), repo runbook [`../runbooks/RUN_LABOR_AUTOMATION_RISK_STACK_DBT.md`](../runbooks/RUN_LABOR_AUTOMATION_RISK_STACK_DBT.md).

---

## Part C — How to use this during the surge

1. **Pick a vendor cluster** from Part A → open its **`MIGRATION_TASKS_*.md`** → run listed inventory SQL → update **`MIGRATION_LOG.md`** on exit.
2. **Pair each FACT wave** with at least one **GOV_*** study (coverage, lineage, or quality) from Part B so merges carry evidence.
3. **Do not** mark **`T-*`** `migrated` without catalog alignment when metrics are in scope — see **`T-CATALOG-METRIC-VENDOR-ROLLOUT`**.
