# Vendor context hub

**Purpose:** One folder per **`vendor_code`** in **`seeds/reference/catalog/vendor.csv`**. Each vendor has:

| File | Role |
|------|------|
| **`{vendor_code}/{vendor_code}.md`** | Text methodology: scope, grain, read paths (`TRANSFORM` vs `RAW` / shares), catalog alignment, links to migration tasks. |
| **`{vendor_code}/dictionary.csv`** | Tabular field / metric dictionary (extend as `DESCRIBE` / lineage work completes). |
| **`{vendor_code}/dictionary.yaml`** | Structured metadata: vendor ids, default grains, `source()` families, links to seeds. |

**Intake mirror (column inventory + long-form guidance):** [`../vendors/`](../vendors/) — one `vendor_metrics.csv` + `vendor_guidance.md` per vendor, regenerated from pretium-ai-dbt `metric.csv` where available (`python3 scripts/docs/generate_all_vendors_intake_full.py`). **`zillow`** there is hand-curated and skipped by the script.

**Machine-readable inventory (all vendors):** [`0_inventory/`](./0_inventory/) — `vendors_inventory.csv`, `vendors_inventory.yaml`, and `README.md`.

**Canonical registry:** Do not invent vendor codes here; **`vendor.csv`** is the source of truth. Regenerate per-vendor stubs after seed changes:

```bash
cd pretiumdata-dbt-semantic-layer
python3 scripts/docs/generate_vendor_context_from_seed.py
```

**Cross-vendor analysis:** [migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md), [migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md](../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md).

**Operating rules:** [OPERATING_MODEL.md](../OPERATING_MODEL.md) (who owns Jon silver vs Alex dbt), [migration/MIGRATION_RULES.md](../migration/MIGRATION_RULES.md) (no legacy `*_PROD` in the semantic-layer dbt graph).

## Methodology template (every `{vendor_code}.md`)

Each vendor markdown follows the same sections so agents and humans can compare vendors quickly:

1. **Identity** — `vendor_id`, label, definition (from catalog).
2. **Contract** — `data_type`, `refresh_cadence`, `contract_status`, `source_schema`, `data_share_type`, `vertical_codes`.
3. **Read path** — Prefer **`TRANSFORM.{VENDOR}`** / **`TRANSFORM.FACT`** Jon silver where available; else **`RAW.*`**, **`SOURCE_ENTITY.*`**, **`SOURCE_SNOW.*`** per `source_schema` and [migration/MIGRATION_BASELINE_RAW_TRANSFORM.md](../migration/MIGRATION_BASELINE_RAW_TRANSFORM.md).
4. **Grain & concepts** — Typical geo/time grains; primary `concept_code` links (see coverage matrix).
5. **Catalog** — `dataset.csv` / `metric.csv` rows; `MET_*` registration and `bridge_product_type_metric` when FACT paths exist.
6. **dbt** — `models/sources/*.yml` entries and `models/transform/dev/**` fact read-throughs (this repo).
7. **Migration & QA** — Primary task doc link when present; otherwise matrix + registry.
8. **Dictionary** — Pointers to `dictionary.csv` / `dictionary.yaml`; fill rows as columns are inventoried.

## Folder index

Generated vendor folders are listed under **[`0_inventory/vendors_inventory.csv`](./0_inventory/vendors_inventory.csv)** (`docs_subpath` column). For a flat A–Z list, sort by `vendor_code` in that file.
