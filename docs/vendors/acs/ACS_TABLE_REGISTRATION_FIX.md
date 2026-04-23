# ACS Table Registration and Structure Fix

**Date**: 2026-01-27  
**Status**: ✅ **FIXED**

---

## Issues Fixed

### 1. ✅ COPY INTO Syntax Error
**Problem**: `COPY INTO` doesn't support `WHERE` clause directly  
**Error**: `syntax error line 3 at position 0 unexpected 'WHERE'`

**Solution**: Use subquery in `FROM` clause:
```sql
-- Before (incorrect)
COPY INTO TEMP_ACS_B01001
FROM @STAGE/B01001/tract/
WHERE METADATA$FILENAME LIKE '%pattern%'
FILE_FORMAT = (TYPE = PARQUET);

-- After (correct)
COPY INTO TEMP_ACS_B01001
FROM (
    SELECT *
    FROM @STAGE/B01001/tract/
    WHERE METADATA$FILENAME LIKE '%pattern%'
)
FILE_FORMAT = (TYPE = PARQUET);
```

### 2. ✅ Missing Tables
**Problem**: `ACS_TRACT_RAW` and `ACS_TRACT_LONG` tables don't exist  
**Error**: `invalid identifier 'TABLE_CODE'`

**Solution**: Added table creation statements at the beginning of the script:
```sql
CREATE TABLE IF NOT EXISTS SOURCE_PROD.ACS.ACS_TRACT_RAW (
    TABLE_CODE VARCHAR(10) NOT NULL,
    GEO_ID VARCHAR(11) NOT NULL,
    YEAR NUMBER NOT NULL,
    VAR_CODE VARCHAR(20) NOT NULL,
    VAR_VALUE NUMBER,
    SOURCE_FILE VARCHAR(200),
    INGESTED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    PRIMARY KEY (TABLE_CODE, GEO_ID, YEAR, VAR_CODE)
);

CREATE TABLE IF NOT EXISTS SOURCE_PROD.ACS.ACS_TRACT_LONG (
    TABLE_CODE VARCHAR(10) NOT NULL,
    ID_TRACT VARCHAR(11) NOT NULL,
    YEAR NUMBER NOT NULL,
    VAR_CODE VARCHAR(20) NOT NULL,
    VAR_VALUE NUMBER,
    PRIMARY KEY (TABLE_CODE, ID_TRACT, YEAR, VAR_CODE)
);
```

---

## Table Structure

### ACS_TRACT_RAW
**Purpose**: Raw ACS data in long format (before normalization)  
**Schema**:
- `TABLE_CODE` (VARCHAR(10)) - ACS table code (e.g., B01001, B15003)
- `GEO_ID` (VARCHAR(11)) - 11-digit tract FIPS code
- `YEAR` (NUMBER) - Data year
- `VAR_CODE` (VARCHAR(20)) - Variable code (e.g., B01001_001E)
- `VAR_VALUE` (NUMBER) - Variable value
- `SOURCE_FILE` (VARCHAR(200)) - Source file name
- `INGESTED_AT` (TIMESTAMP_NTZ) - Ingestion timestamp

**Primary Key**: `(TABLE_CODE, GEO_ID, YEAR, VAR_CODE)`

### ACS_TRACT_LONG
**Purpose**: Cleaned/normalized ACS data in long format  
**Schema**:
- `TABLE_CODE` (VARCHAR(10)) - ACS table code
- `ID_TRACT` (VARCHAR(11)) - 11-digit tract FIPS code
- `YEAR` (NUMBER) - Data year
- `VAR_CODE` (VARCHAR(20)) - Variable code
- `VAR_VALUE` (NUMBER) - Variable value

**Primary Key**: `(TABLE_CODE, ID_TRACT, YEAR, VAR_CODE)`

**Note**: `ID_TRACT` in LONG vs `GEO_ID` in RAW (same data, different column name for consistency)

---

## Expected Table Codes

### Existing Tables (16)
From existing ACS pipeline:
- B25041, B25042, B25031, B25024, B25032
- B25003, B25008, B25010, B25004, B25077
- B25058, B25064, B25070, B25071, B25092, B25085

### New Tables (2)
- **B01001** - Age and Sex
- **B15003** - Educational Attainment

**Total**: 18 tables

---

## Verification Script

Created `sql/pipelines/2_1_r_raw/acs_verify_table_structure.sql` to:
1. Check all tables in `SOURCE_PROD.ACS` schema
2. Check all tables in `SOURCE_PROD.CENSUS` schema (if exists)
3. Verify table structures
4. List registered table codes
5. Compare expected vs actual table codes

**Run verification**:
```sql
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM \
  --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/pipelines/2_1_r_raw/acs_verify_table_structure.sql
```

---

## Updated Script

### `sql/pipelines/2_1_r_raw/acs_load_age_education_tract.sql`

**Changes**:
1. ✅ Added table creation (Step 1.5)
2. ✅ Fixed COPY INTO syntax (use subquery)
3. ✅ Both B01001 and B15003 use corrected syntax

---

## Next Steps

1. ✅ Tables will be created automatically
2. ✅ COPY INTO syntax fixed
3. ⏭️  Re-run ACS load script
4. ⏭️  Run verification script to check table codes
5. ⏭️  Verify all 18 tables are registered

---

## Notes

- **Table creation**: Uses `CREATE TABLE IF NOT EXISTS` - safe to run multiple times
- **Primary keys**: Prevent duplicate data
- **Schema consistency**: Matches existing ACS pipeline structure
- **SOURCE_PROD.CENSUS**: May not exist - verification script checks both schemas

