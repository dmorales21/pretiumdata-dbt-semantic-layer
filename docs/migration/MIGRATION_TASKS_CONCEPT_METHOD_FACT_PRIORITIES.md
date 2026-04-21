# FACT-only backlog — concept methods (`registry/concept_methods/*.yml`)

**Owner:** Alex  
**Source of truth (YAML):** `registry/concept_methods/*.yml` in the product / registry repo (machine-grounded inventory Alex pasted into migration planning **2026-04-19**).  
**Governing:** `MIGRATION_RULES.md`, `MIGRATION_TASKS.md`, corridor docs where H3 facts apply.

## Scope (strict)

- **In scope:** `FACT_*` models to **author** in **pretiumdata-dbt-semantic-layer** under `models/transform/dev/**`, materializing to **`TRANSFORM.DEV`** per five-target rules (read upstream via `source()` / `ref()`, no hardcoded vendor FQNs).
- **Out of scope for this document:** `FEATURE_*`, `MODEL_*`, `ref_feature_corridor_*`, macros, and **existing** `transform_prod.fact.*` unions (e.g. `fact_housing_pricing_all_ts`) unless we explicitly open a **port** task — those are **consumer / parity** work, not net-new FACT creation here.

## Alex ↔ agent — cross-repo test gate

After each **task batch** (PR-sized unit of work: new `FACT_*`, new `source()`, or contract change that pretium-ai-dbt might compile against):

1. Agent finishes semantic-layer changes and runs **`dbt build` / `dbt test`** in **pretiumdata-dbt-semantic-layer** as usual.
2. Agent **must ask Alex** to run **`dbt compile` / `dbt build` / `dbt test`** in **pretium-ai-dbt** on the relevant selection (or full slice) so downstream consumers are smoke-tested **before** merge.

*(Recorded in `MIGRATION_LOG.md` batch **006**.)*

---

## Consolidated FACT → CONCEPT priority (cross-tracker)

Single stack reconciling [`CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md`](../reference/CATALOG_WISHLIST_DATA_MODEL_PRIORITIES.md), [`MIGRATION_LAYER2_EXECUTION_TRACKER.md`](./MIGRATION_LAYER2_EXECUTION_TRACKER.md), and **§P** feature readiness. **Lower number = build sooner.**

| Rank | Deliverable | Layer | Why |
|-----:|-------------|-------|-----|
| **1** | Finish **WL_020** open cells (CoStar / Markerr / Yardi Matrix **`metric`** + `bridge_product_type_metric` once matching **`FACT_*`** exist) | Catalog + FACT | Unlocks governed rent / market panels without hand-waving **`MET_*`**. |
| **2** | **`fact_realtor_inventory_cbsa`** + **`feature_supply_pressure_cbsa_monthly`** | FACT → FEATURE | **Shipped** — SOURCE_PROD.REALTOR MSA landing + Layer 2 feature port. Optional: mirror Jon **TRANSFORM.FACT** if silver-only policy wins. |
| **3** | **`feature_home_price_delta_zip_monthly`** from existing **`FACT_ZILLOW_*`** | FEATURE (FACT already in repo) | Layer 2 “next three” #1 — high reuse, clear vendor, no new silver. |
| **4** | **Redfin** cleaned + **`FACT_*`** per **`MIGRATION_TASKS_STANFORD_REDFIN.md`** / **WL_047** | FACT (+ `metric` rows) | Tier 0 wishlist; fills non-Zillow price path for §P. |
| **5** | **Cherre** share smoke + **corridor FACT** inventory (**WL_048**) → **`fact_cherre_mls_h3_r8_monthly`** (P3a) before heavy recorder | FACT | MLS / listings path supports absorption + later **P4** recorder facts. |
| **6** | **`fact_bls_laus_cbsa_monthly`** (T-CMF-P0a) + ADR on `AREA_CODE` vs OMB CBSA | FACT | Completes government labor spine at metro grain for concepts/features. |
| **7** | **LODES hex chain** (**P1a–P1c**) after H3 spine + `fact_lodes_od_bg` stable | FACT | Corridor labor / gravity; feeds **WL_021**-adjacent features without new ontology. |
| **8** | **ACS / income `FACT_*`** (typed county or hex snapshot when **D/E/F** inventory clears) + register **`MET_*`** for **`CON_014` income** | FACT + catalog | Closes the largest gap in [`SERVING_DEMO_METRICS_CATALOG_MAP.md`](../reference/SERVING_DEMO_METRICS_CATALOG_MAP.md) §2–§3 (`median_hh_income`). |
| **9** | **`metric_derived_input`** seed (**WL_040**) then expand **`metric_derived`** for engineered scores | Catalog | Required before large §12 / composite registrations. |
| **10** | **Cherre recorder** + **Zonda** deed facts (**P4a–P4c**) + **`transactions` `concept`** row when promoted | FACT + CONCEPT | Sale volume ontology; **blocked** until product + `concept.csv` intake ([`SERVING_DEMO_METRICS_CATALOG_MAP.md`](../reference/SERVING_DEMO_METRICS_CATALOG_MAP.md) §6). |

**CONCEPT objects (thin unions / marts):** prefer **new `CONCEPT_*` only after** backing **`FACT_*`** and **`metric`** rows exist — keep **`concept_rent_market_monthly`** / **`concept_rent_property_monthly`** healthy first; add **affordability** or **transactions** concepts only when Tier-2 facts above land (see wishlist **WL_004**, **WL_043** for absorption naming). **Registry:** **WL_021** / **WL_022** are **contracts**, not substitutes for FACT build.

---

## Priority tiers (FACT creation order)

Lower **P#** = do sooner, subject to upstream Jon silver / `SOURCE_PROD` availability and corridor geo readiness.

### P0 — Government spine (already started in semantic-layer)

| Priority | `FACT_*` (target name) | Concept bucket | Upstream / notes |
|----------|-------------------------|----------------|------------------|
| P0a | `fact_bls_laus_cbsa_monthly` (or read-through view) | `labor_growth_access` | `TRANSFORM.BLS.LAUS_CBSA` — **Part C:** `AREA_CODE` ≠ OMB CBSA; document-only or thin bridge. |
| P0b | *(blocked on warehouse)* typed ACS hex snapshot | `household_demographics_demand` | `fact_census_acs5_h3_r8_snapshot` — depends ACS5 inventory **D/E/F** + H3 crosswalks; not a bare `ACS5` read-through. |

**Done / in repo (not duplicated here):** `fact_bls_laus_county`, `fact_lodes_od_bg`, `fact_bps_permits_county` (views); Zillow research `FACT_ZILLOW_*` set.

### P1 — LODES employment-center chain (derived facts, not raw OD_BG)

| Priority | `FACT_*` | Concept bucket | Engineering notes from method cards |
|----------|----------|----------------|--------------------------------------|
| P1a | `fact_lodes_od_h3_r8_annual` | `labor_growth_access` | H3_r8 annual OD; depends hex spine + `fact_lodes_od_bg` / `TRANSFORM.LODES.OD_H3_R8`. |
| P1b | `fact_lodes_h3r8_workplace_gravity` | `labor_growth_access` | Workplace gravity; LODES vintage assumptions. |
| P1c | `fact_lodes_nearest_center_h3_r8_annual` | `labor_growth_access` | Nearest high-wage center; chain after OD hex. |

### P2 — Rent (Markerr + multi-vendor pricing union *port* optional)

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P2a | `fact_markerr_rent_h3_r8_monthly` | `rent` | `markerr_transform.rent_property`; CLASS_CATEGORY tier mix; not ACS contract rent. |
| P2b | `fact_markerr_sfr_rent_h3_r8_monthly` | `rent` | SFR rent index / level from `TRANSFORM.MARKERR.*`. |
| P2c | *(port / redesign, not greenfield)* `fact_housing_pricing_all_ts` lineage | `rent` | Union of Yardi / Zillow / JBREC / Apartment List — **metric_id** discipline; ZIP/CBSA; **separate task** if we only **re-point** pretium-ai-dbt to semantic-layer `ref()` rather than recreate SQL here. |

### P3 — Absorption / tightness

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P3a | `fact_cherre_mls_h3_r8_monthly` | `absorption_tightness` | MLS listing stats; ZIP→H3 area-weighted rollup; MLS footprint vs CBSA. |
| P3b | `fact_markerr_mf_pipeline_h3_r8_monthly` | `absorption_tightness` | MF pipeline; parallel semantics vs DOM. |

*(Parcl/Realtor inventory metrics on `fact_housing_inventory_all_ts` are **union / features** first — FACT port same caveat as P2c.)*

### P4 — Transactions (sale volume)

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P4a | `fact_cherre_recorder_sfr_h3_r8_monthly`, `fact_cherre_recorder_mf_h3_r8_monthly` | `transactions_sale_volume` | Recording lag; arms-length filters in cleaned layer. |
| P4b | `fact_rca_mf_transactions_h3_r8_monthly` | `transactions_sale_volume` | Sparse hex in thin markets. |
| P4c | `fact_zonda_deeds_h3_r8_monthly`, `fact_zonda_sfr_h3_r8_monthly`, `fact_zonda_btr_h3_r8_monthly` | `transactions_sale_volume` | Segment mapping alignment. |

### P5 — Value / AVM (Cherre)

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P5a | `fact_cherre_avm_h3_r8_monthly` | `value_avm` | Vendor refresh / model risk. |
| P5b | `fact_cherre_sfr_h3_r8_snapshot`, `fact_cherre_mf_h3_r8_snapshot`, `fact_cherre_stock_h3_r8` | `value_avm` | Snapshot vs AVM monthly join discipline. |

### P6 — Occupancy / operations

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P6a | `fact_markerr_occupancy_h3_r8_monthly` | `occupancy_operations` | Avoid double-count vs related rent facts at same grain. |
| P6b | `fact_progress_occupancy_monthly`, `fact_bh_occupancy_monthly` | `occupancy_operations` | OpCo property / portfolio_monthly; selection bias. |

### P7 — Location / amenities

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P7a | `fact_markerr_amenity_h3_r8_snapshot` | `location_amenity_access` | Taxonomy vs Overture harmonization. |
| P7b | `fact_overture_amenity_h3_r8_snapshot` | `location_amenity_access` | Category mapping for fusion with Markerr. |

### P8 — Affordability (county composites)

| Priority | `FACT_*` | Concept bucket | Engineering notes |
|----------|----------|----------------|---------------------|
| P8a | `fact_affordability_county` | `household_demographics_demand` | County grain vs hex corridor — cross-check / constraint use. |

---

## Task register (copy to `MIGRATION_LOG.md` / Linear as batches)

Use **`T-CMF-P0a`**, **`T-CMF-P2a`**, … internally or map to existing **`T-VENDOR-*`** / **`T-CORRIDOR-*`** rows in `MIGRATION_TASKS.md` when execution starts.

| ID | `FACT_*` | Status | Depends |
|----|----------|--------|---------|
| T-CMF-P0a | `fact_bls_laus_cbsa_monthly` | planned | `bls_transform.laus_cbsa` source + Part C ADR text |
| T-CMF-P1a–c | LODES hex chain (3 models) | planned | `fact_lodes_od_bg`, corridor / REFERENCE.GEOGRAPHY H3 spine |
| T-CMF-P2a | `fact_markerr_rent_h3_r8_monthly` | planned | Markerr transform source registration, H3 xwalk |
| T-CMF-P2b | `fact_markerr_sfr_rent_h3_r8_monthly` | planned | Same |
| T-CMF-P3a | `fact_cherre_mls_h3_r8_monthly` | planned | Cherre MLS cleaned + geo rollup spec |
| T-CMF-P3b | `fact_markerr_mf_pipeline_h3_r8_monthly` | planned | Markerr MF pipeline tables |
| … | *(extend rows as batches open)* | | |

---

## Agent reminder (end of each batch)

**Ask Alex explicitly:** run **`dbt`** in **pretium-ai-dbt** (`/Users/aposes/dev/pretium/pretium-ai-dbt/dbt/`) with the selection that covers downstream models affected by this batch, and paste pass/fail before merge.
