# BH Yardi Data Review & Table Prioritization

**Date**: 2026-01-29  
**Status**: 🔴 **CRITICAL REVIEW REQUIRED**  
**Purpose**: Review BH Yardi data, prioritize tables for Progress comparability, identify top vendors, and fix BTR signal critical failure

---

## Executive Summary

### Critical Issues Identified

1. **🔴 CRITICAL: BTR Signal Not Using Zonda Data**
   - Current: BTR signal uses `fact_housing_hou_btr_all_ts` (John Burns only)
   - Required: Should use Zonda BTR data (`ZONDA_BTR_COMPREHENSIVE`)
   - Impact: Missing critical BTR market intelligence from Zonda

2. **⚠️ BH Yardi Tables Missing**
   - Progress has: `housing_hou_operations_yardi_sfdc`, `housing_hou_demand_yardi_sfdc`, `housing_hou_asset_yardi_sfdc`
   - BH needs: Equivalent tables for operational comparability

3. **⚠️ Zonda BTR Table Missing**
   - Referenced: `TRANSFORM_PROD.CLEANED.ZONDA_BTR_COMPREHENSIVE` (in `cleaned_zonda_parties.sql`)
   - Status: **NOT FOUND** in CLEANED schema
   - Impact: BTR signal cannot use Zonda data

---

## 1. BH Yardi Data Status

### 1.1 Current Yardi Tables (Progress)

**Source**: `DS_SOURCE_PROD_YARDI.YARDI_SHARE.*`

**Progress Fact Tables** (✅ **EXIST**):
1. `TRANSFORM_PROD.FACT.HOUSING_HOU_OPERATIONS_YARDI_SFDC`
   - Sources: `yardi_trans`, `yardi_detail`, `yardi_workorders`, `sfdc_case_workorders`
   - Metrics: Work orders, maintenance, payment processing
   - OpCo Access: PROGRESS

2. `TRANSFORM_PROD.FACT.HOUSING_HOU_DEMAND_YARDI_SFDC`
   - Sources: `yardi_lease_history`, `yardi_tenant`, `yardi_prospect`, `yardi_tenant_history`, `sfdc_account_leases`
   - Metrics: Lease history, tenant lifecycle, prospect conversion, lease velocity
   - OpCo Access: PROGRESS

3. `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_YARDI_SFDC`
   - Sources: `yardi_property`, `yardi_unit`
   - Metrics: Unit characteristics, property attributes, portfolio composition
   - OpCo Access: PROGRESS

### 1.2 BH Yardi Tables Required

**Priority: HIGH** ⭐

BH needs equivalent tables for operational comparability:

#### Priority 1: BH Operations (CRITICAL)
**Target Table**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OPERATIONS_YARDI_SFDC_BH`

**Sources** (same as Progress, filtered by OpCo):
- `yardi_trans` (filter: `opco_access = 'BH'` or property filter)
- `yardi_detail` (filter: BH properties)
- `yardi_workorders` (filter: BH properties)
- `sfdc_case_workorders` (filter: BH properties)

**Metrics**:
- Work order volumes
- Maintenance frequency
- Payment processing
- Operational efficiency indicators

**Comparability**: Enables Progress vs BH operational performance comparison

---

#### Priority 2: BH Demand (CRITICAL)
**Target Table**: `TRANSFORM_PROD.FACT.HOUSING_HOU_DEMAND_YARDI_SFDC_BH`

**Sources**:
- `yardi_lease_history` (filter: BH properties)
- `yardi_tenant` (filter: BH properties)
- `yardi_prospect` (filter: BH properties)
- `yardi_tenant_history` (filter: BH properties)
- `sfdc_account_leases` (filter: BH properties)

**Metrics**:
- Lease velocity (days to lease)
- Prospect-to-lease conversion
- Tenant lifecycle stages
- Lease renewal rates

**Comparability**: Enables Progress vs BH demand/leasing performance comparison

---

#### Priority 3: BH Asset (HIGH)
**Target Table**: `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_YARDI_SFDC_BH`

**Sources**:
- `yardi_property` (filter: BH properties)
- `yardi_unit` (filter: BH properties)

**Metrics**:
- Portfolio property count
- Unit distribution (bedrooms, sqft)
- Property tier distribution
- Portfolio composition

**Comparability**: Enables Progress vs BH portfolio composition comparison

---

### 1.3 BH Property Identification

**Required**: Property-level filter to identify BH properties

**Options**:
1. **Property Name Pattern**: Filter by property name patterns (e.g., "BH Communities", "BH_*")
2. **OpCo Flag**: If Yardi has OpCo identifier field
3. **Reference Table**: `TRANSFORM_PROD.REF.BH_PROPERTIES_REFERENCE` (if exists)
4. **Salesforce Mapping**: Link via Salesforce `PROPERTIES__C` with BH classification

**Action**: Verify BH property identification method in Yardi data

---

## 2. Top Vendors Identification

### 2.1 Vendor Priority by Metric Count & Coverage

Based on system usage and fact table integration:

#### Tier 1: Critical Market Intelligence Vendors ⭐

1. **Zillow** (ZILLOW)
   - Coverage: 893+ CBSAs
   - Metrics: ZHVI, ZORI, inventory, days on market
   - Frequency: Daily
   - Fact Tables: `HOUSING_HOU_PRICING_ALL_TS`, `HOUSING_HOU_DEMAND_ALL_TS`

2. **Parcl Labs** (PARCLLABS)
   - Coverage: 893+ CBSAs
   - Metrics: DOM, months of supply, absorption, ownership
   - Frequency: Daily
   - Fact Tables: `FACT_PARCLLABS_INVENTORY`, `FACT_PARCLLABS_PRICING`, `FACT_PARCLLABS_OWNERSHIP`

3. **GreenStreet** (GREENSTREET)
   - Coverage: ~100 CBSAs (Tier 1 data)
   - Metrics: Rent growth, NOI growth, occupancy, demand/supply forecasts
   - Frequency: Quarterly
   - Fact Tables: `FACT_GREENSTREET_PROJECTIONS_TS`

4. **Oxford Economics** (OXFORD_ECONOMICS / AMREG)
   - Coverage: All 939 CBSAs
   - Metrics: Forward rent/price forecasts, economic projections
   - Frequency: Quarterly
   - Fact Tables: Used in `PROGRESS_OFFERINGS_TIMESERIES_CBSA`

5. **John Burns** (JOHN_BURNS / JBREC)
   - Coverage: BTR/MF markets
   - Metrics: BTR rent, occupancy, deliveries, MF metrics
   - Frequency: Quarterly
   - Fact Tables: `FACT_HOUSING_HOU_BTR_ALL_TS`, `FACT_HOUSING_HOU_MULTIFAMILY_ALL_TS`

---

#### Tier 2: High-Value Market Intelligence Vendors

6. **Realtor.com** (REALTOR)
   - Coverage: 350-500 CBSAs
   - Metrics: Active listings, DOM, months of supply, median price
   - Frequency: Monthly
   - Fact Tables: Used in `PROGRESS_OFFERINGS_TIMESERIES_CBSA`

7. **Redfin** (REDFIN)
   - Coverage: 350-500 CBSAs
   - Metrics: Inventory, months of supply, homes sold, absorption rate, DOM
   - Frequency: Monthly
   - Fact Tables: Used in `PROGRESS_OFFERINGS_TIMESERIES_CBSA`

8. **Zonda** (ZONDA) ⚠️ **CRITICAL FOR BTR**
   - Coverage: BTR construction pipeline
   - Metrics: BTR plans, under construction, deliveries, builder data
   - Frequency: Monthly/Quarterly
   - Fact Tables: **MISSING** - Should populate `FACT_HOUSING_HOU_BTR_ALL_TS`

9. **CoStar** (COSTAR)
   - Coverage: Commercial/MF markets
   - Metrics: Rent growth, occupancy, cap rates, construction pipeline
   - Frequency: Quarterly
   - Fact Tables: Used in economic projections

10. **Census/ACS** (CENSUS)
    - Coverage: All geographies
    - Metrics: Demographics, housing stock, income
    - Frequency: Annual
    - Fact Tables: Multiple fact tables

---

#### Tier 3: Operational & Internal Vendors

11. **Yardi** (YARDI) - Internal
    - Coverage: Progress + BH properties
    - Metrics: Lease history, occupancy, rent, operations
    - Frequency: Daily
    - Fact Tables: `HOUSING_HOU_OPERATIONS_YARDI_SFDC`, `HOUSING_HOU_DEMAND_YARDI_SFDC`

12. **Salesforce** (SALESFORCE) - Internal
    - Coverage: Progress + BH properties
    - Metrics: Work orders, maintenance, lease dates
    - Frequency: Daily
    - Fact Tables: Combined with Yardi tables

---

### 2.2 Vendor Coverage Summary

| Vendor | Coverage | Frequency | Critical For | Status |
|--------|----------|-----------|--------------|--------|
| Zillow | 893+ CBSAs | Daily | SFR Market Intelligence | ✅ Active |
| Parcl Labs | 893+ CBSAs | Daily | SFR Market Intelligence | ✅ Active |
| GreenStreet | ~100 CBSAs | Quarterly | Forward Forecasts | ✅ Active |
| Oxford Economics | 939 CBSAs | Quarterly | Economic Forecasts | ✅ Active |
| John Burns | BTR/MF | Quarterly | BTR/MF Intelligence | ✅ Active |
| **Zonda** | **BTR Pipeline** | **Monthly** | **BTR Construction** | **🔴 MISSING** |
| Realtor.com | 350-500 CBSAs | Monthly | Supply Baselines | ✅ Active |
| Redfin | 350-500 CBSAs | Monthly | Supply Baselines | ✅ Active |
| CoStar | Commercial/MF | Quarterly | MF Intelligence | ✅ Active |
| Yardi | Progress+BH | Daily | Operational Performance | ✅ Active |

---

## 3. BTR Signal Critical Failure

### 3.1 Current Implementation

**Signal**: `ANALYTICS_PROD.SCORES.FCT_BTR_MARKET_SIGNAL`

**Current Data Source**: `FACT_HOUSING_HOU_BTR_ALL_TS`
- **Vendor**: `JOHN_BURNS` only
- **Metrics**: BTR_RENT, BTR_OCCUPANCY, BTR_TOTAL_UNITS, BTR_COMMUNITY_COUNT
- **Coverage**: Limited to John Burns markets

**Problem**: Missing Zonda BTR data (construction pipeline, builder data, deliveries)

---

### 3.2 Required Zonda Integration

**Missing Table**: `TRANSFORM_PROD.CLEANED.ZONDA_BTR_COMPREHENSIVE`

**Status**: 
- ❌ **NOT FOUND** in CLEANED schema
- ⚠️ Referenced in `cleaned_zonda_parties.sql` but table doesn't exist
- ⚠️ Referenced in documentation but not created

**Required Zonda BTR Metrics**:
1. **BTR Construction Pipeline**:
   - Plans (future projects)
   - Under Construction (active projects)
   - Deliveries (completed projects)
   - Builder/Developer information

2. **BTR Market Data**:
   - Community count by market
   - Unit count by market
   - Project-level details

3. **BTR Comparables**:
   - Unit square footage
   - Median sale price
   - Builder concentration

---

### 3.3 Fix Required

#### Step 1: Create Zonda BTR CLEANED Table

**Action**: Create `TRANSFORM_PROD.CLEANED.ZONDA_BTR_COMPREHENSIVE`

**Source**: Verify actual Zonda source table:
- `SOURCE_PROD.ZONDA.ZONDA_BTR_COMPARABLES` (if exists)
- `SOURCE_PROD.ZONDA.ZONDA_BTR_*` (verify table names)

**Schema** (expected):
```sql
CREATE TABLE TRANSFORM_PROD.CLEANED.ZONDA_BTR_COMPREHENSIVE (
    PROJECT_ID VARCHAR,
    PROJECT_NAME VARCHAR,
    DATE_REFERENCE DATE,
    ZIP_CODE VARCHAR,
    CITY VARCHAR,
    STATE VARCHAR,
    ID_CBSA VARCHAR,
    BUILDER_NAME VARCHAR,
    DEVELOPER_NAME VARCHAR,
    PRODUCT_TYPE_CODE VARCHAR DEFAULT 'BTR',
    UNITS_PLANNED NUMBER,
    UNITS_UNDER_CONSTRUCTION NUMBER,
    UNITS_DELIVERED NUMBER,
    UNIT_SQFT NUMBER,
    MEDIAN_SALE_PRICE NUMBER,
    -- Additional fields as available
    CREATED_AT TIMESTAMP_NTZ,
    UPDATED_AT TIMESTAMP_NTZ
);
```

---

#### Step 2: Create Zonda BTR Fact Table

**Action**: Create `TRANSFORM_PROD.FACT.FACT_HOUSING_HOU_BTR_ZONDA_TS`

**Purpose**: Factize Zonda BTR data into canonical format

**Metrics to Extract**:
- `ZONDA_BTR_PLANS` - Units planned
- `ZONDA_BTR_UNDER_CONSTRUCTION` - Units under construction
- `ZONDA_BTR_DELIVERIES` - Units delivered
- `ZONDA_BTR_COMMUNITY_COUNT` - Community count
- `ZONDA_BTR_BUILDER_COUNT` - Builder concentration

**Geography**: CBSA, ZIP5 (if available)

---

#### Step 3: Update BTR Signal to Include Zonda

**Action**: Modify `FCT_BTR_MARKET_SIGNAL` to union John Burns + Zonda data

**Current**:
```sql
FROM {{ ref('fact_housing_hou_btr_all_ts') }}
WHERE vendor_name = 'JOHN_BURNS'
```

**Required**:
```sql
WITH btr_metrics AS (
    -- John Burns data
    SELECT * FROM {{ ref('fact_housing_hou_btr_all_ts') }}
    WHERE vendor_name = 'JOHN_BURNS'
    
    UNION ALL
    
    -- Zonda data
    SELECT * FROM {{ ref('fact_housing_hou_btr_zonda_ts') }}
    WHERE vendor_name = 'ZONDA'
)
```

**Benefits**:
- Adds construction pipeline visibility
- Adds builder concentration data
- Expands market coverage
- Provides forward-looking supply intelligence

---

## 4. Table Prioritization for BH Comparability

### 4.1 Priority Matrix

| Priority | Table | Purpose | Comparability Metric | Effort |
|----------|-------|---------|---------------------|--------|
| **P0** | `HOUSING_HOU_DEMAND_YARDI_SFDC_BH` | Lease velocity, prospect conversion | Days to lease, conversion rate | Medium |
| **P0** | `HOUSING_HOU_OPERATIONS_YARDI_SFDC_BH` | Work orders, maintenance | Operational efficiency | Medium |
| **P1** | `HOUSING_HOU_ASSET_YARDI_SFDC_BH` | Portfolio composition | Property/unit distribution | Low |
| **P1** | `FACT_HOUSING_HOU_BTR_ZONDA_TS` | BTR construction pipeline | Supply intelligence | High |
| **P2** | `HOUSING_HOU_PRICING_YARDI_BH` | Rent growth, pricing power | Rent premium, growth | Medium |

---

### 4.2 Implementation Plan

#### Phase 1: BH Demand Table (Week 1-2)

**Goal**: Enable Progress vs BH lease velocity comparison

**Steps**:
1. Identify BH properties in Yardi (property name pattern or reference table)
2. Create `HOUSING_HOU_DEMAND_YARDI_SFDC_BH` fact table
3. Filter existing Yardi cleaned models by BH property filter
4. Aggregate to CBSA level for comparability
5. Validate against Progress metrics

**Key Metrics**:
- `BH_DAYS_TO_LEASE` - Lease velocity
- `BH_PROSPECT_CONVERSION_RATE` - Prospect to lease
- `BH_LEASE_RENEWAL_RATE` - Renewal rate
- `BH_TENANT_TURNOVER` - Turnover rate

---

#### Phase 2: BH Operations Table (Week 2-3)

**Goal**: Enable Progress vs BH operational efficiency comparison

**Steps**:
1. Filter Yardi operations tables by BH properties
2. Create `HOUSING_HOU_OPERATIONS_YARDI_SFDC_BH` fact table
3. Aggregate work orders, maintenance events
4. Calculate operational efficiency metrics
5. Validate data quality

**Key Metrics**:
- `BH_WORK_ORDER_VOLUME` - Work order count
- `BH_MAINTENANCE_FREQUENCY` - Maintenance events per unit
- `BH_PAYMENT_PROCESSING_TIME` - Payment processing efficiency

---

#### Phase 3: Zonda BTR Integration (Week 3-4) ⚠️ **CRITICAL**

**Goal**: Fix BTR signal to include Zonda data

**Steps**:
1. **Verify Zonda Source**: Identify actual Zonda BTR source table
2. **Create CLEANED Table**: `ZONDA_BTR_COMPREHENSIVE`
3. **Create Fact Table**: `FACT_HOUSING_HOU_BTR_ZONDA_TS`
4. **Update BTR Signal**: Union John Burns + Zonda data
5. **Validate**: Ensure signal populates with Zonda metrics

**Success Criteria**:
- BTR signal includes Zonda construction pipeline data
- BTR signal includes builder concentration
- BTR signal coverage expands to Zonda markets

---

## 5. Top Vendors Summary

### 5.1 Critical Vendors (Must Include)

1. **Zillow** - SFR market fundamentals
2. **Parcl Labs** - Real-time SFR intelligence
3. **GreenStreet** - Forward forecasts (Tier 1 markets)
4. **Oxford Economics** - Economic projections (all markets)
5. **John Burns** - BTR/MF intelligence
6. **Zonda** - BTR construction pipeline ⚠️ **MISSING**
7. **Realtor.com** - Supply baselines
8. **Redfin** - Supply baselines
9. **Yardi** - Operational performance (Progress + BH)
10. **Salesforce** - Operational performance (Progress + BH)

---

### 5.2 Vendor Data Status

| Vendor | CLEANED | FACT | Signal Integration | Status |
|--------|---------|------|------------------|--------|
| Zillow | ✅ | ✅ | ✅ | ✅ Active |
| Parcl Labs | ✅ | ✅ | ✅ | ✅ Active |
| GreenStreet | ✅ | ✅ | ✅ | ✅ Active |
| Oxford Economics | ✅ | ✅ | ✅ | ✅ Active |
| John Burns | ✅ | ✅ | ✅ | ✅ Active |
| **Zonda** | **❌** | **❌** | **❌** | **🔴 CRITICAL FAILURE** |
| Realtor.com | ✅ | ✅ | ✅ | ✅ Active |
| Redfin | ✅ | ✅ | ✅ | ✅ Active |
| Yardi (Progress) | ✅ | ✅ | ✅ | ✅ Active |
| Yardi (BH) | ✅ | ❌ | ❌ | ⚠️ Needs Fact Tables |

---

## 6. Action Items

### Immediate (P0 - Critical)

1. **🔴 Fix BTR Signal - Zonda Integration**
   - Verify Zonda source table location
   - Create `ZONDA_BTR_COMPREHENSIVE` cleaned table
   - Create `FACT_HOUSING_HOU_BTR_ZONDA_TS` fact table
   - Update `FCT_BTR_MARKET_SIGNAL` to include Zonda data
   - **Owner**: Data Engineering
   - **Timeline**: 1 week

2. **🔴 Create BH Demand Fact Table**
   - Identify BH property filter
   - Create `HOUSING_HOU_DEMAND_YARDI_SFDC_BH`
   - Enable Progress vs BH lease velocity comparison
   - **Owner**: Data Engineering
   - **Timeline**: 1 week

---

### High Priority (P1)

3. **Create BH Operations Fact Table**
   - Create `HOUSING_HOU_OPERATIONS_YARDI_SFDC_BH`
   - Enable operational efficiency comparison
   - **Timeline**: 1 week

4. **Create BH Asset Fact Table**
   - Create `HOUSING_HOU_ASSET_YARDI_SFDC_BH`
   - Enable portfolio composition comparison
   - **Timeline**: 3 days

---

### Medium Priority (P2)

5. **Create BH Pricing Fact Table**
   - Create `HOUSING_HOU_PRICING_YARDI_BH`
   - Enable rent growth comparison
   - **Timeline**: 1 week

6. **Validate All Vendor Data**
   - Ensure all top vendors are factized
   - Verify signal integrations
   - **Timeline**: Ongoing

---

## 7. Success Criteria

### BTR Signal Fix
- ✅ Zonda data populates `FACT_HOUSING_HOU_BTR_ZONDA_TS`
- ✅ BTR signal includes Zonda construction pipeline metrics
- ✅ BTR signal includes builder concentration
- ✅ BTR signal coverage expands

### BH Comparability
- ✅ BH demand metrics available (lease velocity, conversion)
- ✅ BH operations metrics available (work orders, maintenance)
- ✅ Progress vs BH comparison enabled
- ✅ All metrics at CBSA level for comparability

### Vendor Coverage
- ✅ All top 10 vendors factized
- ✅ All top 10 vendors integrated into signals
- ✅ Zonda BTR data included

---

## 8. Next Steps

1. **Verify Zonda Source**: Query `SOURCE_PROD.ZONDA.*` to identify actual BTR table names
2. **Create Zonda CLEANED**: Build `ZONDA_BTR_COMPREHENSIVE` from source
3. **Create Zonda FACT**: Build `FACT_HOUSING_HOU_BTR_ZONDA_TS`
4. **Update BTR Signal**: Modify to include Zonda data
5. **Create BH Fact Tables**: Build BH equivalents of Progress tables
6. **Validate**: Test all integrations and comparability

---

**Note**: This is a critical review document. The BTR signal failure is a high-priority issue that must be addressed immediately to ensure accurate BTR market intelligence.

