# Vendor × concept × dataset coverage — migration backlog

**Owner:** Alex  
**Canonical repo:** pretiumdata-dbt-semantic-layer (this tree).  
**Inputs:** `seeds/reference/catalog/vendor.csv` (~50 vendors), `concept.csv` (20 concepts), `dataset.csv` (~85 dataset rows), `models/sources/*.yml` (declared read paths).  
**Related:** `MIGRATION_TASKS.md`, `MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`, `CATALOG_METRIC_DERIVED_LAYOUT.md`, `MODEL_FEATURE_ESTIMATION_PLAYBOOK.md`, `METRIC_INTAKE_CHECKLIST.md`, `MIGRATION_BATCH_INDEX.md`.

---

## 1. How to read this matrix

| Join | Rule |
|------|------|
| Dataset → vendor | `dataset.vendor_code` → `vendor.vendor_code` |
| Dataset → concept | `dataset.concept_code` → `concept.concept_code` |
| Product × metric | **`bridge_product_type_metric.csv`** has a **minimal** row set (each `product_type_code` → **`cybersyn_fhfa_house_price_timeseries_value`**). **`catalog_wishlist` WL_020** is **`in_progress`** with **`primary_catalog_concept_code=homeprice`** and **`primary_catalog_metric_code`** aligned to **`metric.csv`**. Systematic coverage (rent, UW packs, CBSA variants) still uses **`dataset` + `metric` + this doc** until the bridge is extended. |

**Vendors with zero `dataset` rows (catalog-only today):** `bea`, `cfpb`, `cybersyn`, `fbi`, `fdic`, `nws`, `salesforce`, `usps` — largest **registry vs product** gaps.

---

## 2. Concept gaps (ontology vs vendor semantics)

Stretch mappings below should be **re-pointed** after new `concept_code` rows exist (add to `concept.csv` + `geo_level_codes` / `frequency_codes` as needed).

| Gap | Why it matters | Typical vendors / datasets |
|-----|----------------|----------------------------|
| **Climate & physical hazard** | First Street + FEMA NRI are not “vacancy.” | `first_street`, `fema` (e.g. datasets using `vacancy` today) |
| **Insurance / operating expense** | Bankrate + Quadrant are not “cap rate.” | `bankrate`, `quadrant` |
| **Risk-free / mortgage rates** | FRED + Freddie PMMS are rates, not cap rates. | `fred`, `freddie_mac` |
| **Location / POI / mobility** | Overture is not “school quality.” | `overture` |
| **Banking / deposits / branches** | FDIC SOD does not map to LTV/delinquency. | `fdic` (no dataset yet) |
| **Law enforcement / safety (FBI)** | `crime` exists; FBI vendor unhooked. | `fbi` (no dataset yet) |
| **Mortgage market fairness / HMDA** | CFPB is its own analytic family. | `cfpb` (no dataset yet) |
| **Weather / hazard events** | NWS is not “macro employment.” | `nws` (no dataset yet) |
| **Regional economic accounts** | BEA is GDP/RPP/income, not a thin “employment” slice. | `bea` (no dataset yet) |
| **CRM / pipeline** | Salesforce is deal flow, not occupancy in the IC sense. | `salesforce` (no dataset yet) |
| **Cybersyn umbrella** | Vendor `cybersyn` exists; Cybersyn-backed rows in **`dataset`** use **agency** `vendor_code` (`hud`, `irs`, `fhfa`, …). | Document **`cybersyn` = registry / share** vs agency rows |

**Concrete catalog work:** add concepts such as **`climate`** (or **`hazard`**), **`insurance_expense`**, **`interest_rate`** (or split **`macro_rate`** vs **`mortgage_rate`**), **`location_amenity`**, and optionally **`financial_institution_context`**, **`mortgage_market_regulatory`**, **`deal_pipeline`** — then **re-point** stretch `dataset.concept_code` values. Keep **`vacancy`**, **`cap_rate`**, **`education`** for IC meanings that match the data.

---

## 3. Vendor clusters — migration needs (summary)

### A. Government / silver spine

| Vendor | Notes | Task / next step |
|--------|--------|-------------------|
| **acs** | `income` via census | **`T-TRANSFORM-CENSUS-ACS5-READY`** before expanding `metric` rows. |
| **census** | permits, population, employment | BPS/PEP/CBP — consumer tests; align new `FACT_*` with **`dataset` / `metric`**. |
| **bls** | unemployment, employment | LAUS views in semantic layer; QCEW `transform_dev` — promote or document. |
| **lehd** | employment | OD_BG + corridor chain — **`T-TRANSFORM-LODES-OD-BG-READY`**, corridor docs. |
| **hud** | rent + Cybersyn HUD panel | Split **program rent (FMR/SAFMR)** vs **Cybersyn HUD** in definitions. |
| **irs** / **fhfa** / **freddie_mac** | migration / homeprice / delinquency / cap_rate | `metric.csv` wired; extend **`metric_derived`** + **`bridge_product_type_metric`**. |

### B. Transactional market + property intelligence

| Vendor | Notes | Task / next step |
|--------|--------|-------------------|
| **cherre** | homeprice, ltv, income | **`T-VENDOR-CHERRE-READY`**. |
| **zillow** / **redfin** / **realtor** | homeprice, rent, vacancy | Redfin/Zillow migration tasks; Realtor `source_prod_only` — FACT port or defer IC. |
| **markerr** | rent, crime, education, permits | Align **`concept_rent_*`** + corridor supply. |
| **costar** | rent | **`T-VENDOR-COSTAR-READY`**. |
| **parcllabs** | homeprice, vacancy | Add **`rent`** dataset if rent panel is first-class; review ownership vs vacancy semantics. |

### C. Surveys / research / macro

| Vendor | Notes | Task / next step |
|--------|--------|-------------------|
| **jbrec**, **green_street**, **oxford_economics**, **apartment_list**, **sp_global**, **cotality** | Various | Promote **`pipeline_status`** where facts exist; fix concept stretches (Oxford WDMARCO → macro; SP Global national index). |

### D. OpCo / operational

| Vendor | Notes | Task / next step |
|--------|--------|-------------------|
| **yardi** (+ matrix) | occupancy, rent | **`T-VENDOR-YARDI-READY`** §1.5 artifacts. |
| **apartmentiq** | occupancy | MF KPI — **`product_type`** in catalog. |
| **funnel** | occupancy | DS_066 **blocked** — unblock or **`is_active=false`** on vendor until data exists. |
| **anchor_loans** / **selene** | ltv | `source_entity_only` — FACT when contract allows. |
| **salesforce** | *(no dataset)* | Add **`deal_pipeline`** (or similar) concept + dataset stub, or deactivate vendor until modeled. |

### E. Spatial / hazard / reference

| Vendor | Notes | Task / next step |
|--------|--------|-------------------|
| **first_street**, **fema** | concept stretch | Reclass to **`climate`** / **`hazard`** when added — **`T-VENDOR-FIRST-STREET-READY`**. |
| **overture** | education stretch | Reclass to **`location_amenity`**. |
| **epoch_ai** | employment stretch | Reclass to model-benchmark / internal taxonomy. |

### F. Administrative / other

| **onet**, **cps_nber**, **education_nces**, **nhpd**, **tax_foundation**, **bankrate**, **quadrant**, **preqin**, **internal** | See §2 | NHPD → **`supply_pipeline`** / affordable supply; **internal** + DS_077 — prefer **`irs`** vendor or document Pretium-typed **`FACT_*`**. |

### G. Catalog-only vendors (no `dataset` row)

**Snowflake vet (pretium):** [VENDOR_CATALOG_ONLY_SNOWSQL_VET.md](./VENDOR_CATALOG_ONLY_SNOWSQL_VET.md) — schema visibility, Cybersyn **106** objects, **FBI** row/geo/date stats, **FDIC** SOURCE_PROD empty landing, **partial SELECT grants**, **`SOURCE_ENTITY.PROGRESS`** empty table list. SQL: `scripts/sql/migration/vet_catalog_only_vendors_pretium.sql`.

| Vendor | Migration need |
|--------|----------------|
| **bea** | `dataset` + `metric` + **`T-TRANSFORM-*`** when BEA FACT lands. |
| **cybersyn** | Synthetic **`dataset`** rows for share discovery **or** document registry-only; reads use agency **`vendor_code`**. |
| **fbi** / **fdic** / **usps** / **nws** / **cfpb** | For each: (1) `dataset` stub (2) Snowflake object (3) `FACT_*` in semantic layer (4) `concept` (5) `metric` — **or** `vendor.is_active=false` until contracted. |

---

## 4. Order of operations (checklist)

1. **Freeze concept taxonomy** — add missing **`concept_code`** rows (§2); update **`geo_level_codes` / `frequency_codes`** on `concept` where new grains appear.  
2. **Re-point stretch `dataset.concept_code`** (FEMA, First Street, Overture, FRED, Bankrate/Quadrant, Oxford WDMARCO-style macro series, epoch_ai, parcl).  
3. **Add `dataset` (+ `pipeline_status`)** for the eight vendors with no row, or **deactivate** vendors not under contract.  
4. **Populate `bridge_product_type_metric.csv`** — start with **rent** and **homeprice** (CoStar, Zillow, Markerr, Parcl, ApartmentIQ, Matrix).  
5. **Drift check:** align **`metric.table_path`** with **`dataset.source_schema`** for each governed FACT (CI or periodic SQL).  
6. **`MIGRATION_LOG.md`** — append a batch whenever concept/dataset/vendor seed changes merge.

---

## 5. Source schema vet — `dataset.source_schema` vs dbt `sources`

**Scope:** This repo’s declared Snowflake read paths live under **`models/sources/*.yml`**. The catalog lists **many** `SOURCE_PROD.*` and `TRANSFORM.[VENDOR]` schemas that are **not** each mirrored with a dedicated `source()` block here yet — that is expected during migration; the table below records **vet status** for planning.

| `dataset.source_schema` (distinct) | Declared in `models/sources`? | Notes |
|--------------------------------------|-------------------------------|--------|
| **TRANSFORM.DEV** | **Yes** (implicit via models + `transform_dev_vendor_ref`, zillow, fund_opco paths) | Primary Alex **`FACT_*`** home. |
| **TRANSFORM.BPS** | **Yes** (`transform_bps`) | |
| **TRANSFORM.BLS** | **Yes** (`bls_transform`) | |
| **TRANSFORM.CENSUS** | **Yes** (`transform_census`) | |
| **TRANSFORM.LODES** | **Yes** (`transform_lodes`) | |
| **TRANSFORM.CHERRE** | **Yes** (`cherre_transform`) | |
| **TRANSFORM.COSTAR** | **Yes** (`transform_costar`) | |
| **TRANSFORM.MARKERR** | **Yes** (`transform_markerr`) | |
| **TRANSFORM.YARDI** / **TRANSFORM.YARDI_MATRIX** | **Yes** (`transform_yardi`, `transform_yardi_matrix`) | Legacy: `yardi_bh`. |
| **TRANSFORM.APARTMENTIQ** | **Yes** (`transform_apartmentiq`) | |
| **TRANSFORM.REDFIN** | **Yes** (via `transform_fact` tables + lineage) | Confirm table list vs `dataset`. |
| **TRANSFORM.ZONDA** | Partial (`transform_fact.zonda_*`) | Extend sources if new tables consumed. |
| **TRANSFORM.FIRST_STREET** / **TRANSFORM.OVERTURE** / **TRANSFORM.STANFORD** / **TRANSFORM.REGRID** | **Partial / missing** | Add `sources_transform_<vendor>.yml` as FACT models land. |
| **GLOBAL_GOVERNMENT.CYBERSYN** | **Yes** (`global_government_cybersyn`) | HUD/FHFA/IRS paths also use **`SOURCE_SNOW.US_REAL_ESTATE`**. |
| **SOURCE_SNOW.US_REAL_ESTATE** | **Yes** (`source_snow_us_real_estate`) | |
| **SOURCE_ENTITY.PRETIUM** | **Yes** (`source_entity_pretium`) | Oxford + entity tables. |
| **SOURCE_ENTITY.ANCHOR_LOANS** / **SOURCE_ENTITY.SELENE** | **Not in this repo’s sources** | Add when entity reads are migrated from pretium-ai-dbt. |
| **SOURCE_PROD.*** (FRED, REALTOR, JBREC, …) | **Not declared** in semantic-layer `sources` | **Gap:** register per vendor batch or inherit via thin `FACT_*` read-through only. |

**Action:** For each new **`FACT_*`** in `models/transform/dev/`, add or extend **`sources_*.yml`** so `source()` matches **`dataset.source_schema`** + table contract; never hardcode FQNs in SQL (`MIGRATION_RULES.md`).

---

## 6. Row index (machine-generated snapshot)

| Count | Artifact |
|------:|----------|
| 50 | `vendor.csv` rows (excl. header) |
| 20 | `concept.csv` rows |
| 85 | `dataset.csv` rows |
| 8 | Vendors in `vendor.csv` with **no** `dataset` row (`bea`, `cfpb`, `cybersyn`, `fbi`, `fdic`, `nws`, `salesforce`, `usps`) |

---

## 7. Skipped vendors, migration wave order, and crosswalk inventory

**Consolidated** from the former `artifacts/VENDOR_SKIPPED_UP_NEXT_XWALK_PRIORITY.md` (deleted — content lives here + **`MIGRATION_BATCH_INDEX.md`** batch **015**).

### Skipped (no `dataset` row — catalog-only today)

| Priority | `vendor_code` | Why skipped | Next catalog action |
|----------|---------------|-------------|----------------------|
| P1 | **bea** | No `dataset`; BEA FACTs not yet registered | Add `dataset` + `metric` when `FACT_BEA_*` lands; xwalk: state/CBSA FIPS via `GEOGRAPHY_INDEX`. |
| P1 | **cybersyn** | Umbrella vendor; rows use agency codes (`hud`, `irs`, `fhfa`) | Either add synthetic `dataset` rows with `vendor_code=cybersyn` for discovery, or document agency-only pattern (no Snowflake change). |
| P2 | **fbi** / **fdic** / **cfpb** | Crime / deposits / HMDA not modeled in semantic layer yet | `dataset` stubs + Cybersyn or native `FACT_*`; xwalk: county/state FIPS. |
| P2 | **usps** / **nws** | Postal / weather feeds not wired | `dataset` when contract + object exist; xwalk: ZIP ↔ county/CBSA (`REFERENCE.GEOGRAPHY` postal vs ZCTA split per `geo_level` seed). |
| P3 | **salesforce** | CRM — no IC dataset | Add `concept` (e.g. deal_pipeline) + `dataset` stub, or deactivate vendor until modeled. |

### Up next (migration wave — `dataset` exists, gates pending)

Ordered to match **Zillow → BLS/BPS → Markerr → Redfin → BH stack → CoStar → Yardi → First Street/RCA**.

| Wave | Cluster | Vendors | Primary xwalk / dimensional risk |
|------|---------|---------|-----------------------------------|
| W1 | Zillow + government spine | zillow, bls, census, lehd, hud (+ cybersyn paths) | CBSA/ZIP normalization; LAUS **CBSA `AREA_CODE` ≠ OMB CBSA** — prefer county rollups; LODES **BG→CBSA/H3** for corridor. |
| W2 | Markerr + Redfin | markerr, redfin | Redfin **MSA** ↔ **OMB CBSA**; Markerr **ZIP→CBSA** for SFR panels. |
| W3 | BH multifamily | apartmentiq, yardi (+ **yardi_matrix**) | **ZIP/ZCTA** submarket match (`SUBMARKETMATCHZIPZCTA_BH`); property grain ↔ CBSA via property ZIP. |
| W4 | CoStar + scenarios | costar | Scenario **CBSA** code LPAD 5; quarter→month interpolation contract. |
| W5 | Yardi operational | yardi, funnel | Silver `*_PROGRESS` / `*_BH`; ledger **TRANS** keys; funnel **blocked** until ingest. |
| W6 | Property intelligence + risk | cherre, first_street, cotality | Cherre **property_id** ↔ ZIP/CBSA; First Street **property** climate; Cotality tract↔county. |
| W7 | Macro / research | oxford_economics, jbrec, green_street, fred, freddie_mac, fhfa | Oxford **MSA↔CBSA** (`ref_oxford_metro_cbsa`); FRED/Freddie **national** only. |
| W8 | Parcl + listings vendors | parcllabs, realtor | **Parcl market id** ↔ CBSA; Realtor `source_prod_only` until FACT. |

### Crosswalk inventory (objects / rules)

| Need | From | To | Where it lives / action |
|------|------|----|-------------------------|
| Cybersyn → Pretium geo | `GEO_ID` + `SOURCE_LEVEL` | `geo_level_code` + FIPS/CBSA | `REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX` + `geography_level_dictionary` seed; extend `geo_level.source_snow_cybersyn_level` to drive down **`unmapped`** count. |
| USPS ZIP vs ZCTA | postal `zip` | census `zcta` | `geo_level` seed notes — never treat ZCTA row as `zip` product grain. |
| BLS LAUS metro | `LAUS_CBSA.AREA_CODE` | OMB `cbsa_id` | Prefer **`FACT_BLS_LAUS_COUNTY`** rollup; document exception in `metric` / `dataset`. |
| Redfin MSA | Redfin metro key | `cbsa_id` | Crosswalk table or name match QA; see `MIGRATION_TASKS_STANFORD_REDFIN.md`. |
| Parcl markets | `parcl_id` | `cbsa_id` / ZIP | `REF` Parcl unified ids (pretium-ai-dbt) or new `REF_PARCL_MARKET_CBSA` in semantic layer when approved. |
| Cherre / MLS | `tax_assessor_id` / property key | ZIP, CBSA | Assessor + MLS join models; H3 optional (`enable_h3_models`). |
| LEHD / corridor | BG OD pairs | H3 R8 / CBSA | `TRANSFORM.LODES.OD_H3_R8` chain per corridor doc. |
| Oxford AMREG | Oxford MSA | Pretium CBSA | `TRANSFORM.DEV.REF_OXFORD_METRO_CBSA` (migrated). |

---

## 8. Dimensional checks (Snowflake)

Run (from inner dbt project root):

`snowsql -c pretium -f scripts/sql/validation/dimensional_reference_catalog_and_geography.sql`

Interpret **`failure_rows`**: `0` = pass; `>0` = fix seeds or rebuild `REFERENCE.GEOGRAPHY` models.

**Last documented run (`snowsql -c pretium`, 2026-04-19):** all **`REFERENCE.CATALOG`** FK-style checks **0 failures**; **`GEOGRAPHY_INDEX`** rows with **`GEO_LEVEL_CODE = unmapped` → 64,145** — extend **`geo_level`** seed `source_snow_cybersyn_level` and rebuild **`geography_level_dictionary`** / **`geography_index`** (see `geo_level` row **`GEO_023`** notes). Re-run the script after crosswalk changes and update this subsection (or **`MIGRATION_BATCH_INDEX.md`** batch **015**) with new counts.

---

*Update this file when taxonomy or `dataset` / `sources` coverage changes materially; append **`MIGRATION_LOG.md`** (short row) and **`MIGRATION_BATCH_INDEX.md`** (verbose notes) in the same PR.*
