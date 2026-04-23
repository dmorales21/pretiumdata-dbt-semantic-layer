# QCEW and BLS Completion Plan

**Date**: 2026-01-11  
**Status**: ✅ **QCEW NAICS DATA LOADED** | ⚠️ **BLS WORK REMAINING**

---

## QCEW NAICS Status

### ✅ Completed
1. **Data Structure**: Table `QCEW_NAICS_CBSA` created
2. **Data Extraction**: Views extract from raw variant
3. **Data Load**: Data loaded into table
4. **Sectoral Views**: 5 sectoral views operational
5. **Demand Integration**: 4 demand framework views created

### ⚠️ Remaining QCEW Work

#### 1. Features Layer
**File**: `sql/analytics/features/create_qcew_naics_cbsa_features.sql` (exists, needs execution)

**Purpose**: Create feature-engineered QCEW NAICS data with:
- Year-over-year growth rates
- Employment/wage shares within CBSA
- Industry mix scores (local vs national)

**Action**: Execute existing SQL file to create features table/view

#### 2. Atlas Integration
**Table**: `ADMIN.METRIC_DOCS`

**Metrics to Register**:
- `BLS_QCEW_NAICS_EMPLOYMENT_CBSA` - Employment by NAICS sector
- `BLS_QCEW_NAICS_WAGE_CBSA` - Wages by NAICS sector
- `BLS_QCEW_NAICS_GROWTH_CBSA` - Growth rates by sector
- `BLS_QCEW_INDUSTRY_MIX_EFFECT` - Industry mix component

**Taxonomy**: HOUSEHOLD / LABOR
**Geography**: MSA_METRIC = TRUE, ZIP_METRIC = FALSE
**Frequency**: QUARTERLY

#### 3. Data Refresh Automation
**Task**: Create Snowflake task to refresh QCEW NAICS data

**Logic**:
- Monitor `SOURCE_PROD.BLS.QCEW_COUNTY_RAW` for new quarters
- Execute MERGE into `QCEW_NAICS_CBSA`
- Update sectoral views

---

## BLS Status

### Current State

#### ✅ Existing BLS Views
- `TRANSFORM_PROD.CLEANED.BLS_ECI` (VIEW)
- `TRANSFORM_PROD.CLEANED.BLS_EMPLOYMENT_CBSA` (VIEW)
- `TRANSFORM_PROD.CLEANED.BLS_JOLTS` (VIEW)
- `TRANSFORM_PROD.CLEANED.BLS_LAUS` (VIEW)
- `TRANSFORM_PROD.JOINED.BLS_EMPLOYMENT` (VIEW)
- `TRANSFORM_PROD.JOINED.BLS_PRICE` (VIEW)

#### ❌ Missing/Empty
- `ANALYTICS_PROD.FEATURES.BLS_CPS_MSA_FEATURES` - **EMPTY** (0 rows)

### BLS Work Needed

#### 1. Populate BLS_CPS_MSA_FEATURES
**Table**: `ANALYTICS_PROD.FEATURES.BLS_CPS_MSA_FEATURES`

**Data Needed**:
- Monthly employment data by MSA
- Unemployment rates
- Labor force participation rates
- Wage data

**Source**: BLS Current Population Survey (CPS) or Local Area Unemployment Statistics (LAUS)

**Action**: 
- Identify source data location
- Create ETL to populate table
- Link to CBSA geography

#### 2. Integrate BLS with QCEW
**Purpose**: Combine BLS monthly data with QCEW quarterly data for comprehensive employment picture

**Views to Create**:
- `V_EMPLOYMENT_COMPREHENSIVE_CBSA` - Combined QCEW + BLS
- `V_EMPLOYMENT_TRENDS_CBSA` - Monthly trends from BLS, quarterly detail from QCEW

#### 3. BLS Atlas Integration
**Metrics to Register**:
- `BLS_CPS_EMPLOYMENT_CBSA` - Monthly employment
- `BLS_CPS_UNEMPLOYMENT_RATE_CBSA` - Unemployment rate
- `BLS_CPS_LFP_RATE_CBSA` - Labor force participation

---

## Implementation Priority

### Phase 1: Complete QCEW (Immediate)
1. ✅ Execute `create_qcew_naics_cbsa_features.sql`
2. ⚠️ Register QCEW NAICS metrics in METRIC_DOCS
3. ⚠️ Create data refresh task

### Phase 2: Complete BLS (Next)
1. ⚠️ Identify BLS CPS/LAUS source data
2. ⚠️ Populate `BLS_CPS_MSA_FEATURES` table
3. ⚠️ Create BLS-QCEW integration views
4. ⚠️ Register BLS metrics in METRIC_DOCS

### Phase 3: Integration (After QCEW/BLS Complete)
1. ⚠️ Create comprehensive employment views
2. ⚠️ Integrate with demand framework
3. ⚠️ Set up automated refresh for both

---

## Files to Create/Execute

### QCEW
1. ✅ `sql/analytics/features/create_qcew_naics_cbsa_features.sql` (exists - execute)
2. ⚠️ `sql/admin/metric_docs/register_qcew_naics_metrics.sql` (create)
3. ⚠️ `sql/tasks/create_qcew_naics_refresh_task.sql` (create)

### BLS
1. ⚠️ `sql/transform/cleaned/populate_bls_cps_msa_features.sql` (create)
2. ⚠️ `sql/analytics/features/create_bls_qcew_integration.sql` (create)
3. ⚠️ `sql/admin/metric_docs/register_bls_metrics.sql` (create)

---

## AI Replacement Risk - Deferred

### Status: ⏸️ **DEFERRED UNTIL O*NET DATA STRUCTURED**

**Rationale**: 
- Requires O*NET occupational automation scores
- O*NET data needs planning and structuring
- Focus on completing QCEW/BLS foundation first

**Future Work**:
1. Structure O*NET data (automation scores, remote work capability)
2. Map O*NET → NAICS → CBSA
3. Create occupation-based risk index
4. Combine with industry-based risk (from QCEW NAICS)

---

## Summary

✅ **QCEW NAICS**: Data loaded, views operational  
⚠️ **QCEW Features**: SQL exists, needs execution  
⚠️ **BLS CPS**: Table empty, needs population  
⏸️ **AI Risk**: Deferred until O*NET structured

**Next Steps**: Execute QCEW features, then work on BLS CPS population.

