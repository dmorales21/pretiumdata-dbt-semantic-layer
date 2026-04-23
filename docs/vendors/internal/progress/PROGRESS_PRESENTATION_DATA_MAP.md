# Progress Presentation Data Map - Snowflake Locations

**Date**: 2026-01-27  
**Purpose**: Comprehensive mapping of all Progress presentation metrics to their Snowflake database, schema, table, and column locations  
**Status**: Complete mapping for all presentation sections

---

## Overview

This document maps every metric from the Progress presentation slides to its location in Snowflake. Metrics are organized by presentation section and include:
- Database.schema.table.column paths
- Example SQL queries where helpful
- Data gaps and integration requirements
- Distinction between internal (tenant-level) and public (geographic) data sources

---

## 1. Progress Homes Are Affordable

### By Tenure

#### Cost to Own vs. Cost to Rent

**Rent Data**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`
- **Filter**: `METRIC_ID = 'ZILLOW_ZORI'` AND `TENANCY_CODE = 'RENT'`
- **Geography**: ZIP or CBSA level
- **Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    GEO_ID,
    GEO_LEVEL_CODE,
    VALUE as ZORI_RENT
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS
WHERE METRIC_ID = 'ZILLOW_ZORI'
  AND TENANCY_CODE = 'RENT'
  AND DATE_REFERENCE >= '2019-01-01'
ORDER BY DATE_REFERENCE DESC, GEO_ID;
```

**Mortgage Payment Proxy**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_ALL_TS`
- **Filter**: `METRIC_ID = 'ZILLOW_ZHVI'` (Zillow Home Value Index)
- **Calculation**: ZHVI × interest rate assumptions + principal/amortization
- **Note**: Interest rate history may need to be sourced from FRED or external data

**Taxes/Insurance**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Columns**: `TAXES_YEARLY`, `INSURANCE_YEARLY`
- **Aggregation**: Average by ZIP or CBSA for market-level analysis

**Monthly Cost Segmentation**:
- **Framework**: See `docs/SIGNAL_DATA_REQUIREMENTS.md` for existing signal framework
- **Concept**: "Monthly Cost (To rent or own)" already modeled in signal system

#### Owner Incomes vs. Renter Incomes

**Owner Income**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` or `FACT_ACS_CBSA_TS`
- **Filter**: `METRIC_ID = 'ACS_B19019_MEDIAN_OWNER_INCOME'`
- **Geography**: ZIP or CBSA level

**Renter Income**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` or `FACT_ACS_CBSA_TS`
- **Filter**: `METRIC_ID = 'ACS_B19019_MEDIAN_RENTER_INCOME'`
- **Geography**: ZIP or CBSA level

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    GEO_ID,
    GEO_LEVEL_CODE,
    MAX(CASE WHEN METRIC_ID = 'ACS_B19019_MEDIAN_OWNER_INCOME' THEN VALUE END) as MEDIAN_OWNER_INCOME,
    MAX(CASE WHEN METRIC_ID = 'ACS_B19019_MEDIAN_RENTER_INCOME' THEN VALUE END) as MEDIAN_RENTER_INCOME
FROM TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS
WHERE METRIC_ID IN ('ACS_B19019_MEDIAN_OWNER_INCOME', 'ACS_B19019_MEDIAN_RENTER_INCOME')
  AND DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS)
GROUP BY DATE_REFERENCE, GEO_ID, GEO_LEVEL_CODE;
```

#### Rent vs Own Monthly Cost Gap (by Market)

**Build from**:
- Zillow ZORI (rent): `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS` (METRIC_ID = 'ZILLOW_ZORI')
- Zillow ZHVI (home value): `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_ALL_TS` (METRIC_ID = 'ZILLOW_ZHVI')
- Mortgage calculation: ZHVI × interest rate + amortization
- Taxes/Insurance: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` (aggregated by market)

**Calculation**: (Mortgage + Taxes + Insurance) - Rent = Cost Gap

#### Owner Burden vs Renter Burden

**Owner Burden**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Source**: Calculated from ACS B25070 (housing cost burden tables)
- **Note**: May need to derive from owner-occupied housing cost data

**Renter Burden**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Columns**: 
  - `RENT_BURDEN_30_34_9` (30-34.9% of income)
  - `RENT_BURDEN_35_39_9` (35-39.9% of income)
  - `RENT_BURDEN_40_49_9` (40-49.9% of income)
  - `RENT_BURDEN_50PLUS` (50%+ of income)
- **Also Available**: `TRANSFORM_PROD.FACT.HOUSEHOLD_HH_AFFORDABILITY_ALL_TS` (if factized)

**Example Query**:
```sql
SELECT 
    ID_TRACT,
    CBSA_CODE,
    RENT_BURDEN_30_34_9,
    RENT_BURDEN_35_39_9,
    RENT_BURDEN_40_49_9,
    RENT_BURDEN_50PLUS,
    (RENT_BURDEN_30_34_9 + RENT_BURDEN_35_39_9 + RENT_BURDEN_40_49_9 + RENT_BURDEN_50PLUS) / 
        NULLIF(RENTER_OCCUPIED, 0) * 100 as PCT_RENT_BURDENED_30PLUS
FROM ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT
WHERE DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT);
```

#### Renter Income Distribution (by Bracket)

**Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` or `FACT_ACS_CBSA_TS`

**Metrics**: ACS B19001 income brackets
- `ACS_B19001_INCOME_LESS_10K`
- `ACS_B19001_INCOME_10_15K`
- `ACS_B19001_INCOME_15_20K`
- `ACS_B19001_INCOME_20_25K`
- `ACS_B19001_INCOME_25_30K`
- `ACS_B19001_INCOME_30_35K`
- `ACS_B19001_INCOME_35_40K`
- `ACS_B19001_INCOME_40_45K`
- `ACS_B19001_INCOME_45_50K`
- `ACS_B19001_INCOME_50_60K`
- `ACS_B19001_INCOME_60_75K`
- `ACS_B19001_INCOME_75_100K`
- `ACS_B19001_INCOME_100_125K`
- `ACS_B19001_INCOME_125_150K`
- `ACS_B19001_INCOME_150_200K`
- `ACS_B19001_INCOME_200K_PLUS`

**Reference**: `sql/analytics/governance/01_create_income_bin_dimension.sql` for bracket definitions

#### AMI / Income Limits

**Location**: `SOURCE_PROD.HUD.HUD_2026_SAFMR`
- **Table**: Contains AMI thresholds by CBSA
- **Cleaned Version**: `TRANSFORM_PROD.CLEANED.HUD_SAFMR_CBSA_TS` (if exists)
- **Fact Table**: `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`
- **Filter**: `METRIC_ID LIKE 'HUD_SAFMR%'`

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    ID_CBSA,
    METRIC_ID,
    VALUE as AMI_THRESHOLD
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS
WHERE METRIC_ID LIKE 'HUD_SAFMR%'
  AND DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS WHERE METRIC_ID LIKE 'HUD_SAFMR%');
```

### By Income Level

#### Progress Options by AMI Level

**Requires**:
- Progress property data: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- AMI crosswalk: Join with HUD SAFMR data by CBSA
- **Calculation**: Map Progress properties to AMI thresholds

#### AMI Required to Afford Homeownership

**Calculation**:
- Home values: `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_ALL_TS` (ZHVI)
- Mortgage assumptions: 20% down, 30% DTI, interest rate
- **Formula**: (Home Value × 0.20) / 0.30 = Required Annual Income

### Progress / Internal

#### Effective Rent Paid (Net of Concessions) vs Market Rent

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Columns**: 
  - `RENT_CURRENT` (effective rent paid)
  - `RENT_MARKET` (market rent)
- **Calculation**: `RENT_CURRENT / RENT_MARKET` = discount ratio

**Also Available**: `analysis/progress_rent_validation/sql/create_progress_rent_growth_view_enhanced.sql` for rent calculations

**Example Query**:
```sql
SELECT 
    ZIP_CODE,
    CBSA_CODE,
    AVG(RENT_CURRENT) as AVG_EFFECTIVE_RENT,
    AVG(RENT_MARKET) as AVG_MARKET_RENT,
    AVG(RENT_CURRENT) / NULLIF(AVG(RENT_MARKET), 0) as EFFECTIVE_TO_MARKET_RATIO,
    COUNT(*) as PROPERTY_COUNT
FROM TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES
WHERE RENT_CURRENT IS NOT NULL 
  AND RENT_MARKET IS NOT NULL
GROUP BY ZIP_CODE, CBSA_CODE;
```

#### Rent-to-Income (at Lease Start)

**Location**: Salesforce lease data + applicant income verification
- **Tables**: 
  - `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` (lease data)
  - `DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_ABSTRACT__C` (detailed lease info)
  - `DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_APPLICATION__C` (applicant income)

**Note**: Requires joining lease start date with applicant income at time of application

#### Renewal Rent Change vs Inflation

**Location**: `analysis/progress_rent_validation/sql/create_progress_rent_growth_view_enhanced.sql`
- **Metric**: `percent_eff_rent_growth` (calculated from lease history)
- **Calculation**: (Current Effective Rent - Prior Effective Rent) / Prior Effective Rent

**Inflation Comparison**: May need to join with CPI data from FRED or external source

---

## 2. Safe and Well-Maintained

### Safety

#### Work Order Response Time

**Aggregated Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Columns**: `TOTAL_WORK_ORDERS`, `WORK_ORDERS_LAST_30_DAYS`, etc.
- **Note**: Response time needs to be calculated from detailed work order data

**Detailed Work Orders**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE`
- **Filter**: `ISWORKORDER__C = 1`
- **Calculation**: Median of (RESOLVED_DATE - CREATED_DATE) for response time

**Example Query**:
```sql
SELECT 
    PROPERTY_ID,
    MEDIAN(DATEDIFF(HOUR, CREATEDDATE, CLOSEDDATE)) as MEDIAN_RESPONSE_TIME_HOURS,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY DATEDIFF(HOUR, CREATEDDATE, CLOSEDDATE)) as MEDIAN_RESPONSE_TIME,
    COUNT(*) as TOTAL_WORK_ORDERS
FROM DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE
WHERE ISWORKORDER__C = 1
  AND CLOSEDDATE IS NOT NULL
GROUP BY PROPERTY_ID;
```

#### % of Emergencies Solved Quickly

**Aggregated Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Column**: `EMERGENCY_WORK_ORDERS`

**Detailed Data**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE`
- **Filter**: Priority/emergency flags + `ISWORKORDER__C = 1`
- **Calculation**: Count of emergencies resolved within X hours / Total emergencies

### Inspections

#### Code Violations

**Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.VIOLATION__C`
- **Join**: May need to join with property data to get property-level violation counts
- **Aggregation**: Count violations by property, ZIP, or CBSA

### Repairs

#### Maintenance Spend by % of Household Income

**Maintenance Cost**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Columns**: `TOTAL_MAINTENANCE_COST`, `AVG_MAINTENANCE_COST`

**Property Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Join**: On `PROPERTY_ID` or `ID_SALESFORCE`

**Income Data**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS`
- **Filter**: `METRIC_ID = 'ACS_B19013_MEDIAN_HOUSEHOLD_INCOME'`

**Calculation**: (Maintenance Cost / Household Income) × 100

#### Preventative Maintenance

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Columns**: `ROUTINE_WORK_ORDERS` vs `EMERGENCY_WORK_ORDERS`
- **Ratio**: `ROUTINE_WORK_ORDERS / (ROUTINE_WORK_ORDERS + EMERGENCY_WORK_ORDERS)` = Preventative maintenance rate

#### New Appliances

**Status**: Not found in current schema
**Action Required**: May need Salesforce integration or Yardi data

### Progress Data

#### Work Order Response Time (Median + % Within SLA by Priority)

**Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE`
- **Calculation**: Group by priority level, calculate median response time and % within SLA threshold

#### Emergency Work Orders: % Resolved Within X Hours

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS` + `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE`
- **Filter**: Emergency priority work orders
- **Calculation**: Count resolved within X hours / Total emergency work orders

#### Inspection Outcomes: Pass Rate, Findings per Inspection, Repeat Findings Rate

**Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.VIOLATION__C` or inspection-specific tables
- **Pass Rate**: (Inspections with no violations / Total inspections) × 100
- **Findings per Inspection**: Average violation count per inspection
- **Repeat Findings**: Count of properties with same violation type multiple times

#### Turn/Make-Ready Time + Cost per Turn

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Columns**: `MOVE_IN_DATE`, `MOVE_OUT_DATE`, `LEASE_START_DATE`
- **Calculation**: `MOVE_IN_DATE - MOVE_OUT_DATE` = Turn time
- **Note**: May need Yardi integration for detailed turn cost data

#### Preventative Maintenance Completion Rate

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Column**: `ROUTINE_WORK_ORDERS`
- **Calculation**: (Completed routine work orders / Scheduled routine work orders) × 100
- **Note**: May need scheduled vs completed comparison from Salesforce

---

## 3. Family-Sized

### Unit Size by Square Feet

**Progress Properties**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Column**: `SQUARE_FEET`

**Market Comparison**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSEHOLD_HH_STRUCTURE_ALL_TS`
- **Source**: ACS data for market-level unit size distribution

**Example Query**:
```sql
SELECT 
    ZIP_CODE,
    AVG(SQUARE_FEET) as AVG_UNIT_SIZE_SQFT,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY SQUARE_FEET) as MEDIAN_UNIT_SIZE_SQFT,
    COUNT(*) as PROPERTY_COUNT
FROM TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES
WHERE SQUARE_FEET IS NOT NULL
GROUP BY ZIP_CODE;
```

### Number of Bedrooms

**Progress Properties**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Column**: `BEDROOMS`

**Market Comparison**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Columns**: 
  - `RENTER_2_BEDROOMS`
  - `RENTER_3_BEDROOMS`
  - `RENTER_4_BEDROOMS`
  - `RENTER_5PLUS_BEDROOMS`
- **Source**: ACS B25042 (bedrooms by tenure)

### HH with Kids

**Public Data**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSEHOLD_HH_STRUCTURE_ALL_TS` or `FACT_ACS_*` tables
- **Note**: May need to derive from household composition variables (family households with children)

**Internal Data**:
- **Location**: Salesforce application data (see "Progress Organize Ops" section)
- **Table**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` or `LEASE_ABSTRACT__C`
- **Column**: Dependents/children count (if collected)

### Pets

**Status**: Not found in current schema
**Internal Only**: May be in Salesforce lease data
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` or `LEASE_ABSTRACT__C`
- **Note**: This is tenant-level data, not available in public sources

### Multi-Gen Households

**Location**: ACS household structure data
- **Check**: `TRANSFORM_PROD.FACT.HOUSEHOLD_HH_STRUCTURE_ALL_TS`
- **Source**: ACS B11001 variables (household type)
- **Filter**: Multi-generational household indicators

---

## 4. Located Near Opportunity

### Distance to Work

**Job Accessibility**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_LODES_SUMMARY`
- **Columns**: 
  - `TOTAL_JOBS` (total jobs in tract)
  - `PCT_JOBS_IN_TRACT` (percentage of jobs in tract)
  - `JOB_ACCESSIBILITY_WEIGHT` (accessibility score)

**Commute Data**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Columns**: 
  - `COMMUTE_LESS_5MIN`
  - `COMMUTE_5_9MIN`
  - `COMMUTE_10_14MIN`
  - `COMMUTE_15_19MIN`
  - `COMMUTE_20_24MIN`
  - `COMMUTE_25_29MIN`
  - `PCT_COMMUTE_UNDER_30_MIN` (calculated)
- **Source**: ACS B08303 (commute time)

**Example Query**:
```sql
SELECT 
    ID_TRACT,
    CBSA_CODE,
    TOTAL_JOBS,
    PCT_JOBS_IN_TRACT,
    PCT_COMMUTE_UNDER_30_MIN
FROM ANALYTICS_PROD.MODELED.V_TRACT_LODES_SUMMARY l
JOIN ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT h
    ON l.ID_TRACT = h.ID_TRACT
WHERE l.DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM ANALYTICS_PROD.MODELED.V_TRACT_LODES_SUMMARY);
```

### Distance to School

**School Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.EDUCATION_PUBLIC_K12_SCHOOLS` and `EDUCATION_POSTSECONDARY_SCHOOLS`
- **Columns**: School coordinates (latitude/longitude)
- **Calculation**: Distance from property coordinates to nearest school
- **Note**: Requires geospatial distance calculation

### Distance to Services

**Status**: Not explicitly found
**Action Required**: May need to derive from POI data or geocoding services

### Opportunity by Health

**Status**: Not found in current schema
**Potential Sources**: CDC data may exist in `SOURCE_PROD` - need to check CDC schema

### Opportunity by Environment

**Location**: `FEMA_NATIONAL_RISK_INDEX` database
- **Table**: `FEMA_NATIONAL_RISK_INDEX.NRI_SCH.NRI_CENSUSTRACTS`
- **Columns**: Risk scores, hazard ratings (flood, wildfire, etc.)

### Opportunity by School

**Status**: School quality data not yet integrated
**Reference**: See `docs/SIGNAL_DATA_REQUIREMENTS.md` for school quality signal status
**Action Required**: May need GreatSchools API integration

### Opportunity by Crime

**Location**: `TRANSFORM_PROD.CLEANED.MARKERR_CRIME` (if exists)
**Alternative**: FBI UCR data
**Note**: Crime safety signal data exists but may need factization

---

## 5. Renters Cannot Afford Ownership Due To

### Costs Outpacing Incomes

#### Owning is a Burden on Many

**Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Source**: Owner burden calculations from ACS B25070
- **Note**: May need to derive owner cost burden from owner-occupied housing cost data

#### Ownership is Taken When Costs Rise Above Budget

**Source**: ACS tenure data + cost burden analysis
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Analysis**: Compare owner cost burden trends with tenure transitions

#### Stacked Bar Chart of Owner Costs by Cost Over Time (Change 2019-2025)

**Rent Trends**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`
- **Filter**: `METRIC_ID = 'ZILLOW_ZORI'` AND `TENANCY_CODE = 'RENT'`

**Home Values**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_ALL_TS`
- **Filter**: `METRIC_ID = 'ZILLOW_ZHVI'`

**Calculation**: 
- Mortgage payments: ZHVI × interest rate + amortization
- Taxes: From property tax data or Progress properties
- Insurance: From Progress properties or market averages
- Stack by cost component over time

#### DTI Requirements

**Location**: `ANALYTICS_PROD.FEATURES.V_HMDA_TRACT_SUMMARY`
- **Column**: `AVG_DTI` (average debt-to-income ratio)
- **Note**: Not explicitly stored as requirement, but average DTI shows market standards

#### Debt is Rising in the Form of Student Loans

**Status**: Not found
**Action Required**: May need external data source (Federal Student Aid data, credit bureau data)

### Higher Lending Standards

#### DTI Requirements

**Location**: `ANALYTICS_PROD.FEATURES.V_HMDA_TRACT_SUMMARY`
- **Column**: `AVG_DTI`

#### LTV Requirements

**Location**: `ANALYTICS_PROD.FEATURES.V_HMDA_TRACT_SUMMARY`
- **Column**: `AVG_LTV` (average loan-to-value ratio)

#### Credit Score Requirements

**Status**: Not explicitly found
**Action Required**: May be in HMDA data or require external credit score data

### Need for Savings

#### Downpayment (Income Required to Afford 20% Down)

**Calculation**:
- Home value: `TRANSFORM_PROD.FACT.HOUSING_HOU_ASSET_ALL_TS` (ZHVI)
- Downpayment: ZHVI × 0.20
- Required income: Downpayment / (savings rate assumption)

**Income Data**: ACS median income from `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS`

#### Escrow + Move-in

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Note**: May have move-in costs in lease data
- **Action Required**: May need Salesforce/Yardi integration for detailed move-in cost data

### Low Supply

#### Reduction in Single-Family as % of New Supply

**Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`
- **Filter**: `PRODUCT_TYPE_CODE = 'SFR'`
- **Metrics**: Permit counts, new construction starts
- **BPS Permits**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS` (BPS metrics)

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    GEO_ID,
    GEO_LEVEL_CODE,
    SUM(CASE WHEN PRODUCT_TYPE_CODE = 'SFR' THEN VALUE ELSE 0 END) as SFR_SUPPLY,
    SUM(CASE WHEN PRODUCT_TYPE_CODE IN ('SFR', 'MF', 'ALL') THEN VALUE ELSE 0 END) as TOTAL_SUPPLY,
    SUM(CASE WHEN PRODUCT_TYPE_CODE = 'SFR' THEN VALUE ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN PRODUCT_TYPE_CODE IN ('SFR', 'MF', 'ALL') THEN VALUE ELSE 0 END), 0) * 100 as SFR_PCT_OF_SUPPLY
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS
WHERE METRIC_ID LIKE '%PERMIT%' OR METRIC_ID LIKE '%CONSTRUCTION%'
GROUP BY DATE_REFERENCE, GEO_ID, GEO_LEVEL_CODE
ORDER BY DATE_REFERENCE DESC;
```

#### Reduction in Overall Supply

**Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`
- **Vendors**: REALTOR, REDFIN, ZILLOW, PARCLLABS
- **Metrics**: Inventory levels, active listings

#### % of New Single-Family Supply by Builders

**Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`
- **Source**: BPS permit data (may have builder info if available)
- **Alternative**: `TRANSFORM_PROD.FACT.FACT_MARKERR_CBSA_TS` or `FACT_MARKERR_ZIP_TS` (Markerr data)

#### % of New Stock Provided by Builders

**Same as above**

#### % of New Stock Bought by Progress

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Columns**: `PURCHASE_PRICE`, acquisition dates
- **Calculation**: Progress acquisitions / Total market supply
- **Compare to**: Market supply data from `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`

#### Reduction in Single-Family Rent Due to Stimulated Supply

**Rent Trends**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`
- **Filter**: `METRIC_ID = 'ZILLOW_ZORI'` AND `PRODUCT_TYPE_CODE = 'SFR'`

**Supply**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`
- **Filter**: `PRODUCT_TYPE_CODE = 'SFR'`

**Analysis**: Correlation between supply increases and rent changes

---

## 6. Why Progress Helps

### Provides Single-Family Option

#### Progress SFR Portfolio Size

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Filter**: `PROPERTY_TYPE = 'Single Family'`
- **Count**: Total properties by market

**Market Presence**:
- **Location**: `ANALYTICS_PROD.MARKETS.MARKET_PROGRAM_MEMBERSHIP`
- **Filter**: `PROGRAM = 'PROGRESS'`

### Maintains Housing Quality

**See "Safe and Well-Maintained" section above**

### Communicates to Tenants

**Status**: Not found in current schema
**Action Required**: May be in Salesforce (tenant communication logs, satisfaction surveys)

### Support New Supply in-Masse

#### Progress Acquisition Volume

**Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Columns**: `PURCHASE_PRICE`, acquisition dates
- **Aggregation**: Sum by time period, compare to market supply

**Compare to Market Supply**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`

---

## 7. Progress Organize Ops - Tenant Data

### Internal (Best for "Who Lives in Our Homes")

**Critical Note**: Tenant-level data (FICO, pets, kids, detailed income) is ONLY available in Salesforce application/screening data. Public data does not provide tenant-level precision.

#### Tenant Application + Screening Outputs

**Income**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` or lease application tables
- **Table**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_APPLICATION__C`
- **Column**: Applicant income (if collected)

**Credit Score Band / FICO**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_APPLICATION__C` or screening outputs
- **Note**: This is the ONLY clean path to tenant-level FICO at scale

**Debts**:
- **Location**: Application data or lease abstract
- **Table**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` or `LEASE_ABSTRACT__C`

**Household Size**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT`
- **Note**: Lease data may contain household info

**Dependents**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` or `LEASE_ABSTRACT__C`
- **Note**: If collected during application process

**Pets**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT` or `LEASE_ABSTRACT__C`
- **Note**: This is the ONLY clean path to tenant-level pets data at scale

**Example Query**:
```sql
-- Tenant profile analysis (requires Salesforce schema exploration)
SELECT 
    a.ID as ACCOUNT_ID,
    a.LEASE_FROM_DATE__PC as LEASE_START,
    la.INCOME__C as APPLICANT_INCOME,
    la.CREDIT_SCORE__C as FICO_SCORE,
    a.HOUSEHOLD_SIZE__C as HOUSEHOLD_SIZE,
    a.DEPENDENTS__C as DEPENDENTS,
    a.PETS__C as HAS_PETS
FROM DS_SOURCE_PROD_SFDC.SFDC_SHARE.ACCOUNT a
LEFT JOIN DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_APPLICATION__C la
    ON a.ID = la.ACCOUNT__C
WHERE a.LEASE_FROM_DATE__PC >= DATEADD(YEAR, -1, CURRENT_DATE());
```

### Public Data (Geographic Segmentation)

#### Identify Geos of Institutional Ownership → ZIP Codes for Analysis

**Institutional Ownership by ZIP**:
- **Location**: `TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_ZIP`
- **Alternative**: `TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_CBSA`

**Portfolio Size Segmentation**:
- **Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_SF_HOUSING_STOCK_OWNERSHIP`
- **Fact Table**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS`
- **Filter**: `METRIC_ID LIKE 'PARCLLABS_OWNERSHIP%'`

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    ID_ZIP,
    NAME_ZIP,
    NAME_CBSA,
    institutional_units,
    institutional_penetration_pct,
    pr_unit_count
FROM TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_ZIP
WHERE DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_ZIP)
  AND flag_institutional_present = 1
ORDER BY institutional_units DESC;
```

#### Segment Then Cluster Tenant Profile of ZIP Codes

**Income Stratification (Income of Renters vs. Owners)**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS`
- **Metrics**: 
  - `METRIC_ID = 'ACS_B19019_MEDIAN_OWNER_INCOME'`
  - `METRIC_ID = 'ACS_B19019_MEDIAN_RENTER_INCOME'`

**Income Brackets**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS`
- **Source**: B19001 income distribution variables (INCOME_LESS_10K through INCOME_200K_PLUS)

**Example Query**:
```sql
SELECT 
    GEO_ID as ID_ZIP,
    MAX(CASE WHEN METRIC_ID = 'ACS_B19019_MEDIAN_OWNER_INCOME' THEN VALUE END) as MEDIAN_OWNER_INCOME,
    MAX(CASE WHEN METRIC_ID = 'ACS_B19019_MEDIAN_RENTER_INCOME' THEN VALUE END) as MEDIAN_RENTER_INCOME,
    MAX(CASE WHEN METRIC_ID = 'ACS_B19001_INCOME_50_60K' THEN VALUE END) as INCOME_50_60K,
    MAX(CASE WHEN METRIC_ID = 'ACS_B19001_INCOME_75_100K' THEN VALUE END) as INCOME_75_100K
FROM TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS
WHERE METRIC_ID IN ('ACS_B19019_MEDIAN_OWNER_INCOME', 'ACS_B19019_MEDIAN_RENTER_INCOME', 
                     'ACS_B19001_INCOME_50_60K', 'ACS_B19001_INCOME_75_100K')
  AND DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS)
GROUP BY GEO_ID;
```

---

## 8. Debunk: Not Crowding Out Homeowners

### 1x1 in Financial Crisis (2012-2016, Dilapidation)

#### MLS Data for Financial Crisis Period

**Source Table**:
- **Location**: `DS_SOURCE_PROD_TPANALYTICS.TPANALYTICS.MLS_TAX_RECORDER_CLEANED`
- **Filter**: `DATE_REFERENCE BETWEEN '2012-01-01' AND '2016-12-31'`

**Cleaned View**:
- **Location**: `TRANSFORM_PROD.CLEANED.MLS_LISTINGS`
- **Filter**: `DATE_REFERENCE BETWEEN '2012-01-01' AND '2016-12-31'`

**Aggregated Views**:
- **Location**: `TRANSFORM_PROD.JOINED.PANEL_MLS_ABSORPTION_CBSA`
- **Location**: `TRANSFORM_PROD.JOINED.PANEL_MLS_PRICE_FUNDAMENTALS_CBSA`

**Note**: May need to filter for dilapidated properties (property condition scores)

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    ID_CBSA,
    COUNT(*) as TOTAL_LISTINGS,
    AVG(PRICE) as AVG_PRICE,
    MEDIAN(PRICE) as MEDIAN_PRICE,
    AVG(DOM) as AVG_DOM
FROM TRANSFORM_PROD.CLEANED.MLS_LISTINGS
WHERE DATE_REFERENCE BETWEEN '2012-01-01' AND '2016-12-31'
  AND PRODUCT_TYPE = 'SFR'
GROUP BY DATE_REFERENCE, ID_CBSA
ORDER BY DATE_REFERENCE, ID_CBSA;
```

### Portfolio Purchases (2018-2025)

#### Pronounced Institutional Presence

**Institutional Ownership**:
- **Location**: `TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_ZIP` or `INSTITUTIONAL_OWNERSHIP_CBSA`
- **Time Series**: `TRANSFORM_PROD.JOINED.PANEL_HOUSING_HOU_OWNERSHIP_TS`
- **Filter**: `DATE_REFERENCE BETWEEN '2018-01-01' AND '2025-12-31'`

**Portfolio Size Segmentation**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS`
- **Filter**: `METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS'`

**Reference**: `analysis/progress_rent_validation/docs/defense_narrative_summary.md` for institutional ownership analysis

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    ID_CBSA,
    NAME_CBSA,
    MAX(CASE WHEN METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS' THEN VALUE END) as INSTITUTIONAL_UNITS_1000PLUS,
    MAX(CASE WHEN METRIC_ID = 'PARCLLABS_HOUSING_STOCK_SF_UNITS' THEN VALUE END) as TOTAL_SF_STOCK,
    MAX(CASE WHEN METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS' THEN VALUE END) / 
        NULLIF(MAX(CASE WHEN METRIC_ID = 'PARCLLABS_HOUSING_STOCK_SF_UNITS' THEN VALUE END), 0) * 100 as INSTITUTIONAL_PENETRATION_PCT
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS
WHERE DATE_REFERENCE BETWEEN '2018-01-01' AND '2025-12-31'
  AND METRIC_ID IN ('PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS', 'PARCLLABS_HOUSING_STOCK_SF_UNITS')
GROUP BY DATE_REFERENCE, ID_CBSA, NAME_CBSA
ORDER BY DATE_REFERENCE DESC, INSTITUTIONAL_PENETRATION_PCT DESC;
```

### Definition of Institutional Ownership

#### Size (ParclLabs)

**100+ Units**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS`
- **Filter**: `METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS'`

**1000+ Units**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS`
- **Filter**: `METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS'`

**Source Table**: `TRANSFORM_PROD.CLEANED.PARCLLABS_SF_HOUSING_STOCK_OWNERSHIP`

**Reference**: `analysis/progress_rent_validation/docs/defense_narrative_summary.md` for institutional ownership analysis
- Shows 0.14% institutional ownership nationally (1000+ portfolios)
- 98.19% non-portfolio ownership

---

## 9. Value 1: Affording SF Rentership

### Prefer Rentership

#### Who Are Working People and Where Do They Work

**Job Accessibility**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_LODES_SUMMARY`
- **Columns**: `TOTAL_JOBS`, `PCT_JOBS_IN_TRACT`, `JOB_ACCESSIBILITY_WEIGHT`

**Employment by Industry**:
- **Location**: `TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA`
- **Note**: 87M rows - employment by industry/NAICS code
- **Filter**: By NAICS code for specific industries

**Occupation Data**:
- **Location**: `SOURCE_PROD.ONET.*` tables
- **Tables**: 
  - `SOURCE_PROD.ONET.OCCUPATION_BASE` (occupation metadata)
  - `SOURCE_PROD.ONET.WORK_ACTIVITIES_GENERAL` (work activities)
  - `SOURCE_PROD.ONET.EDUCATION_TRAINING` (education requirements)

**BLS Employment**:
- **Location**: `ANALYTICS_PROD.FEATURES.BLS_CPS_MSA_FEATURES`
- **Columns**: `EMPLOYED_COUNT`, `CPS_AVG_WEEKLY_WAGE`, `LABOR_FORCE_COUNT`

**Example Query**:
```sql
SELECT 
    CBSA_CODE,
    NAICS_CODE,
    SUM(EMPLOYMENT) as TOTAL_EMPLOYMENT,
    AVG(WAGE) as AVG_WAGE
FROM TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA
WHERE DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA)
GROUP BY CBSA_CODE, NAICS_CODE
ORDER BY CBSA_CODE, TOTAL_EMPLOYMENT DESC;
```

#### Otherwise Unable to Afford Housing Type

**Source**: Rent burden + income analysis (see "Affordable" section above)
**Calculation**: Cost gap analysis - Rent vs Own calculations

### Typical Renter Profile

#### Structure: Impact on Household Formation and Lifestyle Choices

**Preference for Single-Family**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Column**: `RENTER_1_UNIT` (renters in 1-unit structures)
- **Source**: ACS B25032

**Overcrowding**:
- **Calculation**: May need to derive from ACS household size vs unit size
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Source**: ACS household size and unit size variables

#### Attributes: Pets, Kids, FICOs

**Pets**:
- **Status**: Internal only
- **Location**: Salesforce lease data (see "Progress Organize Ops" section)
- **Note**: Public data does not provide tenant-level pets data

**Kids**:
- **Internal**: Salesforce application data (see "Progress Organize Ops" section)
- **Public**: ACS household composition
- **Location**: `TRANSFORM_PROD.FACT.HOUSEHOLD_HH_STRUCTURE_ALL_TS` or `FACT_ACS_*` tables

**FICOs**:
- **Status**: Internal only
- **Location**: Salesforce screening outputs (see "Progress Organize Ops" section)
- **Note**: Public data does not provide tenant-level FICO scores

#### Occupation

**Employment by Industry/Occupation**:
- **Location**: `TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA`
- **Filter**: By NAICS code for occupation categories

**O*NET Occupation Details**:
- **Location**: `SOURCE_PROD.ONET.*` tables
- **Use**: Join with tenant application data for Progress-specific tenant occupations

**Note**: May need to join with tenant application data for Progress-specific tenant occupations

#### Budget

**Income**:
- **See "Affordable" section**: ACS + internal application data
- **Internal**: Salesforce application data
- **Public**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` (median renter income)

**Credit Score**:
- **Status**: Internal only
- **Location**: Salesforce screening (see "Progress Organize Ops" section)

#### Family Formation

**Household Structure**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSEHOLD_HH_STRUCTURE_ALL_TS`
- **Source**: ACS household structure data

**Household Composition**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Columns**: Family vs non-family households
- **Source**: ACS B11001

#### Education Level

**Public Data**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` or `FACT_ACS_CBSA_TS`
- **Source**: ACS B15003 variables (education distribution)
- **Metrics**: Education attainment levels (high school, bachelor's, etc.)

**Internal Data**:
- **Status**: May be in Salesforce application data
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.LEASE_APPLICATION__C`

---

## 10. Value 2: Increase of Housing Supply

### Institutions Not Capable of Mass Provision

#### Institutional Capacity Analysis

**Institutional Ownership**:
- **Location**: `TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_ZIP` or `INSTITUTIONAL_OWNERSHIP_CBSA`

**Portfolio Size Distribution**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS`
- **Metrics**: All portfolio size segments
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_2_9_UNITS`
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_10_99_UNITS`
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS`
  - `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS`

**Market Share**:
- **Calculation**: Compare institutional units to total housing stock
- **Total Stock**: `TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS` (METRIC_ID = 'PARCLLABS_HOUSING_STOCK_SF_UNITS')

**Reference**: `analysis/progress_rent_validation/docs/defense_narrative_summary.md`
- Shows 0.14% institutional ownership nationally (1000+ portfolios)
- 71.05% of portfolio ownership is small portfolios (2-9 units)
- 98.19% of housing stock is non-portfolio

**Example Query**:
```sql
SELECT 
    DATE_REFERENCE,
    ID_CBSA,
    MAX(CASE WHEN METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS' THEN VALUE END) as INSTITUTIONAL_UNITS,
    MAX(CASE WHEN METRIC_ID = 'PARCLLABS_HOUSING_STOCK_SF_UNITS' THEN VALUE END) as TOTAL_SF_STOCK,
    MAX(CASE WHEN METRIC_ID = 'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS' THEN VALUE END) / 
        NULLIF(MAX(CASE WHEN METRIC_ID = 'PARCLLABS_HOUSING_STOCK_SF_UNITS' THEN VALUE END), 0) * 100 as INSTITUTIONAL_MARKET_SHARE_PCT
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS
WHERE DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS)
  AND METRIC_ID IN ('PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS', 'PARCLLABS_HOUSING_STOCK_SF_UNITS')
GROUP BY DATE_REFERENCE, ID_CBSA
ORDER BY INSTITUTIONAL_MARKET_SHARE_PCT DESC;
```

### Alternative Loan Products and Workouts

#### Deephaven / Selene Loan Products

**Status**: Not explicitly found in current schema
**Potential Location**: `SOURCE_ENTITY.ANCHOR_LOANS.*` tables (if Deephaven/Selene are loan originators)
**Action Required**: May need external integration or new data source

---

## 11. Impact of Dissolution

### Renters Who Cannot Afford Housing Type

#### Affordability Analysis Post-Dissolution

**Rent Burden + Income Data**:
- **See "Affordable" section** for rent burden metrics
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT` (rent burden brackets)

**Market Rent vs Tenant Income**:
- **Progress Properties**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
  - `RENT_CURRENT` (current rent)
  - `RENT_MARKET` (market rent)
- **Tenant Income**: Salesforce application data (internal only)

**ACS Affordability Metrics**:
- **Location**: `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT`
- **Columns**: Rent burden brackets (30-34.9%, 35-39.9%, 40-49.9%, 50%+)

### Value of Supply / Market Liquidity

#### Supply Metrics

**Inventory Levels**:
- **Location**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS`
- **Metrics**: Active listings, inventory counts

**Absorption Rates**:
- **Location**: `TRANSFORM_PROD.JOINED.PANEL_MLS_ABSORPTION_CBSA`
- **Columns**: `ABSORPTION_RATE`, `NEW_LISTINGS`, `ABSORBED_LISTINGS`

**Parcl Labs Events**:
- **Location**: `TRANSFORM_PROD.CLEANED.PARCLLABS_HOUSING_EVENT_COUNTS`
- **Metrics**: Sales, listings, transfers

#### Market Liquidity

**Absorption and DOM**:
- **Location**: `TRANSFORM_PROD.JOINED.PANEL_MLS_ABSORPTION_CBSA`
- **Columns**: `ABSORPTION_RATE`, `AVG_DOM`

**Transaction Volume**:
- **MLS Data**: `TRANSFORM_PROD.CLEANED.MLS_LISTINGS`
- **Redfin Data**: `TRANSFORM_PROD.FACT.HOUSING_HOU_DEMAND_ALL_TS`
- **Metrics**: Sales counts, transaction volume

**Months of Supply**:
- **Realtor.com**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS` (METRIC_ID like 'REALTOR%')
- **Redfin**: `TRANSFORM_PROD.FACT.HOUSING_HOU_INVENTORY_ALL_TS` (METRIC_ID like 'REDFIN%')

---

## 12. Place-Based Opportunity

### Future Income

#### Income Growth Forecasts

**Economic Forecasts**:
- **Location**: `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED`
- **Note**: Oxford Economics / Cybersyn forecasts

**MARKERR Forecasts**:
- **Location**: `TRANSFORM_PROD.FACT.FACT_MARKERR_CBSA_TS` or `FACT_MARKERR_ZIP_TS`
- **Status**: If available

**Historical Income Trends**:
- **Location**: ACS time series data
- **Source**: `TRANSFORM_PROD.FACT.FACT_ACS_ZIP_TS` or `FACT_ACS_CBSA_TS`
- **Metrics**: Median household income over time

### Health Outcomes

**Status**: Not explicitly found in current schema
**Potential Sources**: CDC data may exist in `SOURCE_PROD` - need to check CDC schema
**Environmental Health**: `FEMA_NATIONAL_RISK_INDEX` database (climate/hazard risk)

### Professions: Muni Gov, Healthcare, Education

#### Municipal Government Employment

**QCEW Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA`
- **Filter**: NAICS codes for government (92 - Public Administration)

**BLS Government Employment**:
- **Location**: `ANALYTICS_PROD.FEATURES.BLS_CPS_MSA_FEATURES`
- **Columns**: Government employment counts

#### Healthcare Employment

**QCEW Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA`
- **Filter**: NAICS 62 - Health Care and Social Assistance

**O*NET Healthcare Occupations**:
- **Location**: `SOURCE_PROD.ONET.*` tables
- **Filter**: Healthcare-related SOC codes

#### Education Employment

**QCEW Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA`
- **Filter**: NAICS 61 - Educational Services

**School Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.EDUCATION_PUBLIC_K12_SCHOOLS` and `EDUCATION_POSTSECONDARY_SCHOOLS`
- **Note**: School locations and characteristics

**IPEDS Data**:
- **Location**: `SOURCE_PROD.IPEDS.*` tables
- **Note**: Postsecondary education data

**Example Query**:
```sql
SELECT 
    CBSA_CODE,
    NAICS_CODE,
    SUM(EMPLOYMENT) as TOTAL_EMPLOYMENT,
    AVG(WAGE) as AVG_WAGE
FROM TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA
WHERE DATE_REFERENCE = (SELECT MAX(DATE_REFERENCE) FROM TRANSFORM_PROD.CLEANED.QCEW_NAICS_CBSA)
  AND NAICS_CODE IN ('61', '62', '92')  -- Education, Healthcare, Government
GROUP BY CBSA_CODE, NAICS_CODE
ORDER BY CBSA_CODE, NAICS_CODE;
```

---

## 13. Value of Scale / Serving the Role of Government

### Disaster Relief

**Status**: Not explicitly found in current schema
**Climate/Hazard Data**: `FEMA_NATIONAL_RISK_INDEX` database (risk scores, hazard ratings)
**Action Required**: May need Progress-specific disaster response data from Salesforce or operational systems

### Liquidity = Maintenance/Repairs

#### Maintenance Capacity at Scale

**Maintenance Metrics**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Columns**: `TOTAL_WORK_ORDERS`, `TOTAL_MAINTENANCE_COST`, `AVG_MAINTENANCE_COST`

**Work Order Volume**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE`
- **Filter**: `ISWORKORDER__C = 1`

**Maintenance Spend**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Column**: `TOTAL_MAINTENANCE_COST`

**Portfolio Scale**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES`
- **Aggregation**: Property count by market

**Example Query**:
```sql
SELECT 
    p.CBSA_CODE,
    COUNT(DISTINCT p.ID_SALESFORCE) as PROPERTY_COUNT,
    SUM(m.TOTAL_MAINTENANCE_COST) as TOTAL_MAINTENANCE_SPEND,
    AVG(m.TOTAL_MAINTENANCE_COST) as AVG_MAINTENANCE_COST_PER_PROPERTY,
    SUM(m.TOTAL_WORK_ORDERS) as TOTAL_WORK_ORDERS,
    AVG(m.TOTAL_WORK_ORDERS) as AVG_WORK_ORDERS_PER_PROPERTY
FROM TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES p
LEFT JOIN TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS m
    ON p.ID_SALESFORCE = m.ID_SALESFORCE
WHERE m.DATE_REFERENCE >= DATEADD(MONTH, -12, CURRENT_DATE())
GROUP BY p.CBSA_CODE
ORDER BY PROPERTY_COUNT DESC;
```

#### Repair Response Time

**Detailed Work Orders**:
- **Location**: `DS_SOURCE_PROD_SFDC.SFDC_SHARE.CASE`
- **Calculation**: Work order timestamps for response time calculation
- **Formula**: `CLOSEDDATE - CREATEDDATE` = Response time

**Aggregated Data**:
- **Location**: `TRANSFORM_PROD.CLEANED.PROGRESS_MAINTENANCE_EVENTS`
- **Columns**: `WORK_ORDERS_LAST_30_DAYS`, etc.

---

## Data Gaps and Integration Requirements

### Missing Data Sources

1. **Tenant-Level Attributes (Internal Only)**:
   - FICO scores: Only in Salesforce screening data
   - Pets: Only in Salesforce lease data
   - Detailed household composition: Only in Salesforce application data

2. **Disaster Relief Metrics**:
   - Progress-specific disaster response data
   - May need Salesforce or operational system integration

3. **Alternative Loan Products**:
   - Deephaven/Selene loan data
   - May need external integration

4. **Health Outcomes**:
   - CDC health data may exist but needs verification
   - Check `SOURCE_PROD.CDC` schema

5. **School Quality**:
   - Not yet integrated
   - May need GreatSchools API integration

6. **Student Loan Debt**:
   - Not found in current schema
   - May need Federal Student Aid data or credit bureau data

7. **New Appliances**:
   - Not found in current schema
   - May need Salesforce or Yardi integration

8. **Tenant Communication Metrics**:
   - Not found in current schema
   - May be in Salesforce (communication logs, satisfaction surveys)

### Integration Priorities

1. **High Priority**: Verify Salesforce schema structure for tenant-level data (FICO, pets, kids, income)
2. **Medium Priority**: Integrate school quality data (GreatSchools API)
3. **Medium Priority**: Verify CDC health data availability
4. **Low Priority**: Alternative loan product data integration
5. **Low Priority**: Student loan debt data integration

---

## Key Implementation Notes

1. **Fact Table Priority**: Many metrics exist in CLEANED schema but need to be promoted to FACT tables per the memory requirement: "Rental metrics must be sourced from vendor-tied sources and used via fact datasets"

2. **Progress Internal Data**: Most Progress-specific metrics are in `TRANSFORM_PROD.CLEANED.PROGRESS_PROPERTIES` and `PROGRESS_MAINTENANCE_EVENTS`, but may need Salesforce/Yardi integration for detailed operational metrics

3. **Tenant-Level Data**: FICO scores, pets, and detailed tenant attributes are ONLY available in Salesforce application/screening data - public data does not provide tenant-level precision. This is critical for "who lives in our homes" analysis.

4. **Institutional Ownership**: Well-covered in `TRANSFORM_PROD.FACT.INSTITUTIONAL_OWNERSHIP_ZIP` and `HOUSING_HOU_OWNERSHIP_ALL_TS` with Parcl Labs data. Portfolio size segmentation (100+, 1000+) is available.

5. **MLS Historical Data**: Available in `DS_SOURCE_PROD_TPANALYTICS.TPANALYTICS.MLS_TAX_RECORDER_CLEANED` for financial crisis period (2012-2016) analysis.

6. **Geographic Segmentation**: Use institutional ownership ZIP codes to segment and cluster tenant profiles - combine internal tenant data (FICO, pets, kids) with public ZIP-level demographics

7. **Calculated Metrics**: Many metrics (cost gaps, burden calculations, DTI, institutional market share) require calculations from multiple sources rather than direct table lookups

---

## References

- **Institutional Ownership Analysis**: `analysis/progress_rent_validation/docs/defense_narrative_summary.md`
- **Signal Framework**: `docs/SIGNAL_DATA_REQUIREMENTS.md`
- **Income Bin Definitions**: `sql/analytics/governance/01_create_income_bin_dimension.sql`
- **Rent Growth Calculations**: `analysis/progress_rent_validation/sql/create_progress_rent_growth_view_enhanced.sql`

---

**Last Updated**: 2026-01-27  
**Document Status**: Complete mapping for all presentation sections

