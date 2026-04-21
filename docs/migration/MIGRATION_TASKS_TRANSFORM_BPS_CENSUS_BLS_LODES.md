# Migration readiness — `TRANSFORM.BPS.PERMITS_COUNTY`, `TRANSFORM.CENSUS.ACS5`, `TRANSFORM.BLS.LAUS_CBSA`, `TRANSFORM.BLS.LAUS_COUNTY`, `TRANSFORM.LODES.OD_BG`

**Owner:** Alex  
**Governing docs:** [docs/README.md](../README.md), `MIGRATION_RULES.md`, `MIGRATION_BASELINE_RAW_TRANSFORM.md` §1–2, pretium-ai-dbt `design/final/DEPRECATION_MIGRATION_COMPLIANCE.md` (legacy consumer map only).  
**Vendor catalog index:** [CATALOG_NEEDS_VENDOR_INVENTORY_INDEX.md](./CATALOG_NEEDS_VENDOR_INVENTORY_INDEX.md)  
**pretium-ai-dbt anchors:** `dbt/models/sources.yml` (`transform_bps`, `bls_transform`), direct reads in `dbt/models/analytics/facts/` (ACS5, LAUS, LODES), `DEPRECATION_MIGRATION_COMPLIANCE.md` (BPS CBSA naming caveat; LAUS_CBSA `AREA_CODE` caveat)

**Snowflake profile snapshot:** 2026-04-19 (`pretium` connection) — row counts and `DESCRIBE` captured in inventory SQL comments; re-run before cutover.

### Physical snapshot (2026-04-19)

| Object | Rows (approx.) | Notes |
|--------|----------------|--------|
| `TRANSFORM.BPS.PERMITS_COUNTY` | 3,051,480 | Columns include `DATE_REFERENCE`, `ID_CBSA`, `CBSA_CODE_OMB`, `BUILDING_USE`, `MEASURE`, `ESTIMATE_TYPE`, `YEAR_REFERENCE`, `MONTH_REFERENCE`, `VALUE` — **CBSA grain**. |
| `TRANSFORM.CENSUS.ACS5` | 619,107,029 | EAV: `YEAR`, `LEVEL`, `VARIABLE_ID`, `GROUP_ID`, `GEO_ID`, `STATE_ID`…`BLOCK_GROUP_ID`, `VALUE`, `MARGIN_OF_ERROR`, `LABEL`, … |
| `TRANSFORM.BLS.LAUS_CBSA` | 167,968 | `DATE_REFERENCE`, `AREA_CODE`, `UNEMPLOYMENT_RATE`, `UNEMPLOYED_COUNT`, `EMPLOYMENT`, `LABOR_FORCE`, … — see **Part C** caveat. |
| `TRANSFORM.BLS.LAUS_COUNTY` | 5,548,860 | `DATE_REFERENCE`, `COUNTY_FIPS`, `MEASURE_CODE`, `METRIC_NAME`, `VALUE`, `SERIES_ID`, … |
| `TRANSFORM.LODES.OD_BG` | 64,098,606 | BG×BG OD + segment `JOBS_*` columns, `VINTAGE_YEAR`, `DATE_REFERENCE`, `GEO_LEVEL_CODE`, … |

**Task IDs (update `MIGRATION_TASKS.md`):**

| Task ID | Object | Status |
|---------|--------|--------|
| **T-TRANSFORM-BPS-PERMITS-COUNTY-READY** | `TRANSFORM.BPS.PERMITS_COUNTY` | `pending` |
| **T-TRANSFORM-CENSUS-ACS5-READY** | `TRANSFORM.CENSUS.ACS5` | `pending` |
| **T-TRANSFORM-BLS-LAUS-CBSA-READY** | `TRANSFORM.BLS.LAUS_CBSA` | `pending` |
| **T-TRANSFORM-BLS-LAUS-COUNTY-READY** | `TRANSFORM.BLS.LAUS_COUNTY` | `pending` |
| **T-TRANSFORM-LODES-OD-BG-READY** | `TRANSFORM.LODES.OD_BG` | `pending` |

---

## §1.5 Inventory deliverables (Snowflake)

- [x] **Phase-1 (batch 002):** Fast probes — `scripts/sql/migration/inventory_transform_bps_census_bls_lodes_phase1_fast.sql`; artifact **`docs/migration/artifacts/2026-04-19_batch002_transform_bps_census_bls_lodes_phase1.csv`**; linked from **`MIGRATION_LOG.md`** batch **002**. Covers row counts, `INFORMATION_SCHEMA` column counts, LAUS_CBSA date span, LODES `VINTAGE_YEAR` min/max, BPS + LAUS county duplicate-grain probes (see CSV notes on BPS probe).
- [ ] **Full workbook (expensive / off-hours):** Run **`inventory_transform_bps_census_bls_lodes.sql`** including **ACS-D** (full `LEVEL` distribution), **ACS-E/F** (bounded-year dup logic), **LODES-D** (full `VINTAGE_YEAR` distribution), **BPS-C** sample rows — archive CSV under **`docs/migration/artifacts/`** and extend **`MIGRATION_LOG.md`**.
- [x] **ACS5 + LODES metadata-only reruns:** `scripts/sql/migration/inventory_transform_acs5_lodes_metadata_only.sql` (`DESCRIBE` only); batch **005** artifacts `2026-04-19_batch005_acs5_describe.csv`, `2026-04-19_batch005_lodes_od_bg_describe.csv`.

---

## Part A — `TRANSFORM.BPS.PERMITS_COUNTY`

### A0. Role

Census **Building Permits Survey** silver in **`TRANSFORM.BPS`**. **CBSA grain** (`ID_CBSA`, `CBSA_CODE_OMB`, `CBSA_NAME`) — do **not** assume county FIPS despite the table name (see compliance doc).

### A1. Inventory

- [ ] Run **`scripts/sql/migration/inventory_transform_bps_census_bls_lodes.sql`** block **BPS-***.
- [ ] Archive CSV under `docs/migration/artifacts/`; link **`MIGRATION_LOG.md`**.

### A1.5 Grain and keys

- [ ] **BPS-D:** duplicate template on `(DATE_REFERENCE, ID_CBSA, BUILDING_USE, MEASURE, ESTIMATE_TYPE, YEAR_REFERENCE, MONTH_REFERENCE)` (adjust after `DESCRIBE` drift).
- [ ] **BPS-E:** cardinality: distinct `BUILDING_USE`, `MEASURE`, `ESTIMATE_TYPE`.

### A2. Consumers (pretium-ai-dbt)

- [ ] `source('transform_bps', 'permits_county')` and any scorecard / MF ranking models (see `sources.yml` `market_rankings_mf` meta).

### A3. Exit

- [ ] Smoke `SELECT 1` in migration role; flip **`T-TRANSFORM-BPS-PERMITS-COUNTY-READY`**.

---

## Part B — `TRANSFORM.CENSUS.ACS5`

### B0. Role

**EAV** ACS 5-year extracts at multiple levels (`LEVEL`, `GEO_ID`, `YEAR`, `VARIABLE_ID`, `VALUE`, …). **Very large** (~619M rows in account snapshot).

### B1. Inventory

- [x] **ACS-A** column list on file: **`snowsql`** `DESCRIBE TABLE TRANSFORM.CENSUS.ACS5` → batch **005** artifact `2026-04-19_batch005_acs5_describe.csv`; rerunnable **`inventory_transform_acs5_lodes_metadata_only.sql`**.
- [ ] **ACS-C** row count (~619M) optional / expensive.
- [ ] **ACS-D / ACS-E / ACS-F** from **`inventory_transform_bps_census_bls_lodes.sql`**: `LEVEL` distribution; `YEAR` distribution for `LEVEL='block_group'`; dup check `(GEO_ID, VARIABLE_ID, YEAR)` bounded vintages — **warehouse window**.

### B2. Consumers

- [ ] `fact_acs_demographics_county.sql`, `fact_census_acs5_h3_r8_snapshot.sql`, corridor / scorecard features (grep `TRANSFORM.CENSUS.ACS5`).

### B3. Exit

- [ ] Document vintage years required (e.g. 2014 / 2019 / 2024) vs physical `YEAR` values; flip task when parity proven.

---

## Part C — `TRANSFORM.BLS.LAUS_CBSA`

### C0. Role

Metro-area LAUS table (`DATE_REFERENCE`, `AREA_CODE`, rates / counts). **`AREA_CODE` is not a reliable OMB CBSA join key** — pretium-ai-dbt **`fact_bls_laus_cbsa_monthly`** aggregates from **county** LAUS + `dim_geo_county_cbsa` instead.

### C1. Inventory

- [ ] **LAUS-CBSA-*** blocks; **LAUS-CBSA-D:** min/max `DATE_REFERENCE`; **LAUS-CBSA-E:** `AREA_CODE` sample vs county FIPS pattern (documentation only).

### C2. Consumers

- [ ] Any direct readers of `LAUS_CBSA` vs county rollup path; align migration docs so new code does not join `AREA_CODE` to `CBSA_CODE` without crosswalk.

### C3. Exit

- [ ] Smoke + governance note on **non-CBSA** semantics of `AREA_CODE`; flip task.

---

## Part D — `TRANSFORM.BLS.LAUS_COUNTY`

### D0. Role

County LAUS long/pivoted format: `DATE_REFERENCE`, `COUNTY_FIPS`, `MEASURE_CODE`, `VALUE`, … — authoritative input for **`fact_bls_laus_county_monthly`** and CBSA rollups.

### D1. Inventory

- [x] **LAUS-CNTY-B** row count + **LAUS-CNTY-E** dup probe on file (batch **002** phase-1 CSV); **LAUS-CNTY-A** columns via **`snowsql`** `DESCRIBE` → batch **004** artifact `2026-04-19_batch004_bls_laus_county_describe.csv`.
- [ ] **LAUS-CNTY-D:** full `MEASURE_CODE` / `METRIC_NAME` distribution export (optional worksheet).

### D2. Consumers

- [ ] `fact_bls_laus_county_monthly.sql`, `fact_household_labor_laus_county.sql`, `cleaned_bls_laus_county` lineage from raw where applicable.

### D3. Exit

- [ ] Flip **`T-TRANSFORM-BLS-LAUS-COUNTY-READY`**.

---

## Part E — `TRANSFORM.LODES.OD_BG`

### E0. Role

LEHD **LODES** origin–destination job counts at **block-group** residence × workplace grain (plus segment columns `JOBS_*`). **~64M rows** in account snapshot — distinct from **`SOURCE_PROD.LEHD`** block-level raw used by `cleaned_lodes_od_bg` (confirm whether `TRANSFORM.LODES.OD_BG` is DE-maintained rollup of same spec).

**Sibling (corridor Ward chain):** **`TRANSFORM.LODES.OD_H3_R8`** — hex-pair annual OD (~3.9M rows, 2026-04-19) feeding `fact_lodes_od_h3_r8_annual` → employment-center chain — see **`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md`** §2.2 and **`T-CORRIDOR-LODES-OD-H3-R8-READY`**.

### E1. Inventory

- [x] **LODES-A** columns: **`snowsql`** `DESCRIBE TABLE TRANSFORM.LODES.OD_BG` → batch **005** artifact `2026-04-19_batch005_lodes_od_bg_describe.csv`; **`fact_lodes_od_bg`** view + row-count parity vs batch **002** (see **`MIGRATION_LOG.md`** batch **005**).
- [ ] **LODES-D:** full `VINTAGE_YEAR` distribution; **LODES-E:** dup check from **`inventory_transform_bps_census_bls_lodes.sql`** (bounded vintage).

### E2. Consumers

- [ ] `fact_lodes_h3r8_workplace_gravity.sql`, `fact_lodes_od_county_annual.sql`, `fact_lodes_od_h3_r8_annual` chain (grep `TRANSFORM.LODES.OD_BG`).

### E3. Exit

- [ ] Confirm single read path: **TRANSFORM.LODES.OD_BG** vs **cleaned** from `SOURCE_PROD.LEHD`; flip task when contract is explicit.

---

## Downstream — corridor Ward pipeline & MF scorecard (not duplicate “corridor doc”)

These government objects are **inputs** to work modeled elsewhere; keep **`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md`** as the spine checklist.

| Source | Downstream (pretium-ai-dbt / Python) |
|--------|--------------------------------------|
| **BPS `PERMITS_COUNTY`** | MF market scorecard / supply features (county–CBSA rollups); official permit pipeline vs Markerr ZIP permits. |
| **`LODES.OD_BG`** | Block-group OD gravity → hex / county aggregations that feed **`corridor_pipeline`** gravity column and related **`fact_lodes_*`** chains (see **`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md` §2**). |
| **`LODES.OD_H3_R8`** | Ward hex-pair OD → **`fact_lodes_od_h3_r8_annual`** → employment-center chain (**corridor doc §2.2–2.3**). |
| **ACS5** | ACS snapshots at tract/BG/county used in corridor **ACS** fingerprint and scorecard demographics — **heavy workbook deferred** (Part B). |

**Batch 012c:** semantic-layer **`fact_bps_permits_county`** and **`fact_lodes_od_bg`** have **warn**-severity **`dbt_utils.equal_rowcount`** vs **`source()`** so read-through views do not silently diverge from Jon silver row counts.

---

## Part F — Combined exit

- [ ] Register sources in **pretiumdata-dbt-semantic-layer** `sources_transform.yml` when first models compile there.
- [ ] Update **`MIGRATION_LOG.md`** with inventory dates and any `LAUS_CBSA` / BPS grain caveats for downstream engineers.

**Exit criteria:** §A1.5–E1 artifacts on file; ACS5 duplicate logic agreed; LAUS_CBSA semantic warning acknowledged in catalog or ADR; LODES dual-path resolved.
