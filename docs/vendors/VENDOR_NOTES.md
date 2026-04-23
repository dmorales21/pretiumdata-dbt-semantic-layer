# Vendor Notes — Single source of vendor knowledge

**Purpose:** This document contains **all** vendor notes: what each vendor provides, how to run it, status, gaps, and key commands. Use it as the one place for vendor knowledge; vendor folders (`anchor_loans/`, `black_knight/`, etc.) hold only deep-dive or one-off docs.  
**Full index:** [README.md](README.md)  
**Last updated:** 2026-02-17

---

## Quick jump by vendor

| Vendor | What it provides | Key schema / pipeline | Folder |
|--------|------------------|----------------------|--------|
| **Anchor Loans** | Deal screener (Liberty Hill), portfolio, HBF score, demographics, retailers, starts/closings | Cleaned → fact → `v_anchor_deal_screener`; `scripts/anchor/run_liberty_hill_full_pipeline.sh` | [anchor_loans/](anchor_loans/) |
| **Black Knight (BKFS)** | Loan performance (REM/RES), 14 tables Redshift → S3 → Snowflake | SOURCE_PROD.BKFS → CLEANED → FACT | [black_knight/](black_knight/) |
| **Cherre MLS** | MLS listing data (pricing, inventory). Core for fact_housing_pricing, signals | CLEANED (cleaned_cherre_mls_*) → FACT | [cherre_mls/](cherre_mls/) |
| **Funnel BH** | BH conversion/appointment metrics, Power BI mart | DS_FUNNEL_BH.STANDARD (57 views) → cleaned → fact | [funnel_bh/](funnel_bh/) |
| **Yardi (BH / Progress)** | Operations, demand, asset (Yardi + Salesforce) | YARDI share → cleaned_*_yardi_* → fact | [yardi/](yardi/) |
| **Zillow** | ZHVI, ZORI, listings, pending. **CBSA only** for canonical | S3 → staging → CLEANED/FACT | [zillow/](zillow/) |
| **Parcl Labs** | Rental market data, ownership, housing stock, comps | CLEANED → FACT (ownership/housing stock at CBSA) | [parcllabs/](parcllabs/) |
| **ACS / Census** | Demographics, age/education demand | CLEANED → FACT | [acs/](acs/) |
| **BLS** | Labor (QCEW, CPS). CBSA/county; NAICS = BLS industry_code | CLEANED → FACT; QCEW county-before-CBSA | [bls/](bls/) |
| **AMREG** | Economics (CBSA). Materialized view for performance | CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED → fact/signals | [amreg/](amreg/) |
| **Realtor.com** | Inventory, pricing | Factization complete | [realtor/](realtor/) |
| **Green Street** | Analytics | Doc summary in folder | [green_street/](green_street/) |
| **Internal** | Progress, BH, Salesforce — OpCo footprint, properties, CRM | Progress: presentation/signals; BH: see yardi | [internal/](internal/) |

---

## Anchor Loans

**Pipeline:** `scripts/anchor/run_liberty_hill_full_pipeline.sh`. Output: delivery view `v_anchor_deal_screener`.

**Screener contents (canonical list):** Portfolio (Anchor closed deals, sum peak UPB, Progress homes within 10 mi); Location (HBF market score, school rank, crime range, major retailers); Demographics (population, median HH income, top 3 industries, employment, unemployment); Housing (median sale price, months of supply, median DOM, builders within 5 mi); Maps/charts (retailers 1/3/5 mi, Zonda comps, starts vs closings, school/crime by geography).

**Data gaps and status:**  
- **Fixed (2026-02):** Months of supply and median DOM now read from `fact_housing_metrics_zip` (was miswired to inventory/demand facts).  
- **P1:** Starts vs closings (5.3): set `anchor_starts_closings_from_zonda: true` and ensure `fact_zonda_starts_closings_all_ts` is populated.  
- **P2:** Major retailers (2.4, 5.1): requires Overture source `overture_places_us_retailers`. Population/income (3.1, 3.2): need `household_hh_demographics_all_ts` with ZIP rows. Top 3 industries (3.3): set `anchor_use_qcew_top3: true` if QCEW ready.  
- **P3:** Builders within 5 mi (4.4) needs Zonda BTR projects with lat/lon. School/crime (5.4, 5.5): guide says H3-6 within 1/3/5 mi; implementation uses H3-8 and CBSA only.

**Key vars (dbt):** `anchor_starts_closings_from_zonda`, `anchor_use_qcew_top3`.  
**PDF guide:** `pip install -r scripts/anchor/requirements-pdf.txt` then `./scripts/anchor/build_screener_guide_pdf.sh`; see `docs/PDF_CONVERSION_GUIDE.md`.

---

## Black Knight (BKFS)

**Status:** Implementation complete. **Source:** Redshift `extdata.bkfs` → S3 → Snowflake. **Database:** SOURCE_PROD.BKFS. **14 tables** (~26.8B rows); monthly updates.

**Architecture:** Redshift → [Python UNLOAD] → S3 (`pret-ai-general/sources/BKFS/`) → [Snowflake COPY INTO] → SOURCE_PROD.BKFS → [dbt cleaned] → TRANSFORM_PROD.CLEANED → [dbt fact] → TRANSFORM_PROD.FACT.

**Prerequisites:** (1) GlobalProtect VPN (https://newvpn.pretiumpartnersllc.com); verify `ping dbred.spark.rcf.pretium.com`. (2) Python: `pip install redshift-connector boto3 pandas pyarrow python-dotenv`. (3) Env vars: REDSHIFT_HOST, REDSHIFT_PORT, REDSHIFT_DATABASE=extdata, REDSHIFT_SCHEMA=bkfs, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, S3_BUCKET=pret-ai-general, S3_PREFIX=sources/BKFS.

**Execution:**  
- Phase 1: `python scripts/bkfs/extract_bkfs_to_s3.py` (or `--table <name>` or `--incremental`).  
- Phase 2: Run in Snowflake order: `01_create_database_schema.sql`, `02_create_s3_stages.sql`, `03_create_tables.sql` (under `sql/source_prod/bkfs/`).  
- Phase 3: `04_load_from_s3.sql`.  
- Phase 4: `05_validate_load.sql`.  
- Phase 5 (dbt): `dbt run --select cleaned_bkfs_loan cleaned_bkfs_loanmonth_ts cleaned_bkfs_property` then `dbt run --select fact_bkfs_loan_characteristics fact_bkfs_loan_performance capital_cap_debt_bkfs`; optionally `+capital_cap_debt_all_ts`.

**Key tables:** loan, loanmonth, loancurrent, property, heloc, loss_mitigation, etc. (see runbook for full list).

---

## Cherre MLS

**Role:** Core for fact_housing_pricing and signals. **Flow:** CLEANED (cleaned_cherre_mls_*) → FACT. MVP run order: `guides/MVP_CHERRE_COMP_RUN_ORDER.md`; optional Phase A: `RUN_PHASE_A=1 ./scripts/run_mvp_cherre_comp.sh` or `./scripts/run_mvp_cherre_comp.sh`.

**Factization (if using SQL path):** (1) Verify CLEANED: `snowsql -q "SELECT COUNT(*) FROM TRANSFORM_PROD.CLEANED.CLEANED_CHERRE_MLS_PRICING_ZIP WHERE DATE_REFERENCE >= '2024-01-01';"`. (2) Run `snowsql -f sql/factize_mls_data.sql`. Metrics factized: CHERRE_MLS_MEDIAN_LIST_PRICE_ZIP, MEDIAN_PRICE_PER_SQFT_ZIP, ACTIVE_LISTINGS_ZIP, TOTAL_LISTINGS_ZIP, RENT_T3_CHANGE_PCT. Quality flags: VALID, STALE, OUTLIER, NULL. Governance metadata from ADMIN.CATALOG.DIM_DATASET. After factization: ensure MLS data is in housing union and tenancy tradeoff signal uses it (primary MLS, fallback Zillow ZORI).

**Permissions:** CREATE TABLE on TRANSFORM_PROD.FACT; SELECT on TRANSFORM_PROD.CLEANED and ADMIN.CATALOG.DIM_DATASET.

---

## Funnel BH

**Source:** Database `DS_FUNNEL_BH`, schema **STANDARD** (primary). **57 application views** (no tables); all must have a cleaned model in TRANSFORM_PROD.CLEANED.

**sources.yml:** database: DS_FUNNEL_BH, schema: STANDARD.

**Key views for fact layer:** LISTING_HISTORY_DAILY, CLIENT_APPOINTMENTS, CLIENT_TOUCHES, CLIENT_FUNNEL, LEASE_TRANSACTION_HISTORY, etc. Funnel fact layer and run order documented in DS_FUNNEL_BH_VIEWS_INVENTORY; Power BI uses mart long → delivery wide. Discovery for conversion metrics and OBJECT columns: `funnel_bh/discovery/README.md`.

**Docs in folder:** FUNNEL_DATA_TRANSFORMATION_BUSINESS.md (Power BI, metrics), FUNNEL_DATA_TRANSFORMATION_DATA_SCIENCE.md (grain, catalog, lineage), FUNNEL_VARIANT_COLUMNS_INVENTORY.md (OBJECT columns).

---

## Yardi (BH / Progress)

**Progress:** Full stack. Source `DS_SOURCE_PROD_YARDI.YARDI_SHARE.*`. Fact tables: HOUSING_HOU_OPERATIONS_YARDI_SFDC, HOUSING_HOU_DEMAND_YARDI_SFDC, HOUSING_HOU_ASSET_YARDI_SFDC (sources: yardi_trans, yardi_detail, yardi_workorders, sfdc_*, yardi_lease_history, yardi_tenant, yardi_prospect, yardi_property, yardi_unit).

**BH (critical issues):** (1) **BTR signal:** Currently uses `fact_housing_hou_btr_all_ts` (John Burns only). Should use Zonda BTR; `TRANSFORM_PROD.CLEANED.ZONDA_BTR_COMPREHENSIVE` is referenced but **NOT FOUND** in CLEANED — BTR signal cannot use Zonda until this is built. (2) **BH Yardi tables missing:** Progress has operations/demand/asset fact tables; BH needs equivalents (e.g. HOUSING_HOU_OPERATIONS_YARDI_SFDC_BH, _DEMAND_, _ASSET_) with same metrics, filtered by BH properties, for Progress vs BH comparability.

**Priority:** Build Zonda BTR cleaned table; add BH operations/demand/asset fact tables.

---

## Zillow

**Status:** Ready for execution. **Canonical:** Use **CBSA only** for canonical metrics (no MSA in new objects). P0: ZHVI MSA (CBSA spot home values), ZORI ZIPCODE (ZIP rent). P0 recommended: ZORI MSA, LISTINGS SFR MSA, PENDING MSA.

**Scripts (sql/zillow/):** 01_create_staging.sql (S3 stage `s3://pret-ai-general/sources/ZILLOW/`, file format, *_RAW tables); 02_load_raw_data.sql (COPY INTO); 03_transform_to_long_format.sql (unpivot to long; MERGE into SOURCE_PROD.ZILLOW); 04_validate_data.sql (108 CBSAs, 20k+ ZIPs, data through 2025-10-31); 05_populate_fact_tables.sql (FACT.FACT_ZILLOW_MSA_TS, FACT_ZILLOW_ZIP_TS).

**Python:** `python scripts/zillow/load_to_snowflake.py --step all` or `--step 1` through `5`. S3 layout: __ZHVI_SFRCONDO/, __ZORI_ZIPCODE/, __ZORI_MSA/, __LISTINGS_SFR/, __PENDING/.

**Access:** Role DATA_ENGINEER; SOURCE_PROD + TRANSFORM_PROD; warehouse LOAD_WH.

---

## Parcl Labs

**Status:** Factization complete. **Script:** `sql/transform/fact/populate_fact_housing_hou_ownership_parcllabs_cbsa.sql`. Populates HOUSING_HOU_OWNERSHIP_ALL_TS with Parcl ownership and housing stock at **CBSA** (aggregated from ZIP). Sources: PARCLLABS_OWNERSHIP_PORTFOLIO_* (100_999, 1000_PLUS, ALL_PORTFOLIO_UNITS), PARCLLABS_HOUSING_STOCK_SF_UNITS. Script deletes existing PARCLLABS/CBSA rows then inserts. Execute via Snowflake UI or Python connector (see folder). Also: rental market data and comps; pipeline status and validation docs in folder.

---

## BLS / QCEW

**QCEW:** NAICS data loaded. Table QCEW_NAICS_CBSA; sectoral views and demand integration views created. **Remaining:** (1) Features layer: run `sql/analytics/features/create_qcew_naics_cbsa_features.sql` (YoY growth, employment/wage shares, industry mix). (2) Atlas: register metrics in ADMIN.METRIC_DOCS (BLS_QCEW_NAICS_EMPLOYMENT_CBSA, _WAGE_, _GROWTH_, BLS_QCEW_INDUSTRY_MIX_EFFECT). (3) Refresh automation: Snowflake task to monitor SOURCE_PROD.BLS.QCEW_COUNTY_RAW and MERGE into QCEW_NAICS_CBSA. **Governance:** QCEW county values before CBSA rollup; NAICS = BLS industry_code; see docs/governance (QCEW_NAICS_AND_COUNTY_BEFORE_CBSA).

---

## AMREG

**Status:** Materialization complete. **Table:** TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED (recent AMREG 2020+ to avoid view timeouts). ~35.6M rows; 296 CBSAs; 31 dates (2020–2050); 657 metrics. Categories: EMPLOYMENT (336 metrics), OTHER_ECONOMIC, ECONOMIC_OUTPUT, WAGES_INCOME, HOUSING_RE, DEMOGRAPHICS. Integration: MOMENTUM signal enhancement via `sql/transform/create_amreg_momentum_integration.sql`. Use ref('amreg_cbsa_economics_materialized') or equivalent in dbt; do not use raw view for heavy queries.

---

## ACS, Realtor, Green Street, Internal

**ACS:** Demographics, age/education demand. CLEANED → FACT; integration complete doc in folder.  
**Realtor.com:** Inventory, pricing. Factization complete; see folder.  
**Green Street:** Analytics; documentation update summary in folder.  
**Internal:** Progress (presentation data map, signal progress, BKFS ingestion, offerings methodology); BH (see Yardi); Salesforce (internal/salesforce). OpCo footprint and properties feed portfolio/delivery views.

---

## One-line by domain

- **Housing (listings, pricing, rent):** Cherre MLS (core), Zillow (ZHVI/ZORI CBSA), Parcl Labs (rental, ownership), Realtor.com.  
- **Operations / OpCo:** Yardi (BH, Progress), Funnel BH (conversion), Internal (Progress, BH, Salesforce).  
- **Deal screening / HBF:** Anchor Loans (Liberty Hill, screener views).  
- **Credit / loan performance:** Black Knight (BKFS) — Redshift → Snowflake.  
- **Demographics / labor:** ACS, BLS (QCEW, CPS), AMREG (economics).

---

## Conventions (all vendors)

- **Cleaned:** `cleaned_{vendor}_{object}` in TRANSFORM_PROD.CLEANED.  
- **Fact:** From cleaned or canonical fact only; `fact_{domain}_{category}_*` in TRANSFORM_PROD.FACT.  
- **Geography:** **CBSA** for canonical metrics unless runbook states otherwise.  
- **Canonical naming:** [CANONICAL_NAMING_CONVENTIONS.md](../governance/CANONICAL_NAMING_CONVENTIONS.md). Vendor runbooks do not override [DOCUMENTATION_CANON](../governance/DOCUMENTATION_CANON.md).

---

## Where to find what

| Need | Where |
|------|--------|
| Run a vendor pipeline | DATA_ENGINEER_NAV §4 Pipelines & runbooks; or this doc (per-vendor sections above). |
| Vendor source → cleaned → fact | This doc; governance: [CLEANED_FACT_INVENTORY_AND_PRIORITY](../governance/CLEANED_FACT_INVENTORY_AND_PRIORITY.md). |
| Deep-dive or one-off vendor doc | Vendor folders (anchor_loans/, black_knight/, …); [README.md](README.md). |
| **Vendor files in OneDrive System** (staging, file counts, Coda pipeline, Data/ folders) | [EXTERNAL_VENDOR_CONTEXT_ONEDRIVE_SYSTEM.md](EXTERNAL_VENDOR_CONTEXT_ONEDRIVE_SYSTEM.md) — paths, key docs, and context for `/Users/aposes/Library/CloudStorage/OneDrive-Pretium/System`. |
