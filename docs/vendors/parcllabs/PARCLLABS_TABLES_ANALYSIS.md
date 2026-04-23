# ParclLabs Tables Analysis

## Date: 2026-01-19
## Purpose: Document ParclLabs table structure and identify rent history data

---

## Key Findings

### Existing ParclLabs Tables in CLEANED

Based on documentation review, the following ParclLabs tables exist in `TRANSFORM_PROD.CLEANED`:

1. **PARCLLABS_HOUSING_STOCK** - Housing stock by product type (SFR, CONDO, TOWNHOUSE, OTHER)
2. **PARCLLABS_HOUSING_EVENT_COUNTS_TALL** - Event counts (SALES, TRANSFERS, NEW_LISTINGS_FOR_SALE, NEW_LISTINGS_FOR_RENT)
3. **PARCLLABS_ZIP_ABSORPTION_HISTORY** - Absorption metrics (SALES, NEW_LISTINGS_FOR_SALE, FOR_SALE_INVENTORY, ABSORPTION_RATE, MONTHS_OF_SUPPLY)
4. **PARCLLABS_HOUSING_EVENT_PRICES** - Pricing data from housing events
5. **PARCLLABS_HOUSING_EVENT_PRICES_TALL** - Tall format pricing data
6. **PARCLLABS_MARKET** - Market-level data
7. **PARCLLABS_MARKET_TALL** - Tall format market data

### Missing: PARCLLABS_RENT_HISTORY

**Status**: ⚠️ **NOT FOUND**

The factization script `populate_fact_housing_hou_pricing_parcllabs_rent.sql` references:
- `TRANSFORM_PROD.CLEANED.PARCLLABS_RENT_HISTORY`
- Columns: `DATE_REFERENCE`, `ZIP_CODE`, `MEDIAN_RENT`, `BEDROOMS`

**Investigation Needed**:
1. Check if `PARCLLABS_RENT_HISTORY` exists in `SOURCE_PROD.PARCLLABS` schema
2. Check if rent data exists in `PARCLLABS_HOUSING_EVENT_PRICES` or `PARCLLABS_HOUSING_EVENT_PRICES_TALL`
3. Determine if a CLEANED view needs to be created from source data

---

## ParclLabs Data Structure

### Housing Stock
- **Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_STOCK`
- **Structure**: Wide format with product type columns
- **Geography**: Parcl ID (maps to ZIP5 via `PARCLLABS_MARKET.NAME_GEOGRAPHY`)
- **Time Series**: Monthly data
- **Product Types**: SFR, CONDO, TOWNHOUSE, OTHER, ALL

### Housing Events
- **Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_COUNTS_TALL`
- **Structure**: Tall format
- **Metrics**: SALES, TRANSFERS, NEW_LISTINGS_FOR_SALE, NEW_LISTINGS_FOR_RENT
- **Time Series**: 6 months (2025-06-30 to 2025-11-30)
- **Geography**: Parcl ID

### Absorption History
- **Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_ZIP_ABSORPTION_HISTORY`
- **Structure**: Wide format
- **Metrics**: SALES, NEW_LISTINGS_FOR_SALE, FOR_SALE_INVENTORY, ABSORPTION_RATE, MONTHS_OF_SUPPLY
- **Time Series**: 34 months (2023-01-01 to 2025-10-01)
- **Geography**: ZIP5
- **Row Count**: 896K rows, 31,904 unique ZIPs

### Housing Event Prices
- **Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES` / `PARCLLABS_HOUSING_EVENT_PRICES_TALL`
- **Structure**: Pricing data from housing events
- **Potential Rent Data**: May contain rental pricing information
- **Investigation Needed**: Check if rent prices are in these tables

---

## Rent History Investigation

### Current Factization Script
The existing script `populate_fact_housing_hou_pricing_parcllabs_rent.sql` expects:
- Source: `TRANSFORM_PROD.CLEANED.PARCLLABS_RENT_HISTORY`
- Columns: `DATE_REFERENCE`, `ZIP_CODE`, `MEDIAN_RENT`, `BEDROOMS`
- Product Type: `ALL` (product-agnostic)
- Tenancy: `RENT`

### Next Steps

1. **Check SOURCE_PROD**:
   ```sql
   SHOW TABLES LIKE '%RENT%' IN SCHEMA SOURCE_PROD.PARCLLABS;
   SHOW TABLES LIKE '%RENTAL%' IN SCHEMA SOURCE_PROD.PARCLLABS;
   ```

2. **Check CLEANED**:
   ```sql
   SHOW TABLES LIKE '%RENT%' IN SCHEMA TRANSFORM_PROD.CLEANED;
   SHOW TABLES LIKE '%RENTAL%' IN SCHEMA TRANSFORM_PROD.CLEANED;
   ```

3. **Check Housing Event Prices**:
   ```sql
   SELECT DISTINCT META_METRIC 
   FROM TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_PRICES_TALL
   WHERE META_METRIC LIKE '%RENT%' OR META_METRIC LIKE '%rental%';
   ```

4. **If Rent Data Exists in Source**:
   - Create `TRANSFORM_PROD.CLEANED.PARCLLABS_RENT_HISTORY` view
   - Aggregate by ZIP5, DATE_REFERENCE, BEDROOMS
   - Calculate MEDIAN_RENT

5. **If Rent Data Doesn't Exist**:
   - Update factization script to handle missing view gracefully
   - Document that ParclLabs rent data is not available

---

## ParclLabs API Documentation

Based on `docs/api/parcl_api.md`, ParclLabs API provides:
- Property search with housing event history
- Market-level analytics
- Housing stock data
- Sales, listings, rentals, investor activity

**Note**: The API documentation suggests rental data may be available, but the specific table structure in our warehouse needs verification.

---

## Recommendations

1. **Immediate**: Run investigation queries to determine if rent data exists
2. **If Rent Data Exists**: Create `PARCLLABS_RENT_HISTORY` CLEANED view
3. **If Rent Data Doesn't Exist**: 
   - Update factization script to skip gracefully
   - Document limitation
   - Consider alternative sources for rent data

---

## Related Documentation

- `docs/parcl_upstream_structure_analysis.md` - Upstream structure analysis
- `docs/parcl_time_series_analysis_report.md` - Time series characteristics
- `sql/transform/fact/populate_fact_housing_hou_pricing_parcllabs_rent.sql` - Existing factization script
- `sql/transform/fact/datasets/parcllabs/EXECUTION_SUMMARY.md` - ParclLabs factization summary

