# Fund IV comps / pricing API — **data** underpinning (no `CONCEPT_*` requirement)

**Scope:** Physical Snowflake (and Progress sources) coverage for `fund4_comps_pricing_api_spec.md` (Cherre comps, county AVM context, subject disposition, Parcl, Markerr, cycle inputs). **Objects** = optional; this checklist is **row‑level / table‑level** readiness.

**Vet script:** `scripts/sql/validation/fund4_pricing_api_data_presence.sql` (edit FQNs; run with `snowsql`).

---

## Summary

| Area | Ready in semantic-layer repo? | Physical data likely? | Action |
|------|--------------------------------|-------------------------|--------|
| **Cherre CBSA/MA AVM aggregates** | **Yes** — `cherre_avm_geo_stats` passthrough over `TRANSFORM.CHERRE.USA_AVM_GEO_STATS` | If Dynamic Table exists | Grants + `dbt run -s cherre_avm_geo_stats` |
| **Cherre county AVM monthly** (median/p25/p75, parcel_count, …) | **Catalog only** — `metric.csv` points at `TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY`; **no `models/transform/dev/cherre/fact_cherre_avm_county_monthly.sql` here** | Unknown until Snowflake `DESCRIBE` / rowcount | **DE:** materialize table/view **or** add dbt passthrough when upstream exists; **IC:** remove / defer `MET_*` if object absent |
| **Cherre IHPM parcel universe** (comps, lat/lon, confidence, last sale) | **No** — not in `sources_cherre_transform.yml` | Spec: `EDW_PROD.DELIVERY.V_CHERRE_IHPM_PROPERTY` | **DE:** grant + optional `TRANSFORM.DEV` read‑through view; **do not** assume `TRANSFORM.CHERRE` has parcel IHPM without inventory |
| **Subject disposition “yield property”** (tribeca, rent, AVM, BPO, geo) | **Partial** — `SOURCE_ENTITY.PROGRESS` + `fact_sfdc_disposition_c` / BPO facts when var enabled; **not** the full `V_IC_DISPOSITION_YIELD_PROPERTY` join | Spec assumes EDW IC view | **DE:** expose same columns via **delivery view clone** in `TRANSFORM.DEV` **or** warehouse grants to EDW view |
| **Markerr rent (CBSA MF, bed buckets for API logic)** | **Yes** — `fact_markerr_rent_property_cbsa_monthly` + `fact_markerr_rent_sfr` feed `concept_rent_market_monthly` | If `TRANSFORM.MARKERR.*` visible | Grants + Markerr pipeline |
| **Zillow / listings / home price / transactions** (market context) | **Yes** — existing `FACT_*` + concepts in repo | If silver loaded | Standard transform dev runs |
| **Parcl Labs** (indices, comps, motivated sellers) | **Vendor docs + catalog datasets**; **no Parcl `FACT_*` in this repo** | Spec: **MCP / API** | **Default:** API‑only (no Snowflake requirement). **Optional:** land `SOURCE_PROD.PARCLLABS` / transform facts (see pretium‑ai‑dbt inventory) if product wants SQL joins |
| **Redfin “cycle”** (MOS, DOM, list/sale) | **Stub in `concept_avm_market_monthly`**; cycle endpoint may live outside this repo | Spec references **ANALYTICS** market‑cycle | **IC:** confirm which table/view backs `/market-cycle`; wire grants |

---

## Detailed matrix (spec → data)

| Spec need | Minimal columns / grain | Canonical location (today) | Gap |
|-----------|-------------------------|------------------------------|-----|
| Subject for comps / pricing | `TRIBECA_NUMBER`, geo, beds, sqft, yr, `MONTHLY_RENT`, `VALUATION_AVM`, BPO fields | `EDW_PROD.DELIVERY.V_IC_DISPOSITION_YIELD_PROPERTY` (spec) | Not modeled in this repo; Progress raw ≠ IC mart |
| Cherre subject enrichment | Join ZIP/state/bed/sqft → IHPM | `V_CHERRE_IHPM_PROPERTY` | No dbt source in this repo |
| Cherre comps radius | Parcel lat/lon, AVM, confidence, filters | `V_CHERRE_IHPM_PROPERTY` | Same |
| Cherre county AVM panel | county FIPS, month, p25/p50/p75, parcel_count, confidence, assessed ratio | `ANALYTICS.FACTS.CHERRE_AVM_COUNTY_MONTHLY` (spec) vs **`TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY`** (catalog) | **Resolve FQN** with DE; ensure latest `AVM_MONTH` row per county |
| Parcl ZIP market | `parcl_id`, indices, events | MCP / CSV downloads | Snowflake optional |
| Markerr 3BR/4BR P50 | CBSA × month × bedroom | `RENT_PROPERTY_CBSA_MONTHLY` (+ SFR if used) | API must pick columns / CBSA join |
| Consensus / list band inputs | MOS, DOM, sale‑to‑list | Redfin / internal cycle mart | Confirm non‑stub source for Fund IV geography |

---

## Catalog integrity note

Several **`MET_*`** rows already register **`TRANSFORM.DEV.FACT_CHERRE_AVM_COUNTY_MONTHLY`** (`metric.csv`, Cherre FAM rows). If Snowflake has **no** such relation, those registrations are **false positives** — run `scripts/sql/validation/catalog_metric_registration_coverage.sql` (when enabled) and fix `table_path` or build the fact.

---

## Changelog

| Ver | Date | Notes |
|-----|------|--------|
| 0.1 | 2026-04-20 | Initial data underpinning matrix + vet script path. |
