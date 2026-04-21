# Pipeline status vocabulary (index)

**Owner:** Alex  
**Status:** **index** — dataset lifecycle and readiness live in migration + catalog artifacts, not a standalone `pipeline_status` prose file.

## Where status is recorded

| Topic | Document / artifact |
|-------|------------------------|
| **Vendor / dataset / metric registry** | [migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md](./migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md) |
| **Task-level readiness (`T-*`)** | [migration/MIGRATION_TASKS.md](./migration/MIGRATION_TASKS.md) |
| **Catalog backlog / blocked** | [reference/CATALOG_WISHLIST.md](./reference/CATALOG_WISHLIST.md) |
| **Landing compliance snapshots** | Inner project `registry/LANDING_COMPLIANCE_INVENTORY.yml` (see [registry/README.md](../registry/README.md)) |

If a seed or table named `pipeline_status` is introduced later, document it in **MIGRATION_REGISTRY** and link here.
