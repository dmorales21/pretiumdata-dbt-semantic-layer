# Vendor inventory (`0_inventory`)

**Purpose:** Single place to see **all** catalog vendors and where their human + machine-readable context lives.

| File | Format | Use |
|------|--------|-----|
| **`vendors_inventory.csv`** | CSV | Spreadsheets, DuckDB, quick filters; includes `docs_subpath` → `docs/vendor/{vendor_code}/`. |
| **`vendors_inventory.yaml`** | YAML | Agents, CI, or codegen that need structured vendor lists. |

**Source of truth for columns** (except `docs_subpath`, `primary_migration_doc`, `notes`):  
`pretiumdata-dbt-semantic-layer/seeds/reference/catalog/vendor.csv`

**Regenerate** after editing `vendor.csv`:

```bash
python3 scripts/docs/generate_vendor_context_from_seed.py
```

The script refreshes this inventory and ensures each `docs/vendor/{vendor_code}/` folder has `{vendor_code}.md`, `dictionary.csv`, and `dictionary.yaml`.
