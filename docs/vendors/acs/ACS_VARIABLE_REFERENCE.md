# ACS Variable Reference Guide

**Date**: 2026-01-08  
**Purpose**: Reference guide for ACS (American Community Survey) variables and metrics used in tenant cohort stratification

---

## Overview

This document provides a comprehensive reference for ACS variables and metrics used in STRATA's tenant cohort stratification strategy. ACS data is sourced from the U.S. Census Bureau's American Community Survey and provides demographic, economic, and housing characteristics at the ZIP and CBSA levels.

---

## Part 1: Income Variables

### B19013: Median Household Income

**Variable Code**: `B19013_001`  
**Description**: Median household income in the past 12 months (inflation-adjusted dollars)  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Primary income stratification metric  
**Stratification**: 
- `HIGH_INCOME`: >= 100K
- `MIDDLE_INCOME`: 50K-100K
- `LOW_INCOME`: < 50K

### B19001: Household Income Distribution

**Variable Codes**: 
- `B19001_002`: <10K
- `B19001_003`: 10K-14,999
- `B19001_004`: 15K-19,999
- `B19001_005`: 20K-24,999
- `B19001_006`: 25K-29,999
- `B19001_007`: 30K-34,999
- `B19001_008`: 35K-39,999
- `B19001_009`: 40K-44,999
- `B19001_010`: 45K-49,999
- `B19001_011`: 50K-59,999
- `B19001_012`: 60K-74,999
- `B19001_013`: 75K-99,999
- `B19001_014`: 100K-124,999
- `B19001_015`: 125K-149,999
- `B19001_016`: 150K-199,999
- `B19001_017`: 200K+

**Description**: Distribution of households by income brackets  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Income distribution analysis, income cohort stratification  
**Derived Metrics**:
- `PCT_INCOME_<BRACKET>`: Percentage of households in each income bracket
- `PCT_MIDDLE_INCOME`: Sum of 50K-150K brackets
- `PCT_HIGH_INCOME`: Sum of 100K+ brackets

---

## Part 2: Household Type Variables

### B11001: Household Type

**Variable Codes**:
- `B11001_002`: Family households
- `B11001_007`: Non-family households

**Description**: Distribution of family vs non-family households  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Household type stratification  
**Derived Metrics**:
- `PCT_FAMILY_HOUSEHOLDS`: Percentage of family households
- `PCT_NON_FAMILY_HOUSEHOLDS`: Percentage of non-family households

### B11016: Household Type by Presence of Children

**Variable Codes**:
- `B11016_002`: Family households with children
- `B11016_010`: Family households without children
- `B11016_011`: Non-family households

**Description**: Household type broken down by presence of children  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Family-oriented tenant cohort identification

### Household Size Distribution

**Derived from B11001 and related tables**:
- `PCT_HOUSEHOLD_SIZE_1`: Single-person households
- `PCT_HOUSEHOLD_SIZE_2`: Two-person households
- `PCT_HOUSEHOLD_SIZE_3`: Three-person households
- `PCT_HOUSEHOLD_SIZE_4`: Four-person households
- `PCT_HOUSEHOLD_SIZE_5PLUS`: Five+ person households

**Use Case**: Household size stratification for unit type targeting

---

## Part 3: Age Variables

### B01001: Age and Sex

**Variable Codes** (examples):
- `B01001_003`: Male, 18-19 years
- `B01001_004`: Male, 20 years
- `B01001_005`: Male, 21 years
- `B01001_006`: Male, 22-24 years
- `B01001_007`: Male, 25-29 years
- `B01001_008`: Male, 30-34 years
- `B01001_009`: Male, 35-39 years
- `B01001_010`: Male, 40-44 years
- `B01001_011`: Male, 45-49 years
- `B01001_012`: Male, 50-54 years
- `B01001_013`: Male, 55-59 years
- `B01001_014`: Male, 60-61 years
- `B01001_015`: Male, 62-64 years
- `B01001_016`: Male, 65-66 years
- `B01001_017`: Male, 67-69 years
- `B01001_018`: Male, 70-74 years
- `B01001_019`: Male, 75-79 years
- `B01001_020`: Male, 80-84 years
- `B01001_021`: Male, 85+ years
- (Similar codes for females: `B01001_027` through `B01001_049`)

**Description**: Age and sex distribution of population  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Age cohort stratification  
**Derived Metrics**:
- `MEDIAN_AGE`: Median age of population
- `PCT_AGE_<BRACKET>`: Percentage in age brackets (e.g., `PCT_AGE_25_44`, `PCT_AGE_65_PLUS`)
- `AGE_STRATIFICATION`: `PRIME_BUYING_AGE`, `ESTABLISHED_BUYERS`, `SENIOR_BUYERS`, `YOUNG_BUYERS`

**Age Brackets**:
- `<18`: Children
- `18-24`: Young adults
- `25-34`: Prime renting/buying age
- `35-44`: Established renters/buyers
- `45-54`: Established buyers
- `55-64`: Pre-retirement buyers
- `65+`: Senior buyers/renters

---

## Part 4: Education Variables

### B15003: Educational Attainment

**Variable Codes**:
- `B15003_022`: Bachelor's degree
- `B15003_023`: Master's degree
- `B15003_024`: Professional degree
- `B15003_025`: Doctorate degree

**Description**: Educational attainment for population 25 years and over  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Education cohort stratification  
**Derived Metrics**:
- `PCT_BACHELORS_PLUS`: Percentage with Bachelor's degree or higher
- `PCT_GRADUATE_DEGREE`: Percentage with graduate degree (Master's, PhD, professional)
- `EDUCATION_STRATIFICATION`: `HIGH_EDUCATION`, `MIDDLE_EDUCATION`, `LOW_EDUCATION`

---

## Part 5: Poverty Variables

### B17001: Poverty Status

**Variable Codes**:
- `B17001_002`: Income in the past 12 months below poverty level
- `B17001_031`: Income in the past 12 months at or above poverty level

**Description**: Poverty status of households  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Poverty stratification for affordable housing targeting  
**Derived Metrics**:
- `PCT_BELOW_POVERTY`: Percentage below federal poverty line
- `POVERTY_STRATIFICATION`: `HIGH_POVERTY`, `MODERATE_POVERTY`, `LOW_POVERTY`

---

## Part 6: Rent Burden Variables

### B25070: Gross Rent as Percentage of Income

**Variable Codes**:
- `B25070_002`: Less than 10.0 percent
- `B25070_003`: 10.0 to 14.9 percent
- `B25070_004`: 15.0 to 19.9 percent
- `B25070_005`: 20.0 to 24.9 percent
- `B25070_006`: 25.0 to 29.9 percent
- `B25070_007`: 30.0 to 34.9 percent
- `B25070_008`: 35.0 to 39.9 percent
- `B25070_009`: 40.0 to 49.9 percent
- `B25070_010`: 50.0 percent or more

**Description**: Gross rent as percentage of household income  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Rent burden stratification  
**Derived Metrics**:
- `PCT_RENT_BURDENED`: Percentage spending >= 30% of income on rent
- `PCT_SEVERELY_BURDENED`: Percentage spending >= 50% of income on rent
- `RENT_BURDEN_STRATIFICATION`: `LOW_BURDEN`, `MODERATE_BURDEN`, `HIGH_BURDEN`

### B25095: Gross Rent as Percentage of Income (Owner-Occupied)

**Variable Codes**: Similar to B25070 but for owner-occupied units  
**Description**: Gross rent (for owner-occupied units) as percentage of household income  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Owner-occupied affordability analysis

---

## Part 7: Housing Structure Variables

### B25024: Units in Structure

**Variable Codes**:
- `B25024_002`: 1-unit, detached
- `B25024_003`: 1-unit, attached
- `B25024_004`: 2 units
- `B25024_005`: 3-4 units
- `B25024_006`: 5-9 units
- `B25024_007`: 10-19 units
- `B25024_008`: 20-49 units
- `B25024_009`: 50 or more units

**Description**: Distribution of housing units by structure type  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Supply stratification (SFR vs MF)  
**Derived Metrics**:
- `PCT_1_UNIT`: Percentage of single-unit structures (SFR supply indicator)
- `PCT_2_4_UNITS`: Percentage of 2-4 unit structures (small MF)
- `PCT_5P_UNITS`: Percentage of 5+ unit structures (large MF)

### B25003: Tenure

**Variable Codes**:
- `B25003_002`: Owner-occupied
- `B25003_003`: Renter-occupied

**Description**: Owner vs renter occupancy  
**Geography Levels**: ZIP, CBSA  
**Use Case**: Demand stratification (owner vs rental demand)  
**Derived Metrics**:
- `PCT_OWNER`: Percentage of owner-occupied units
- `PCT_RENTER`: Percentage of renter-occupied units

---

## Part 8: Composite Tenant Cohorts

### Renter Cohorts

**PROFESSIONAL_RENTER_COHORT**:
- Income: `HIGH_INCOME` (>= 100K median OR >= 40% in 100K+ brackets)
- Rent Burden: `LOW_BURDEN` (<30% of income)
- Education: `HIGH_EDUCATION` (>= 40% Bachelor's+)
- Use Case: Traditional SFR equity offerings

**FAMILY_RENTER_COHORT**:
- Income: `MIDDLE_INCOME` (50K-100K median OR >= 40% in 50K-150K brackets)
- Rent Burden: `MODERATE_BURDEN` (30-50% of income)
- Household Type: `FAMILY_HOUSEHOLD_COHORT` (>= 60% family households)
- Use Case: Front Yard SFR equity offerings

**AFFORDABLE_RENTER_COHORT**:
- Income: `LOW_INCOME` (<50K median OR >= 40% in <50K brackets)
- Rent Burden: `HIGH_BURDEN` (>50% of income)
- Education: `LOW_EDUCATION` (<20% Bachelor's+)
- Use Case: Affordable housing offerings

**MIXED_RENTER_COHORT**:
- Balanced mix of characteristics
- Use Case: General SFR equity offerings

### Buyer Cohorts

**PROFESSIONAL_BUYER_COHORT**:
- Income: `HIGH_INCOME`
- Education: `HIGH_EDUCATION`
- Age: `PRIME_BUYING_AGE` (>= 30% aged 25-44)
- Use Case: Homebuilder finance (horizontal development)

**FAMILY_BUYER_COHORT**:
- Income: `MIDDLE_INCOME`
- Household Type: `FAMILY_HOUSEHOLD_COHORT`
- Age: `PRIME_BUYING_AGE`
- Use Case: Homebuilder finance (vertical construction)

**ESTABLISHED_BUYER_COHORT**:
- Income: `HIGH_INCOME`
- Age: `ESTABLISHED_BUYERS` (>= 30% aged 45-64)
- Education: `HIGH_EDUCATION`
- Use Case: Homebuilder finance (land banking)

**FIRST_TIME_BUYER_COHORT**:
- Income: `MIDDLE_INCOME`
- Age: `YOUNG_BUYERS` (>= 20% aged <25) OR `PRIME_BUYING_AGE`
- Education: `MIDDLE_EDUCATION`
- Use Case: Homebuilder finance (first-time buyer programs)

---

## Part 9: Data Sources and Tables

### Source Tables

1. **`SOURCE_PROD.ACS.ACS_LONG_ZCTA5`**:
   - Raw ACS data at ZIP (ZCTA5) level
   - Contains VAR_CODE, VAR_LABEL, VALUE, YEAR
   - Used for: Direct variable extraction

2. **`TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS`**:
   - Transformed ACS data at ZIP level
   - Contains METRIC_ID, VALUE, DATE_REFERENCE
   - Used for: ZIP-level stratification views

3. **`TRANSFORM_PROD.FACT.FACT_ACS_CBSA_TS`**:
   - Transformed ACS data at CBSA level (aggregated from ZIP)
   - Contains METRIC_ID, VALUE, DATE_REFERENCE
   - Used for: CBSA-level stratification views

### Catalog Tables

1. **`ADMIN.CATALOG.DIM_METRIC`**:
   - Central registry of all metrics
   - Contains METRIC_ID, METRIC_NAME, DOMAIN, TAXON, GEOGRAPHY_LEVELS
   - Used for: Metric discovery and validation

2. **`ADMIN.CATALOG.DIM_TAXON`**:
   - Taxon classifications (HH_DEMOGRAPHY, HH_AFFORDABILITY, HH_STRUCTURE, HH_LABOR)
   - Used for: Metric categorization

---

## Part 10: Metric ID Format

ACS metrics in STRATA follow a standardized METRIC_ID format:

**Format**: `ACS_<VAR_CODE>`

**Examples**:
- `ACS_B19013_001`: Median household income
- `ACS_B19001_002`: Households with income <10K
- `ACS_B25070_007`: Rent burden 30.0-34.9 percent

**Geography-Specific Metrics**:
- ZIP-level: Stored in `FACT_ACS_ZIP_TS` with `ID_ZIP`
- CBSA-level: Stored in `FACT_ACS_CBSA_TS` with `ID_CBSA`

---

## Part 11: Stratification Views

### Base Stratification Views

1. **`V_ZIP_STRATIFICATION`**:
   - Base ZIP-level ACS stratification
   - Includes: Income, household type, age, education, poverty, rent burden
   - Location: `ANALYTICS_PROD.MARKETS.V_ZIP_STRATIFICATION`

2. **`V_CBSA_STRATIFICATION`**:
   - Base CBSA-level ACS stratification
   - Mirrors ZIP-level structure
   - Location: `ANALYTICS_PROD.MARKETS.V_CBSA_STRATIFICATION`

### Product-Type Stratification Views

1. **`V_PRODUCT_TYPE_ACS_STRATIFICATION_ZIP`**:
   - Product-type-specific stratification (SF, MF, BTR, Affordable)
   - Includes: Supply and demand stratifications for each product type
   - Location: `ANALYTICS_PROD.MARKETS.V_PRODUCT_TYPE_ACS_STRATIFICATION_ZIP`

### Tenant Cohort Views

1. **`V_TENANT_COHORT_STRATIFICATION_ZIP`**:
   - Composite tenant cohort view (ZIP level)
   - Includes: Income, household type, age, education, poverty, rent burden cohorts
   - Location: `ANALYTICS_PROD.MARKETS.V_TENANT_COHORT_STRATIFICATION_ZIP`

2. **`V_TENANT_COHORT_STRATIFICATION_CBSA`**:
   - Composite tenant cohort view (CBSA level)
   - Mirrors ZIP-level structure
   - Location: `ANALYTICS_PROD.MARKETS.V_TENANT_COHORT_STRATIFICATION_CBSA`

---

## Part 12: Usage Examples

### Example 1: Query Income Stratification

```sql
SELECT 
    ID_ZIP,
    MEDIAN_HOUSEHOLD_INCOME,
    INCOME_STRATIFICATION,
    PCT_MIDDLE_INCOME,
    PCT_HIGH_INCOME
FROM ANALYTICS_PROD.MARKETS.V_ZIP_STRATIFICATION
WHERE DATE_REFERENCE >= DATEADD(YEAR, -2, CURRENT_DATE())
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ID_ZIP ORDER BY DATE_REFERENCE DESC) = 1
ORDER BY MEDIAN_HOUSEHOLD_INCOME DESC;
```

### Example 2: Query Renter Cohorts

```sql
SELECT 
    ID_ZIP,
    ZIP_RENTER_INCOME_COHORT,
    ZIP_RENTER_INCOME_STRATIFICATION,
    ZIP_RENT_BURDEN_STRATIFICATION,
    ZIP_PCT_HIGH_INCOME,
    ZIP_PCT_SEVERELY_BURDENED
FROM ANALYTICS_PROD.MODELED.PROG_SFR_BASE_CURRENT_OUTLOOK_ZIP
WHERE ZIP_RENTER_INCOME_COHORT = 'PROFESSIONAL_RENTER_COHORT'
ORDER BY ZIP_MARKET_RANK_2Y;
```

### Example 3: Query Buyer Cohorts

```sql
SELECT 
    ID_CBSA,
    MARKET_NAME,
    BUYER_INCOME_COHORT,
    BUYER_HOUSEHOLD_TYPE_COHORT,
    BUYER_AGE_COHORT,
    PCT_HIGH_INCOME,
    PCT_FAMILY_HOUSEHOLDS,
    PCT_AGE_25_44
FROM ANALYTICS_PROD.MODELED.ANCHOR_LOANS_CURRENT_OUTLOOK
WHERE BUYER_INCOME_COHORT = 'PROFESSIONAL_BUYER_COHORT'
ORDER BY MARKET_RANK_2Y;
```

---

## References

- **ACS Data Documentation**: [U.S. Census Bureau ACS Documentation](https://www.census.gov/programs-surveys/acs/data.html)
- **STRATA Documentation**:
  - `docs/TENANT_COHORT_STRATEGY.md`: Tenant cohort strategy overview
  - `docs/ACS_VARIABLE_INVENTORY.md`: ACS variable inventory and gap analysis
- **Discovery Results**:
  - `exports/fund_7_q1_2026/metadata/acs_metrics_from_catalog.json`: Metrics from DIM_METRIC catalog
  - `exports/fund_7_q1_2026/metadata/acs_variables_from_source.json`: Variables from source data
  - `exports/fund_7_q1_2026/metadata/acs_coverage_gaps.json`: Gap analysis results

---

**Last Updated**: 2026-01-08  
**Version**: 1.0

