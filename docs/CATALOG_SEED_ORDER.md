# Catalog Seed Order
# REFERENCE.CATALOG seed wave order — must be respected to avoid FK failures
# Run: dbt seed --target reference --select reference.catalog.<table>

## Wave 1 — no FK dependencies
dbt seed --target reference --select \
  reference.catalog.vertical \
  reference.catalog.frequency \
  reference.catalog.geo_level \
  reference.catalog.data_status \
  reference.catalog.metric_category \
  reference.catalog.risk_rating \
  reference.catalog.rate_type

## Wave 2 — depend on Wave 1
dbt seed --target reference --select \
  reference.catalog.product_type \
  reference.catalog.concept \
  reference.catalog.function \
  reference.catalog.model_type \
  reference.catalog.estimate_type \
  reference.catalog.hold_period \
  reference.catalog.exit_strategy \
  reference.catalog.amenity_tier \
  reference.catalog.rent_tier \
  reference.catalog.ltv_tier \
  reference.catalog.market_tier \
  reference.catalog.flood_zone \
  reference.catalog.natural_hazard_type

## Wave 3 — depend on Wave 2
dbt seed --target reference --select \
  reference.catalog.opco \
  reference.catalog.class \
  reference.catalog.investment_strategy \
  reference.catalog.loan_type \
  reference.catalog.score_tier \
  reference.catalog.insurance_type \
  reference.catalog.construction_status \
  reference.catalog.vacancy_tier \
  reference.catalog.cap_rate_tier

## Wave 4 — depend on Wave 3
dbt seed --target reference --select \
  reference.catalog.business_team \
  reference.catalog.geography_status \
  reference.catalog.deal_status \
  reference.catalog.delinquency_bucket \
  reference.catalog.portfolio_size_tier \
  reference.catalog.renovation_type \
  reference.catalog.property_condition

## Wave 5 — no FK dependencies (simple dimension tables)
dbt seed --target reference --select \
  reference.catalog.absorption_tier \
  reference.catalog.bath_type \
  reference.catalog.bedroom_type \
  reference.catalog.crime_tier \
  reference.catalog.dscr_tier \
  reference.catalog.employment_sector \
  reference.catalog.hoa_type \
  reference.catalog.income_band \
  reference.catalog.lease_term \
  reference.catalog.market_cycle_phase \
  reference.catalog.market_status \
  reference.catalog.migration_type \
  reference.catalog.noi_tier \
  reference.catalog.occupancy_status \
  reference.catalog.ownership_type \
  reference.catalog.parking_type \
  reference.catalog.permit_type \
  reference.catalog.population_segment \
  reference.catalog.price_tier \
  reference.catalog.promotion_gate \
  reference.catalog.school_rating_tier \
  reference.catalog.tenancy \
  reference.catalog.transit_score_tier \
  reference.catalog.units_in_structure \
  reference.catalog.utility_type \
  reference.catalog.vintage \
  reference.catalog.walk_score_tier \
  reference.catalog.zoning_type

## Wave 6 — manual population required first
# Populate vendor.csv, dataset.csv, metric.csv before running
dbt seed --target reference --select reference.catalog.vendor
dbt seed --target reference --select reference.catalog.dataset
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

## Run all tests after seeding
dbt test --target reference --select reference.catalog.*

## Enforcement
# - All CATALOG seeds target REFERENCE.CATALOG regardless of dbt target
# - DRAFT seeds target REFERENCE.DRAFT — for Alex's in-progress objects
# - Promotion from DRAFT to CATALOG requires owner approval
# - No object in ANALYTICS or SERVING may use a dimension code
#   that does not have an active row in REFERENCE.CATALOG
