# Presley corridor stack — required **underlying** tables (registry-grounded)

**Owner:** Alex  
**Purpose:** Single inventory of **Snowflake / dbt objects** that must exist (or be built into **`TRANSFORM.DEV`**) so Presley’s **1_fact** registry rows and **`corridor_model` v1** engineering can compile — without using **`TRANSFORM_PROD`** in new paths.  
**Jon:** **`REFERENCE.GEOGRAPHY`** (census spine, HUD postal xwalks when loaded there, H3 polyfills, bridges).  
**Alex:** **`TRANSFORM.DEV`** for **`FACT_*`**, vendor **`REF_*`** copies (e.g. Zillow metro→CBSA), and typed facts not yet in **`TRANSFORM.FACT`**.

**Registry roots (product repo, not this dbt repo):** `registry/datasets/*.yaml`, `registry/features/corridor_model.yaml`, `registry/models/arbitrage_score.yaml`, `registry/presley/FEATURE_CONCEPT_BRIDGE.yml`.

---

## A. **`1_fact` / registry `object_name` → upstream dependencies**

| Registry-style `object_name` | Target home (new Alex contract) | Underlying reads / builds (representative) |
|------------------------------|----------------------------------|---------------------------------------------|
| **`census_acs5_h3_r8_snapshot`** | **`TRANSFORM.DEV`** `FACT_CENSUS_ACS5_H3_R8_SNAPSHOT` (dbt TBD) | **`TRANSFORM.CENSUS.ACS5`** (`source('transform_census','acs5')`); **`REFERENCE.GEOGRAPHY`**: county/CBSA xwalks, **H3_R8** polyfills / bridges (e.g. CBSA–hex spine per corridor doc); **HUD** `POSTAL_COUNTY_XWALK` / `ZCTA_CBSA_XWALK` where ZIP grain enters. |
| **`cherre_stock_h3_r8_snapshot`** | **`TRANSFORM.DEV`** | Cherre assessor / stock silver (**`SOURCE_PROD`** / **`TRANSFORM`** vendor tables per baseline); **REFERENCE.GEOGRAPHY** for H3 assignment; parcel filters per cleaned models. |
| **`cherre_avm_h3_r8_snapshot`** | **`TRANSFORM.DEV`** | Cherre AVM time series / cleaned path; H3 rollup; REFERENCE for geo. |
| **`cherre_recorder_sfr_h3_r8_24m`** | **`TRANSFORM.DEV`** | **`cleaned_cherre_recorder_*`** lineage (pretium-ai-dbt) → hex aggregates; recording-lag filters. |
| **`cherre_recorder_mf_h3_r8_24m`** | **`TRANSFORM.DEV`** | Same family; MF slice (registry notes v1 may not wire). |
| **`lodes_gravity_h3_r8_annual`** | **`TRANSFORM.DEV`** | **`fact_lodes_od_bg`** (read-through **`TRANSFORM.LODES.OD_BG`**); **`TRANSFORM.LODES.OD_H3_R8`**; employment-center / gravity dbt chain; **REFERENCE.GEOGRAPHY** hex spine. |
| **`lodes_access_h3_r8_annual`** | **`TRANSFORM.DEV`** | OD / workplace access measures; same LODES + H3 bridge family as gravity (spec-dependent). |
| **`markerr_occupancy_h3_r8_12m`** | **`TRANSFORM.DEV`** | **`markerr_transform`** / Markerr rent-property–class feeds; **REFERENCE.GEOGRAPHY** for H3; avoid double-count with rent facts. |
| **`markerr_amenity_h3_r8_snapshot`** | **`TRANSFORM.DEV`** | Markerr amenity product; H3 snapshot grain. |
| **`overture_amenity_h3_r8_snapshot`** | **`TRANSFORM.DEV`** | **`source('overture_maps', …)`** (or vendor equivalent); category harmonization vs Markerr. |
| **`rca_transactions_h3_r8_24m`** | **`TRANSFORM.DEV`** | **`TRANSFORM.RCA`** / MSCI share + cleaned RCA lineage; sparse-hex caveat. |
| **`reference_bridge_h3_r8_static`** | **`REFERENCE.GEOGRAPHY`** (Jon) | **CBSA–H3_R8** polyfill / static join spine (not a vendor fact); see **`MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md`** §1. |

**Zillow research (adjacent to Presley rent union, not the same registry row):** `FACT_ZILLOW_*` need **`SOURCE_PROD.ZILLOW.RAW_*`**, **`REFERENCE.GEOGRAPHY.POSTAL_COUNTY_XWALK`**, **`REFERENCE.GEOGRAPHY.COUNTY_CBSA_XWALK`**, seeds **`ref_zillow_county_to_fips`**, and **`TRANSFORM.DEV.REF_ZILLOW_METRO_TO_CBSA`** (Alex CTAS from Jon **`TRANSFORM.REF.ZILLOW_TO_CENSUS_CBSA_MAPPING`** per `docs/migration/sql/create_ref_zillow_metro_to_cbsa.sql`).

---

## B. **Government read-throughs already in semantic-layer (supporting labor / permits)**

| `FACT_*` in **`TRANSFORM.DEV`** | Upstream |
|--------------------------------|----------|
| `fact_bps_permits_county` | **`TRANSFORM.BPS.PERMITS_COUNTY`** |
| `fact_bls_laus_county` | **`TRANSFORM.BLS.LAUS_COUNTY`** |
| `fact_bls_laus_cbsa_monthly` | **`TRANSFORM.BLS.LAUS_CBSA`** (observe-only; **`AREA_CODE`** caveat) |
| `fact_lodes_od_bg` | **`TRANSFORM.LODES.OD_BG`** (dual-path vs **`SOURCE_PROD.LEHD`** still to resolve) |

---

## C. **Engineering / modeling / estimation (not new `FACT_*` in this doc)**

| Layer | Artifact | Depends on |
|-------|----------|------------|
| **2_feature** | `corridor_model` v1 | All §A **H3_R8** facts at stable column names + **`reference_bridge_h3_r8_static`** |
| **3_model** | `arbitrage_score_v1_h3_r8_snapshot` | **`2_feature/corridor_model/v1/`** |
| **4_estimate** | scored output | **`3_model`** train/predict pipeline |

---

## D. **Operational order (Alex)**

1. Ensure **Jon** objects in **`REFERENCE.GEOGRAPHY`** exist for your account (postal county xwalk, county–CBSA, H3 polyfills used by corridor).  
2. Land **vendor ref copies** in **`TRANSFORM.DEV`** where Jon does not host them (e.g. **`REF_ZILLOW_METRO_TO_CBSA`**).  
3. Build **`TRANSFORM.DEV`** **`FACT_*`** from **`SOURCE_PROD`** / **`TRANSFORM.[VENDOR]`** silver per **`MIGRATION_RULES.md`**.  
4. Run **`dbt build`** in **pretiumdata-dbt-semantic-layer**, then **Alex runs `dbt` in pretium-ai-dbt** on affected consumers (see **`MIGRATION_LOG.md`** batch **006**).

---

*Hub: [docs/README.md](../README.md)*
