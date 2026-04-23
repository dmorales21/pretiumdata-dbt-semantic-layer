# Vendor intake bundles (`docs/vendors/{vendor_code}/`)

Every **`vendor_code`** in **`seeds/reference/catalog/vendor.csv`** should have the **same two-file shape** here (some vendors have richer narrative + hundreds of metric rows; others are placeholders until intake lands):

| File | Purpose |
|------|---------|
| **`vendor_metrics.csv`** | One row per distinct physical **`(table_path, snowflake_column)`** from **`seeds/reference/catalog/metric.csv`** for that vendor (collapsed from many `metric_id`s on long tables). If there are no metrics yet, a single **TBD** row aligned to **`source_schema`**. Includes **`domain`** derived from **`docs/reference/concepts_by_domain.csv`**. |
| **`vendor_guidance.md`** | Standard headings: identity, contract table, link to **`docs/vendor/{code}/`**, physical metrics summary, sample concept mapping, join/refresh placeholders, changelog. Embeds **`docs/vendor/{code}/{code}.md`** when that file exists; otherwise a **stub** from the vendor seed row. |

**Exceptions:** **`zillow`** is skipped by the generator (preserve hand-curated `docs/vendors/zillow/`).

## Regenerate (this repo)

From repo root (**`pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer`**):

```bash
python3 scripts/docs/generate_all_vendors_intake_full.py
```

The script prefers **`seeds/reference/catalog/metric.csv`** in this repo; if it is missing, it falls back to **`pretium-ai-dbt/dbt/seeds/reference/catalog/metric.csv`** when that clone path exists.

### After adding a new vendor to `vendor.csv`

1. Run the generator (creates **`vendor_metrics.csv`** + stub **`vendor_guidance.md`**).
2. Hand-edit **`vendor_guidance.md`** and optionally add **`docs/vendor/{code}/{code}.md`** for methodology; re-run the generator to refresh the embed and metrics table.

## Source of truth

- **Metric definitions:** `seeds/reference/catalog/metric.csv` (and `metric_raw` / merge scripts as documented in **`docs/reference/METRIC_CSV_BUILD_SPEC.md`**).
- **Vendor metadata:** `seeds/reference/catalog/vendor.csv`.
- **Concept → domain:** `docs/reference/concepts_by_domain.csv`.

## Catalog seed tests (`dataset_*` bridges)

If **`relationships_*`** on **`dataset_product_type`** / **`dataset_vertical`** fail against Snowflake with “missing **`dataset_code`**”, **`REFERENCE.CATALOG.DATASET`** is usually **stale** relative to git (partial seed or old rows). Refresh **`dataset`** and both bridges together, for example:

```bash
dbt seed --full-refresh --target reference --select \
  reference.catalog.dataset \
  reference.catalog.dataset_product_type \
  reference.catalog.dataset_vertical
```
