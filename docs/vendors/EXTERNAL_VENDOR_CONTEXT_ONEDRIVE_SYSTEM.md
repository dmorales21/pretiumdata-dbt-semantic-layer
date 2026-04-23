# External vendor context — OneDrive System

**Purpose:** Reference to vendor-related documents and data **outside** this repo, under `OneDrive-Pretium/System`. Use this when you need staging status, file counts, Coda pipeline notes, or source data locations.  
**In-repo vendor notes:** [VENDOR_NOTES.md](VENDOR_NOTES.md) (single source of vendor runbooks and pipeline steps).

---

## Base path

- **Path:** `/Users/aposes/Library/CloudStorage/OneDrive-Pretium/System`  
  (Alternate: `OneDrive-PretiumPartnersLLC` may appear in some JSON paths.)

---

## 1. Vendor staging (`System/vendor_staging/`)

Staging area for vendor files organized for dbt migration. **5,873 files** across **19 vendors**.

### Key documents (read these for context)

| Document | Path | Context |
|----------|------|--------|
| **00_VENDOR_REFERENCE.md** | `System/vendor_staging/00_VENDOR_REFERENCE.md` | Canonical vendor list from Snowflake: commercial (COSTAR, GREEN_STREET, JBREC, MARKERR, PARCLLABS, REALTOR, REDFIN, ZILLOW), government (ACS, BLS, CENSUS, FRED, HUD, IPEDS, LEHD, ONET), research (NBER, TAX_FOUNDATION). SOURCE convention: `VENDOR:DATASET:VERSION`. Transform layers: SOURCE_PROD → CLEANED → FACT → EDW_PROD. |
| **VENDOR_PIPELINE_STATUS.md** | `System/vendor_staging/VENDOR_PIPELINE_STATUS.md` | Tier 1–5 status by vendor; file counts; next actions (e.g. “Migrate to dbt sources”); lane structure (ingest_candidates, cleaned_candidates, fact_candidates, _intake_raw, docs). dbt migration checklist. |
| **CODA_PIPELINE_UPDATES.md** | `System/vendor_staging/CODA_PIPELINE_UPDATES.md` | Coda table “Vendors” pipeline column update text per vendor (Tier 1–5 + “Other”). Cursor-executable script and row IDs for Coda API. |
| **ORGANIZATION_COMPLETE.md** | `System/vendor_staging/ORGANIZATION_COMPLETE.md` | Completion summary: 5,873 files organized; 19 vendors; lane classification; dataset inference per vendor (e.g. ZILLOW: ZHVI, ZORI, investment_scores); SOURCE string standardization; next steps (lane refinement, promotion to production repos, Coda registry). |

### Vendor subfolders (staging)

Each has lane subdirs: `ingest_candidates/`, `cleaned_candidates/`, `fact_candidates/`, `_intake_raw/`, `docs/`, optional `README.md`.

- **TIER 1 (production-ready):** ZILLOW (12), REALTOR (12), GREEN_STREET (64), JBREC (25), HUD (26).  
- **TIER 2 (audit):** ELISEAI (2,988), COSTAR (2,704).  
- **TIER 3 (operational):** PROGRESS (10), PARCLLABS (SQL from GitHub), MARKERR (SQL from GitHub).  
- **TIER 4 (supporting):** CENSUS_BUREAU (6), REGRID (3), REZONE (3), IMAGINE_HOMES (8), BLACK_KNIGHT (1).  
- **TIER 5 (research):** OXFORD (1), MOODYS (1), TRADING_ECONOMICS (1), URBAN_INSTITUTE (1).  
- **Other:** COTALITY, EVICTION_LAB, CPS, IPEDS, REDFIN (no files staged), ZONDA, YARDI, CHERRE (check integration).

### Registry / results (JSON)

- **coda_registry_data.json** — Consolidated registry (5,873 entries) for Coda intake.  
- **organization_results.json** — Initial 10 vendors (5,841 files).  
- **additional_results.json** — Supplemental vendors (e.g. COTALITY, CENSUS_BUREAU, IMAGINE_HOMES) with source/dest paths and lane.  
- **github_results.json** — Repo-sourced SQL (e.g. popshift-local, anchor-down, absorption) and vendors detected.

---

## 2. Data folder (`System/Data/`)

Vendor-named and topic folders that hold **source data** and supporting files (not necessarily in vendor_staging yet):

| Folder | Context |
|--------|--------|
| **Zillow** | Zillow source files. |
| **Realtor.com** | Realtor.com data. |
| **GreenStreet** | Green Street data. |
| **Cherre** | Cherre data. |
| **CoStar** | CoStar data. |
| **Elise** | EliseAI (high volume). |
| **BH** | BH operational. |
| **Black_Knight** | Black Knight. |
| **John Burns** | JBREC. |
| **Markerr** | Markerr. |
| **Zonda** | Zonda. |
| **HUD** | HUD (AFFH, opportunity zones, PHA). |
| **Census_Geos** | Census/PHA crosswalks, column maps, parquet (feeds CENSUS_BUREAU staging). |
| **Cotality** | Cotality (e.g. CoreLogic Neighborhood Data Dictionary). |
| **Eviction_Lab** | Eviction Lab. |
| **Imagine_Homes** | Portfolio tape (interim_capex_spend, property_details, hoa_dues, etc.). |
| **REGRID** | Parcel data. |
| **ReZone** | Zoning data. |
| **IPEDS** | IPEDS. |
| **Dictionaries** | Data dictionaries (multiple vendors). |
| **RentalData** | Rental data. |
| **Selene** | Selene. |
| **TradingEconomics** | Macro data. |
| **UrbanInstitute** | Urban Institute. |
| **Moodys** | Moody’s. |
| **Deephaven** | Deephaven. |
| **Coda** | Coda-related data. |
| **Data_Sources.xlsx** | Master data sources reference. |

---

## 3. Documentation folder (`System/Documentation/`)

System-level docs (code organization, deployment, Snowflake client). **Not vendor-specific** but references data sources:

- **README.md** — System overview; data sources: Parcl Labs, Census/ACS, BLS, FRED, News APIs.  
- **CODE_ORGANIZATION_EXECUTION_PLAN.md**, **COMPREHENSIVE_FUNCTION_CATALOG.md**, **DEPLOYMENT_PLAN.md**, **FUNCTION_LIBRARY.md** — Code and deployment.  
- **production_ready_snowflake_client.py** — Snowflake client.

---

## 4. How this ties to the repo

| Need | Where |
|------|--------|
| **How to run a vendor pipeline in dbt / Snowflake** | This repo: [VENDOR_NOTES.md](VENDOR_NOTES.md). |
| **What’s staged for migration; Coda pipeline text; file counts** | OneDrive: `System/vendor_staging/` (docs above). |
| **Raw/source files and vendor folders** | OneDrive: `System/Data/<Vendor>/`. |
| **SOURCE convention and canonical vendor list** | OneDrive: `00_VENDOR_REFERENCE.md`; repo: [CANONICAL_NAMING_CONVENTIONS.md](../governance/CANONICAL_NAMING_CONVENTIONS.md), [VENDOR_NOTES.md](VENDOR_NOTES.md). |

---

## 5. Quick reference — vendors in OneDrive vs repo

| Vendor | OneDrive System | Repo (docs/vendors/) |
|--------|------------------|----------------------|
| Zillow | vendor_staging/ZILLOW; Data/Zillow | zillow/ |
| Realtor | vendor_staging/REALTOR; Data/Realtor.com | realtor/ |
| Green Street | vendor_staging/GREEN_STREET; Data/GreenStreet | green_street/ |
| JBREC / John Burns | vendor_staging/JBREC; Data/John Burns | (see governance) |
| HUD | vendor_staging/HUD; Data/HUD | (see governance) |
| Parcl Labs | vendor_staging/PARCLLABS; Data (via GitHub) | parcllabs/ |
| Black Knight | vendor_staging/BLACK_KNIGHT; Data/Black_Knight | black_knight/ |
| Progress | vendor_staging/PROGRESS; Data/BH | internal/progress/ |
| EliseAI | vendor_staging/ELISEAI; Data/Elise | — |
| CoStar | vendor_staging/COSTAR; Data/CoStar | — |
| Cherre | Data/Cherre; “check integration” in Coda doc | cherre_mls/ |
| Yardi | “Check with David Morales” in Coda doc | yardi/ |
| Zonda | “Check strata-deployment archive” in Coda doc | (see governance) |
| Census/ACS | vendor_staging/CENSUS_BUREAU; Data/Census_Geos | acs/ |
| Redfin | “No files currently staged” in Coda doc | (see governance) |

---

**Last updated:** 2026-02-17
