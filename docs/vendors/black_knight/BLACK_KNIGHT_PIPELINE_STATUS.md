# Black Knight Pipeline Implementation Status

**Last Updated**: 2026-01-27  
**Status**: 🚧 **IN PROGRESS** (Steps 0-2 Complete)

---

## ✅ Completed Components

### Step 0: Geography Dimensions
- ✅ **`sql/analytics/ref/create_bridge_zip_tract.sql`**
  - Creates `ANALYTICS_PROD.REF.BRIDGE_ZIP_TRACT` table
  - ZIP5 → ID_TRACT crosswalk with weights
  - Uses H3_XWALK_6810_CANON as source
  - Weights from housing units (preferred) or population (fallback)
  - View: `V_BRIDGE_ZIP_TRACT_LATEST`

### Step 0: Decode Mappings
- ✅ **`sql/analytics/ref/create_dim_bk_codebook.sql`**
  - Creates `ANALYTICS_PROD.REF.DIM_BK_CODEBOOK` table
  - Decode mappings for: OCCUPANCY, PRODUCT_TYPE, PURPOSE_OF_LOAN, PAYMENT_STATUS
  - View: `V_DIM_BK_CODEBOOK_LATEST`
  - Function: `FN_DECODE_BK_CODE(code_type, code_value)`

### Step 1: Model Month
- ✅ **`sql/analytics/modeled/bk/01_create_bk_model_month.sql`**
  - Creates `ANALYTICS_PROD.MODELED.BK_MODEL_MONTH` table (single-row)
  - View: `V_BK_MODEL_MONTH_CURRENT`
- ✅ **`scripts/bk/01_extract_bk_model_month.py`**
  - Extracts latest months from Redshift (loancurrent, loanmonth, property)
  - Updates Snowflake BK_MODEL_MONTH with minimum latest month

### Step 2: Loan Current
- ✅ **`sql/analytics/modeled/bk/02_create_bk_loan_current.sql`**
  - Creates `ANALYTICS_PROD.MODELED.BK_LOAN_CURRENT` table
  - 242M rows expected
  - Includes freshness contract fields
  - View: `V_BK_LOAN_CURRENT_DECODED` (with decoded fields)
- ✅ **`scripts/bk/02_extract_bk_loan_current.py`**
  - Extracts from Redshift `bkfs.loancurrent`
  - Loads to Snowflake in batches
  - Calculates ZIP coverage flag

---

## 🚧 In Progress / Pending

### Step 3: Performance 12M
- ⏳ **`sql/analytics/modeled/bk/03_create_bk_perf_12m_geo_cbsa.sql`** (TODO)
- ⏳ **`scripts/bk/03_extract_bk_perf_12m_geo_cbsa.py`** (TODO)
  - Aggregate from `bkfs.loanmonth` (10.3B rows)
  - Metrics: PREPAY_RATE_12M, ROLL_30_60, ROLL_60_90, ROLL_90_FC, DQ_30P_SHARE, etc.
  - Geography: CBSA-level and ZIP-level

### Step 4: Sale Event 12M
- ⏳ **`sql/analytics/modeled/bk/04_create_bk_sale_event_12m_geo_cbsa.sql`** (TODO)
- ⏳ **`scripts/bk/04_extract_bk_sale_event_12m_geo_cbsa.py`** (TODO)
  - Aggregate from `bkfs.property` / `bkfs.property_enh` (10.1B rows)
  - Metrics: SALE_EVENT_RATE_12M, REFI_EVENT_RATE_12M
  - Geography: ZIP-level (preferred) or CBSA-level

### Step 5: Modeling Views
- ⏳ **`sql/analytics/modeled/bk/05_create_bk_modeling_views.sql`** (TODO)
  - `V_BK_TURNOVER_CBSA`
  - `V_BK_TURNOVER_TRACT` (via ZIP crosswalk)
  - `V_BK_BORROWER_QUALITY_CBSA`
  - `V_BK_BORROWER_QUALITY_TRACT` (via ZIP crosswalk)
  - `V_BK_SERVICING_PIPELINE_CBSA`

### Step 6: Wire into RealizedOpportunity
- ⏳ **`sql/analytics/modeled/bk/06_wire_bk_into_realized_opportunity.sql`** (TODO)
  - Turnover precedence: BK → ACS → Listings
  - Data Quality precedence: BK → HMDA → Default
  - RES loan-level scoring (separate from tract framework)

---

## 📋 Next Steps

1. **Complete Step 3**: Build BK_PERF_12M_GEO_CBSA table and extraction script
2. **Complete Step 4**: Build BK_SALE_EVENT_12M_GEO_CBSA table and extraction script
3. **Complete Step 5**: Create modeling-facing views with tract-level aggregation
4. **Complete Step 6**: Wire BK metrics into RealizedOpportunity framework
5. **Test Pipeline**: Run end-to-end extraction and validate data quality
6. **Documentation**: Update runbook with operational procedures

---

## 🔍 Key Files Created

### SQL Scripts
- `sql/analytics/ref/create_bridge_zip_tract.sql`
- `sql/analytics/ref/create_dim_bk_codebook.sql`
- `sql/analytics/modeled/bk/01_create_bk_model_month.sql`
- `sql/analytics/modeled/bk/02_create_bk_loan_current.sql`

### Python Scripts
- `scripts/bk/01_extract_bk_model_month.py`
- `scripts/bk/02_extract_bk_loan_current.py`

### Documentation
- `docs/BLACK_KNIGHT_PIPELINE_IMPLEMENTATION.md` (implementation plan)
- `docs/BLACK_KNIGHT_PIPELINE_STATUS.md` (this file)

---

## 📊 Data Volume Estimates

| Table | Source | Rows | Extraction Strategy |
|-------|--------|------|---------------------|
| `BK_LOAN_CURRENT` | `bkfs.loancurrent` | 242M | Batch extract (10K batches) |
| `BK_PERF_12M_GEO_CBSA` | `bkfs.loanmonth` | 10.3B → Aggregated | Aggregate in Redshift, extract summary |
| `BK_SALE_EVENT_12M_GEO_CBSA` | `bkfs.property` | 10.1B → Aggregated | Aggregate in Redshift, extract summary |

---

**Note**: This is a "fastest path to value" implementation. Focus on getting core metrics (turnover, borrower quality, servicing pipeline) into Snowflake first, then iterate on additional features.

