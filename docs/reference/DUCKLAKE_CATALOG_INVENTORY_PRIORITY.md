# Duck Lake (`pretium_s3`) + **REFERENCE.CATALOG** — priority inventory

**Purpose:** One place to list (1) **Snowflake `REFERENCE.CATALOG`** objects this repo must keep healthy for governance and CI, and (2) which of those (plus a few thin derivatives) should eventually be **registered in the Duck Lake / MotherDuck read path** (`pretium_s3` share) for low-cost, read-only analytics.

**Framing (cost, catalog pattern):** [PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md](./PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md)  
**Seed load order:** [CATALOG_SEED_ORDER.md](../CATALOG_SEED_ORDER.md)  
**Wishlist → build order (WL_020 / 047 / 048, tiers):** [CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md](./CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md)

---

## P0 — Snowflake catalog inventory (must be present for spine + CI)

These seeds are **authoritative in Snowflake** when you run `dbt seed --target reference --select path:seeds/reference/catalog` (respect **waves** in `CATALOG_SEED_ORDER.md` so FK seeds do not fail).

| Priority | Seed / object | Role |
|----------|----------------|------|
| P0.1 | **Wave 1** — `vertical`, `frequency`, `geo_level`, `data_status`, `metric_category`, … | Dimension tokens used everywhere (`data_status_code`, FK targets). |
| P0.2 | **Wave 2** — `concept`, `function`, `model_type`, `estimate_type`, `product_type`, … | **`bridge_product_type_metric`** and **`metric_derived`** FK parents. |
| P0.3 | **Wave 6** — `vendor`, `dataset`, **`metric`** | Vendor × dataset × observable measure registry (`MET_*`). |
| P0.4 | **`bridge_product_type_metric`** | Product-type ↔ `metric_code` applicability (**WL_020**); `dbt test --select bridge_product_type_metric` is the smoke many PRs run. |
| P0.5 | **`metric_derived`** | Analytics-layer registry (`FEATURE_*` / `MODEL_*` / `ESTIMATE_*`); load **after** `metric` (Wave 6c). **CSV rule:** each row must have exactly **14** columns; empty optional codes use consecutive commas with **no** extra comma between `estimate_type_code` and `concept_code` (see `MDV_003` row pattern: `estimate,,,lower,,rent,…`). |
| P0.6 | **`catalog_wishlist`** | Backlog metadata (optional for lake; keep in Snowflake for governance). Depends on `concept` + `metric` for typed columns. |

**Not P0 for minimal lake slice:** the long tail of tier / band dimensions (Waves 3–5) — still required for **full** `dbt seed` of `path:seeds/reference/catalog`, but a **Duck Lake v0** export can omit them until a notebook needs a specific tier.

---

## P1 — Duck Lake / share — objects to register (read-only consumer contract)

Per [PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md](./PRETIUM_S3_DUCKLAKE_CLAUDE_SCOPE.md): expose **small, pre-materialized, partition-friendly** tables so MotherDuck / Claude can join **without** scanning all of **`TRANSFORM.DEV`**.

| Register in Duck Lake (v0) | Rationale |
|----------------------------|-----------|
| **`REFERENCE.CATALOG`** copies of P0.1–P0.4 seeds (dimensions + `metric` + `bridge_product_type_metric`) | Stable vocabulary for filters and joins off-Snowflake. |
| **`metric_derived`** | Documents which analytics outputs exist; small row count. |
| **`catalog_wishlist`** (optional) | Roadmap context for humans/agents; small. |
| **Thin mart / feature exports** (future) | e.g. partitioned Parquet/Iceberg for **`concept_rent_market_monthly`**, **`feature_rent_market_monthly_spine`** — only after an explicit export pipeline; **not** implied by `dbt seed` alone. |

**Do not** default-export full **`TRANSFORM.DEV.FACT_*`** tables to Duck Lake: volume and cost dominate; export **curated slices** (corridor hex, county panels) per product decision, with lineage in `registry/lineage/` where applicable.

**Polaris / Iceberg (WL_041+):** When **R0–R2** land, add **`REFERENCE.GEO`** / calendar spine tables the program names to this inventory and to the share allowlist in the same change as the Snowflake object.

**`SERVING.DEMO` (Alex rows 81–83):** For the dev-only delivery matrix, proposed Iceberg/Parquet objects, explicit gaps (no `models/serving/` yet, no Iceberg plumbing in-repo), and a **two-table first slice** (`demo_concept_rent_market_monthly` + `demo_catalog_bridge_pack`), see [**SERVING_DEMO_ICEBERG_TARGETS.md**](./SERVING_DEMO_ICEBERG_TARGETS.md). For population-list slugs vs **`metric` / `metric_derived`**, see [**SERVING_DEMO_METRICS_CATALOG_MAP.md**](./SERVING_DEMO_METRICS_CATALOG_MAP.md).

---

## Validation (local / CI)

```bash
cd pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer
dbt seed --target reference --select path:seeds/reference/catalog
dbt test --target reference --select bridge_product_type_metric metric_derived
```

---

## Related

- [SERVING_DEMO_ICEBERG_TARGETS.md](./SERVING_DEMO_ICEBERG_TARGETS.md) — `SERVING.DEMO` matrix, targets, gaps  
- [SERVING_DEMO_METRICS_CATALOG_MAP.md](./SERVING_DEMO_METRICS_CATALOG_MAP.md) — population metrics vs `REFERENCE.CATALOG`  
- [CATALOG_METRIC_DERIVED_LAYOUT.md](./CATALOG_METRIC_DERIVED_LAYOUT.md)  
- [QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md](../migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md) (FACT ↔ `metric` in Snowflake)
