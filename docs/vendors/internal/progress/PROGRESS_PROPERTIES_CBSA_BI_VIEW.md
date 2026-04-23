# Progress Properties by CBSA - BI View

**Date**: 2026-01-27  
**Status**: ✅ **DEPLOYED**  
**Location**: `EDW_PROD.DELIVERY.V_PROGRESS_PROPERTIES_BY_CBSA`

---

## Overview

Business Intelligence view aggregating Progress Residential properties by CBSA (Core Based Statistical Area). Uses `H3_XWALK_6810_CANON` to map ZIP codes to CBSA codes and names.

---

## Key Features

### Geographic Enrichment
- **ZIP → CBSA Mapping**: Uses `TRANSFORM_PROD.REF.H3_XWALK_6810_CANON` to enrich ZIP codes with CBSA codes and names
- **Fallback Handling**: Properties without CBSA mapping are grouped under 'UNKNOWN' / 'Unknown Market'

### Property Filtering
- **Active Properties Only**: Filters for `IS_DELETED = FALSE` and `IS_INACTIVE = FALSE`
- **Owned Properties**: Separate count for `IS_OWNED = 1`

---

## Metrics Included

### Property Counts
- `TOTAL_PROPERTIES` - Total distinct properties (by ID_SALESFORCE)
- `OWNED_PROPERTIES` - Properties where IS_OWNED = 1
- `OCCUPIED_PROPERTIES` - Properties with tenant status
- `OCCUPIED_WEBSITE` - Properties with WEBSITE_BANNER = 'Occupied'
- `COMING_SOON` - Properties with WEBSITE_BANNER = 'Coming Soon'
- `NOT_AVAILABLE` - Properties with WEBSITE_BANNER = 'Not Available'

### Property Characteristics (Averages)
- `AVG_BEDROOMS`, `AVG_BATHROOMS`, `AVG_SQUARE_FEET`
- `AVG_YEAR_BUILT`, `MEDIAN_YEAR_BUILT`

### Financial Metrics
- **Purchase Price**: `TOTAL_PURCHASE_PRICE`, `AVG_PURCHASE_PRICE`, `MEDIAN_PURCHASE_PRICE`, `AVG_PURCHASE_PRICE_PER_SF`
- **Rent Metrics**: 
  - `TOTAL_CURRENT_RENT`, `AVG_CURRENT_RENT`, `MEDIAN_CURRENT_RENT`
  - `TOTAL_MARKET_RENT`, `AVG_MARKET_RENT`, `MEDIAN_MARKET_RENT`
  - `AVG_RENT_PREMIUM` (current - market)
- **Yields**: `AVG_CAP_RATE`, `AVG_GROSS_YIELD`, `AVG_NET_YIELD`

### Operating Expenses
- `TOTAL_TAXES_YEARLY`, `AVG_TAXES_YEARLY`
- `TOTAL_HOA_YEARLY`, `AVG_HOA_YEARLY`
- `TOTAL_INSURANCE_YEARLY`, `AVG_INSURANCE_YEARLY`

### Portfolio Composition
- **Tier Levels**: `TIER_LEVEL_1_COUNT`, `TIER_LEVEL_2_COUNT`, `TIER_LEVEL_3_COUNT`, `TIER_UNKNOWN_COUNT`
- **Diversity**: `CLUSTER_COUNT`, `FUND_COUNT`, `ENTITY_COUNT`

### Geographic Coverage
- `ZIP_COUNT` - Number of distinct ZIP codes
- `COUNTY_COUNT` - Number of distinct counties
- `CITY_COUNT` - Number of distinct cities

### Data Quality Flags
- `PROPERTIES_WITHOUT_CBSA` - Properties that failed to map to CBSA
- `PROPERTIES_WITHOUT_ZIP` - Properties missing ZIP code
- `PROPERTIES_WITHOUT_RENT` - Properties missing rent data

### Date Ranges
- `EARLIEST_CLOSING_DATE`, `LATEST_CLOSING_DATE`
- `EARLIEST_STABILIZED_DATE`, `LATEST_STABILIZED_DATE`

---

## Usage Examples

### Top 10 Markets by Property Count
```sql
SELECT 
    CBSA_CODE,
    CBSA_NAME,
    STATE,
    TOTAL_PROPERTIES,
    OWNED_PROPERTIES,
    AVG_CURRENT_RENT,
    AVG_PURCHASE_PRICE
FROM EDW_PROD.DELIVERY.V_PROGRESS_PROPERTIES_BY_CBSA
ORDER BY TOTAL_PROPERTIES DESC
LIMIT 10;
```

### Markets with High Rent Premium
```sql
SELECT 
    CBSA_CODE,
    CBSA_NAME,
    AVG_CURRENT_RENT,
    AVG_MARKET_RENT,
    AVG_RENT_PREMIUM,
    TOTAL_PROPERTIES
FROM EDW_PROD.DELIVERY.V_PROGRESS_PROPERTIES_BY_CBSA
WHERE AVG_RENT_PREMIUM > 0
ORDER BY AVG_RENT_PREMIUM DESC
LIMIT 20;
```

### Data Quality Check
```sql
SELECT 
    CBSA_CODE,
    CBSA_NAME,
    TOTAL_PROPERTIES,
    PROPERTIES_WITHOUT_CBSA,
    PROPERTIES_WITHOUT_ZIP,
    PROPERTIES_WITHOUT_RENT,
    CASE 
        WHEN TOTAL_PROPERTIES > 0 
        THEN (PROPERTIES_WITHOUT_CBSA + PROPERTIES_WITHOUT_ZIP + PROPERTIES_WITHOUT_RENT) / TOTAL_PROPERTIES 
        ELSE 0 
    END AS DATA_QUALITY_ISSUE_RATE
FROM EDW_PROD.DELIVERY.V_PROGRESS_PROPERTIES_BY_CBSA
WHERE PROPERTIES_WITHOUT_CBSA > 0 
   OR PROPERTIES_WITHOUT_ZIP > 0 
   OR PROPERTIES_WITHOUT_RENT > 0
ORDER BY DATA_QUALITY_ISSUE_RATE DESC;
```

### Portfolio Composition by Tier
```sql
SELECT 
    CBSA_CODE,
    CBSA_NAME,
    TOTAL_PROPERTIES,
    TIER_LEVEL_1_COUNT,
    TIER_LEVEL_2_COUNT,
    TIER_LEVEL_3_COUNT,
    TIER_UNKNOWN_COUNT,
    CASE 
        WHEN TOTAL_PROPERTIES > 0 
        THEN TIER_LEVEL_1_COUNT / TOTAL_PROPERTIES 
        ELSE 0 
    END AS PCT_TIER_1
FROM EDW_PROD.DELIVERY.V_PROGRESS_PROPERTIES_BY_CBSA
ORDER BY TOTAL_PROPERTIES DESC;
```

---

## Technical Details

### Source Tables
- **Primary**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Enrichment**: `TRANSFORM_PROD.REF.H3_XWALK_6810_CANON`

### Join Logic
```sql
LEFT JOIN TRANSFORM_PROD.REF.H3_XWALK_6810_CANON h3
    ON LEFT(TRIM(pp.ZIP_CODE), 5) = CAST(h3.ID_ZIP AS VARCHAR)
    AND h3.GEO_LEVEL = 'ZIP'
    AND h3.ID_CBSA IS NOT NULL
```

### Filtering
- `IS_DELETED = FALSE OR IS_DELETED IS NULL`
- `IS_INACTIVE = FALSE OR IS_INACTIVE IS NULL`

### Aggregation
- Grouped by: `CBSA_CODE`, `CBSA_NAME`, `STATE`
- Ordered by: `TOTAL_PROPERTIES DESC`

---

## Notes

1. **ZIP Code Normalization**: Uses `LEFT(TRIM(ZIP_CODE), 5)` to handle ZIP+4 and whitespace
2. **CBSA Mapping**: Properties without CBSA mapping are grouped under 'UNKNOWN' / 'Unknown Market'
3. **Active Properties**: Only includes properties that are not deleted and not inactive
4. **Null Handling**: Uses `COALESCE` for CBSA code/name to ensure grouping works correctly

---

**Status**: ✅ View deployed and ready for use in `EDW_PROD.DELIVERY` schema.

