# Zillow Market Data Loading Guide

**Date**: 2026-01  
**Status**: ✅ **READY FOR EXECUTION**

---

## Overview

This guide provides complete instructions for loading the missing P0-critical Zillow Market Data from S3 into Snowflake. The solution addresses the gaps identified in your requirements:

### P0 Minimum Adds (Required)
1. ✅ **ZHVI MSA** - CBSA spot home values (enables yield calculation)
2. ✅ **ZORI ZIPCODE** - ZIP-level observed rent (enables ZIP yield)

### P0 Strongly Recommended
3. ✅ **ZORI MSA** - Canonical rent definition at MSA
4. ✅ **LISTINGS SFR MSA** - Active listings count (supply velocity)
5. ✅ **PENDING MSA** - Pending sales (absorption precursor)

---

## Solution Components

### SQL Scripts (`sql/zillow/`)

1. **`01_create_staging.sql`**
   - Creates S3 stage pointing to `s3://pret-ai-general/sources/ZILLOW/`
   - Creates CSV file format for Zillow data
   - Creates raw landing tables (`*_RAW`)

2. **`02_load_raw_data.sql`**
   - Loads CSV files from S3 into raw tables
   - Handles 5 priority datasets
   - Uses `COPY INTO` with pattern matching

3. **`03_transform_to_long_format.sql`**
   - Converts wide format (date columns) to long format
   - Uses `LATERAL FLATTEN` to unpivot VARIANT data
   - Creates transformed tables in `SOURCE_PROD.ZILLOW`
   - Uses `MERGE` for upsert operations

4. **`04_validate_data.sql`**
   - Validates completeness, coverage, and recency
   - Checks P0 requirements (108 CBSAs, 20k+ ZIPs, data through 2025-10-31)
   - Performs data quality checks

5. **`05_populate_fact_tables.sql`**
   - Populates `TRANSFORM_PROD.FACT.FACT_ZILLOW_MSA_TS`
   - Populates `TRANSFORM_PROD.FACT.FACT_ZILLOW_ZIP_TS`
   - Maps SOURCE_PROD tables to FACT table format

### Python Script (`scripts/zillow/load_to_snowflake.py`)

Automated loader that executes SQL scripts in sequence with validation.

**Usage:**
```bash
# Run all steps
python scripts/zillow/load_to_snowflake.py --step all

# Run specific step
python scripts/zillow/load_to_snowflake.py --step 1  # Staging
python scripts/zillow/load_to_snowflake.py --step 2  # Load
python scripts/zillow/load_to_snowflake.py --step 3  # Transform
python scripts/zillow/load_to_snowflake.py --step 4  # Validate
```

---

## Prerequisites

### 1. S3 Data Structure

Ensure Zillow CSV files are uploaded to S3 in this structure:
```
s3://pret-ai-general/sources/ZILLOW/
├── __ZHVI_SFRCONDO/
│   └── *.csv (MSA-level home values)
├── __ZORI_ZIPCODE/
│   └── *.csv (ZIP-level rent)
├── __ZORI_MSA/
│   └── *.csv (MSA-level rent)
├── __LISTINGS_SFR/
│   └── *.csv (SFR listings)
└── __PENDING/
    └── *.csv (Pending sales)
```

### 2. Snowflake Access

- **Role**: `DATA_ENGINEER`
- **Database**: `SOURCE_PROD` (for staging/raw/transformed)
- **Database**: `TRANSFORM_PROD` (for FACT tables)
- **Schema**: `ZILLOW`
- **Warehouse**: `LOAD_WH`

### 3. Environment Variables (for Python script)

```bash
export SNOWFLAKE_ACCOUNT="SS54694-PRETIUMDATA"
export SNOWFLAKE_USER="DATABASE_PRETIUM"
export SNOWFLAKE_PASSWORD="your_password"
export SNOWFLAKE_DATABASE="PRETIUM_PROD"
export SNOWFLAKE_WAREHOUSE="LOAD_WH"
export SNOWFLAKE_ROLE="DATA_ENGINEER"
```

---

## Execution Steps

### Option 1: Automated (Recommended)

```bash
# Run all steps
python scripts/zillow/load_to_snowflake.py --step all
```

### Option 2: Manual SQL Execution

```sql
-- Step 1: Create staging
USE ROLE DATA_ENGINEER;
USE DATABASE SOURCE_PROD;
USE WAREHOUSE LOAD_WH;
USE SCHEMA ZILLOW;

-- Execute: sql/zillow/01_create_staging.sql

-- Step 2: Load raw data
-- Execute: sql/zillow/02_load_raw_data.sql

-- Step 3: Transform
-- Execute: sql/zillow/03_transform_to_long_format.sql

-- Step 4: Validate
-- Execute: sql/zillow/04_validate_data.sql

-- Step 5: Populate FACT tables
USE DATABASE TRANSFORM_PROD;
USE SCHEMA FACT;
-- Execute: sql/zillow/05_populate_fact_tables.sql
```

---

## Expected Results

### SOURCE_PROD.ZILLOW Tables

After successful execution:

| Table | Expected Rows | Geography | Purpose |
|-------|--------------|-----------|---------|
| `ZILLOW_ZHVI_MSA` | ~32k | 108 CBSAs × ~300 months | CBSA home values |
| `ZILLOW_ZORI_ZIPCODE` | ~6M | 20k+ ZIPs × ~300 months | ZIP rent |
| `ZILLOW_ZORI_MSA` | ~32k | 108 CBSAs × ~300 months | MSA rent |
| `ZILLOW_LISTINGS_SFR_MSA` | ~32k | 108 CBSAs × ~300 months | SFR listings |
| `ZILLOW_PENDING_MSA` | ~32k | 108 CBSAs × ~300 months | Pending sales |

### Data Completeness Checks

Validation queries will verify:
- ✅ **ZHVI MSA**: Coverage for all 108 CBSAs
- ✅ **ZORI ZIPCODE**: Coverage for 20k+ ZIPs
- ✅ **Data recency**: At least through 2025-10-31
- ✅ **Yield calculation readiness**: Both ZHVI and ZORI available at MSA and ZIP levels

---

## Yield Calculation Enablement

Once data is loaded, you can calculate yields:

### CBSA Yield (Spot, Observed)
```sql
SELECT 
    z.ID_CBSA,
    z.DATE_REFERENCE,
    12 * r.ZORI / z.ZHVI AS gross_yield_spot_cbsa
FROM SOURCE_PROD.ZILLOW.ZILLOW_ZHVI_MSA z
INNER JOIN SOURCE_PROD.ZILLOW.ZILLOW_ZORI_MSA r
    ON z.ID_CBSA = r.ID_CBSA
    AND z.DATE_REFERENCE = r.DATE_REFERENCE
WHERE z.DATE_REFERENCE >= '2025-10-01';
```

### ZIP Yield (Spot, Observed)
```sql
SELECT 
    z.ID_ZIP,
    z.DATE_REFERENCE,
    12 * r.ZORI / z.ZHVI AS gross_yield_spot_zip
FROM SOURCE_PROD.ZILLOW.ZILLOW_ZHVI_MEDIAN z  -- Assuming this exists
INNER JOIN SOURCE_PROD.ZILLOW.ZILLOW_ZORI_ZIPCODE r
    ON z.ID_ZIP = r.ID_ZIP
    AND z.DATE_REFERENCE = r.DATE_REFERENCE
WHERE z.DATE_REFERENCE >= '2025-10-01';
```

---

## Troubleshooting

### Issue: Stage not accessible
- Verify S3 bucket path: `s3://pret-ai-general/sources/ZILLOW/`
- Check AWS credentials in stage definition
- Verify IAM permissions for S3 bucket access

### Issue: No data loaded
- Check S3 folder structure matches expected paths (`__ZHVI_SFRCONDO/`, etc.)
- Verify CSV files exist in S3 folders
- Check file format matches Zillow CSV structure
- Review error messages in Snowflake query history

### Issue: Transformation fails
- Verify raw data loaded successfully (check `*_RAW` tables)
- Check VARIANT column structure matches expected format
- Review date column format (should be YYYY-MM-DD or similar)
- Check for NULL values in critical fields

### Issue: Data quality issues
- Run validation queries (`04_validate_data.sql`)
- Check for missing CBSAs or ZIPs
- Verify date ranges meet P0 requirements
- Review null value percentages

---

## Next Steps After Loading

1. **Update TRANSFORM_PROD.CLEANED views** to include new metrics
2. **Update FEATURES layer** to calculate yields:
   - `gross_yield_spot_cbsa = 12 * zori_msa / zhvi_msa`
   - `gross_yield_spot_zip = 12 * zori_zip / zhvi_zip`
3. **Update SCORES layer** to incorporate yield-based scoring
4. **Register datasets** in `ADMIN.CATALOG.DIM_DATASET`

---

## Files Created

- `sql/zillow/01_create_staging.sql`
- `sql/zillow/02_load_raw_data.sql`
- `sql/zillow/03_transform_to_long_format.sql`
- `sql/zillow/04_validate_data.sql`
- `sql/zillow/05_populate_fact_tables.sql`
- `sql/zillow/README.md`
- `scripts/zillow/load_to_snowflake.py`
- `docs/ZILLOW_DATA_LOADING_GUIDE.md` (this file)

---

## References

- [Zillow Dataset Audit](ZILLOW_DATASET_AUDIT.md)
- [Imagine Homes Loader](../../scripts/imagine_homes/load_to_snowflake.py) (reference implementation)

---

**Ready to execute!** Run `python scripts/zillow/load_to_snowflake.py --step all` to begin.

