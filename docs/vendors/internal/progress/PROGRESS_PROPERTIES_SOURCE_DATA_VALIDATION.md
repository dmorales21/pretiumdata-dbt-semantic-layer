# Progress Properties Source Data Validation

**Date**: 2026-01-27  
**Purpose**: Validate source data structure and identify offering mapping requirements

---

## Executive Summary

**Key Finding**: The `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` table does **NOT** contain explicit offering identifiers (TRAD, FY, AH). Properties must be mapped to offerings using portfolio footprint and tract characteristics.

---

## Table Structure Analysis

### Source Table: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`

**Total Columns**: 129  
**Primary Identifiers**:
- `ID_SALESFORCE` (VARCHAR(18), NOT NULL) - Primary key
- `ID_PROPERTY_HMY` (VARCHAR(30), nullable) - Homey property ID
- `PROPERTY_NUMBER` (VARCHAR(9), nullable) - Property number

**Geographic Columns**:
- `ZIP_CODE` (VARCHAR(1300), nullable)
- `CITY` (VARCHAR(50), nullable)
- `STATE` (VARCHAR(2), nullable)
- `COUNTY` (VARCHAR(1300), nullable)
- `MSA_NAME` (VARCHAR(1300), nullable) - Market name
- `LATITUDE` (FLOAT, nullable)
- `LONGITUDE` (FLOAT, nullable)
- **Note**: No `CBSA_CODE` column directly - must be enriched via ZIP crosswalk

**Property Characteristics**:
- `PROPERTY_TYPE` (VARCHAR(255)) - "Single Family"
- `BEDROOMS`, `BATHROOMS`, `SQUARE_FEET`, `YEAR_BUILT`
- `HOME_TIER_LEVEL` (VARCHAR(255)) - "Level 1", "Level 3", etc.
- `CLUSTER` (VARCHAR(255)) - Market sub-cluster
- `TIER` (VARCHAR(255), nullable)

**Status Flags**:
- `IS_OWNED` (NUMBER(38,0)) - 1 = owned, 0 = not owned
- `IS_INACTIVE` (NUMBER(38,0)) - 1 = inactive, 0 = active
- `IS_DELETED` (NUMBER(38,0)) - 1 = deleted, 0 = not deleted
- `STATUS` (VARCHAR(1300)) - "Yardi Process", "Sold", etc.
- `STAGE` (VARCHAR(255)) - "Yardi Process", "Progress Sells Property", etc.
- `WEBSITE_BANNER` (VARCHAR(1300)) - "Occupied", "Coming Soon", "Not Available"

**Financial Columns**:
- `PURCHASE_PRICE`, `RENT_CURRENT`, `RENT_MARKET`
- `CAP_RATE`, `GROSS_YIELD`, `NET_YIELD`
- `TAXES_YEARLY`, `HOA_YEARLY`, `INSURANCE_YEARLY`

**Operational Columns**:
- `LEASE_START_DATE`, `LEASE_END_DATE`
- `MOVE_IN_DATE`, `MOVE_OUT_DATE`
- `OCCUPANCY_STATUS`, `TENANT_STATUS_YARDI`, `UNIT_STATUS_YARDI`

**Entity/Portfolio Columns**:
- `ENTITY` (VARCHAR(255)) - "Progress"
- `ENTITY_OWNED` (VARCHAR(255)) - Fund name
- `FUND_ID` (VARCHAR(18))
- `PORTFOLIO_ID` (VARCHAR(18), nullable)
- `OPCO_NAME` (VARCHAR(20)) - "Progress Residential"
- `OPCO_ID` (VARCHAR(20)) - "PROGRESS_RESIDENTIAL"

---

## Critical Finding: No Offering Column

**There is NO column in `PROGRESS_PROPERTIES` that explicitly identifies which offering (TRAD, FY, AH) a property belongs to.**

**Implications**:
1. Properties cannot be directly filtered by offering
2. Offering assignment must be **inferred** from:
   - **Tract location** (via `V_OFFERING_DIFFERENTIATION_TRACT`)
   - **Portfolio footprint** (via `V_PORTFOLIO_TRACT_FOOTPRINT`)
   - **Property characteristics** (tier level, cluster, etc.)

---

## Offering Definition Reference

**Source**: `ANALYTICS_PROD.MODELED.DIM_OFFERING_PATH_MAPPING`

**Progress Offerings Defined**:
- `PROG_SFR_TRAD` - Traditional SFR Renter Demand
- `PROG_SFR_AH` - Affordable/HCV SFR Renter Demand  
- `PROG_SFR_FY` - Family/Sticky SFR Renter Demand

**All Progress offerings are**:
- `PATH` = 'RENTER'
- `STRUCTURE_BUCKET` = 'SFR'
- `PRICING_ASSUMPTION_TYPE` = 'RENT_BASED'
- `TARGET_RENT_TO_INCOME` = 0.30

---

## Data Quality Assessment

### Active Properties Filter
```sql
WHERE (IS_DELETED = FALSE OR IS_DELETED IS NULL) 
  AND (IS_INACTIVE = FALSE OR IS_INACTIVE IS NULL)
```

**This filter should be applied in all portfolio footprint queries** to ensure we only count properties that Progress currently owns and operates.

### Geographic Completeness

**Required for Tract Mapping**:
- ✅ `ZIP_CODE` - Available (VARCHAR(1300), may need LEFT(..., 5) normalization)
- ✅ `LATITUDE` / `LONGITUDE` - Available (FLOAT, nullable)
- ⚠️ `CBSA_CODE` - **NOT directly available** - must be enriched via:
  - `H3_XWALK_6810_CANON` (ZIP → CBSA)
  - Or `MSA_NAME` → CBSA mapping (less reliable)

**Current Implementation**: Uses ZIP-to-tract crosswalk via `H3_XWALK_6810_CANON`, which is correct.

---

## Property-to-Offering Mapping Strategy

### Current Approach (Portfolio-Based)

**Step 1**: Map properties to tracts
- Use `ZIP_CODE` → `H3_XWALK_6810_CANON` → `ID_TRACT`
- Fallback: Spatial join using `LATITUDE`/`LONGITUDE` if ZIP match fails

**Step 2**: Assign offerings based on tract characteristics
- **TRAD**: Tracts with `PROGRESS_PROPERTY_COUNT >= 10` (established footprint)
- **FY**: Tracts with `PROGRESS_PROPERTY_COUNT >= 10` + meaningful FY demand
- **AH**: Tracts with `PROGRESS_PROPERTY_COUNT < 10` + affordability demand

**Step 3**: Aggregate property counts by offering
- Count properties in TRAD tracts → `PROGRESS_PROPERTIES_IN_TRAD`
- Count properties in FY tracts → `PROGRESS_PROPERTIES_IN_FY`
- Count properties in AH tracts → `PROGRESS_PROPERTIES_IN_AH`

### Validation Query

```sql
-- Validate property-to-tract mapping
SELECT 
    COUNT(DISTINCT pp.ID_SALESFORCE) AS TOTAL_PROPERTIES,
    COUNT(DISTINCT pf.ID_TRACT) AS TRACTS_WITH_PROPERTIES,
    SUM(pf.PROGRESS_PROPERTY_COUNT) AS TOTAL_PROPERTY_COUNTS,
    AVG(pf.PROGRESS_PROPERTY_COUNT) AS AVG_PROPERTIES_PER_TRACT
FROM TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES pp
INNER JOIN ANALYTICS_PROD.MODELED.V_PORTFOLIO_TRACT_FOOTPRINT pf
    ON pp.ID_SALESFORCE = -- Need to join via tract
WHERE (pp.IS_DELETED = FALSE OR pp.IS_DELETED IS NULL) 
  AND (pp.IS_INACTIVE = FALSE OR pp.IS_INACTIVE IS NULL);
```

**Note**: This query needs to be completed - we need to join properties to tracts via ZIP or spatial join.

---

## Recommended Next Steps

### 1. Validate Portfolio Footprint View
- Verify that `V_PORTFOLIO_TRACT_FOOTPRINT` correctly counts all active Progress properties
- Check for properties that fail to map to tracts (ZIP not in crosswalk, missing lat/lon)

### 2. Create Property-to-Offering Mapping Table (Optional)
If explicit offering assignment is needed:
```sql
CREATE TABLE ANALYTICS_PROD.MODELED.DIM_PROPERTY_OFFERING_MAPPING (
    ID_SALESFORCE VARCHAR(18) NOT NULL PRIMARY KEY,
    ID_PROPERTY_HMY VARCHAR(30),
    PROPERTY_NUMBER VARCHAR(9),
    ID_TRACT VARCHAR(11),
    OFFERING_ID VARCHAR(50),  -- 'PROG_SFR_TRAD', 'PROG_SFR_FY', 'PROG_SFR_AH'
    ASSIGNMENT_METHOD VARCHAR(50),  -- 'PORTFOLIO_FOOTPRINT', 'MANUAL', 'RULE_BASED'
    ASSIGNED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    ASSIGNED_BY VARCHAR(100)
);
```

### 3. Validate Offering Differentiation
- Run `V_OFFERING_DIFFERENTIATION_CBSA` to check portfolio overlap percentages
- Verify TRAD has high overlap, AH has low overlap (as expected)

### 4. Data Quality Checks
- Count properties with missing ZIP codes
- Count properties with missing lat/lon
- Count properties that fail to map to tracts
- Count properties that map to tracts but have no offering assignment

---

## Summary

✅ **Source table structure validated** - 129 columns, all expected fields present  
✅ **Offering definitions exist** - `DIM_OFFERING_PATH_MAPPING` defines PROG_SFR_TRAD, PROG_SFR_AH, PROG_SFR_FY  
❌ **No explicit offering column** - Properties must be mapped via tract characteristics  
✅ **Geographic data available** - ZIP, lat/lon present for tract mapping  
✅ **Active property filter** - `IS_DELETED` and `IS_INACTIVE` flags available  

**Conclusion**: The current portfolio-based approach (mapping properties to tracts, then assigning offerings based on tract characteristics) is the correct strategy given the absence of explicit offering identifiers in the source table.

