# BKFS Source Tables Missing - Complete Setup Guide

**Date**: 2026-01-29  
**Issue**: Source tables don't exist in `SOURCE_PROD.BKFS`  
**Status**: ⚠️ **TABLES NEED TO BE CREATED AND LOADED**

---

## Problem

The dbt models are failing because the source tables don't exist yet:
```
Object 'SOURCE_PROD.BKFS.LOAN' does not exist
Object 'SOURCE_PROD.BKFS.LOANMONTH' does not exist  
Object 'SOURCE_PROD.BKFS.PROPERTY' does not exist
```

The BKFS signal models depend on these source tables, but they haven't been loaded from Redshift yet.

---

## Solution: Complete BKFS Pipeline Setup

The BKFS integration requires a full pipeline: **Redshift → S3 → Snowflake**

### Step 1: Create Source Tables (DDL)

Run the table creation script:

```bash
# Execute via Snowflake
snowsql -c prod -f sql/source_prod/bkfs/03_create_tables.sql
```

Or manually in Snowflake (creates all 14 tables):
- `SOURCE_PROD.BKFS.LOAN`
- `SOURCE_PROD.BKFS.LOANMONTH`
- `SOURCE_PROD.BKFS.PROPERTY`
- `SOURCE_PROD.BKFS.LOANCURRENT`
- `SOURCE_PROD.BKFS.LOANDELINQUENCYHISTORY`
- And 9 more...

**Script location**: `sql/source_prod/bkfs/03_create_tables.sql`

---

### Step 2: Set Up S3 Stages (for data loading)

```bash
snowsql -c prod -f sql/source_prod/bkfs/02_create_s3_stages.sql
```

This creates:
- Parquet file format (`FF_BKFS_PARQUET`)
- S3 stage (`STG_BKFS_S3` pointing to `s3://pret-ai-general/sources/BKFS/`)

**Script location**: `sql/source_prod/bkfs/02_create_s3_stages.sql`

---

### Step 3: Extract Data from Redshift to S3

**Prerequisites**:
- VPN connection to Redshift
- AWS credentials for S3 access
- Python environment with `redshift-connector`, `boto3`, `pandas`, `pyarrow`

```bash
# Activate virtual environment
source venv/bin/activate

# Set environment variables
export REDSHIFT_HOST=dbred.spark.rcf.pretium.com
export REDSHIFT_PORT=5439
export REDSHIFT_DATABASE=extdata
export REDSHIFT_SCHEMA=bkfs
export REDSHIFT_USER=aposes
export REDSHIFT_PASSWORD=your_password

export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export S3_BUCKET=pret-ai-general
export S3_PREFIX=sources/BKFS

# Run extraction script
python scripts/bkfs/extract_bkfs_to_s3.py
```

**Script location**: `scripts/bkfs/extract_bkfs_to_s3.py`

**What this does**:
- Connects to Redshift `extdata.bkfs`
- Runs `UNLOAD` queries to export data as Parquet
- Uploads to S3: `s3://pret-ai-general/sources/BKFS/{table_name}/`

---

### Step 4: Load Data from S3 into Snowflake

```bash
snowsql -c prod -f sql/source_prod/bkfs/04_load_from_s3.sql
```

**What this does**:
- Runs `COPY INTO` for all 14 tables
- Loads data from S3 Parquet files into Snowflake tables
- Updates metadata columns (`_s3_file_name`, `_extract_date`)

**Script location**: `sql/source_prod/bkfs/04_load_from_s3.sql`

**Note**: This is a LARGE data load (26.8 billion rows total). Consider:
- Running during off-peak hours
- Loading incrementally by table
- Using `LOAD_WH` warehouse for better performance

---

### Step 5: Validate Data Load

```bash
snowsql -c prod -f sql/source_prod/bkfs/05_validate_load.sql
```

**What this checks**:
- Row counts for all tables
- Sample data verification
- Schema validation

**Script location**: `sql/source_prod/bkfs/05_validate_load.sql`

---

### Step 6: Run dbt Models

Once source tables are loaded and validated:

```bash
# Run all BKFS models
dbt run --select tag:bkfs

# Or run specific layers
dbt run --select tag:bkfs,tag:cleaned     # Cleaned models only
dbt run --select tag:bkfs,tag:features    # Feature models only
dbt run --select tag:bkfs,tag:scores      # Signal models only
dbt run --select tag:bkfs,tag:bi          # BI views only
```

---

## Quick Start (If Data Already in S3)

If BKFS data is already extracted to S3, skip Step 3:

```bash
# 1. Create tables
snowsql -c prod -f sql/source_prod/bkfs/03_create_tables.sql

# 2. Set up S3 stages
snowsql -c prod -f sql/source_prod/bkfs/02_create_s3_stages.sql

# 3. Load from S3
snowsql -c prod -f sql/source_prod/bkfs/04_load_from_s3.sql

# 4. Validate
snowsql -c prod -f sql/source_prod/bkfs/05_validate_load.sql

# 5. Run dbt
dbt run --select tag:bkfs
```

---

## Alternative: Use Sample Data for Testing

If you want to test the dbt models without the full data pipeline:

### Option A: Create Empty Tables

```sql
-- Run DDL only (Step 1)
-- This creates empty tables that dbt can reference
-- Models will run but return no data
```

### Option B: Load Subset of Data

Modify `04_load_from_s3.sql` to load only recent months:

```sql
COPY INTO SOURCE_PROD.BKFS.LOANMONTH
FROM @STG_BKFS_S3/loanmonth/
FILE_FORMAT = (FORMAT_NAME = 'FF_BKFS_PARQUET')
PATTERN = '.*2024-.*[.]parquet'  -- Only 2024 data
ON_ERROR = 'CONTINUE';
```

---

## Expected Table Sizes

| Table | Rows | Size (est.) |
|-------|------|-------------|
| `LOAN` | 242M | ~50 GB |
| `LOANMONTH` | 10.3B | ~2 TB |
| `PROPERTY` | 10.1B | ~1.5 TB |
| `LOANCURRENT` | 242M | ~50 GB |
| `LOANDELINQUENCYHISTORY` | 242M | ~40 GB |
| Other tables | ~2B | ~200 GB |

**Total**: ~26.8 billion rows, ~4 TB

---

## Documentation References

- **Integration Runbook**: `docs/BKFS_INTEGRATION_RUNBOOK.md`
- **Redshift Access**: `docs/REDSHIFT_BKFS_RUNBOOK.md`
- **Signal Documentation**: `docs/BKFS_SIGNAL_INTEGRATION_FINAL_SUMMARY.md`

---

## Next Steps

1. **Immediate**: Create empty tables (Step 1) so dbt can compile
2. **Short-term**: Load sample data for testing
3. **Production**: Run full pipeline (Redshift → S3 → Snowflake)

---

**Last Updated**: 2026-01-29  
**Status**: Schema exists ✅ | Tables needed ⚠️

