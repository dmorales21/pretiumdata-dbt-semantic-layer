# Cybersyn — `SOURCE_SNOW.GLOBAL_GOVERNMENT` migration tasks

**Goal:** Governed geography + housing-market semantic layer: Cybersyn-native tables in **SOURCE_SNOW**, canonical spines in **REFERENCE.GEOGRAPHY**, normalized **TRANSFORM** facts.

**Authoritative bring-in matrix** (distinct `table_name` from `SOURCE_SNOW.GLOBAL_GOVERNMENT.CYBERSYN_DATA_CATALOG`, columns `tier` … `notes`): [`../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md`](../reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md).

**Machine list:** [`artifacts/cybersyn_global_government_catalog_table_names.tsv`](./artifacts/cybersyn_global_government_catalog_table_names.tsv).

**Task register row:** `T-CYBERSYN-GLOBAL-GOVERNMENT-READY` in [`MIGRATION_TASKS.md`](./MIGRATION_TASKS.md).

---

## Required actions (checklist)

1. **Catalog drift** — Re-run `SELECT DISTINCT TABLE_NAME` on `SOURCE_SNOW.GLOBAL_GOVERNMENT.CYBERSYN_DATA_CATALOG`; refresh the TSV; reconcile matrix row counts and tier assignments.
2. **LEVEL → canonical geo** — No Cybersyn `LEVEL` string ships to broad joins until crosswalked through **`REFERENCE.GEOGRAPHY.GEOGRAPHY_LEVEL_DICTIONARY`** (see matrix examples: `CensusCoreBasedStatisticalArea`→`cbsa`, `CensusZipCodeTabulationArea`→`zcta`, …). Close **`REFERENCE.CATALOG`** / `geo_level` gaps (e.g. product `zip` vs census `zcta`) where facts register.
3. **Latest vocabulary** — Design and REFERENCE docs use **latest** / **as-of**. Source tables whose names end in `_pit` are **latest / as-of / history-grain** companions in **SOURCE_SNOW**; do not call REFERENCE outputs “PIT” except when quoting `_pit` in a Snowflake name.
4. **REFERENCE.GEOGRAPHY contract** — Target utilities: **`GEOGRAPHY_INDEX`**, **`GEOGRAPHY_CODES`**, **`GEOGRAPHY_SHAPES`**, **`GEOGRAPHY_RELATIONSHIPS`**, **`GEOGRAPHY_CURRENT`** (flattened **latest** join surface). Physical model may still be named `GEOGRAPHY_LATEST` until a deliberate rename (see matrix §REFERENCE).
5. **Placement** — **REFERENCE** = shared spines/utilities only; **SOURCE_SNOW** = vendor tables as landed; **TRANSFORM** = tall, tested, semantic-ready models (`matrix.target_layer`).
6. **Tier cadence** — Follow matrix tiers **1→6** (geography backbone → housing/demographics/migration → finance/mortgage → institutions → risk overlays → address/POI). Tier **99** = other / explicitly **de-prioritized** for first-order real-estate intelligence (`openalex_*`, `github_*`, most `sec_*`, `world_bank_*`, `oecd_*`, broad international macro unless directly needed).
7. **dbt wiring** — Register chosen objects in **`models/sources/sources_global_government.yml`** (and **`sources_source_snow_us_real_estate.yml`** where the share lands `FHFA_*` / `IRS_*` / `FREDDIE_MAC_*`); add **TRANSFORM.DEV** `FACT_*` / staging only after Tier-1 geography joins and dictionary are stable. **Shipped (batch 009c + 010):** **`FACT_FHFA_HOUSE_PRICE`** reads **`SOURCE_SNOW.US_REAL_ESTATE`** `FHFA_HOUSE_PRICE_*` (not `GLOBAL_GOVERNMENT.CYBERSYN` on pretium dev). HUD / IRS Cybersyn feeds ship **county** and **CBSA** (or CBSA-attributed OD) as separate `FACT_*` views where both grains exist.
8. **MVP cut** — Implement the matrix **“Recommended first-cut shortlist”** before expanding FHFA / HMDA / Freddie / FDIC / crime / weather / FEMA overlays.
9. **Catalog vendor map + tests** — Keep `seeds/reference/catalog/cybersyn_catalog_table_vendor_map.csv` aligned with `artifacts/cybersyn_global_government_catalog_table_names.tsv` (run `python3 scripts/reference/catalog/regenerate_cybersyn_catalog_table_vendor_map.py` after TSV refresh). `dbt seed` + `dbt test --select cybersyn_catalog_table_vendor_map` validates one row per `table_name`, FK to `vendor`, and tier allow-list.

---

## Ownership

- **REFERENCE.GEOGRAPHY** / dictionary — Jon (coordinate before changing contracts).
- **SOURCE_SNOW** registration and **TRANSFORM.DEV** facts — Alex (per `MIGRATION_RULES.md` / `MIGRATION_LOG.md`).
