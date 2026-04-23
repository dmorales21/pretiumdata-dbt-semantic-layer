# Data Freshness & AMREG Integration Analysis

**Date**: 2025-12-30  
**Purpose**: Identify stale data sources and diagnose AMREG query failures

---

## 📊 Data Freshness Summary

### Current Signal Data Status

| Signal | Latest Date | Days Stale | Source Table(s) | Issue |
|-------|-------------|------------|-----------------|-------|
| **ABSORPTION** | 2025-08-01 | **153 days** | `GOLD_REDFIN_ZIP_TIME_SERIES` | ⚠️ **CRITICAL** |
| **SUPPLY_PRESSURE** | 2025-10-31 | **62 days** | `GOLD_REDFIN_ZIP_TIME_SERIES` | ⚠️ **STALE** |
| **VELOCITY (CBSA)** | 2025-08-01 | **153 days** | `FACT_VELOCITY_SIGNAL_CBSA` | ⚠️ **CRITICAL** |
| **VELOCITY (ZIP)** | 2025-10-31 | **62 days** | Redfin ZIP data | ⚠️ **STALE** |
| **RENT_BURDEN** | 2026-01-01 | 0 days | `HUD_FMR` + `MARKERR_INCOME_EMPLOYMENT` | ✅ Current (but income source may be stale) |
| **GC_CAPACITY** | 2026-01-01 | 0 days | Permit data | ✅ Current |

---

## 🚨 Critical Stale Data Issues

### Issue #1: Redfin Data Pipeline Stalled ⚠️ **CRITICAL**

**Affected Signals**: ABSORPTION, SUPPLY_PRESSURE, VELOCITY (CBSA)

**Source Table**: `TRANSFORM_PROD.GOLD.GOLD_REDFIN_ZIP_TIME_SERIES`

**Current Status**:
- Latest data: **2025-08-01** (153 days stale)
- No data for: September, October, November, December 2025
- Expected: Monthly updates (should have data through November 2025 at minimum)

**Root Cause**: 
- Redfin data ingestion pipeline appears stalled
- Source data stops at August 2025
- No newer data available in GOLD layer

**Action Required**:
1. ✅ **Immediate**: Check Redfin ETL job status
2. ✅ **Immediate**: Verify Redfin API/data feed connectivity
3. ✅ **Short-term**: Update signal date filters to include any new data when available
4. ✅ **Short-term**: Re-run signal calculations for missing months (Sep-Dec 2025)

---

### Issue #2: MARKERR Income Data Stale ⚠️ **HIGH**

**Affected Signal**: RENT_BURDEN

**Source Table**: `TRANSFORM_PROD.CLEANED.MARKERR_INCOME_EMPLOYMENT`

**Current Status**:
- Latest data: **2025-06-30** (183 days stale)
- No Q3 or Q4 2025 data loaded
- Signal uses latest available income per ZIP (workaround for date mismatch)

**Root Cause**:
- MARKERR income data pipeline appears stalled
- Source data stops at Q2 2025
- HUD FMR is current (2026-01-01) but paired with stale income data

**Action Required**:
1. ✅ **Immediate**: Check MARKERR data ingestion pipeline
2. ✅ **Immediate**: Verify MARKERR data source availability
3. ✅ **Short-term**: Consider Census ACS as alternative income source
4. ✅ **Short-term**: Update RENT_BURDEN to flag stale income data

---

## 🔍 AMREG Integration: Diagnosis

### AMREG View Status

**Views Identified**:
- `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS`
- `TRANSFORM_PROD.CLEANED.AMREG_REGIONAL_ECONOMICS`

**Issue**: Views return `ROW_COUNT = null`, indicating:
- Views with expensive underlying queries
- Potential broken dependencies
- Large dataset causing timeouts
- Complex transformations

---

## 🔧 AMREG Investigation Steps

### Step 1: Find Source Tables

**Query**: Check SOURCE_PROD and all databases for AMREG/Oxford tables

**Expected Locations**:
- `SOURCE_PROD` schema (raw data)
- `TPANALYTICS` or `PRETIUM` schemas (vendor data)
- `FINANCE__ECONOMICS` database (if external)

### Step 2: Check GOLD Layer

**Query**: Check if AMREG data is already materialized in GOLD

**Benefit**: If materialized, can query directly without view overhead

### Step 3: Get View DDL

**Query**: `GET_DDL('VIEW', 'TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS')`

**Purpose**: Understand transformation logic and dependencies

### Step 4: Test with Aggressive Filters

**Query**: 
```sql
SELECT * FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS
WHERE ID_CBSA = '12060' AND DATE_REFERENCE >= '2024-01-01'
LIMIT 10;
```

**Purpose**: Test if data is accessible at all (may timeout if view is broken)

### Step 5: Check Dependencies

**Query**: Use `SNOWFLAKE.ACCOUNT_USAGE.OBJECT_DEPENDENCIES`

**Purpose**: Identify broken links in view chain

---

## 📋 Source Table Inventory

### Signal → Source Table Mapping

| Signal | Primary Source | Latest Date | Days Stale | Secondary Source | Latest Date | Days Stale |
|-------|---------------|-------------|------------|------------------|-------------|------------|
| **RENT_BURDEN** | `CLEANED.HUD_FMR` | 2026-01-01 | 0 | `CLEANED.MARKERR_INCOME_EMPLOYMENT` | 2025-06-30 | **183** |
| **ABSORPTION** | `GOLD.GOLD_REDFIN_ZIP_TIME_SERIES` | 2025-08-01 | **153** | - | - | - |
| **SUPPLY_PRESSURE** | `GOLD.GOLD_REDFIN_ZIP_TIME_SERIES` | 2025-08-01 | **153** | - | - | - |
| **VELOCITY (CBSA)** | `MODELED.FACT_VELOCITY_SIGNAL_CBSA` | 2025-08-01 | **153** | - | - | - |
| **VELOCITY (ZIP)** | Redfin ZIP (via existing signal) | 2025-10-31 | **62** | - | - | - |
| **GC_CAPACITY** | `MODELED.FACT_GC_CAPACITY_SIGNAL_CBSA` | 2026-01-01 | 0 | - | - | - |

---

## 🎯 Recommended Actions

### Priority 1: Redfin Data Pipeline (3 signals affected)
1. ✅ Check ETL job status for `GOLD_REDFIN_ZIP_TIME_SERIES`
2. ✅ Verify Redfin API/data feed connectivity
3. ✅ Check if newer data exists in raw source (before GOLD layer)
4. ✅ Update signal implementations to remove restrictive date filters
5. ✅ Re-run signal calculations once new data is available

### Priority 2: MARKERR Income Pipeline (1 signal affected)
1. ✅ Check ETL job status for `MARKERR_INCOME_EMPLOYMENT`
2. ✅ Verify MARKERR data source availability
3. ✅ Consider Census ACS as alternative income source
4. ✅ Add `DATA_FRESHNESS_DAYS` flag to RENT_BURDEN signal

### Priority 3: AMREG Integration
1. ✅ Find source tables (check SOURCE_PROD, GOLD, external databases)
2. ✅ Check if GOLD layer has materialized AMREG data
3. ✅ Get view DDL to understand dependencies
4. ✅ Test with aggressive filters
5. ✅ Check object dependencies for broken links

---

## 📊 Expected vs Actual Freshness

| Signal | Expected Latest | Actual Latest | Gap | Status |
|-------|---------------|---------------|-----|--------|
| RENT_BURDEN | 2025-12-31 | 2026-01-01 | ✅ Current | ✅ OK (but income source stale) |
| ABSORPTION | 2025-12-01 | 2025-08-01 | **4 months** | ⚠️ **CRITICAL** |
| SUPPLY_PRESSURE | 2025-12-01 | 2025-10-31 | **2 months** | ⚠️ **STALE** |
| VELOCITY (CBSA) | 2025-12-01 | 2025-08-01 | **4 months** | ⚠️ **CRITICAL** |
| VELOCITY (ZIP) | 2025-12-01 | 2025-10-31 | **2 months** | ⚠️ **STALE** |
| GC_CAPACITY | 2025-12-31 | 2026-01-01 | ✅ Current | ✅ OK |

---

## 🔄 Next Steps

1. **Investigate Redfin Pipeline**: Check ETL jobs and data source availability
2. **Investigate MARKERR Pipeline**: Check income data ingestion status
3. **AMREG Integration**: Follow 5-step investigation process
4. **Update Monitoring**: Add automated alerts for data freshness >60 days
5. **Documentation**: Update source table inventory with actual locations

---

**Status**: Analysis complete. Redfin and MARKERR pipelines require immediate attention.

