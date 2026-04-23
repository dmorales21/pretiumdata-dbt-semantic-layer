# Built `metric.csv` from `metric_raw.csv`

**Scripts:** `scripts/reference/catalog/build_metric_csv_from_metric_raw.py`  
**Inputs:** `seeds/reference/catalog/metric_raw.csv` (author hand-edits and bulk sync)  
**Output:** `seeds/reference/catalog/metric.csv` (generated — commit both files)

## Source-of-truth options (A / B / C)

| Path | Description | When |
|------|-------------|------|
| **A — Manifest / codegen** | dbt parse/run → manifest or registry YAML emits MET rows per `FACT_*` contract | Best long-term automation |
| **B — Snowflake** | INFORMATION_SCHEMA / contract tables in Snowflake | Environment-coupled; ops diagnostics |
| **C — Hybrid (default today)** | **TRANSFORM.DEV** `FACT_*` / `CONCEPT_*` registrations from **`metric_raw`** ∪ **FK closure** ∪ optional **`metric_overrides.csv`** | Pragmatic until A is wired |

## Hybrid C — merge rules

1. **Core set:** every raw row whose `table_path` contains **`TRANSFORM.DEV`** and (**`FACT_`** or **`CONCEPT_`**, case-insensitive). This is the **warehouse registration** slice for the transform corridor.
2. **FK closure:** every `metric_code` referenced from:
   - `bridge_product_type_metric.csv`
   - `metric_derived.csv` → `primary_metric_code`
   - `metric_derived_input.csv` → `input_metric_code`
   - `catalog_wishlist.csv` → `primary_catalog_metric_code`  
   must appear in the built file (row copied from raw).
3. **Overrides:** optional `seeds/reference/catalog/metric_overrides.csv` with `metric_code`, `force_include` (`TRUE` / `FALSE`). `TRUE` pulls a row from raw even if not in core; `FALSE` drops a code **unless** still required by step 2 (closure wins).

**Precedence:** closure > exclude override; raw row is the data payload for each `metric_code`.

## CI / local workflow

1. Edit **`metric_raw.csv`** (or `python3 scripts/sync_metric_csv_from_pretium_ai_dbt.py` → writes raw).
2. `python3 scripts/reference/catalog/build_metric_csv_from_metric_raw.py`
3. `dbt parse` / `dbt seed --select metric …` as needed.

GitHub Actions runs the build script **before** `dbt parse` so **`metric.csv`** is present for seed resolution.

## Intake policy

- **`metric_raw`:** backlog, bulk registration, vendor fingerprints, **category errors** (e.g. ACS burden under `concept_code=rent`) — fix before promoting semantics to P0 canonical names.
- **`metric` (built):** what REFERENCE loads; must keep **`metric_code`** **unique** and FK-safe to sibling seeds.

## Related

- Vendor intake: [`../migration/MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md`](../migration/MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md)  
- Seed order: [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md)
