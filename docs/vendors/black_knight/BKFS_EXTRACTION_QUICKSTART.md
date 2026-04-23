# BKFS Data Extraction Quick Start

**Last Updated**: 2026-01-29  
**Purpose**: Extract Black Knight Financial Services (BKFS) loan data from Redshift to S3, then load into Snowflake

---

## Overview

This guide walks through extracting BKFS data from Redshift → S3 → Snowflake using:
- **Redshift UNLOAD** for efficient extraction to S3 in Parquet format
- **Snowflake COPY INTO** for loading from S3

**S3 Location**: `s3://pret-ai-general/sources/BLACK_KNIGHT/`

---

## Prerequisites

### 1. VPN Connection
```bash
# Connect to GlobalProtect VPN
# URL: https://newvpn.pretiumpartnersllc.com
# Verify: ping dbred.spark.rcf.pretium.com
```

### 2. Python Environment
```bash
# Activate virtual environment
source venv/bin/activate

# Install required packages
pip install redshift-connector boto3 psycopg2-binary
```

### 3. AWS Credentials
Ensure AWS credentials are configured for S3 access:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify S3 access
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/
```

---

## Quick Start - Test Extraction

**Test with the smallest table first** (loanlookup - only 243 rows):

```bash
# Run test extraction
bash scripts/bkfs/test_extraction.sh
```

This will:
1. Check VPN connection
2. Extract `loanlookup` table (243 rows)
3. Verify files in S3

---

## Full Extraction (All 14 Tables)

⚠️ **Warning**: This extracts ~20 billion rows and may take 2-4 hours.

```bash
# Run full extraction
bash scripts/bkfs/extract_all_bkfs_tables.sh
```

### Extraction Options

#### Extract specific table:
```bash
python scripts/bkfs/extract_bkfs_to_s3.py --table loan
```

#### Extract all tables:
```bash
python scripts/bkfs/extract_bkfs_to_s3.py
```

#### Incremental extraction (future):
```bash
python scripts/bkfs/extract_bkfs_to_s3.py --incremental
```

---

## Load Data into Snowflake

### Step 1: Create Schema
```sql
-- Run: sql/source_prod/bkfs/01_create_database_schema.sql
CREATE SCHEMA IF NOT EXISTS SOURCE_PROD.BKFS 
COMMENT = 'Black Knight Financial Services loan performance data';
```

### Step 2: Create S3 Stages
```sql
-- Run: sql/source_prod/bkfs/02_create_s3_stages.sql
-- Creates:
--   - FF_BKFS_PARQUET (file format)
--   - STG_BKFS_S3 (main stage)
--   - Table-specific stages (optional)
```

### Step 3: Create Tables
```sql
-- Run: sql/source_prod/bkfs/03_create_tables.sql
-- Creates all 14 BKFS table structures
```

### Step 4: Load Data from S3
```sql
-- Run: sql/source_prod/bkfs/04_load_from_s3.sql
-- Uses COPY INTO to load Parquet files from S3
```

### Step 5: Validate Load
```sql
-- Run: sql/source_prod/bkfs/05_validate_load.sql
-- Checks row counts and data quality
```

---

## Table Summary

| Table | Rows | Type | Priority |
|-------|------|------|----------|
| `loanlookup` | 243 | Static | TEST |
| `view_dq_buyout_adj` | 96 | View | TEST |
| `resolution` | 3.7M | Static | P3 |
| `loss_mitigation_mod` | 4.4M | Static | P3 |
| `loanarm` | 27.8M | Static | P2 |
| `loan` | 242M | Static | **P1** |
| `loancurrent` | 242M | Static | **P1** |
| `loandelinquencyhistory` | 242M | Static | **P1** |
| `property_enh` | 242M | Static | P2 |
| `heloc` | 1.5B | Time Series | P2 |
| `loss_mitigation_fb` | 1.8B | Time Series | P3 |
| `loss_mitigation` | 4.5B | Time Series | P2 |
| `property` | 10.1B | Time Series | **P1** |
| `loanmonth` | 10.3B | Time Series | **P1** |

**P1 = Priority 1** (Critical for signals)  
**P2 = Priority 2** (Important for enrichment)  
**P3 = Priority 3** (Optional for advanced analytics)

---

## Extraction Strategy

### Phase 1: Test (5 minutes)
```bash
# Extract test tables
python scripts/bkfs/extract_bkfs_to_s3.py --table loanlookup
python scripts/bkfs/extract_bkfs_to_s3.py --table view_dq_buyout_adj
```

### Phase 2: Small Tables (30 minutes)
```bash
# Extract smaller static tables
python scripts/bkfs/extract_bkfs_to_s3.py --table resolution
python scripts/bkfs/extract_bkfs_to_s3.py --table loss_mitigation_mod
python scripts/bkfs/extract_bkfs_to_s3.py --table loanarm
```

### Phase 3: Medium Tables (1-2 hours)
```bash
# Extract 242M row tables
python scripts/bkfs/extract_bkfs_to_s3.py --table loan
python scripts/bkfs/extract_bkfs_to_s3.py --table loancurrent
python scripts/bkfs/extract_bkfs_to_s3.py --table loandelinquencyhistory
python scripts/bkfs/extract_bkfs_to_s3.py --table property_enh
```

### Phase 4: Large Tables (2-4 hours)
```bash
# Extract time-series tables (10B+ rows)
python scripts/bkfs/extract_bkfs_to_s3.py --table loanmonth
python scripts/bkfs/extract_bkfs_to_s3.py --table property
python scripts/bkfs/extract_bkfs_to_s3.py --table loss_mitigation
python scripts/bkfs/extract_bkfs_to_s3.py --table heloc
python scripts/bkfs/extract_bkfs_to_s3.py --table loss_mitigation_fb
```

---

## Monitoring Extraction

### Check S3 files
```bash
# List all extracted files
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/ --recursive

# Check specific table
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/loan/ --recursive

# Check file sizes
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/ --recursive --human-readable --summarize
```

### Check Redshift connection
```python
# Run quick test
python scripts/redshift_simple_test.py
```

---

## Troubleshooting

### Issue: "Connection reset by peer"
**Solution**: Verify VPN connection
```bash
ping dbred.spark.rcf.pretium.com
```

### Issue: "Permission denied to UNLOAD"
**Solution**: Check Redshift IAM role or use AWS credentials
- Option 1 (Preferred): Set `REDSHIFT_IAM_ROLE` environment variable
- Option 2: Ensure `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set

### Issue: "No files in S3"
**Solution**: Check S3 permissions and verify UNLOAD completed
```bash
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/loanlookup/ --recursive
```

### Issue: "S3 bucket not accessible"
**Solution**: Verify AWS credentials and S3 permissions
```bash
aws sts get-caller-identity
aws s3 ls s3://pret-ai-general/
```

---

## Environment Variables

```bash
# Redshift Connection
export REDSHIFT_HOST="dbred.spark.rcf.pretium.com"
export REDSHIFT_PORT="5439"
export REDSHIFT_DATABASE="extdata"
export REDSHIFT_SCHEMA="bkfs"
export REDSHIFT_USER="aposes"
export REDSHIFT_PASSWORD="your_password_here"

# S3 Configuration
export S3_BUCKET="pret-ai-general"
export S3_PREFIX="sources/BLACK_KNIGHT"
export AWS_REGION="us-east-1"

# Optional: IAM Role for UNLOAD (preferred over credentials)
export REDSHIFT_IAM_ROLE="arn:aws:iam::123456789012:role/RedshiftUnloadRole"
```

---

## Next Steps

After extraction is complete:

1. **Verify data in S3**
   ```bash
   aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/ --recursive --summarize
   ```

2. **Load into Snowflake**
   - Run SQL scripts in order: `01_create_database_schema.sql` → `02_create_s3_stages.sql` → `03_create_tables.sql` → `04_load_from_s3.sql`

3. **Run dbt transformations**
   ```bash
   dbt run --select cleaned_bkfs_*
   dbt run --select feature_bkfs_*
   dbt run --select fct_*_signal
   ```

4. **Validate signals**
   ```bash
   dbt run --select bi.vw_bkfs_*
   ```

---

## Support

For issues, contact:
- **Redshift Access**: Derek Baxter (dbaxter@progressresidential.com)
- **AWS/S3 Access**: IT Support
- **dbt/Snowflake**: Data Engineering Team

---

**Last Updated**: 2026-01-29

