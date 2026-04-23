# Parcl Labs November/December 2025 Data Check

**Date**: 2026-01-XX  
**Purpose**: Verify November and December 2025 data availability and pipeline flow

## Findings

### Source Data Status

#### SOURCE_PROD.PARCLLABS Schema
- **PARCL_CBSA_ENRICHED_METRICS_HISTORICAL**: 
  - Latest date: **2025-06-01** (30 dates total)
  - ❌ **No November/December 2025 data**

- **DEMAND_DF_HISTORICAL**: 
  - Latest date: **2025-06-01** (30 dates total)
  - ❌ **No November/December 2025 data**

- **HOUSING_EVENT_COUNTS**: 
  - ✅ **November 2025 data available**: 2025-11-01 (21,372 rows)
  - Date range: 2025-06-01 to 2025-11-01 (6 dates)
  - Uses `MONTHLY_DATE` column (not DATE_REFERENCE)
  - ⚠️ **December 2025 data not yet available**

### TRANSFORM_PROD.CLEANED Status

#### PARCLLABS_HOUSING_EVENT_COUNTS_TALL
- ✅ **November 2025 data available**: 2025-11-30 (64,116 rows, 21,372 unique Parcl IDs)
- Date range: 2025-06-30 to 2025-11-30 (6 dates)
- This is the source for ZIP absorption calculations

#### PARCLLABS_ZIP_ABSORPTION_HISTORY
- **Current coverage**: 34 dates (2023-01-01 to **2025-10-01**)
- **Total rows**: 896,110
- ❌ **No November/December 2025 data** - **ETL PROCESS NEEDED**
- ⚠️ **Gap identified**: November data exists in source but hasn't been transformed yet

**Monthly breakdown (2025)**:
- 2025-10: 14,697 rows
- 2025-09: 14,750 rows
- 2025-08: 14,800 rows
- 2025-07: 15,725 rows
- 2025-06: 28,316 rows
- 2025-05: 28,240 rows
- ... (earlier months have ~27K-28K rows)

### Pipeline Configuration

#### Validated View
- **View**: `TRANSFORM_PROD.CLEANED.VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED`
- **Date filter**: `DATE_REFERENCE >= '2023-01-01' AND DATE_REFERENCE <= '2025-12-31'`
- ✅ **Ready to accept Nov/Dec 2025 data when available**

#### Model Table
- **Table**: `ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1`
- **Latest date**: 2025-10-01
- ⚠️ **ETL process needs to be run to populate Nov/Dec data when available**

#### Final View
- **View**: `ANALYTICS_PROD.FEATURES.VW_PARCL_ZIP_ABSORPTION_LATEST_V1`
- **Filter**: Latest DATE_REFERENCE only
- ✅ **Will automatically show Nov/Dec when model table is updated**

## Recommendations

### 1. **Source Data Status** ✅
   - ✅ November 2025 data is available in `SOURCE_PROD.PARCLLABS.HOUSING_EVENT_COUNTS`
   - ✅ November 2025 data is available in `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_COUNTS_TALL`
   - ⚠️ December 2025 data not yet available (check again later)

### 2. **ETL Process - URGENT** ⚠️
   - **Issue**: November 2025 data exists in source but hasn't been transformed into `PARCLLABS_ZIP_ABSORPTION_HISTORY`
   - **Action Required**: 
     1. Identify/create ETL process that transforms `PARCLLABS_HOUSING_EVENT_COUNTS_TALL` → `PARCLLABS_ZIP_ABSORPTION_HISTORY`
     2. Process needs to:
        - Pivot tall format to wide format
        - Join with geography mapping (PARCL_ID → ZIP_CODE)
        - Calculate ABSORPTION_RATE and MONTHS_OF_SUPPLY
        - Load November 2025 data (and December when available)
   - **Pipeline Gap**: Data exists in source but transformation step is missing/not running

### 3. **Pipeline Readiness**
   - ✅ Validated view is configured for 2025-12-31 end date
   - ✅ Views will automatically include new data when source is updated
   - ⚠️ ETL process needs to be run to populate model table

### 4. **Data Estimates (if needed)**
   - If Nov/Dec data is not available, consider:
     - Using historical patterns to estimate
     - Using CBSA-level data if available
     - Flagging as estimated/missing in quality metadata

## Next Steps

1. ✅ **Source Data Verified**: November 2025 data exists in `PARCLLABS_HOUSING_EVENT_COUNTS_TALL`
2. ⚠️ **URGENT - ETL Process**: 
   - Find or create ETL that transforms `PARCLLABS_HOUSING_EVENT_COUNTS_TALL` → `PARCLLABS_ZIP_ABSORPTION_HISTORY`
   - Process November 2025 data (and December when available)
   - Ensure ETL runs regularly for future months
3. **Validate Pipeline**: Once ETL runs, verify data flows:
   - `PARCLLABS_ZIP_ABSORPTION_HISTORY` → `VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED` → `PARCL_ZIP_ABSORPTION_MODEL_V1` → `VW_PARCL_ZIP_ABSORPTION_LATEST_V1`
4. **Monitor**: Check for December 2025 data availability in source

## Status Summary

| Component | Status | Latest Date | Nov/Dec Ready |
|-----------|--------|-------------|---------------|
| SOURCE_PROD.PARCLLABS.HOUSING_EVENT_COUNTS | ✅ Nov Available | 2025-11-01 | ⚠️ Dec Missing |
| TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_COUNTS_TALL | ✅ Nov Available | 2025-11-30 | ⚠️ Dec Missing |
| TRANSFORM_PROD.CLEANED.PARCLLABS_ZIP_ABSORPTION_HISTORY | ✅ **Nov Loaded** | **2025-11-30** | ✅ **ETL Created** |
| VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED | ✅ **Nov Available** | **2025-11-30** | ✅ Configured |
| PARCL_ZIP_ABSORPTION_MODEL_V1 | ⚠️ Needs ETL | 2025-10-01 | ⚠️ Needs ETL |
| VW_PARCL_ZIP_ABSORPTION_LATEST_V1 | ⚠️ Needs Model Update | 2025-10-01 | ⚠️ Needs Model Update |

## Resolution

**✅ November 2025 Data Loaded**: 
- ✅ ETL script created: `sql/transform/cleaned/load_parcl_zip_absorption_nov_dec_2025.sql`
- ✅ November 2025 data loaded: 20,748 rows, 20,748 unique ZIPs
- ✅ Data flows through validated view automatically
- ⚠️ **Model table needs ETL update** to include November data in feature engineering
- ⚠️ **December 2025 data not yet available** in source (will be loaded when available)

