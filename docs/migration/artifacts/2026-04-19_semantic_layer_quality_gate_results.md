# Semantic layer quality gate results (batch 021)

**Date:** 2026-04-19  
**Project:** pretiumdata-dbt-semantic-layer (inner dbt root)

## dbt — `path:seeds/reference/catalog`

| Command | Result |
|--------|--------|
| `dbt test --select path:seeds/reference/catalog` | **PASS** — **801** data tests + project hooks (**803** nodes), **0** errors (run on `target=dev`). |

## dbt — parse + catalog listing (CI-equivalent)

| Command | Result |
|--------|--------|
| `DBT_PROFILES_DIR=ci dbt parse` | **PASS** (placeholder Snowflake profile target **`parse`** — no warehouse use). |
| `scripts/ci/run_catalog_quality_checks.sh` | **PASS** — `dbt deps`, `dbt parse`, `dbt ls --select path:seeds/reference/catalog --resource-type seed`. |

## Snowflake — `scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`

Each line: `check_name` → `failure_rows`.

| Check | failure_rows |
|-------|-------------:|
| CATALOG:dataset.vendor_code missing in vendor | 0 |
| CATALOG:dataset.concept_code missing in concept | 0 |
| CATALOG:dataset.geo_level_code missing in geo_level | 0 |
| CATALOG:dataset.frequency_code missing in frequency | 0 |
| CATALOG:metric.concept_code missing in concept | 0 |
| CATALOG:metric.vendor_code missing in vendor | 0 |
| CATALOG:metric.geo_level_code missing in geo_level | 0 |
| CATALOG:metric.frequency_code missing in frequency | 0 |
| CATALOG:vendor.refresh_cadence missing in frequency | 0 |
| GEOGRAPHY:level_dictionary.canonical_geo_level_code missing in geo_level | 0 |
| GEOGRAPHY:index rows with GEO_LEVEL_CODE = unmapped | **64145** |
| GEOGRAPHY:index.GEO_LEVEL_CODE missing in catalog geo_level | 0 |

Per **`METRIC_INTAKE_CHECKLIST.md` §4**, the **`unmapped`** count is a **crosswalk backlog signal**, not a hard catalog FK failure.
