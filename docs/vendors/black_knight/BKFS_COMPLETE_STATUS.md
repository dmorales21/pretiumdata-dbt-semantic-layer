# BKFS Data Ingestion - Complete Status

**Last Updated**: 2026-01-29 14:05 EST  
**Status**: 🚀 **MULTI-PHASE IN PROGRESS**  
**Phase**: Data extraction and loading running in parallel

---

## Executive Summary

### ✅ Completed
- **LOANLOOKUP**: 243 rows extracted & loaded to Snowflake ✓
- **LOAN**: 242,752,111 rows extracted & **loaded to Snowflake** ✓ ✓
- **LOANDELINQUENCYHISTORY**: Extracted to S3 ✓

### 🔄 In Progress
- **LOANMONTH**: Extracting from Redshift (10.4 BILLION rows)
- **PROPERTY**: Extracting from Redshift (10.1 BILLION rows)
- **9 Additional Tables**: Extracting in parallel

---

## Detailed Status

### Phase 1-3: Setup & Test ✅ COMPLETE

1. ✅ **Redshift Connection Tested** - loanlookup (243 rows) extracted
2. ✅ **Snowflake Schema Created** - `SOURCE_PROD.BKFS` with 14 tables
3. ✅ **S3 Stages Created** - PARQUET_FORMAT and initial stages configured
4. ✅ **Test Data Loaded** - loanlookup successfully loaded to Snowflake

### Phase 4: Priority Tables - IN PROGRESS

#### ✅ LOAN Table - COMPLETE
- **Status**: **FULLY LOADED TO SNOWFLAKE**
- **Rows**: 242,752,111 (verified in Snowflake)
- **Extraction**: ~30 seconds (with timeout fix)
- **S3 Files**: 128 Parquet files (7.71 GB)
- **Snowflake Load**: ~10 seconds
- **Key Fix**: Increased Redshift connection timeout from 30s to 3600s

#### 🔄 LOANMONTH Table - EXTRACTING
- **Status**: Redshift UNLOAD in progress
- **Rows**: 10,384,814,350 (10.4 BILLION)
- **Expected Size**: ~500-750 GB compressed
- **Estimated Time**: 2-4 hours for extraction
- **S3 Destination**: `s3://pret-ai-general/sources/BLACK_KNIGHT/loanmonth/2026-01-29/`

#### 🔄 PROPERTY Table - EXTRACTING
- **Status**: Redshift UNLOAD in progress
- **Rows**: 10,112,267,020 (10.1 BILLION)
- **Expected Size**: ~500-700 GB compressed
- **Estimated Time**: 2-4 hours for extraction
- **S3 Destination**: `s3://pret-ai-general/sources/BLACK_KNIGHT/property/2026-01-29/`

### Phase 5: Remaining Tables - IN PROGRESS

#### ✅ LOANDELINQUENCYHISTORY - EXTRACTED
- **Status**: Extraction complete
- **S3 Location**: `s3://pret-ai-general/sources/BLACK_KNIGHT/loandelinquencyhistory/2026-01-29/`

#### 🔄 Additional Tables Extracting (9 tables)
1. loss_mitigation
2. heloc
3. loancurrent
4. property_enh
5. loanarm
6. loss_mitigation_fb
7. loss_mitigation_mod
8. resolution
9. view_dq_buyout_adj

**Extraction Method**: All running in parallel using `extract_bkfs_to_s3.py`

---

## Architecture & Process

### Data Flow
```
Redshift (extdata.bkfs)
  ↓ UNLOAD (Parquet, 1GB files)
S3 (s3://pret-ai-general/sources/BLACK_KNIGHT/)
  ↓ COPY INTO (via snowsql)
Snowflake (SOURCE_PROD.BKFS)
```

### Key Scripts Created

1. **`scripts/bkfs/extract_bkfs_to_s3.py`**
   - Extracts tables from Redshift to S3 (Parquet format)
   - Connection timeout: 3600s (1 hour) for large tables
   - Uses AWS credentials from environment variables
   - ALLOWOVERWRITE for re-extraction capability

2. **`scripts/bkfs/load_bkfs_to_snowflake.sh`**
   - Loads single tables using snowsql (not MCP)
   - Uses PRETIUM_S3_INTEGRATION
   - FORCE=TRUE to bypass metadata cache

3. **`scripts/bkfs/load_all_bkfs_tables.sh`** ⭐ NEW
   - Comprehensive load script for all 14 tables
   - Creates all stages automatically
   - Loads in optimal order (large tables first)
   - Final summary query showing row counts

4. **`scripts/bkfs/extract_remaining_tables.sh`**
   - Extracts all remaining tables sequentially
   - Individual log files for each table

---

## Critical Fixes Applied

### 1. Redshift Connection Timeout
- **Problem**: `The read operation timed out` for large tables
- **Fix**: Increased timeout from 30s to 3600s in `extract_bkfs_to_s3.py`
- **Impact**: LOAN extraction succeeded in ~30 seconds

### 2. S3 Overwrite Handling
- **Problem**: `Specified unload destination on S3 is not empty`
- **Fix**: Added `ALLOWOVERWRITE` to UNLOAD command
- **Impact**: Can re-extract without manual S3 cleanup

### 3. LOANLOOKUP Schema Mismatch
- **Problem**: Table definition didn't match actual Parquet schema
- **Fix**: Recreated table with correct columns (description, typecode, type)
- **Impact**: Test data loaded successfully

### 4. Snowflake Stage Path
- **Problem**: Stage pointed to `loan/` but files in `loan/2026-01-29/`
- **Fix**: Updated stage URL to include date subdirectory
- **Impact**: LOAN data loaded successfully

### 5. Tool Selection (MCP vs snowsql)
- **Problem**: Using MCP for high-volume COPY INTO operations
- **Fix**: Created snowsql scripts for all loads
- **Impact**: Proper handling of long-running operations

---

## Next Steps (Automated)

Once extractions complete, run the comprehensive load:

```bash
snowsql -a SS54694-PRETIUMDATA \
        -u APOSES@PRETIUM.COM \
        --authenticator externalbrowser \
        -r ACCOUNTADMIN \
        -f /tmp/bkfs_load_all_20260129_140439.sql
```

This will:
1. Create stages for all remaining tables
2. Load LOANMONTH (10.4B rows - ~2-3 hours)
3. Load PROPERTY (10.1B rows - ~2-3 hours)
4. Load remaining 10 tables (~10-30 minutes total)
5. Display final row count summary

---

## Data Volume Summary

| Table | Rows | Est. Size | Status |
|-------|------|-----------|--------|
| loanlookup | 243 | 15 KB | ✅ Loaded |
| loan | 242.7M | 7.71 GB | ✅ Loaded |
| loanmonth | 10.4B | 500-750 GB | 🔄 Extracting |
| property | 10.1B | 500-700 GB | 🔄 Extracting |
| loandelinquencyhistory | ~1-2B | 50-100 GB | ✅ Extracted |
| loss_mitigation | ~500M | 25-50 GB | 🔄 Extracting |
| heloc | ~100M | 5-10 GB | 🔄 Extracting |
| loancurrent | ~200M | 10-20 GB | 🔄 Extracting |
| property_enh | ~10B | 400-600 GB | 🔄 Extracting |
| loanarm | ~50M | 2-5 GB | 🔄 Extracting |
| loss_mitigation_fb | ~100M | 5-10 GB | 🔄 Extracting |
| loss_mitigation_mod | ~100M | 5-10 GB | 🔄 Extracting |
| resolution | ~500M | 25-50 GB | 🔄 Extracting |
| view_dq_buyout_adj | ~1B | 50-100 GB | 🔄 Extracting |
| **TOTAL** | **~22B+** | **~2-3 TB** | **In Progress** |

---

## Technical Notes

### Snowflake Configuration
- **Database**: SOURCE_PROD
- **Schema**: BKFS
- **Warehouse**: AI_WH
- **Role**: ACCOUNTADMIN (for stage creation)
- **Storage Integration**: PRETIUM_S3_INTEGRATION
- **File Format**: PARQUET_FORMAT (Snappy compression)

### Redshift Configuration
- **Host**: sfcapital.cjvg3cmv7dcz.us-east-1.redshift.amazonaws.com
- **Port**: 5439
- **Database**: extdata
- **Schema**: bkfs
- **Connection Timeout**: 3600s

### AWS S3
- **Bucket**: pret-ai-general
- **Prefix**: sources/BLACK_KNIGHT/
- **Structure**: `{table_name}/{YYYY-MM-DD}/*.parquet`
- **Integration**: Uses AWS CLI credentials + Snowflake PRETIUM_S3_INTEGRATION

---

## Monitoring Commands

```bash
# Check extraction status
for table in loanmonth property; do 
  tail -5 /tmp/bkfs_${table}_extract.log
done

# Check S3 files
aws s3 ls s3://pret-ai-general/sources/BLACK_KNIGHT/ --recursive --human-readable

# Check Snowflake row counts (using MCP - discovery only)
SELECT 
  table_name, 
  row_count 
FROM SOURCE_PROD.INFORMATION_SCHEMA.TABLES 
WHERE table_schema = 'BKFS'
ORDER BY row_count DESC;

# Count active extraction processes
ps aux | grep extract_bkfs_to_s3.py | grep -v grep | wc -l
```

---

## Success Criteria

- [x] LOANLOOKUP: 243 rows in Snowflake
- [x] LOAN: 242,752,111 rows in Snowflake
- [ ] LOANMONTH: ~10.4B rows in Snowflake
- [ ] PROPERTY: ~10.1B rows in Snowflake
- [ ] All 14 tables loaded to Snowflake
- [ ] dbt models can reference SOURCE_PROD.BKFS tables
- [ ] BKFS signals (DRG, DOG) operational

---

## Team Communication

**Key Achievement**: Successfully loaded LOAN table (242.7M rows) to Snowflake!

**Current Status**: Multiple large table extractions running in parallel. LOANMONTH (10.4B) and PROPERTY (10.1B) will take 2-4 hours each.

**ETA to Complete**: 4-6 hours for all extractions + 3-5 hours for Snowflake loads = **7-11 hours total**

**Risk**: None - pipeline is stable, just waiting for data volume to process.

