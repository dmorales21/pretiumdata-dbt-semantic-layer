# ✅ BKFS Integration - Ready to Extract Data

**Date**: 2026-01-29  
**Status**: ✅ **ALL CODE COMPLETE** - Ready for data extraction  
**Path Updated**: `s3://pret-ai-general/sources/BLACK_KNIGHT/`

---

## 🎯 Current Situation

**The Problem**: dbt models can't run because the source tables don't exist in Snowflake yet.

**The Solution**: Extract BKFS data from Redshift → S3 → Snowflake

**Good News**: All scripts, SQL, dbt models, and documentation are ready. We just need data!

---

## ✅ What's Ready

### 1. Extraction Scripts (Python)
- ✅ `scripts/bkfs/extract_bkfs_to_s3.py` - Main extraction script
- ✅ `scripts/bkfs/test_extraction.sh` - Test with small table (243 rows)
- ✅ `scripts/bkfs/extract_all_bkfs_tables.sh` - Full extraction (14 tables, ~20B rows)
- ✅ All paths updated to `sources/BLACK_KNIGHT/`

### 2. Snowflake SQL Scripts
- ✅ `sql/source_prod/bkfs/01_create_database_schema.sql` - Create schema
- ✅ `sql/source_prod/bkfs/02_create_s3_stages.sql` - Create S3 stages (updated paths)
- ✅ `sql/source_prod/bkfs/03_create_tables.sql` - Create 14 table structures
- ✅ `sql/source_prod/bkfs/04_load_from_s3.sql` - COPY INTO commands
- ✅ `sql/source_prod/bkfs/05_validate_load.sql` - Validation queries

### 3. dbt Models
- ✅ **Cleaned Layer** (3 models):
  - `cleaned_bkfs_loan.sql`
  - `cleaned_bkfs_loanmonth_ts.sql` (with PAYMENT_STATUS, UPB, BANKRUPTCY_FLAG, FORECLOSURE_ID)
  - `cleaned_bkfs_property.sql`

- ✅ **Features Layer** (4 models):
  - `feature_bkfs_delinquency_metrics.sql`
  - `feature_bkfs_foreclosure_metrics.sql`
  - `feature_bkfs_property_metrics.sql`
  - `feature_bkfs_credit_metrics.sql`

- ✅ **Signals** (3 models):
  - `fct_delinquency_risk_signal.sql`
  - `fct_distressed_opportunity_signal.sql`
  - `fct_loan_performance_signal.sql`

- ✅ **BI Views** (7 models):
  - `vw_bkfs_signal_decomposition.sql`
  - `vw_bkfs_equity_opportunity_screener.sql`
  - `vw_bkfs_debt_risk_scorecard.sql`
  - `vw_bkfs_selene_primary_performing_health.sql`
  - `vw_bkfs_deephaven_non_qm_credit_migration.sql`
  - `vw_bkfs_deephaven_dscr_rental_stress.sql`
  - `vw_bkfs_offering_gate_trigger_summary.sql`

### 4. Documentation
- ✅ `docs/BKFS_EXTRACTION_QUICKSTART.md` - Complete extraction guide
- ✅ `docs/BKFS_PIPELINE_CURRENT_STATUS.md` - Pipeline overview
- ✅ `docs/REDSHIFT_BKFS_RUNBOOK.md` - Redshift connection guide
- ✅ `docs/BKFS_SIGNAL_INTEGRATION_FINAL_SUMMARY.md` - Signal documentation
- ✅ `docs/BKFS_OFFERING_LEVEL_INSIGHTS.md` - Offering insights

---

## 🚀 Next Steps (Execute in Order)

### Step 1: Test Extraction (5 minutes) ⭐ START HERE

```bash
cd /Users/aposes/Library/CloudStorage/OneDrive-PretiumPartnersLLC/System/GitHub_Repos/pretium-ai-dbt

# Ensure VPN is connected first!
# URL: https://newvpn.pretiumpartnersllc.com

# Run test extraction (loanlookup table - only 243 rows)
bash scripts/bkfs/test_extraction.sh
```

**What this does**:
- Checks VPN connection
- Extracts `loanlookup` table (243 rows) from Redshift
- Unloads to S3: `s3://pret-ai-general/sources/BLACK_KNIGHT/loanlookup/2026-01-29/`
- Verifies files were created

**Expected output**:
```
✓ VPN connected
✓ Connected to Redshift
✓ UNLOAD command executed
✓ Found 1 files in S3 (<1 MB)
```

---

### Step 2: Create Snowflake Schema (1 minute)

Run this SQL in Snowflake:

```sql
-- From: sql/source_prod/bkfs/01_create_database_schema.sql
CREATE SCHEMA IF NOT EXISTS SOURCE_PROD.BKFS 
COMMENT = 'Black Knight Financial Services loan performance data';
```

Or use the dbt macro:

```bash
dbt run-operation create_bkfs_schema
```

---

### Step 3: Create S3 Stages in Snowflake (2 minutes)

Run the entire file in Snowflake:

```bash
# File: sql/source_prod/bkfs/02_create_s3_stages.sql
```

This creates:
- `FF_BKFS_PARQUET` file format
- `STG_BKFS_S3` stage pointing to `s3://pret-ai-general/sources/BLACK_KNIGHT/`
- Table-specific stages (optional)

---

### Step 4: Create BKFS Tables (5 minutes)

Run the entire file in Snowflake:

```bash
# File: sql/source_prod/bkfs/03_create_tables.sql
```

This creates all 14 table structures in `SOURCE_PROD.BKFS`:
- LOAN
- LOANMONTH
- LOANCURRENT
- PROPERTY
- HELOC
- LOSS_MITIGATION
- ... (and 8 more)

---

### Step 5: Load Test Data (1 minute)

Run this SQL in Snowflake to load the test table:

```sql
-- Load loanlookup (test table)
COPY INTO SOURCE_PROD.BKFS.LOANLOOKUP
FROM @STG_BKFS_S3/loanlookup/2026-01-29/
FILE_FORMAT = (FORMAT_NAME = 'FF_BKFS_PARQUET')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Verify
SELECT COUNT(*) FROM SOURCE_PROD.BKFS.LOANLOOKUP;
-- Should return: 243
```

---

### Step 6: Test dbt Models (5 minutes)

```bash
# Test cleaned layer (should work now!)
dbt run --select cleaned_bkfs_loan --full-refresh

# If successful, proceed with features
dbt run --select feature_bkfs_* --full-refresh

# Then signals
dbt run --select fct_*_signal --full-refresh

# Then BI views
dbt run --select bi.vw_bkfs_* --full-refresh
```

---

### Step 7: Extract Priority 1 Tables (2-3 hours)

Once test is successful, extract the core tables:

```bash
# Activate venv
source venv/bin/activate

# Extract core tables (one at a time to monitor progress)
python3 scripts/bkfs/extract_bkfs_to_s3.py --table loan            # 242M rows
python3 scripts/bkfs/extract_bkfs_to_s3.py --table loancurrent     # 242M rows
python3 scripts/bkfs/extract_bkfs_to_s3.py --table loanmonth       # 10.3B rows (LARGE!)
python3 scripts/bkfs/extract_bkfs_to_s3.py --table property        # 10.1B rows (LARGE!)
```

**Monitor progress**:
```bash
# Check S3 files
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/ --recursive --human-readable

# Check Redshift connection
ping dbred.spark.rcf.pretium.com
```

---

### Step 8: Load Core Tables into Snowflake (1-2 hours)

After extraction, load each table:

```sql
-- Load LOAN
COPY INTO SOURCE_PROD.BKFS.LOAN
FROM @STG_BKFS_S3/loan/2026-01-29/
FILE_FORMAT = (FORMAT_NAME = 'FF_BKFS_PARQUET')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Load LOANCURRENT
COPY INTO SOURCE_PROD.BKFS.LOANCURRENT
FROM @STG_BKFS_S3/loancurrent/2026-01-29/
FILE_FORMAT = (FORMAT_NAME = 'FF_BKFS_PARQUET')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Load LOANMONTH (LARGE - may take 30+ minutes)
COPY INTO SOURCE_PROD.BKFS.LOANMONTH
FROM @STG_BKFS_S3/loanmonth/2026-01-29/
FILE_FORMAT = (FORMAT_NAME = 'FF_BKFS_PARQUET')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;

-- Load PROPERTY (LARGE - may take 30+ minutes)
COPY INTO SOURCE_PROD.BKFS.PROPERTY
FROM @STG_BKFS_S3/property/2026-01-29/
FILE_FORMAT = (FORMAT_NAME = 'FF_BKFS_PARQUET')
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE;
```

---

### Step 9: Run Full dbt Pipeline (30 minutes)

```bash
# Run all BKFS models
dbt run --select cleaned_bkfs_* feature_bkfs_* fct_*_signal bi.vw_bkfs_*

# Validate
dbt test --select cleaned_bkfs_* feature_bkfs_*
```

---

### Step 10: Extract Remaining Tables (Optional - 2+ hours)

```bash
# Full extraction of all 14 tables
bash scripts/bkfs/extract_all_bkfs_tables.sh
```

---

## 📊 Data Summary

### Test Table (Phase 1)
| Table | Rows | Size | Time |
|-------|------|------|------|
| loanlookup | 243 | <1 MB | <1 min |

### Priority 1 Tables (Phase 2)
| Table | Rows | Size | Time |
|-------|------|------|------|
| loan | 242M | ~10 GB | 10 min |
| loancurrent | 242M | ~15 GB | 10 min |
| loanmonth | 10.3B | ~200 GB | 60 min |
| property | 10.1B | ~150 GB | 60 min |

### All Tables (Phase 3)
- **Total**: 14 tables, ~20B rows, ~500GB
- **Extraction Time**: 4-6 hours
- **Load Time**: 1-2 hours

---

## ✅ Verification Steps

### After Test Extraction
```bash
# Check S3
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/loanlookup/ --recursive

# Expected: 1 Parquet file, <1 MB
```

### After Snowflake Load
```sql
-- Verify row counts
SELECT 'LOANLOOKUP', COUNT(*) FROM SOURCE_PROD.BKFS.LOANLOOKUP
UNION ALL
SELECT 'LOAN', COUNT(*) FROM SOURCE_PROD.BKFS.LOAN;

-- Expected: LOANLOOKUP = 243, LOAN = 242,090,000
```

### After dbt Run
```sql
-- Check cleaned layer
SELECT COUNT(*) FROM CLEANED.CLEANED_BKFS_LOAN;

-- Check features
SELECT COUNT(*) FROM DBT_PROJECTS.FEATURE_BKFS_DELINQUENCY_METRICS;

-- Check signals
SELECT COUNT(*) FROM SCORES.FCT_DELINQUENCY_RISK_SIGNAL;
```

---

## 🚨 Prerequisites

### Before Starting
- [ ] **VPN Connected**: https://newvpn.pretiumpartnersllc.com
  ```bash
  ping dbred.spark.rcf.pretium.com
  ```

- [ ] **AWS CLI Configured**:
  ```bash
  aws sts get-caller-identity
  aws s3 ls s3://pret-ai-general/
  ```

- [ ] **Python Packages Installed**:
  ```bash
  source venv/bin/activate
  python -c "import redshift_connector, boto3; print('✅ Ready')"
  ```

- [ ] **Snowflake Access**: Verify you can create schemas in `SOURCE_PROD`

---

## 📖 Key Documentation Files

- **Start Here**: `docs/BKFS_EXTRACTION_QUICKSTART.md`
- **Current Status**: `docs/BKFS_PIPELINE_CURRENT_STATUS.md`
- **Redshift Guide**: `docs/REDSHIFT_BKFS_RUNBOOK.md`
- **Signal Documentation**: `docs/BKFS_SIGNAL_INTEGRATION_FINAL_SUMMARY.md`

---

## 🎯 Quick Commands

```bash
# Test extraction (START HERE)
bash scripts/bkfs/test_extraction.sh

# Check S3
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/ --recursive

# Extract single table
python3 scripts/bkfs/extract_bkfs_to_s3.py --table loanlookup

# Full extraction
bash scripts/bkfs/extract_all_bkfs_tables.sh

# Run dbt
dbt run --select cleaned_bkfs_* --full-refresh
```

---

## ✅ Success Criteria

1. ✅ Test extraction completes successfully
2. ✅ Files appear in S3: `sources/BLACK_KNIGHT/loanlookup/`
3. ✅ Snowflake schema and tables created
4. ✅ Test data loads into Snowflake (243 rows)
5. ✅ dbt cleaned models run successfully
6. ✅ dbt feature models run successfully
7. ✅ dbt signal models run successfully

---

## 🎯 Next Action: RUN THIS NOW

```bash
cd /Users/aposes/Library/CloudStorage/OneDrive-PretiumPartnersLLC/System/GitHub_Repos/pretium-ai-dbt
bash scripts/bkfs/test_extraction.sh
```

**This will**:
- Verify VPN connection
- Extract 243 rows from Redshift
- Upload to S3 as Parquet
- Verify files created

**Then proceed with Steps 2-9 above.**

---

**Ready to go! 🚀**

