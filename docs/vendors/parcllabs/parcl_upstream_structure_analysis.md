# Parcl Labs Upstream Structure Analysis

**Date**: 2026-01-XX  
**Purpose**: Document structure of upstream Parcl tables and understand data flow

## Key Findings

### Primary Source: PARCLLABS_ZIP_ABSORPTION_HISTORY

**Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_ZIP_ABSORPTION_HISTORY`

**Structure** (Wide format):
- `ZIP_CODE` (TEXT) - ZIP code identifier
- `PARCL_ID` (NUMBER) - Parcl Labs geography ID
- `DATE_REFERENCE` (DATE) - Observation date
- `SALES` (NUMBER) - Closed sales count
- `NEW_LISTINGS_FOR_SALE` (NUMBER) - New listings count
- `FOR_SALE_INVENTORY` (NUMBER) - Active inventory count
- `ABSORPTION_RATE` (FLOAT) - **Computed**: SALES / NEW_LISTINGS_FOR_SALE
- `MONTHS_OF_SUPPLY` (NUMBER) - **Computed**: FOR_SALE_INVENTORY / (SALES / 12)
- `LAST_UPDATED` (TIMESTAMP_NTZ)
- `CREATED_AT` (TIMESTAMP_LTZ)

**Time Series**: 34 dates (2023-01-01 to 2025-10-01), 896K rows, 31,904 unique ZIPs

### Target: PARCL_ZIP_ABSORPTION_MODEL_V1

**Location**: `ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1`

**Structure**: TABLE (not view) with extensive computed columns:
- Base columns from history (ID_ZIP, geographic attributes, DATE_REFERENCE, SALES, NEW_LISTINGS_FOR_SALE, FOR_SALE_INVENTORY, ABSORPTION_RATE, MONTHS_OF_SUPPLY)
- **Temporal comparisons**: ABSORPTION_1M_AGO, ABSORPTION_12M_AGO, ABSORPTION_MOM_PCT, ABSORPTION_YOY_PCT
- **Moving averages**: ABSORPTION_3M_MA, ABSORPTION_6M_MA, ABSORPTION_12M_MA
- **CBSA context**: CBSA_ABSORPTION_AVG, ABSORPTION_VS_CBSA, ABSORPTION_QUINTILE
- **Categorization**: SEASONAL_INDICATOR, INVENTORY_PRESSURE, INVENTORY_REGIME, DATA_TYPE
- **Scoring**: ABSORPTION_SCORE_0_100, ABSORPTION_DAYS, ABSORPTION_SPEED_LABEL, ABSORPTION_VOLATILITY_LABEL, ABSORPTION_VOL_12M, NINE_BOX_LABEL

**Time Series**: 34 dates (2023-01-01 to 2025-10-01), 71M rows, 31,210 unique ZIPs

## Statistical Summary (from PARCLLABS_ZIP_ABSORPTION_HISTORY)

### SALES
- Min: 0
- Max: 1,330
- Avg: 18.67
- StdDev: 29.09
- **Expected Range**: 0 to ~150 (3-sigma: 18.67 ± 87.27)

### NEW_LISTINGS_FOR_SALE
- Min: 0
- Max: 606
- Avg: 19.27
- StdDev: 32.33
- **Expected Range**: 0 to ~116 (3-sigma: 19.27 ± 96.99)

### FOR_SALE_INVENTORY
- Min: 0
- Max: 6,209
- Avg: 126.49
- StdDev: 247.70
- **Expected Range**: 0 to ~870 (3-sigma: 126.49 ± 743.10)

### ABSORPTION_RATE
- Min: 0.0
- Max: 149.75 ⚠️ **EXTREME OUTLIER** (should be 0.0-1.0)
- Avg: 1.22
- StdDev: 1.34
- **Expected Range**: 0.0 to 1.0 (domain knowledge)
- **3-sigma range**: -2.80 to 5.24 (statistical, but domain constraint is 0-1)

### MONTHS_OF_SUPPLY
- Min: 0.04
- Max: 1,221.00 ⚠️ **EXTREME OUTLIER** (should be 0-24)
- Avg: 7.97
- StdDev: 8.23
- **Expected Range**: 0.0 to 24.0 (domain knowledge)
- **3-sigma range**: -16.72 to 32.66 (statistical, but domain constraint is 0-24)

## Data Quality Issues Identified

1. **ABSORPTION_RATE outliers**: Max value 149.75 is way above expected 1.0
   - Likely caused by division by very small NEW_LISTINGS_FOR_SALE values
   - Need to validate: NEW_LISTINGS_FOR_SALE > 0 before computing absorption

2. **MONTHS_OF_SUPPLY outliers**: Max value 1,221 is extreme
   - Likely caused by very low SALES (division by near-zero)
   - Need to validate: SALES > 0 before computing months of supply

3. **Zero values**: Many ZIPs have 0 for SALES, NEW_LISTINGS, or INVENTORY
   - These are valid (no activity), but computed metrics should be NULL, not 0 or extreme values

## Validation Requirements

### Required Fields (70% weight)
- `ZIP_CODE` / `ID_ZIP`
- `DATE_REFERENCE`
- `SALES` (can be 0, but should be >= 0)
- `NEW_LISTINGS_FOR_SALE` (can be 0, but should be >= 0)

### Optional Fields (30% weight)
- `FOR_SALE_INVENTORY` (can be 0, but should be >= 0)
- Geographic attributes (ID_STATE, ID_COUNTY, ID_CBSA, etc.)

### Computed Metrics Validation
- `ABSORPTION_RATE`: Should be 0.0-1.0 (or NULL if NEW_LISTINGS_FOR_SALE = 0)
- `MONTHS_OF_SUPPLY`: Should be 0.0-24.0 (or NULL if SALES = 0)

### Outlier Detection Rules
1. **Statistical**: 3-sigma rule (mean ± 3 * stddev)
2. **Percentile-based**: Outside P5-P95 range
3. **Domain knowledge**: 
   - ABSORPTION_RATE > 1.0 → OUTLIER
   - MONTHS_OF_SUPPLY > 24.0 → OUTLIER
   - Negative values where not allowed → OUTLIER

## Next Steps

1. ✅ Document structure - **COMPLETE**
2. Create validated view on `PARCLLABS_ZIP_ABSORPTION_HISTORY`
3. Apply validation before feature logic in model table

