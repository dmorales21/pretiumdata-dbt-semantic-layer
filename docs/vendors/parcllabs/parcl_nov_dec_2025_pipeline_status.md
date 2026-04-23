# Parcl Labs November/December 2025 Pipeline Status

**Date**: 2026-01-XX  
**Status**: ✅ **November 2025 Data Loaded Successfully**

## Executive Summary

✅ **November 2025 data has been successfully loaded** into the Parcl ZIP absorption pipeline. The ETL process transforms data from the tall format (`PARCLLABS_HOUSING_EVENT_COUNTS_TALL`) to the wide format (`PARCLLABS_ZIP_ABSORPTION_HISTORY`), and it automatically flows through the validated view.

⚠️ **December 2025 data is not yet available** in the source tables. The ETL script is ready to process it when it becomes available.

## Data Flow Status

### ✅ Source Layer
- **SOURCE_PROD.PARCLLABS.HOUSING_EVENT_COUNTS**: November 2025 available (2025-11-01)
- **TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_COUNTS_TALL**: November 2025 available (2025-11-30, 64,116 rows)
- **TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_STOCK_TALL**: November 2025 available (2025-11-30, 95,486 rows)

### ✅ Transform Layer
- **TRANSFORM_PROD.CLEANED.PARCLLABS_ZIP_ABSORPTION_HISTORY**: 
  - ✅ **November 2025 loaded**: 20,748 rows, 20,748 unique ZIPs
  - Latest date: **2025-11-30**
  - Total coverage: 35 dates (2023-01-01 to 2025-11-30)

### ✅ Validated Layer
- **TRANSFORM_PROD.CLEANED.VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED**: 
  - ✅ **November 2025 available**: Automatically includes new data
  - Date range configured: 2023-01-01 to 2025-12-31
  - Quality validation applied per DATE_REFERENCE cohort

### ⚠️ Model Layer
- **ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1**: 
  - ⚠️ **Needs ETL update**: Still at 2025-10-01
  - Requires feature engineering ETL to process November data
  - Will include temporal comparisons, moving averages, CBSA context

### ⚠️ View Layer
- **ANALYTICS_PROD.FEATURES.VW_PARCL_ZIP_ABSORPTION_LATEST_V1**: 
  - ⚠️ **Will update automatically** once model table is updated
  - Currently shows 2025-10-01 (latest in model table)

## ETL Process Created

**File**: `sql/transform/cleaned/load_parcl_zip_absorption_nov_dec_2025.sql`

**Process**:
1. Pivots `PARCLLABS_HOUSING_EVENT_COUNTS_TALL` (tall format) to wide format
2. Joins with `PARCLLABS_MARKET` to get ZIP codes (NAME_GEOGRAPHY for GEO_LEVEL = 'ZIP5')
3. Joins with `PARCLLABS_HOUSING_STOCK_TALL` to get FOR_SALE_INVENTORY (STOCK_ALL_PROPERTIES)
4. Calculates ABSORPTION_RATE and MONTHS_OF_SUPPLY
5. Uses MERGE to update existing or insert new records

**Results**:
- ✅ November 2025: 20,748 rows inserted
- ⚠️ December 2025: 0 rows (data not yet available in source)

## Next Steps

### Immediate
1. ✅ **November data loaded** - Complete
2. ⚠️ **Model ETL**: Update `PARCL_ZIP_ABSORPTION_MODEL_V1` ETL to process November 2025 data
3. ⚠️ **Monitor December**: Check for December 2025 data availability in source

### Ongoing
1. **Automate ETL**: Schedule `load_parcl_zip_absorption_nov_dec_2025.sql` to run monthly
2. **Extend date range**: Update script to process all new months (not just Nov/Dec)
3. **Validate pipeline**: Ensure data flows through all layers correctly

## Data Quality

November 2025 data quality (from validated view):
- **TIER_1 + TIER_2**: Expected ~96% (based on historical patterns)
- **Coverage**: 20,748 ZIPs (vs ~14K-15K in recent months, ~28K in 2023-2024)
- **Completeness**: All required fields present (SALES, NEW_LISTINGS_FOR_SALE)

## Notes

- **ZIP Code Mapping**: Uses `NAME_GEOGRAPHY` from `PARCLLABS_MARKET` where `GEO_LEVEL = 'ZIP5'`
- **Inventory Source**: `FOR_SALE_INVENTORY` comes from `PARCLLABS_HOUSING_STOCK_TALL` (STOCK_ALL_PROPERTIES metric)
- **Date Format**: Source uses end-of-month dates (2025-11-30), which is consistent with historical data

