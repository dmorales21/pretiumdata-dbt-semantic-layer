# Catalog Seed Order
# REFERENCE.CATALOG seed wave order — must be respected to avoid FK failures
# Run: dbt seed --target reference --select reference.catalog.<table>

## Wave 1 — core dimensions + consolidated enum source (no FK dependencies)

**`catalog_enum_source`** replaces ~57 separate small-enum CSV seeds (tiers, types, statuses). Regenerate
from split CSVs only when restoring historical files from git — see
`scripts/reference/catalog/build_catalog_enum_source_seed.py`.

```bash
dbt seed --target reference --select \
  reference.catalog.vertical \
  reference.catalog.domain \
  reference.catalog.frequency \
  reference.catalog.geo_level \
  reference.catalog.unit \
  reference.catalog.asset_type \
  reference.catalog.tenant_type \
  reference.catalog.catalog_enum_source
```

## Wave 2 — depend on Wave 1 (includes **`domain`** before **`concept`**)

```bash
dbt seed --target reference --select \
  reference.catalog.product_type \
  reference.catalog.bedroom_type \
  reference.catalog.bridge_product_type_bedroom_type \
  reference.catalog.concept \
  reference.catalog.concept_geo_level \
  reference.catalog.concept_frequency \
  reference.catalog.concept_vertical \
  reference.catalog.concept_explanation
```

After editing **bridge_product_type_bedroom_type.csv**, refresh the legacy comma field:

`python3 scripts/reference/catalog/sync_product_type_bedroom_codes_from_bridge.py`

## Wave 3 — opco

```bash
dbt seed --target reference --select reference.catalog.opco
```

## Wave 4 — business_team

```bash
dbt seed --target reference --select reference.catalog.business_team
```

## Wave 6 — manual population required first
# Populate vendor.csv, dataset.csv, metric_raw.csv before running
# **Built metric:** run `python3 scripts/reference/catalog/build_metric_csv_from_metric_raw.py`
# so `metric.csv` exists (CI runs this before `dbt parse`). Then seed raw + built:
dbt seed --target reference --select reference.catalog.vendor
dbt seed --target reference --select reference.catalog.dataset
# **dataset_product_type** is the authoring source for product-type scope. Refresh the legacy
# **dataset.product_type_codes** comma field from the bridge (do not hand-edit that column):
#   python3 scripts/reference/catalog/sync_dataset_product_type_from_bridge.py
# First time adding **product_type_codes** / fixing bridge types on Snowflake:
#   dbt seed --full-refresh --target reference --select reference.catalog.dataset reference.catalog.dataset_product_type
dbt seed --target reference --select \
  reference.catalog.dataset_product_type \
  reference.catalog.dataset_vertical
# If **`relationships`** on the bridges fail** (dataset_code not found on **`dataset`**), Snowflake
# **`REFERENCE.CATALOG.DATASET`** is usually out of sync with git — full-refresh **`dataset`** and both
# bridges in one go: `dbt seed --full-refresh --target reference --select reference.catalog.dataset
# reference.catalog.dataset_product_type reference.catalog.dataset_vertical`. See **`docs/vendors/README.md`**.
dbt seed --target reference --select reference.catalog.metric_raw
dbt seed --target reference --select reference.catalog.metric

## Wave 6c — `metric_derived` (depends on Wave 2 + Wave 6 `metric`)

Register **analytics-layer** logical metrics (`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`). Load **after** `metric` so optional `primary_metric_code` FK resolves.

```bash
dbt seed --target reference --select reference.catalog.metric_derived
```

Layout and column semantics: [`reference/CATALOG_METRIC_DERIVED_LAYOUT.md`](./reference/CATALOG_METRIC_DERIVED_LAYOUT.md).

## Wave 6c-input — `metric_derived_input` (depends on Wave 6 `metric` + Wave 6c `metric_derived`)

N:1 lineage from **`metric_derived`** rows to upstream **`metric`** codes (WL_040).

```bash
dbt seed --target reference --select reference.catalog.metric_derived_input
dbt test --target reference --select metric_derived_input
```

## Wave 6d — `catalog_wishlist` (depends on `concept` + `metric` for dimensional columns)

Backlog rows for concept chains, catalog gaps, and infra — see [`reference/CATALOG_WISHLIST.md`](./reference/CATALOG_WISHLIST.md) and playbook **§P**. Columns **`primary_catalog_concept_code`** and **`primary_catalog_metric_code`** align rows to **`concept.csv`** / **`metric.csv`**; seed **after** Waves 2 and 6 **`metric`** (or full catalog slice) so Snowflake columns type consistently.

```bash
dbt seed --target reference --select reference.catalog.concept reference.catalog.metric reference.catalog.catalog_wishlist
dbt test --target reference --select catalog_wishlist
```

## Wave 6b — Cybersyn GLOBAL_GOVERNMENT `table_name` → agency (depends on `vendor`)

Regenerate CSV when `docs/migration/artifacts/cybersyn_global_government_catalog_table_names.tsv` changes:

```bash
python3 scripts/reference/catalog/regenerate_cybersyn_catalog_table_vendor_map.py
```

Then:

```bash
dbt seed --target reference --select reference.catalog.vendor reference.catalog.cybersyn_catalog_table_vendor_map
dbt test --target reference --select cybersyn_catalog_table_vendor_map
```

Equivalent minimal selects (resource names only): `dbt seed --select vendor cybersyn_catalog_table_vendor_map` then `dbt test --select cybersyn_catalog_table_vendor_map`. Full runbook: [`reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`](./reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md#how-to-run-dataset-tests).

## Wave 7a — offerings (B2B / tearsheet pack; before `concept_offering_weight`)

```bash
dbt seed --target reference --select \
  reference.catalog.offering \
  reference.catalog.bridge_offering_product_type \
  reference.catalog.bridge_offering_asset_type \
  reference.catalog.bridge_tenant_type_offering \
  reference.catalog.bridge_product_type_metric \
  reference.catalog.offering_signal_relevance
```

## Wave 7b — `concept_offering_weight` (depends on `offering` + `concept`)

Numeric Presley routing weights; edit **`offering_concept_weight_matrix.yml`** then regenerate the seed:

```bash
python3 scripts/reference/catalog/sync_concept_offering_weight_from_matrix.py
dbt seed --target reference --select reference.catalog.concept_offering_weight
dbt test --target reference --select concept_offering_weight
```

## MotherDuck / lake freshness stamps on `dataset`

After Iceberg (or other lake) export completes, run **`scripts/sql/reference/catalog/stamp_dataset_motherduck_after_iceberg_export.sql`**
(or fold its `UPDATE` into the same Snowflake Task) so **`is_motherduck_served`** and **`last_refresh_date`** reflect Presley-ready datasets.

Full task trees and portfolio/market stamp hooks: [`reference/AUTO_REFRESH_STRATEGY_BY_CONTENT_TYPE.md`](./reference/AUTO_REFRESH_STRATEGY_BY_CONTENT_TYPE.md).

## Derived catalog table — `ENUM` (unified small enumerations)

After **Wave 1** (including **`catalog_enum_source`**, **`frequency`**, **`asset_type`**, **`tenant_type`**), build **`REFERENCE.CATALOG.ENUM`** from the dbt model **`catalog_enum`** (physical alias **`enum`**):

```bash
dbt run --target reference --select catalog_enum
```

## Run all tests after seeding
dbt test --target reference --select reference.catalog.*
dbt test --target reference --select catalog_enum

## Catalog hard-gate singulars (no warehouse — compile only)

CI runs **`dbt compile --select tag:catalog_hard_gate`** so Q6/Q7/Q11/Q19 blocking tests resolve refs. Locally after Snowflake seed:

```bash
dbt test --target reference --select tag:catalog_hard_gate
```

Selector name: **`catalog_hard_gates`** (see **`selectors.yml`**).

## Enforcement
# - All CATALOG seeds target REFERENCE.CATALOG regardless of dbt target
# - DRAFT seeds target REFERENCE.DRAFT — for Alex's in-progress objects
# - Promotion from DRAFT to CATALOG requires owner approval
# - No object in ANALYTICS or SERVING may use a dimension code
#   that does not have an active row in REFERENCE.CATALOG
