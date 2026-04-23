# Parcl Labs Time Series Analysis Report

**Date**: 2026-01-XX  
**Purpose**: Validate time series length and characteristics before implementing validation logic

## Executive Summary

- **PARCLLABS_HOUSING_EVENT_COUNTS_TALL**: Only 6 months of data (2025-06-30 to 2025-11-30)
- **PARCLLABS_ZIP_ABSORPTION_HISTORY**: Contains historical data (needs analysis)
- **PARCL_ZIP_ABSORPTION_MODEL_V1**: 34 months of data (2023-01-01 to 2025-10-01) - **much longer than source**

## Objects Discovered

### Tables in TRANSFORM_PROD.CLEANED (17 total)

1. PARCLLABS_ABSORPTION_SFR_HISTORICAL
2. PARCLLABS_ABSORPTION_SFR_RECENT
3. PARCLLABS_ABSORPTION_SFR_UNIFIED
4. PARCLLABS_ABSORPTION_SFR_WITH_TRENDS
5. PARCLLABS_ABSORPTION_SFR_ZIP
6. PARCLLABS_ACTIVE_LISTINGS
7. PARCLLABS_HOUSING_EVENT_COUNTS
8. **PARCLLABS_HOUSING_EVENT_COUNTS_TALL** ⭐ (Primary source)
9. PARCLLABS_HOUSING_EVENT_PRICES
10. PARCLLABS_HOUSING_EVENT_PRICES_TALL
11. PARCLLABS_HOUSING_EVENT_PROPERTY_ATTRIBUTES_TALL
12. PARCLLABS_HOUSING_STOCK
13. PARCLLABS_HOUSING_STOCK_TALL
14. PARCLLABS_MARKET
15. PARCLLABS_MARKET_TALL
16. PARCLLABS_PRICE_CHANGES
17. **PARCLLABS_ZIP_ABSORPTION_HISTORY** ⭐ (896K rows - potential historical source)

### Views in TRANSFORM_PROD.CLEANED (16 total)

Same names as tables (likely views wrapping the tables)

## Detailed Analysis

### 1. PARCLLABS_HOUSING_EVENT_COUNTS_TALL

**Structure**: Tall/narrow format
- `DATE_REFERENCE` (DATE)
- `ID_PARCL` (NUMBER) - Parcl geography ID
- `META_SOURCE` (VARCHAR)
- `META_DATASET` (VARCHAR)
- `META_METRIC` (VARCHAR) - Metric name
- `VALUE` (NUMBER) - Metric value
- `META_LAST_UPDATED` (TIMESTAMP)

**Time Series Characteristics**:
- **Unique Dates**: 6
- **Date Range**: 2025-06-30 to 2025-11-30
- **Days Span**: 153 days
- **Months Span**: 5 months
- **Total Rows**: 328,869
- **Unique Parcl IDs**: ~21,373 (21,373 for most months, 2,760 for June 2025)
- **Unique Metrics**: 3
  - `NEW_LISTINGS_FOR_SALE`
  - `SALES`
  - `TRANSFERS`

**Monthly Breakdown**:
| Month | Unique Parcl IDs | Total Rows |
|-------|------------------|------------|
| 2025-11 | 21,372 | 64,116 |
| 2025-10 | 21,372 | 64,116 |
| 2025-09 | 21,373 | 64,119 |
| 2025-08 | 21,373 | 64,119 |
| 2025-07 | 21,373 | 64,119 |
| 2025-06 | 2,760 | 8,280 |

**Data Quality**:
- ✅ No NULL dates
- ✅ No future dates
- ✅ No gaps in time series (all dates are monthly end dates)
- ⚠️ **Limited history**: Only 5-6 months of data
- ⚠️ **June 2025 partial**: Only 2,760 Parcl IDs vs ~21,373 for other months

### 2. PARCL_ZIP_ABSORPTION_MODEL_V1 (ANALYTICS_PROD.FEATURES)

**Time Series Characteristics**:
- **Unique Dates**: 34
- **Date Range**: 2023-01-01 to 2025-10-01
- **Days Span**: 1,004 days
- **Months Span**: 33 months
- **Total Rows**: 71,317,641
- **Unique ZIPs**: 31,210

**Key Finding**: 
- ⚠️ **Model has 33 months of data but source only has 5 months**
- This suggests the model is built from a different source or has historical data that's been archived/removed from CLEANED layer

### 3. PARCLLABS_ZIP_ABSORPTION_HISTORY (TRANSFORM_PROD.CLEANED)

**Structure**: Wide format with computed metrics
- `ZIP_CODE` (TEXT)
- `PARCL_ID` (NUMBER)
- `DATE_REFERENCE` (DATE)
- `SALES` (NUMBER)
- `NEW_LISTINGS_FOR_SALE` (NUMBER)
- `FOR_SALE_INVENTORY` (NUMBER)
- `ABSORPTION_RATE` (FLOAT) - **Computed metric**
- `MONTHS_OF_SUPPLY` (NUMBER) - **Computed metric**
- `LAST_UPDATED` (TIMESTAMP_NTZ)
- `CREATED_AT` (TIMESTAMP_LTZ)

**Time Series Characteristics**:
- **Unique Dates**: 34
- **Date Range**: 2023-01-01 to 2025-10-01
- **Days Span**: 1,004 days
- **Months Span**: 33 months
- **Total Rows**: 896,110
- **Unique ZIPs**: 31,904

**Key Finding**: 
- ✅ **This is the historical source for PARCL_ZIP_ABSORPTION_MODEL_V1**
- ✅ Time series matches exactly (34 dates, same range)
- ✅ Already has computed metrics (ABSORPTION_RATE, MONTHS_OF_SUPPLY)
- ✅ Wide format (easier to work with than tall format)

**Monthly Coverage**: Consistent coverage of ~27K-28K ZIPs per month (2023-2024), drops to ~14K-15K in recent months (2025)

## Recommendations

### 1. **Primary Source for Validation** ✅
   - **`PARCLLABS_ZIP_ABSORPTION_HISTORY`** is the primary source
   - Has 33 months of historical data (2023-01 to 2025-10)
   - Already has computed metrics (ABSORPTION_RATE, MONTHS_OF_SUPPLY)
   - Wide format is easier to validate than tall format
   - This is what feeds `PARCL_ZIP_ABSORPTION_MODEL_V1`

### 2. **Validation Window Sizing**
   - **33 months available** - sufficient for comprehensive validation
   - Statistical validation can use full 33-month window
   - For moving averages and trends:
     - 3-month MA: ✅ Feasible
     - 6-month MA: ✅ Feasible
     - 12-month MA: ✅ Feasible
     - 24-month MA: ✅ Feasible

### 3. **Data Quality Considerations**
   - Recent months (2025) show reduced coverage (~14K-15K ZIPs vs ~28K in 2023-2024)
   - This may indicate data source changes or filtering
   - Consider flagging recent months with reduced coverage
   - Monitor ZIP coverage trends

### 4. **Architecture Decision** ✅
   - **Apply validation to `PARCLLABS_ZIP_ABSORPTION_HISTORY`**
   - This is the source that feeds the model
   - `PARCLLABS_HOUSING_EVENT_COUNTS_TALL` appears to be a different pipeline (recent data only, tall format)
   - Validation should happen before `PARCL_ZIP_ABSORPTION_MODEL_V1` is created

## Next Steps

1. ✅ Complete time series analysis for `PARCLLABS_ZIP_ABSORPTION_HISTORY`
2. ✅ Determine relationship between `PARCLLABS_HOUSING_EVENT_COUNTS_TALL` and `PARCL_ZIP_ABSORPTION_MODEL_V1`
3. ✅ Identify which source(s) should receive validation
4. ✅ Adjust validation logic to account for limited time series (5-6 months)

