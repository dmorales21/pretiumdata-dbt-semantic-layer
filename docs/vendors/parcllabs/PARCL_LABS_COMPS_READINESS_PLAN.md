# Parcl Labs System Readiness for Comps Analysis

**Date**: 2026-01-27  
**Status**: ✅ **OWNERSHIP DATA COMPLETE** | ⚠️ **PRICING DATA NEEDS FACTIZATION**

---

## Executive Summary

**Current Status**:
- ✅ **Ownership Data**: Fully factized (22 months, 338 CBSAs)
- ✅ **Housing Stock**: Factized (6 months available in source)
- ⚠️ **Pricing/Rental Data**: Available in CLEANED but NOT factized
- ❌ **Rent History**: Table doesn't exist (needs creation from event prices)

**For Comps Readiness**:
- Comps system uses Parcl Labs API directly (real-time)
- Historical comps analysis needs factized pricing data
- Need to factize rental listing prices from `PARCLLABS_HOUSING_EVENT_PRICES`

---

## Current Data Status

### ✅ Ownership & Stock Data (COMPLETE)

**FACT Table**: `HOUSING_HOU_OWNERSHIP_ALL_TS`

| Metric | Months | CBSAs | Status |
|--------|--------|-------|--------|
| `PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS` | 22 | 338 | ✅ Complete |
| `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS` | 22 | 338 | ✅ Complete |
| `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS` | 22 | 338 | ✅ Complete |
| `PARCLLABS_HOUSING_STOCK_SF_UNITS` | 6 | 338 | ✅ Complete (limited by source) |

**Note**: Housing stock only has 6 months (2025-06 to 2025-11) because that's all that exists in CLEANED table.

---

### ⚠️ Pricing/Rental Data (NEEDS FACTIZATION)

**CLEANED Tables Available**:
1. **`PARCLLABS_HOUSING_EVENT_PRICES`** (72,398 rows)
   - **Time Series**: 7 months (2025-06-30 to 2025-12-31)
   - **Key Columns**:
     - `PRICE_NEW_RENTAL_LISTINGS` - Rent prices for new listings ⭐
     - `PRICE_ACQUISITIONS` - Acquisition prices
     - `PRICE_DISPOSITIONS` - Disposition prices
     - `PRICE_NEW_LISTINGS_FOR_SALE` - Sale prices
     - `PSQF_NEW_RENTAL_LISTINGS` - Price per square foot for rentals
   - **Geography**: PARCL_ID (needs mapping to ZIP/CBSA)

2. **`PARCLLABS_HOUSING_EVENT_PRICES_TALL`** (196,988 rows)
   - **Time Series**: 7 months (2025-06-30 to 2025-12-31)
   - **Structure**: Tall format with `METRIC` and `VALUE` columns
   - **Geography**: PARCL_ID (needs mapping to ZIP/CBSA)

**FACT Table Status**: `HOUSING_HOU_PRICING_ALL_TS`
- ❌ No Parcl Labs pricing data found
- ⚠️ Existing script references non-existent `PARCLLABS_RENT_HISTORY` table

---

## Comps System Requirements

### Current Comps Framework

**Primary Source**: Parcl Labs API (real-time)
- Uses `/v2/property_search` endpoint
- Progressive fallback strategy (5 tiers)
- Returns investor-owned rental listings
- **Coverage**: 60-80% of properties

**Fallback Source**: Zonda Floorplans
- BTR rent data from Snowflake
- **Coverage**: 10-20% additional properties

### Historical Comps Analysis Needs

For historical comps analysis (not just real-time API calls), the system needs:

1. **Factized Rental Prices**:
   - ZIP-level or CBSA-level rental prices
   - Time series data (monthly)
   - Bedroom segmentation
   - Product type (SFR, CONDO, etc.)

2. **Property Characteristics**:
   - Bedrooms, bathrooms, square feet
   - Property type
   - Geographic location (ZIP, CBSA)

3. **Event Dates**:
   - When rental listings were posted
   - When properties were acquired/disposed
   - For matching comps to rent event dates

---

## Required Actions for Comps Readiness

### Priority 1: Factize Rental Listing Prices

**Action**: Create factization script for `PARCLLABS_HOUSING_EVENT_PRICES`

**Source**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES`  
**Target**: `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`

**Metrics to Factize**:
1. `PRICE_NEW_RENTAL_LISTINGS` → `PARCLLABS_MEDIAN_RENT_NEW_LISTINGS`
2. `PSQF_NEW_RENTAL_LISTINGS` → `PARCLLABS_MEDIAN_RENT_PSQF_NEW_LISTINGS`

**Geography Mapping**:
- PARCL_ID → ZIP (via `PARCLLABS_SF_HOUSING_STOCK_OWNERSHIP`)
- ZIP → CBSA (via `MAP_ZIP`)

**Aggregation**:
- Aggregate to ZIP level (median rent by ZIP, DATE_REFERENCE, BEDROOMS)
- Optionally aggregate to CBSA level for market-level analysis

**Time Series**: 7 months (2025-06-30 to 2025-12-31)

---

### Priority 2: Create Rent History View (Optional)

**Action**: Create `PARCLLABS_RENT_HISTORY` view/table from event prices

**Purpose**: Provide standardized rent history format for existing factization script

**Structure**:
```sql
CREATE OR REPLACE VIEW TRANSFORM_PROD.CLEANED.PARCLLABS_RENT_HISTORY AS
SELECT 
    DATE_REFERENCE,
    ZIP_CODE,
    BEDROOMS,
    MEDIAN(PRICE_NEW_RENTAL_LISTINGS) as MEDIAN_RENT
FROM TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES
-- Join to get ZIP from PARCL_ID
GROUP BY DATE_REFERENCE, ZIP_CODE, BEDROOMS
```

**Note**: This would enable the existing `populate_fact_housing_hou_pricing_parcllabs_rent.sql` script to work.

---

### Priority 3: Property-Level Comps Table (Advanced)

**Action**: Create property-level comps lookup table

**Purpose**: Enable fast comp queries by property characteristics

**Structure**:
```sql
CREATE OR REPLACE TABLE TRANSFORM_PROD.JOINED.PARCLLABS_PROPERTY_COMPS AS
SELECT 
    PARCL_ID,
    DATE_REFERENCE,
    ZIP_CODE,
    ID_CBSA,
    BEDROOMS,
    BATHROOMS,
    SQUARE_FEET,
    PRICE_NEW_RENTAL_LISTINGS as RENT,
    PSQF_NEW_RENTAL_LISTINGS as RENT_PSQF,
    PRODUCT_TYPE_CODE,
    OWNER_NAME
FROM TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES
-- Join to get ZIP/CBSA and owner info
```

**Use Case**: Fast comp lookups by ZIP, beds, baths, sqft, date range

---

## Implementation Plan

### Phase 1: Factize Rental Prices (Immediate)

1. **Create factization script**:
   - File: `sql/transform/fact/populate_fact_housing_hou_pricing_parcllabs_rent_listings.sql`
   - Source: `PARCLLABS_HOUSING_EVENT_PRICES`
   - Target: `HOUSING_HOU_PRICING_ALL_TS`
   - Metrics: `PARCLLABS_MEDIAN_RENT_NEW_LISTINGS`, `PARCLLABS_MEDIAN_RENT_PSQF_NEW_LISTINGS`

2. **Geography mapping**:
   - PARCL_ID → ZIP (via ownership table)
   - ZIP → CBSA (via MAP_ZIP)
   - Aggregate to ZIP level (median by ZIP, DATE, BEDROOMS)

3. **Execute and validate**:
   - Run factization script
   - Validate data appears in FACT table
   - Check time series completeness

### Phase 2: Create Rent History View (Optional)

1. **Create view**:
   - File: `sql/transform/cleaned/create_parcllabs_rent_history_view.sql`
   - Aggregates event prices to rent history format
   - Enables existing factization script to work

2. **Execute existing script**:
   - Run `populate_fact_housing_hou_pricing_parcllabs_rent.sql`
   - Should now work with the view

### Phase 3: Property-Level Comps Table (Future)

1. **Create comps lookup table**:
   - File: `sql/transform/joined/create_parcllabs_property_comps.sql`
   - Property-level data for fast comp queries
   - Indexed by ZIP, beds, baths, sqft, date

2. **Create comps query functions**:
   - Functions to query comps by property characteristics
   - Support for progressive fallback (similar to API)

---

## Validation Queries

### Check Factized Rental Prices

```sql
SELECT 
    COUNT(*) as total_rows,
    COUNT(DISTINCT DATE_REFERENCE) as distinct_dates,
    COUNT(DISTINCT GEO_ID) as distinct_zips,
    MIN(DATE_REFERENCE) as earliest_date,
    MAX(DATE_REFERENCE) as latest_date
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS
WHERE VENDOR_NAME = 'PARCLLABS'
  AND METRIC_ID = 'PARCLLABS_MEDIAN_RENT_NEW_LISTINGS';
```

### Check Comps Coverage

```sql
SELECT 
    GEO_ID as ZIP_CODE,
    COUNT(DISTINCT DATE_REFERENCE) as months_with_data,
    COUNT(DISTINCT BEDROOMS) as bedroom_types
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS
WHERE VENDOR_NAME = 'PARCLLABS'
  AND METRIC_ID = 'PARCLLABS_MEDIAN_RENT_NEW_LISTINGS'
GROUP BY GEO_ID
ORDER BY months_with_data DESC;
```

---

## Summary

**Completed**:
- ✅ Ownership data factized (22 months, 338 CBSAs)
- ✅ Housing stock factized (6 months, limited by source)

**Next Steps**:
1. ⏳ Factize rental listing prices from `PARCLLABS_HOUSING_EVENT_PRICES`
2. ⏳ Create rent history view (optional, for existing script)
3. ⏳ Create property-level comps table (future enhancement)

**Comps Readiness**: 
- ✅ Real-time comps: Ready (uses API)
- ⚠️ Historical comps: Needs factized pricing data
- ⏳ Property-level comps: Needs comps lookup table

---

**Last Updated**: 2026-01-27

