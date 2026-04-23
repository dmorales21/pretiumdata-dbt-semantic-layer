# Data Freshness & AMREG Integration: Complete Analysis

**Date**: 2025-12-30  
**Status**: Analysis Complete, Action Items Identified

---

## 🚨 Critical Stale Data Issues

### Issue #1: Redfin Data Pipeline Stalled ⚠️ **CRITICAL**

**Affected Signals**: ABSORPTION, SUPPLY_PRESSURE, VELOCITY (CBSA)

**Source Table**: `TRANSFORM_PROD.GOLD.GOLD_REDFIN_ZIP_TIME_SERIES`

**Current Status**:
- **Latest data**: 2025-08-01 (153 days stale)
- **Missing months**: September, October, November, December 2025
- **Coverage**: 8,713 ZIPs in latest month (August)
- **Expected**: Monthly updates (should have data through November 2025 minimum)

**Root Cause**: 
- Redfin data ingestion pipeline appears stalled
- Source data stops at August 2025
- No newer data available in GOLD layer

**Action Required**:
1. ✅ **Immediate**: Check Redfin ETL job status (`GOLD_REDFIN_ZIP_TIME_SERIES` ingestion)
2. ✅ **Immediate**: Verify Redfin API/data feed connectivity
3. ✅ **Short-term**: Update signal date filters to include any new data when available
4. ✅ **Short-term**: Re-run signal calculations for missing months (Sep-Dec 2025)

---

### Issue #2: MARKERR Income Data Stale ⚠️ **HIGH**

**Affected Signal**: RENT_BURDEN

**Source Table**: `TRANSFORM_PROD.CLEANED.MARKERR_INCOME_EMPLOYMENT`

**Current Status**:
- **Latest data**: 2025-06-30 (185 days stale)
- **Missing quarters**: Q3 2025, Q4 2025
- **Coverage**: 24,756 ZIPs, 206 unique dates (2008-2025)
- **Total rows**: 265M+ rows (very large dataset)

**Root Cause**:
- MARKERR income data pipeline appears stalled
- Source data stops at Q2 2025
- HUD FMR is current (2026-01-01) but paired with stale income data

**Action Required**:
1. ✅ **Immediate**: Check MARKERR data ingestion pipeline
2. ✅ **Immediate**: Verify MARKERR data source availability
3. ✅ **Short-term**: Consider Census ACS as alternative income source
4. ✅ **Short-term**: Add `DATA_FRESHNESS_DAYS` flag to RENT_BURDEN signal output

---

## 📊 Complete Source Table Inventory

### Signal → Source Table Mapping

| Signal | Primary Source | Latest Date | Days Stale | Secondary Source | Latest Date | Days Stale | Status |
|-------|---------------|-------------|------------|------------------|-------------|------------|--------|
| **RENT_BURDEN** | `CLEANED.HUD_FMR` | 2026-01-01 | 0 | `CLEANED.MARKERR_INCOME_EMPLOYMENT` | 2025-06-30 | **185** | ⚠️ Income stale |
| **ABSORPTION** | `GOLD.GOLD_REDFIN_ZIP_TIME_SERIES` | 2025-08-01 | **153** | - | - | - | ⚠️ **CRITICAL** |
| **SUPPLY_PRESSURE** | `GOLD.GOLD_REDFIN_ZIP_TIME_SERIES` | 2025-08-01 | **153** | - | - | - | ⚠️ **CRITICAL** |
| **VELOCITY (CBSA)** | `MODELED.FACT_VELOCITY_SIGNAL_CBSA` | 2025-08-01 | **153** | - | - | - | ⚠️ **CRITICAL** |
| **VELOCITY (ZIP)** | Redfin ZIP (existing) | 2025-10-31 | **62** | - | - | - | ⚠️ Stale |
| **GC_CAPACITY** | `MODELED.FACT_GC_CAPACITY_SIGNAL_CBSA` | 2026-01-01 | 0 | - | - | - | ✅ Current |

---

## 🔍 AMREG Integration: Diagnosis & Solution

### AMREG Source Table Found ✅

**Source Table**: `SOURCE_ENTITY.PRETIUM.AMREG` (BASE TABLE)

**Table Statistics**:
- **Total Rows**: 81,494,613 rows
- **Date Range**: 1980-2050 (71 years)
- **Locations**: 302 MSAs
- **Coverage**: Historical + Forecast data

**View Chain**:
```
SOURCE_ENTITY.PRETIUM.AMREG (BASE TABLE, 81M rows)
    ↓
TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS (VIEW)
    ↓
TRANSFORM_PROD.JOINED.AMREG_CBSA_ECONOMICS (VIEW)
    ↓
EDW_PROD.TOOLS.AMREG_CBSA_ECONOMICS_MSA_APP_VIEW (VIEW)
```

### Why AMREG Queries Fail

**Root Cause**: 
1. **Large Dataset**: 81M+ rows in source table
2. **Complex View**: Multiple joins and transformations
3. **No Date Filtering**: View processes all years (1980-2050)
4. **Crosswalk Join**: Joins with `OXFORD_CBSA_CROSSWALK` (302 mappings, all MEDIUM confidence)

**Test Results**:
- ✅ View works with aggressive filters (single CBSA, date range)
- ❌ View times out with broader queries (no filters)
- ✅ Source table accessible directly

---

## 🔧 AMREG Integration Solution

### Option 1: Materialize CLEANED View (Recommended)

**Create Materialized Table**:
```sql
CREATE OR REPLACE TABLE TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED AS
SELECT * FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS
WHERE DATE_REFERENCE >= '2020-01-01';  -- Recent + forecast only

-- Add indexes
CREATE INDEX IF NOT EXISTS IDX_AMREG_CBSA_DATE 
ON TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED(ID_CBSA, DATE_REFERENCE);

CREATE INDEX IF NOT EXISTS IDX_AMREG_CBSA_METRIC 
ON TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED(META_METRIC, DATE_REFERENCE);
```

**Benefits**:
- Fast queries (pre-computed)
- Can filter by date range during materialization
- Indexes for performance

**Refresh Strategy**: Monthly or quarterly refresh

---

### Option 2: Create Filtered View (Quick Fix)

**Create Date-Filtered View**:
```sql
CREATE OR REPLACE VIEW TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_RECENT AS
SELECT * FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS
WHERE DATE_REFERENCE >= '2020-01-01';  -- Recent + forecast only
```

**Benefits**:
- No storage overhead
- Faster queries (smaller dataset)
- Easy to update

**Drawback**: Still processes full view, just filters results

---

### Option 3: Direct Source Query (For Specific Use Cases)

**Query Source Directly**:
```sql
SELECT 
  xw.ID_CBSA,
  xw.NAME_CBSA,
  DATE_FROM_PARTS(a."Year", 12, 31) AS DATE_REFERENCE,
  a."Indicator" AS META_METRIC,
  a."Data" AS VALUE
FROM SOURCE_ENTITY.PRETIUM.AMREG a
JOIN TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK xw
  ON a."Location_code" = xw.LOCATION_CODE_OXFORD
WHERE a."Region_Type" = 'MSA'
  AND a."Year" >= 2020
  AND xw.ID_CBSA = '12060'  -- Specific CBSA
  AND a."Indicator" LIKE '%Employment%'
ORDER BY a."Year" DESC;
```

**Benefits**:
- Fast for specific queries
- No view overhead
- Direct control

**Drawback**: Requires manual query construction

---

## 📋 Recommended AMREG Integration Plan

### Phase 1: Materialize Recent Data (Immediate)

1. **Create Materialized Table**:
   - Filter: `DATE_REFERENCE >= '2020-01-01'` (recent + forecast)
   - Add indexes on `ID_CBSA`, `DATE_REFERENCE`, `META_METRIC`
   - Estimated size: ~20-30M rows (vs 81M total)

2. **Update Signal Implementations**:
   - Use materialized table instead of view
   - Add date filters to queries
   - Test performance

### Phase 2: Create GOLD Layer Table (Short-term)

1. **Create GOLD Table**:
   - Materialize cleaned AMREG data
   - Add data quality flags
   - Standardize metric names

2. **Create JOINED Layer**:
   - Join with other economic indicators
   - Create composite metrics
   - Add product-specific transformations

### Phase 3: Integrate into Signals (Medium-term)

1. **MOMENTUM Signal Enhancement**:
   - Add AMREG employment data as alternative/complement to BLS
   - Use AMREG forecasts for forward-looking momentum

2. **New Economic Indicators**:
   - GDP growth
   - Wage growth
   - Population forecasts

---

## 🎯 AMREG Use Cases for Signals

### 1. MOMENTUM Signal Enhancement

**Current**: Uses BLS employment (stale: 2025-10-31)

**Enhancement**: Add AMREG employment forecasts
```sql
-- AMREG employment data for MOMENTUM
SELECT 
  ID_CBSA,
  DATE_REFERENCE,
  VALUE AS employment_level
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
WHERE META_METRIC LIKE '%EMPLOYMENT%TOTAL%'
  AND DATE_REFERENCE >= '2020-01-01'
ORDER BY ID_CBSA, DATE_REFERENCE;
```

### 2. Economic Forecasts

**Use Case**: Forward-looking market analysis
- Employment forecasts (2025-2050)
- GDP growth forecasts
- Population forecasts
- Wage growth forecasts

### 3. Market Comparison

**Use Case**: Compare CBSA economic indicators
- Employment growth rates
- GDP per capita
- Wage levels
- Population trends

---

## 📊 AMREG Data Quality

### Crosswalk Quality

**OXFORD_CBSA_CROSSWALK Status**:
- **Total Mappings**: 302 MSAs
- **Unique CBSAs**: 296 (some MSAs map to same CBSA)
- **Match Confidence**: All MEDIUM (no HIGH confidence matches)
- **Coverage**: 302/302 AMREG MSAs mapped

**Recommendation**: Review crosswalk mappings for accuracy

### Data Freshness

**AMREG Source Table**:
- **Latest Year**: 2050 (forecast data)
- **Historical Range**: 1980-2025
- **Update Frequency**: Unknown (need to verify)
- **Forecast Horizon**: Up to 2050

**Note**: AMREG includes forecasts, so "latest" date may be future-dated

---

## 🔄 Action Items Summary

### Immediate (Data Freshness)
1. ✅ **Redfin Pipeline**: Check ETL job status, verify API connectivity
2. ✅ **MARKERR Pipeline**: Check income data ingestion status
3. ✅ **Monitoring**: Set up alerts for data freshness >60 days

### Short-term (AMREG Integration)
1. ✅ **Materialize AMREG**: Create materialized table for recent data (2020+)
2. ✅ **Add Indexes**: Index on ID_CBSA, DATE_REFERENCE, META_METRIC
3. ✅ **Test Performance**: Query materialized table vs view
4. ✅ **Update MOMENTUM**: Integrate AMREG employment data

### Medium-term (Enhancements)
1. ✅ **GOLD Layer**: Create GOLD.AMREG_CBSA_ECONOMICS table
2. ✅ **JOINED Layer**: Create composite economic indicators
3. ✅ **New Signals**: Use AMREG for economic forecast signals

---

## 📁 Files Created

1. **Data Freshness Analysis**: `docs/DATA_FRESHNESS_ANALYSIS.md`
2. **AMREG Integration Plan**: `docs/DATA_FRESHNESS_AND_AMREG_COMPLETE.md` (this file)

---

**Status**: Analysis complete. Redfin and MARKERR pipelines require immediate attention. ✅ **AMREG materialization complete** (35.5M rows, 296 CBSAs, fast queries).

---

## ✅ AMREG Materialization: COMPLETE

### Materialization Results

**Table Created**: `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED`

**Statistics**:
- **Total Rows**: 35,581,472 rows (2020-2050)
- **Unique CBSAs**: 296
- **Unique Dates**: 31 (2020-2050)
- **Unique Metrics**: 657
- **Date Range**: 2020-12-31 to 2050-12-31
- **Forecast Rows**: 28.7M (future dates)
- **Historical Rows**: 6.9M (2020-2025)

**Performance**:
- ✅ Query time: **0.688s** (vs timeout with view)
- ✅ Indexes created on ID_CBSA, DATE_REFERENCE, META_METRIC
- ✅ Primary key: (ID_CBSA, DATE_REFERENCE, META_METRIC)

**Metric Distribution**:
- **EMPLOYMENT**: 336 metrics, 18M rows
- **OTHER_ECONOMIC**: 178 metrics, 9.3M rows
- **ECONOMIC_OUTPUT**: 83 metrics, 5M rows
- **WAGES_INCOME**: 23 metrics, 1.2M rows
- **HOUSING_RE**: 19 metrics, 1M rows
- **DEMOGRAPHICS**: 18 metrics, 974K rows

**Next Steps**:
1. ✅ Use materialized table in signal implementations
2. ✅ Integrate AMREG employment into MOMENTUM signal
3. ✅ Set up monthly refresh schedule
4. ✅ Create GOLD layer table for standardized metrics

