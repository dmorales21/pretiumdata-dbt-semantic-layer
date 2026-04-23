# Signal Framework: MLS Data Integration - Action Plan

**Date**: 2026-01-29  
**Status**: 🚨 **CRITICAL ISSUES IDENTIFIED** - Immediate Action Required  
**Impact**: Signals have 0 data despite 63M+ MLS records available

---

## Executive Summary

### Critical Findings

#### 1. **Data Quality Issue**: Corrupt Future Dates
- MLS data contains dates in year **2079, 2049, 2077** (!!)
- This causes signal filters to exclude all "future" data
- **However**: Recent data (2024-2026) does exist: **63M valid records**

#### 2. **Metric Name Mismatch**: Signal Queries Looking for Wrong Names
- **Signal expects**: `CHERRE_MLS_MEDIAN_DOM_ZIP`, `CHERRE_MLS_ACTIVE_LISTINGS_ZIP`
- **Actual data has**: `CHERRE_MLS_DAYS_ON_MARKET`, `CHERRE_MLS_ACTIVE_LISTINGS` (no `_ZIP` suffix)
- **Result**: 0 rows match despite millions of records available

#### 3. **CBSA Coverage Issue**: ID_CBSA Column Exists But Reports 0 Coverage
- The `ID_CBSA` column exists in schema
- But `COUNT(DISTINCT id_cbsa)` returns **0** for all metrics
- **Hypothesis**: Either NULL values, or data stored at ZIP/PROPERTY level without CBSA rollup

---

## Available MLS Data Assets

### Inventory Metrics (HOUSING_HOU_INVENTORY_CHERRE_MLS)

| Metric ID | Records (2024-2026) | Product Types | Latest Date |
|-----------|---------------------|---------------|-------------|
| **CHERRE_MLS_DAYS_ON_MARKET** | 25.2M | 3 (SF, MF, ?) | 2026-12-31 |
| **CHERRE_MLS_CUMULATIVE_DOM** | 19.3M | 3 | 2026-12-31 |
| **CHERRE_MLS_ACTIVE_LISTINGS** | 10.6M | 3 | 2026-12-29 |
| **CHERRE_MLS_PENDING_LISTINGS** | 4.8M | 3 | 2026-07-31 |
| **CHERRE_MLS_WITHDRAWN_LISTINGS** | 2.0M | 3 | 2026-12-31 |
| **CHERRE_MLS_EXPIRED_LISTINGS** | 1.7M | 3 | 2026-12-29 |
| **Total** | **63.6M records** | | |

###Pricing Metrics (HOUSING_HOU_PRICING_CHERRE_MLS)

| Metric ID | Records (Recent) | Product Types |
|-----------|------------------|---------------|
| **CHERRE_MLS_LIST_PRICE** | 2.2M | 3 |
| **CHERRE_MLS_PRICE_PER_SQFT** | 1.9M | 3 |
| **CHERRE_MLS_PRIOR_SALE_PRICE** | 1.1M | 3 |

---

## Immediate Actions Required

### Priority 1: Fix Metric Name Mismatch (30 minutes)

**File**: `models/analytics_prod/scores/fct_mls_velocity_signal.sql`

**Current (WRONG)**:
```sql
AND metric_id IN (
    'CHERRE_MLS_MEDIAN_DOM_ZIP',       -- ❌ DOESN'T EXIST
    'CHERRE_MLS_CUMULATIVE_DOM_ZIP',   -- ❌ DOESN'T EXIST
    'CHERRE_MLS_ACTIVE_LISTINGS_ZIP',  -- ❌ DOESN'T EXIST
    'CHERRE_MLS_NEW_LISTINGS_ZIP'      -- ❌ DOESN'T EXIST
)
```

**Corrected (ACTUAL DATA)**:
```sql
AND metric_id IN (
    'CHERRE_MLS_DAYS_ON_MARKET',       -- ✅ 25M records
    'CHERRE_MLS_CUMULATIVE_DOM',       -- ✅ 19M records
    'CHERRE_MLS_ACTIVE_LISTINGS',      -- ✅ 11M records
    'CHERRE_MLS_PENDING_LISTINGS'      -- ✅ 5M records (move from pricing CTE)
)
```

### Priority 2: Investigate CBSA Coverage (30 minutes)

**Query to run**:
```sql
-- Check what geo_level_code values exist
SELECT 
    geo_level_code,
    COUNT(*) AS records,
    COUNT(DISTINCT geo_id) AS unique_geos,
    COUNT(DISTINCT CASE WHEN id_cbsa IS NOT NULL THEN id_cbsa END) AS unique_cbsas
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_CHERRE_MLS
WHERE date_reference >= '2026-01-01'
GROUP BY geo_level_code;
```

**Possible outcomes**:
- If `geo_level_code = 'PROPERTY'`: Need to aggregate up to ZIP/CBSA
- If `id_cbsa` is NULL: Need to join to crosswalk table
- If `geo_level_code = 'ZIP'`: Already aggregatable to CBSA

### Priority 3: Fix Data Source References (15 minutes)

The signal is querying the wrong table:

**Current**:
```sql
FROM {{ source('fact', 'housing_hou_inventory_all_ts') }}
WHERE vendor_name = 'CHERRE'
```

**Should be** (dedicated MLS table):
```sql
FROM {{ source('fact', 'housing_hou_inventory_cherre_mls') }}
-- No need for vendor_name filter, already filtered
```

### Priority 4: Handle Future Dates (15 minutes)

Add date validation to exclude corrupt future dates:

```sql
WHERE date_reference >= DATEADD('month', -24, CURRENT_DATE())
  AND date_reference <= CURRENT_DATE() + INTERVAL '1 month'  -- ✅ Exclude 2079 dates
```

---

## Coverage Enhancement Opportunities

### Signals That Can Immediately Benefit from MLS Data

| Signal | Current Coverage | MLS Metrics Available | Impact |
|-------|------------------|------------------------|--------|
| **MLS_VELOCITY** | 0 CBSAs ❌ | DOM, Active, Pending | **CRITICAL** - Built for this! |
| **VELOCITY** | 0 CBSAs ❌ | DOM, Turnover rate | **HIGH** - Primary input |
| **ABSORPTION** | 0 CBSAs ❌ | Sold/Active ratio | **HIGH** - Core metric |
| **SUPPLY_PRESSURE** | 0 CBSAs ❌ | Active, New listings | **MEDIUM** - Inventory signal |
| **PRICE_MOMENTUM** | 0 CBSAs ❌ | List price, PPSF | **MEDIUM** - Price changes |

### New Signal Opportunities Using MLS

1. **LISTING_QUALITY_SIGNAL**
   - Expired listings / Active listings
   - Withdrawn listings / Total listings
   - Price reductions / Active listings
   - **Coverage**: 10M+ records

2. **MARKET_COMPETITIVENESS_SIGNAL**
   - DOM vs historical average
   - Pending ratio vs market norm
   - List price vs prior sale price
   - **Coverage**: 5M+ records

3. **PRODUCT_DIFFERENTIATION_SIGNAL**
   - SF vs MF velocity differences
   - Product-specific absorption rates
   - **Coverage**: 3 product types × all metrics

---

## Implementation Plan

### Phase 1: Fix Critical Issues (2 hours)

1. ✅ **Fix `fct_mls_velocity_signal.sql`** metric names
2. ✅ **Test query** with corrected names
3. ✅ **Investigate CBSA coverage** issue
4. ✅ **Add date validation** to exclude future dates
5. ✅ **Run signal rebuild**: `dbt run --select fct_mls_velocity_signal`
6. ✅ **Validate results**: Check row counts and CBSA coverage

### Phase 2: Extend to Other Signals (4 hours)

7. **VELOCITY Signal**: Add MLS as fallback/enhancement
8. **ABSORPTION Signal**: Incorporate MLS sold/active ratio
9. **SUPPLY_PRESSURE Signal**: Use MLS inventory metrics
10. **PRICE_MOMENTUM Signal**: Add MLS price change signals

### Phase 3: New Signal Development (1 week)

11. Build **LISTING_QUALITY_SIGNAL**
12. Build **MARKET_COMPETITIVENESS_SIGNAL**
13. Enable product differentiation across all signals

---

## Diagnostic Queries to Run Next

### 1. Check Geo Level Distribution
```sql
SELECT 
    geo_level_code,
    COUNT(*) AS records,
    COUNT(DISTINCT geo_id) AS unique_geos,
    COUNT(DISTINCT id_cbsa) AS unique_cbsas,
    COUNT(DISTINCT product_type_code) AS product_types
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_CHERRE_MLS
WHERE date_reference >= '2026-01-01'
GROUP BY geo_level_code;
```

### 2. Sample Recent Data with Geography
```sql
SELECT 
    date_reference,
    geo_id,
    geo_level_code,
    id_cbsa,
    product_type_code,
    metric_id,
    value
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_CHERRE_MLS
WHERE date_reference >= '2026-01-15'
  AND metric_id = 'CHERRE_MLS_DAYS_ON_MARKET'
LIMIT 100;
```

### 3. Check if CBSA Rollup Needed
```sql
-- If data is at PROPERTY/ZIP level, aggregate to CBSA
SELECT 
    id_cbsa,
    product_type_code,
    metric_id,
    AVG(value) AS avg_value,
    COUNT(*) AS property_count
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_CHERRE_MLS
WHERE date_reference >= '2026-01-15'
  AND id_cbsa IS NOT NULL
GROUP BY id_cbsa, product_type_code, metric_id
LIMIT 100;
```

---

## Success Metrics

### Before (Current State)
- ❌ MLS_VELOCITY Signal: 0 rows
- ❌ VELOCITY Signal: 0 CBSAs
- ❌ ABSORPTION Signal: 0 CBSAs
- ❌ Total signal coverage: ~336 CBSAs (ownership only)

### After (Target State)
- ✅ MLS_VELOCITY Signal: 300+ CBSAs
- ✅ VELOCITY Signal: 300+ CBSAs (with MLS backstop)
- ✅ ABSORPTION Signal: 300+ CBSAs
- ✅ Total signal coverage: 300+ CBSAs across 6+ signals
- ✅ Product differentiation: SF, MF, BTR for all signals

---

## Next Step

**START HERE**: Run diagnostic query to check geo_level_code distribution and sample data.

