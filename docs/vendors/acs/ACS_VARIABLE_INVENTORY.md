# ACS Variable Inventory

**Date**: 2026-01-08  
**Purpose**: Comprehensive inventory of ACS metrics and variables available for tenant cohort differentiation

---

## Executive Summary

This document catalogs ACS (American Community Survey) metrics and variables available in the STRATA platform for tenant cohort differentiation. The analysis compares:
- **DIM_METRIC Catalog**: 529 ACS/Census metrics already catalogued
- **Source Data**: 1,355 unique VAR_CODE patterns in `SOURCE_PROD.ACS.ACS_LONG_ZCTA5`

**Key Finding**: Many expected ACS tables (B11001, B01001, B15003, B17001) are not present in the source data, suggesting they may be in a different table or format. We will proceed with available variables and document gaps for future investigation.

---

## Part 1: Metrics Catalogued in DIM_METRIC

### 1.1 Summary Statistics

| Category | Count |
|----------|-------|
| Total ACS/Census Metrics | 529 |
| Income-Related Metrics | 94 |
| Household Type/Size Metrics | 65 |
| Age Demographics Metrics | 9 |
| Education Metrics | 3 |
| Poverty Metrics | 3 |
| Rent Burden Metrics | 104 |

### 1.2 Income Metrics (94 metrics)

**Key Metrics Available**:
- `ACS_B19013_MEDIAN_HOUSEHOLD_INCOME` - Median Household Income
- `ACS_B19019_MEDIAN_OWNER_INCOME` - Median Owner Household Income
- `ACS_B19019_MEDIAN_RENTER_INCOME` - Median Renter Household Income
- Household Income Brackets (16 brackets from <$10K to $200K+)

**Domain/Taxon**: `HOUSEHOLD` / `HH_DEMOGRAPHY`  
**Geography Levels**: ZIP, CBSA, COUNTY  
**Product Type**: ALL

### 1.3 Rent Burden Metrics (104 metrics)

**Key Metrics Available**:
- `ACS_B25070_RENT_BURDEN_30_PCT_OR_MORE` - Rent Burden 30%+ (Cost-Burdened)
- `ACS_B25070_RENT_BURDEN_50_PCT_OR_MORE` - Rent Burden 50%+ (Severely Burdened)
- `ACS_B25071_MEDIAN_RENT_TO_INCOME_RATIO` - Median Rent-to-Income Ratio
- Rent Burden Brackets (10-14.9%, 15-19.9%, 20-24.9%, 25-29.9%, 30-34.9%, 35-39.9%, 40-49.9%, 50%+)

**Domain/Taxon**: `HOUSEHOLD` / `HH_AFFORDABILITY`  
**Geography Levels**: ZIP, CBSA  
**Product Type**: ALL  
**Tenure**: RENT

### 1.4 Household Type/Size Metrics (65 metrics)

**Key Metrics Available**:
- Family vs Non-Family Households
- Household Size Distributions
- Tenure by Household Type

**Domain/Taxon**: `HOUSEHOLD` / `HH_DEMOGRAPHY`, `HH_STRUCTURE`  
**Geography Levels**: ZIP, CBSA

### 1.5 Age, Education, Poverty Metrics (Limited)

**Age Metrics**: 9 metrics (limited coverage)  
**Education Metrics**: 3 metrics (limited coverage)  
**Poverty Metrics**: 3 metrics (limited coverage)

**Note**: These categories have limited metrics catalogued, suggesting they may need to be added from source data or may be in different tables.

---

## Part 2: Variables Available in Source Data

### 2.1 Summary Statistics

| Category | VAR_CODE Count | Coverage |
|----------|----------------|----------|
| Total Unique VAR_CODE Patterns | 1,355 | All ZIPs, 11 years |
| Income Variables (B19001) | 16 | 33,971 ZIPs, 11 years |
| Rent Burden Variables (B25070) | 13 | 33,971 ZIPs, 11 years |
| Housing Cost Variables | 27 | Various tables |

### 2.2 Income Variables (B19001)

**Available VAR_CODEs**:
- `B19001_002` - Less than $10,000
- `B19001_003` - $10,000 to $14,999
- `B19001_004` - $15,000 to $19,999
- `B19001_005` - $20,000 to $24,999
- `B19001_006` - $25,000 to $29,999
- `B19001_007` - $30,000 to $34,999
- `B19001_008` - $35,000 to $39,999
- `B19001_009` - $40,000 to $44,999
- `B19001_010` - $45,000 to $49,999
- `B19001_011` - $50,000 to $59,999
- `B19001_012` - $60,000 to $74,999
- `B19001_013` - $75,000 to $99,999
- `B19001_014` - $100,000 to $124,999
- `B19001_015` - $125,000 to $149,999
- `B19001_016` - $150,000 to $199,999
- `B19001_017` - $200,000 or more

**Coverage**: 33,971 ZIPs, 11 years (2014-2024)  
**Status**: ✅ Available in source, partially catalogued in DIM_METRIC

### 2.3 Rent Burden Variables (B25070)

**Available VAR_CODEs**:
- `B25070_002` - Less than 10.0 percent
- `B25070_003` - 10.0 to 14.9 percent
- `B25070_004` - 15.0 to 19.9 percent
- `B25070_005` - 20.0 to 24.9 percent
- `B25070_006` - 25.0 to 29.9 percent
- `B25070_007` - 30.0 to 34.9 percent
- `B25070_008` - 35.0 to 39.9 percent
- `B25070_009` - 40.0 to 49.9 percent
- `B25070_010` - 50.0 percent or more
- `B25070_011` - Not computed

**Coverage**: 33,971 ZIPs, 11 years  
**Status**: ✅ Available in source, catalogued in DIM_METRIC

### 2.4 Missing Expected Tables

The following ACS tables were expected but **NOT FOUND** in source data:
- ❌ **B19013** - Median Household Income (may be calculated from B19001)
- ❌ **B11001** - Household Type (Family vs Non-Family)
- ❌ **B11016** - Household Size
- ❌ **B01001** - Age by Sex
- ❌ **B15003** - Educational Attainment
- ❌ **B17001** - Poverty Status
- ❌ **B25095** - Gross Rent as Percentage of Household Income (detailed)
- ❌ **B25071** - Median Gross Rent as Percentage of Household Income

**Investigation Needed**: These tables may be:
1. In a different source table (e.g., `ACS_LONG_CBSA` or `ACS_LONG_COUNTY`)
2. Named differently in the source schema
3. Not yet ingested into the platform

---

## Part 3: Gap Analysis

### 3.1 Variables in Source but Not Catalogued

**Count**: 927 variables not catalogued in DIM_METRIC

**Priority Variables to Add**:
1. **B19001 Income Brackets** - All 16 brackets should be mapped to METRIC_IDs
2. **B25070 Rent Burden Brackets** - All 10 brackets should be mapped
3. **B25056/B25058 Housing Cost Variables** - 27 variables available

### 3.2 Metrics Catalogued but Not in Source

**Count**: Many metrics in DIM_METRIC reference ACS tables not found in source

**Investigation Needed**: Verify if these metrics are:
1. Calculated/derived metrics (not direct ACS variables)
2. From different geography levels (CBSA vs ZIP)
3. From different ACS datasets (1-year vs 5-year estimates)

### 3.3 Recommended Additions to DIM_METRIC

**High Priority**:
- Income bracket metrics (B19001_002 through B19001_017)
- Rent burden bracket metrics (B25070_002 through B25070_011)
- Median household income (B19013_001) - if available or calculated

**Medium Priority**:
- Housing cost variables (B25056, B25058, B25059)
- Tenure by age variables (B25074, B25075, B25092) - if available

**Low Priority** (pending source investigation):
- Household type variables (B11001) - if found in other tables
- Age demographics (B01001) - if found in other tables
- Education variables (B15003) - if found in other tables
- Poverty variables (B17001) - if found in other tables

---

## Part 4: Recommended Use Cases for Tenant Cohort Differentiation

### 4.1 Income-Based Cohorts

**Available Data**: B19001 income brackets (16 brackets)

**Cohort Stratification**:
- **LOW_INCOME**: <$50K (B19001_002 through B19001_010)
- **MIDDLE_INCOME**: $50K-$100K (B19001_011 through B19001_013)
- **HIGH_INCOME**: >$100K (B19001_014 through B19001_017)

**Use Cases**:
- Anchor Loans: Target middle-high income buyers ($75K-$150K)
- Progress SFR Traditional: Target middle income renters ($50K-$100K)
- Progress SFR Affordable: Target low income renters (<$50K)

### 4.2 Rent Burden Cohorts

**Available Data**: B25070 rent burden brackets (10 brackets)

**Cohort Stratification**:
- **LOW_BURDEN**: <20% (B25070_002, B25070_003)
- **MODERATE_BURDEN**: 20-30% (B25070_004, B25070_005, B25070_006)
- **HIGH_BURDEN**: 30%+ (B25070_007, B25070_008, B25070_009, B25070_010)

**Use Cases**:
- Affordable Housing: Target high rent burden areas (30%+)
- Traditional SFR: Target low-moderate rent burden (<30%)

### 4.3 Composite Cohorts (Using Available Data)

**Professional Renter Cohort**:
- High income (>$100K) + Low rent burden (<20%)

**Family Renter Cohort**:
- Middle income ($50K-$100K) + Moderate rent burden (20-30%)

**Affordable Renter Cohort**:
- Low income (<$50K) + High rent burden (30%+)

---

## Part 5: Implementation Priority

### Phase 1: Immediate (Available Data)
1. ✅ Map B19001 income brackets to FACT_ACS_ZIP_TS
2. ✅ Map B25070 rent burden brackets to FACT_ACS_ZIP_TS
3. ✅ Add income and rent burden stratifications to ZIP stratification view
4. ✅ Create tenant cohort views using available data

### Phase 2: Investigation Required
1. Investigate missing ACS tables (B11001, B01001, B15003, B17001)
2. Check alternative source tables (CBSA, COUNTY level)
3. Verify if metrics are calculated/derived vs direct ACS variables

### Phase 3: Future Enhancement
1. Add household type/size variables (when found)
2. Add age demographics (when found)
3. Add education variables (when found)
4. Add poverty variables (when found)

---

## Part 6: Data Quality Notes

### Coverage Statistics
- **ZIP Coverage**: 33,971 ZIPs for income and rent burden variables
- **Time Range**: 11 years (2014-2024)
- **Frequency**: Annual (5-year ACS estimates)

### Data Completeness
- Income variables: ✅ High coverage (33,971 ZIPs)
- Rent burden variables: ✅ High coverage (33,971 ZIPs)
- Household type: ❌ Not available in source
- Age demographics: ❌ Not available in source
- Education: ❌ Not available in source
- Poverty: ❌ Not available in source

---

## References

- **Discovery Scripts**:
  - `sql/transform/fact/discover_acs_metrics_from_catalog.sql`
  - `sql/transform/fact/discover_acs_variables_from_source.sql`
  - `sql/transform/fact/analyze_acs_coverage_gaps.sql`

- **Discovery Results**:
  - `exports/fund_7_q1_2026/metadata/acs_metrics_from_catalog.json`
  - `exports/fund_7_q1_2026/metadata/acs_variables_from_source.json`
  - `exports/fund_7_q1_2026/metadata/acs_coverage_gaps.json`

- **Current Implementation**:
  - `sql/transform/fact/populate_fact_acs_zip_complete.sql` - Current FACT_ACS_ZIP_TS population

---

**Last Updated**: 2026-01-08  
**Next Review**: After investigation of missing ACS tables

