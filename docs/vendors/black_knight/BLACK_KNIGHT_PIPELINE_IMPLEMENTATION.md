# Black Knight Pipeline Implementation Plan

**Date**: 2026-01-27  
**Status**: 🚧 **IN PROGRESS**  
**Principle**: Fastest path to value - Extract/Aggregate in Redshift, Model in Snowflake

---

## Architecture Principles

### ✅ DO
- **Extract + Aggregate in Redshift**: Use Redshift for heavy scans and aggregations
- **Model in Snowflake**: Unify with ACS/LODES/HMDA, crosswalk geographies, materialize final views
- **ZIP→Tract Crosswalk in Snowflake**: Reusable for all external feeds (BK, vendor rents, listings)
- **Version Everything**: Crosswalks, decode mappings, freshness contracts

### ❌ DON'T
- **Do NOT model on Redshift**: Redshift is for extraction/aggregation only
- **Do NOT duplicate crosswalks**: One canonical crosswalk in Snowflake
- **Do NOT skip freshness contracts**: Every BK-derived table needs ASOFMONTH, INGESTED_AT, COVERAGE_FLAG

---

## Implementation Sequence

### Step 0: Prework - Geography Dimensions ✅

**Status**: Need to create/verify `BRIDGE_ZIP_TRACT` with weights

**Existing Infrastructure**:
- ✅ `TRANSFORM_PROD.REF.H3_XWALK_6810_CANON` - Has ZIP/TRACT mappings
- ✅ `TRANSFORM_PROD.REF.V_TRACT_CBSA_XWALK` - Tract to CBSA
- ✅ `ADMIN.CATALOG.VW_ZIP_CBSA_XWALK` - ZIP to CBSA

**Missing**:
- ❌ `BRIDGE_ZIP_TRACT` with residential address/housing unit weights
- ❌ `DIM_ZIP` canonical dimension
- ❌ `DIM_TRACT` canonical dimension (may exist, need to verify)

**Action**: Create `BRIDGE_ZIP_TRACT` from H3_XWALK or Census ZCTA-to-Tract crosswalk

---

### Step 1: BK_MODEL_MONTH (Single-Row Table)

**Purpose**: Determine latest common month across all BK tables

**Location**: Snowflake (`ANALYTICS_PROD.MODELED.BK_MODEL_MONTH`)

**Logic**:
```sql
-- Find minimum latest month across:
-- - bkfs.loancurrent (ASOFMONTH)
-- - bkfs.loanmonth (ASOFMONTH)
-- - bkfs.property / property_enh (if has date field)
```

**Output Columns**:
- `MODEL_MONTH` (DATE or VARCHAR YYYYMM)
- `CREATED_AT` (TIMESTAMP)
- `SOURCE_TABLE_MONTHS` (VARCHAR/JSON - audit trail)

---

### Step 2: BK_LOAN_CURRENT (Loan-Level Latest Snapshot)

**Purpose**: Extract current loan snapshot for modeling

**Extraction**: Redshift → Snowflake table

**Keys**:
- `LOANID` (PRIMARY KEY)
- `ZIP5` (normalized string, LEFT 5 chars)
- `CBSA_METRODIVID` (if present in BK data)
- `ASOFMONTH` (equals BK_MODEL_MONTH)

**Core Columns**:
- `UPB` (Unpaid Principal Balance)
- `CURRENTCREDITSCORE`
- `CURRENTLTV` / `CURR_LTV`
- `DTIHOUSINGRATIO`
- `ANNUALINTERESTRATE` / `INTERESTRATE`
- `OCCUPANCYCODE` / `OCCUPANCYID` (will decode)
- `PRODUCTTYPE` / `LOANTYPEID` (will decode)

**Freshness Contract**:
- `BK_ASOFMONTH`
- `BK_INGESTED_AT`
- `BK_SOURCE_COVERAGE_FLAG` (% loans with ZIP populated)

---

### Step 3: BK_PERF_12M_GEO_CBSA (Performance Over Last 12 Months)

**Purpose**: Aggregate loan performance metrics by geography

**Extraction**: Redshift (loanmonth is huge - 10.3B rows) → Snowflake aggregated table

**Time Window**: Last 12 months ending at `BK_MODEL_MONTH`

**Metrics**:
- `PREPAY_RATE_12M` = share of loans with isprepayment=1 within window
- `ROLL_30_60` = roll rate from 30 to 60 days delinquent
- `ROLL_60_90` = roll rate from 60 to 90 days delinquent
- `ROLL_90_FC` = roll rate from 90+ to foreclosure
- `DQ_30P_SHARE` = share of loan-months with 30+ days delinquent
- `DQ_60P_SHARE` = share of loan-months with 60+ days delinquent
- `DQ_90P_SHARE` = share of loan-months with 90+ days delinquent

**Geo Aggregation**:
1. **CBSA-level first** (fast, primary output)
2. **ZIP-level next** (to enable tract mapping via crosswalk)

**Output**: `ANALYTICS_PROD.MODELED.BK_PERF_12M_GEO_CBSA`

---

### Step 4: BK_SALE_EVENT_12M_GEO_CBSA (Sale/Transaction Turnover Proxy)

**Purpose**: Property sale/transaction turnover metrics

**Extraction**: Redshift (property/property_enh - 10.1B rows) → Snowflake aggregated table

**Metrics**:
- `SALE_EVENT_RATE_12M` = property sales within window / total properties
- `REFI_EVENT_RATE_12M` = refinance events / total loans (if transaction_type allows)

**Geo**:
- **ZIP-level preferred** (then tract via crosswalk)
- **CBSA-level fallback**

**Output**: `ANALYTICS_PROD.MODELED.BK_SALE_EVENT_12M_GEO_CBSA`

---

### Step 5: Modeling-Facing Views in Snowflake

**Goal Objects**:

1. **`V_BK_TURNOVER_CBSA`**
   - Source: `BK_SALE_EVENT_12M_GEO_CBSA`
   - Geography: CBSA
   - Metrics: Sale event rate, refi rate

2. **`V_BK_TURNOVER_TRACT`** (via ZIP crosswalk)
   - Source: `BK_SALE_EVENT_12M_GEO_CBSA` (ZIP-level) + `BRIDGE_ZIP_TRACT`
   - Geography: Tract (weighted from ZIP)
   - Formula: `tract_metric = Σ(zip_metric × weight_zip_tract)`

3. **`V_BK_BORROWER_QUALITY_CBSA`**
   - Source: `BK_LOAN_CURRENT` aggregated to CBSA
   - Metrics: Avg credit score, avg LTV, avg DTI

4. **`V_BK_BORROWER_QUALITY_TRACT`** (via ZIP crosswalk)
   - Source: `BK_LOAN_CURRENT` (ZIP-level) + `BRIDGE_ZIP_TRACT`
   - Geography: Tract (weighted from ZIP)

5. **`V_BK_SERVICING_PIPELINE_CBSA`** (RES-focused)
   - Source: `BK_PERF_12M_GEO_CBSA`
   - Metrics: Roll rates, DQ shares, prepay rates

---

### Step 6: Wire into RealizedOpportunity with Explicit Precedence

**Turnover Precedence** (Component 7):
1. **BK turnover** (if tract/CBSA present and not stale)
2. **ACS mobility** (B07401)
3. **Listings proxy** (Realtor/Redfin/Parcl)

**Data Quality Precedence** (Component 9):
1. **BK borrower quality metrics** present
2. **HMDA borrower proxies**
3. **Default penalized constant** (not 0.5 for model-critical)

**RES Offerings**:
- **Do NOT force into tract household framework**
- Create separate RES loan-level score using BK as primary

---

## Missing Components (Must Add)

### 1. Governed ZIP Crosswalk Table

**Table**: `ANALYTICS_PROD.REF.BRIDGE_ZIP_TRACT`

**Minimum Columns**:
- `ZIP5` (VARCHAR(5))
- `ID_TRACT` (VARCHAR(11) - 11-digit GEOID)
- `WEIGHT` (FLOAT - sum to 1 per ZIP5)
- `EFFECTIVE_DATE` / `VINTAGE` (DATE)
- `SOURCE` (VARCHAR - HUD/USPS/Census)
- `NOTES` (VARCHAR - optional)

**Weight Definition**:
- **Preferred**: Residential addresses or housing units weight
- **Fallback**: Population weight (document as limitation)

**Source Options**:
1. HUD USPS ZIP Crosswalk Files
2. Census ZCTA-to-Tract relationship files
3. H3_XWALK_6810_CANON (if has weights)

---

### 2. Decode Mappings for Coded BK Fields

**Table**: `ANALYTICS_PROD.REF.DIM_BK_CODEBOOK`

**Required Decodes**:
- `OCCUPANCY_CODE` / `OCCUPANCYID` → Owner-occupied, Investor, Second home
- `PURPOSE_OF_LOAN` / `PURPOSEOFLOANID` → Purchase, Refinance, Cash-out
- `PRODUCT_TYPE` / `PRODUCTTYPEID` → Conventional, FHA, VA, etc.
- `PAYMENT_STATUS` → Current, 30, 60, 90, Foreclosure, etc.

**Structure**:
- `CODE_TYPE` (VARCHAR - e.g., 'OCCUPANCY', 'PRODUCT_TYPE')
- `CODE_VALUE` (INTEGER - raw BK code)
- `CODE_LABEL` (VARCHAR - human-readable)
- `CODE_DESCRIPTION` (VARCHAR - optional)
- `VINTAGE` (DATE - when decode was valid)
- `SOURCE` (VARCHAR - BK documentation, internal mapping)

---

### 3. Freshness Contracts

**Required Columns** (add to every BK-derived table/view):
- `BK_ASOFMONTH` (DATE - model month from BK_MODEL_MONTH)
- `BK_INGESTED_AT` (TIMESTAMP - when data was loaded)
- `BK_SOURCE_COVERAGE_FLAG` (FLOAT - % of records with required fields populated)

**Example**:
```sql
ALTER TABLE ANALYTICS_PROD.MODELED.BK_LOAN_CURRENT
ADD COLUMN BK_ASOFMONTH DATE,
ADD COLUMN BK_INGESTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
ADD COLUMN BK_SOURCE_COVERAGE_FLAG FLOAT;
```

---

## Implementation Files

### SQL Scripts (Snowflake)

1. `sql/analytics/modeled/bk/00_create_bk_geography_dimensions.sql` - Step 0
2. `sql/analytics/modeled/bk/01_create_bk_model_month.sql` - Step 1
3. `sql/analytics/modeled/bk/02_create_bk_loan_current.sql` - Step 2 (table definition)
4. `sql/analytics/modeled/bk/03_create_bk_perf_12m_geo_cbsa.sql` - Step 3 (table definition)
5. `sql/analytics/modeled/bk/04_create_bk_sale_event_12m_geo_cbsa.sql` - Step 4 (table definition)
6. `sql/analytics/modeled/bk/05_create_bk_modeling_views.sql` - Step 5
7. `sql/analytics/modeled/bk/06_wire_bk_into_realized_opportunity.sql` - Step 6

### Python Scripts (Redshift Extraction)

1. `scripts/bk/01_extract_bk_loan_current.py` - Extract Step 2
2. `scripts/bk/02_extract_bk_perf_12m_geo_cbsa.py` - Extract Step 3
3. `scripts/bk/03_extract_bk_sale_event_12m_geo_cbsa.py` - Extract Step 4

### Reference Data

1. `sql/analytics/ref/create_bridge_zip_tract.sql` - ZIP→Tract crosswalk
2. `sql/analytics/ref/create_dim_bk_codebook.sql` - BK decode mappings

---

## Next Steps

1. ✅ Create implementation plan (this document)
2. 🔄 Create `BRIDGE_ZIP_TRACT` table
3. 🔄 Create `DIM_BK_CODEBOOK` table
4. 🔄 Build Step 1: BK_MODEL_MONTH
5. 🔄 Build Step 2: BK_LOAN_CURRENT (extract + table)
6. 🔄 Build Step 3: BK_PERF_12M_GEO_CBSA (extract + table)
7. 🔄 Build Step 4: BK_SALE_EVENT_12M_GEO_CBSA (extract + table)
8. 🔄 Build Step 5: Modeling views
9. 🔄 Build Step 6: Wire into RealizedOpportunity

---

**Last Updated**: 2026-01-27

