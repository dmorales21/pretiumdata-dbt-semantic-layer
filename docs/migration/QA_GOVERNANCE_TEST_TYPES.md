# QA governance test types (**GOV_***) — taxonomy only (no `REFERENCE.CATALOG` change)

**Purpose:** Name the **categories of QA / validation tests** to implement against metrics, facts, concepts, and analytics models. This is **documentation + test-design vocabulary** only — **not** new seeds, tables, or foreign keys in **`REFERENCE.CATALOG`**.

**Where tests live:** `dbt test` on `models/` and `seeds/`, singular SQL under `tests/`, and Snowflake scripts under `scripts/sql/validation/`. Layered run order: [QA_METRIC_LAYER_VALIDATION.md](./QA_METRIC_LAYER_VALIDATION.md).

---

## Taxonomy (id → name → domain → description)

| Taxon id | Taxon name | Domain id | Description |
|----------|------------|-----------|-------------|
| **GOV_QUALITY** | Quality | GOVERNANCE | Statistical quality: confidence intervals, standard errors, cross-vendor correlation, outlier detection, imputation quality, time-series consistency. |
| **GOV_REFERENCE** | Reference | GOVERNANCE | Reference standards: geographic crosswalks, product-type taxonomies, **metric definitions**, canonical IDs (CBSA, FIPS, ZIP), data dictionary governance. |
| **GOV_BIAS** | Bias | GOVERNANCE | Systematic measurement error: selection bias, survivorship bias, reporting-lag mismatch, seasonal adjustment quality, sampling bias, hedonic / vendor adjustment validity. |
| **GOV_ACCESS** | Access | GOVERNANCE | Data availability: API uptime, update frequency, delivery lag, historical depth, geographic granularity, subscription terms, access mode (REST, GraphQL, Snowflake shares). |
| **GOV_LINEAGE** | Lineage | GOVERNANCE | Provenance: source systems, transformation logic, ETL steps, version control, schema evolution, dependency chains from raw landings to analytical views. |
| **GOV_COVERAGE** | Coverage | GOVERNANCE | Geographic and temporal completeness: market coverage (metros, ZIPs), property-type coverage, series depth, missing-data patterns, sample representativeness. |

---

## Mapping — test **examples** by type (implement as dbt / Snowflake, not as catalog rows)

| Type | Typical artifacts |
|------|---------------------|
| **GOV_QUALITY** | Generic `accepted_range`, `dbt_expectations` or singular SQL on variance / jump detection; multi-vendor reconciliation queries for **`concept_*`** unions. |
| **GOV_REFERENCE** | `relationships` tests on seeds; **`qa_transform_dev_catalog_metric_table_paths.sql`**; geography join-rate scripts; **`METRIC_INTAKE_CHECKLIST`** gates; **[QA_METRIC_LAYER_VALIDATION.md §0.1](./QA_METRIC_LAYER_VALIDATION.md#geo-xwalks)** (**REFERENCE.GEOGRAPHY** *GEO1_GEO2* xwalks). |
| **GOV_BIAS** | Vendor A vs B rollups; lag alignment tests; document seasonal flags in YAML. |
| **GOV_ACCESS** | `SELECT 1` / inventory SQL before builds; **`dataset.csv`** / vendor docs for lag and depth. |
| **GOV_LINEAGE** | **`metric.table_path`** ↔ built object; **`registry/lineage/*.yml`**; **`QA_CATALOG_METRIC_TRANSFORM_DEV_LINEAGE`**. |
| **GOV_COVERAGE** | Preflight on **`REFERENCE.GEOGRAPHY`** xwalks; rowcount / `equal_rowcount` warn tests vs legacy; **`ARCHITECTURE_RULES`** census compliance; **[QA_METRIC_LAYER_VALIDATION.md §0.1](./QA_METRIC_LAYER_VALIDATION.md#geo-xwalks)**. |

Tagging in YAML (optional): add a list field in test `meta` such as `meta.gov_test_types: ['GOV_QUALITY', 'GOV_REFERENCE']` when you want traceability in docs or future reporting — still **no** catalog seed.

**Schema `data_tests` shape (dbt ≥1.5):** each list entry must be a dict with **exactly one** top-level key (the test name, e.g. `dbt_utils.equal_rowcount`). Put `config:` **inside** that block next to `compare_model` / `expression`, not as a sibling key — otherwise parse fails with *“test definition dictionary must have exactly one key”*.

---

## Changelog

| Version | Notes |
|---------|--------|
| **0.1** | Initial taxonomy doc; replaces withdrawn **`governance_*`** catalog seeds. |
| **0.2** | **GOV_REFERENCE** / **GOV_COVERAGE** mapping rows link **[QA_METRIC_LAYER_VALIDATION.md §0.1](./QA_METRIC_LAYER_VALIDATION.md#geo-xwalks)**. |
