# ACS Canonical Segmentation Integration Plan

**Date**: 2026-01-27  
**Purpose**: Integrate missing ACS tables for canonical segmentation  
**Status**: Ready for execution

---

## S3 Availability Status (from user listing)

### ✅ Available in S3
- **B19001/** - Income distribution ✅
- **B19013/** - Median household income ✅
- **B25034/** - Year structure built ✅
- **B25009/** - Tenure by household size ✅
- **B25010/** - Average household size by tenure ✅ (already in view)
- **DP02/** - Household size and composition summaries ✅
- **B07401/** - Mobility (moved in last year) ✅

### ❌ Missing from S3
- **B08303/** - Commute time to work ❌ (needs download)
- **B11016/** - Household size by household type ❌ (optional, Tier-2)

---

## Integration Steps

### Step 1: Load Missing Tables from S3

**File**: `sql/pipelines/2_1_r_raw/acs_load_missing_tables_tract.sql`

**Tables to Load**:
1. ✅ B19013 (Median Income) - Available in S3
2. ✅ B19001 (Income Distribution) - Available in S3
3. ✅ B25034 (Year Built) - Available in S3
4. ❌ B08303 (Commute Time) - **NEEDS DOWNLOAD**
5. ✅ B25009 (Household Size by Tenure) - Available in S3

**Execution**:
```bash
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM \
  --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/pipelines/2_1_r_raw/acs_load_missing_tables_tract.sql
```

---

### Step 2: Download Missing Table (B08303)

**Action Required**: Download B08303 (Commute Time) from Census API

**Script**: Create `scripts/download_acs_commute_time.py` (similar to `download_acs_age_education.py`)

**Census API Endpoint**:
```
https://api.census.gov/data/2023/acs/acs5?get=NAME,B08303_001E,B08303_002E,...,B08303_013E&for=tract:*&in=state:*
```

**S3 Upload**: Upload to `s3://pret-ai-general/sources/DEMOGRAPHY/CENSUS/ACS/B08303/tract/`

---

### Step 3: Enhance V_TRACT_HOUSING_COHORT

**File**: `sql/analytics/modeled/enhance_tract_housing_cohort_canonical_segmentation.sql`

**New Columns Added**:

#### Income Metrics (B19013, B19001)
- `MEDIAN_HOUSEHOLD_INCOME` - Median household income
- `INCOME_TOTAL` - Total households
- `INCOME_LESS_10K` through `INCOME_200K_PLUS` - Income distribution bins
- **Calculated**: `INCOME_DISTRIBUTION_P25`, `P50`, `P75` (from bins)

#### Year Built Metrics (B25034)
- `YEAR_BUILT_TOTAL` - Total housing units
- `YEAR_BUILT_2014_PLUS` - New housing (built 2014+)
- `YEAR_BUILT_2000_2009` - Recent housing
- `YEAR_BUILT_1990_1999` through `YEAR_BUILT_1939_OR_EARLIER` - Vintage bins
- **Calculated**: `NEW_HOUSING_SHARE_PCT`, `VINTAGE_HOUSING_SHARE_PCT`

#### Commute Time Metrics (B08303)
- `COMMUTE_TOTAL` - Total workers
- `COMMUTE_LESS_5MIN` through `COMMUTE_90PLUS_MIN` - Commute time bins
- **Calculated**: `COMMUTE_LESS_30MIN_SHARE_PCT`, `COMMUTE_30_60MIN_SHARE_PCT`, `COMMUTE_60PLUS_MIN_SHARE_PCT`

#### Household Size Distribution (B25009)
- `HH_SIZE_TOTAL` - Total households
- `OWNER_HH_SIZE_1` through `OWNER_HH_SIZE_7PLUS` - Owner household size distribution
- `RENTER_HH_SIZE_1` through `RENTER_HH_SIZE_7PLUS` - Renter household size distribution
- **Note**: `AVG_HOUSEHOLD_SIZE_OWNER` and `AVG_HOUSEHOLD_SIZE_RENTER` already exist (B25010)

**Execution**:
```bash
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM \
  --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/analytics/modeled/enhance_tract_housing_cohort_canonical_segmentation.sql
```

---

### Step 4: Update Canonical Segmentation View

**File**: `sql/analytics/modeled/create_canonical_market_segmentation_v2.sql`

**Updates Needed**:
1. Replace placeholders with actual columns from enhanced `V_TRACT_HOUSING_COHORT`
2. Add calculated metrics (percentiles, shares)
3. Add household size distribution metrics

**Key Updates**:

#### Income Distribution
```sql
-- Replace NULL placeholders with actual calculations
MEDIAN_HOUSEHOLD_INCOME = hc.MEDIAN_HOUSEHOLD_INCOME,
INCOME_DISTRIBUTION_P25 = <calculate from bins>,
INCOME_DISTRIBUTION_P50 = hc.MEDIAN_HOUSEHOLD_INCOME,
INCOME_DISTRIBUTION_P75 = <calculate from bins>,
```

#### Year Built
```sql
-- Replace NULL placeholders
NEW_HOUSING_SHARE_PCT = (hc.YEAR_BUILT_2014_PLUS / NULLIF(hc.YEAR_BUILT_TOTAL, 0)) * 100.0,
VINTAGE_HOUSING_SHARE_PCT = ((hc.YEAR_BUILT_1939_OR_EARLIER + hc.YEAR_BUILT_1940_1949 + hc.YEAR_BUILT_1950_1959) / NULLIF(hc.YEAR_BUILT_TOTAL, 0)) * 100.0,
```

#### Commute Time
```sql
-- Replace NULL placeholders
COMMUTE_LESS_30MIN_SHARE_PCT = (
    (hc.COMMUTE_LESS_5MIN + hc.COMMUTE_5_9MIN + hc.COMMUTE_10_14MIN + 
     hc.COMMUTE_15_19MIN + hc.COMMUTE_20_24MIN + hc.COMMUTE_25_29MIN) / 
    NULLIF(hc.COMMUTE_TOTAL, 0)
) * 100.0,
COMMUTE_30_60MIN_SHARE_PCT = (
    (hc.COMMUTE_30_34MIN + hc.COMMUTE_35_39MIN + hc.COMMUTE_40_44MIN + 
     hc.COMMUTE_45_59MIN) / 
    NULLIF(hc.COMMUTE_TOTAL, 0)
) * 100.0,
COMMUTE_60PLUS_MIN_SHARE_PCT = (
    (hc.COMMUTE_60_89MIN + hc.COMMUTE_90PLUS_MIN) / 
    NULLIF(hc.COMMUTE_TOTAL, 0)
) * 100.0,
```

#### Household Size Distribution
```sql
-- Add new columns
HH_SIZE_AVG_RENTER = hc.AVG_HOUSEHOLD_SIZE_RENTER,
HH_SIZE_AVG_OWNER = hc.AVG_HOUSEHOLD_SIZE_OWNER,
HH_SIZE_DISTRIBUTION_RENTER_1 = (hc.RENTER_HH_SIZE_1 / NULLIF(hc.RENTER_OCCUPIED, 0)) * 100.0,
HH_SIZE_DISTRIBUTION_RENTER_2 = (hc.RENTER_HH_SIZE_2 / NULLIF(hc.RENTER_OCCUPIED, 0)) * 100.0,
HH_SIZE_DISTRIBUTION_RENTER_3 = (hc.RENTER_HH_SIZE_3 / NULLIF(hc.RENTER_OCCUPIED, 0)) * 100.0,
HH_SIZE_DISTRIBUTION_RENTER_4 = (hc.RENTER_HH_SIZE_4 / NULLIF(hc.RENTER_OCCUPIED, 0)) * 100.0,
HH_SIZE_DISTRIBUTION_RENTER_5PLUS = ((hc.RENTER_HH_SIZE_5 + hc.RENTER_HH_SIZE_6 + hc.RENTER_HH_SIZE_7PLUS) / NULLIF(hc.RENTER_OCCUPIED, 0)) * 100.0,
-- Similar for OWNER
```

---

## Household Size: Composition Modifier (Not Separate Mass)

### How Household Size Fits in DemandMass

**Role**: Composition modifier, not separate mass count

**Where it fits**:
1. **TenancyComposition**: Refines renter vs owner demand by household size
   - Larger renter HH → different unit mix (2-4BR demand)
   - Larger owner HH → SFR suitability, bedroom mix, rehab scope

2. **StructureAvailability**: Unit type plausibility
   - 1-person HH → studio/1BR viable
   - 4+ person HH → 3+BR required

3. **BudgetEligibility**: Income per capita vs per household
   - Same household income, larger HH → lower per-capita income
   - Affects affordability calculations

### Metrics in Segmentation Layer

**Core Metrics** (from B25009 + B25010):
- `HH_SIZE_AVG_RENTER` - Average renter household size
- `HH_SIZE_AVG_OWNER` - Average owner household size
- `HH_SIZE_DISTRIBUTION_RENTER_[1,2,3,4,5+]` - Renter household size distribution (%)
- `HH_SIZE_DISTRIBUTION_OWNER_[1,2,3,4,5+]` - Owner household size distribution (%)

**Why It Matters by Offering**:
- **REQ/REM**: Larger renter HH sizes → different unit mix, schools/amenities sensitivity, turnover dynamics
- **RED/RES**: Owner HH size → acquisition strategy (SFR suitability, bedroom mix, rehab scope), PITI stress (more dependents reduce discretionary buffer)

---

## Validation Queries

### Check Data Loaded
```sql
SELECT 
    TABLE_CODE,
    COUNT(DISTINCT ID_TRACT) AS TRACT_COUNT,
    COUNT(*) AS RECORD_COUNT
FROM SOURCE_PROD.ACS.ACS_TRACT_LONG
WHERE TABLE_CODE IN ('B19013', 'B19001', 'B25034', 'B08303', 'B25009')
  AND YEAR = 2023
GROUP BY TABLE_CODE
ORDER BY TABLE_CODE;
```

### Check View Enhancement
```sql
SELECT 
    COUNT(*) AS TOTAL_TRACTS,
    COUNT(MEDIAN_HOUSEHOLD_INCOME) AS TRACTS_WITH_INCOME,
    COUNT(YEAR_BUILT_2014_PLUS) AS TRACTS_WITH_YEAR_BUILT,
    COUNT(COMMUTE_LESS_30MIN) AS TRACTS_WITH_COMMUTE,
    COUNT(RENTER_HH_SIZE_1) AS TRACTS_WITH_HH_SIZE
FROM ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT
WHERE DATE_REFERENCE = 2023;
```

---

## Execution Checklist

- [ ] **Step 1**: Download B08303 (Commute Time) from Census API
- [ ] **Step 2**: Upload B08303 to S3
- [ ] **Step 3**: Load all tables from S3 into Snowflake (`acs_load_missing_tables_tract.sql`)
- [ ] **Step 4**: Enhance V_TRACT_HOUSING_COHORT (`enhance_tract_housing_cohort_canonical_segmentation.sql`)
- [ ] **Step 5**: Update canonical segmentation view with actual columns
- [ ] **Step 6**: Validate data coverage and quality
- [ ] **Step 7**: Test canonical segmentation queries

---

## Status

✅ **Integration Plan Created**  
✅ **S3 Availability Documented**  
✅ **Enhancement SQL Created**  
⚠️ **B08303 Download Required** - Commute time table needs to be downloaded  
✅ **Household Size Framework Documented** - Composition modifier approach

---

## Next Steps

1. **Download B08303**: Create download script and upload to S3
2. **Execute Load Script**: Run `acs_load_missing_tables_tract.sql`
3. **Enhance View**: Run `enhance_tract_housing_cohort_canonical_segmentation.sql`
4. **Update Canonical View**: Replace placeholders with actual columns
5. **Validate**: Run validation queries to ensure data quality

