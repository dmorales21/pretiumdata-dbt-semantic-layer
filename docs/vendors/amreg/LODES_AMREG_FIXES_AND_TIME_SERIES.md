# LODES/AMREG Fixes and Time Series Analysis

**Date**: 2026-01-27  
**Purpose**: Fix LODES and AMREG feature engineering with crosswalks, create time series chart and CSV exports

---

## ✅ Fixes Completed

### 1. LODES Feature Engineering - ✅ FIXED

**Issue**: LODES view `V_TRACT_LODES_SUMMARY` did not have `CBSA_CODE` column directly.

**Solution**: Join with `V_TRACT_HOUSING_COHORT` to get CBSA geography.

**File**: `sql/analytics/modeled/engineer_lodes_features.sql`

**Key Changes**:
- Added LEFT JOIN to `ANALYTICS_PROD.MODELED.V_TRACT_HOUSING_COHORT` on `ID_TRACT`
- Added `CBSA_CODE`, `CBSA_NAME`, `STATE_FIPS`, `COUNTY_FIPS` to output
- Created accessibility flags (high/low job accessibility) using percentile rankings within CBSA

**Status**: ✅ **READY**

---

### 2. AMREG Feature Engineering - ✅ FIXED

**Issue**: AMREG needed Oxford crosswalk to map `LOCATION_CODE` to CBSA.

**Solution**: Join with `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK` using `LOCATION_CODE_OXFORD`.

**File**: `sql/analytics/modeled/engineer_amreg_features.sql`

**Key Changes**:
- Added LEFT JOIN to `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK` on `LOCATION_CODE = LOCATION_CODE_OXFORD`
- Use `COALESCE(ox.ID_CBSA, a.ID_CBSA)` to prefer crosswalk CBSA, fallback to existing ID_CBSA
- Added household growth calculations (YoY, 5-year)
- Added forecast horizon classification (HISTORICAL, FORECAST_1YR, FORECAST_5YR, FORECAST_LONG_TERM)

**Status**: ✅ **READY**

---

## 📊 Time Series Analysis

### 1. ACS National Summary CSV

**Purpose**: Create national-level summary of ACS data for time series analysis.

**File**: `sql/analytics/modeled/create_acs_national_summary_csv.sql`

**Output Columns**:
- **Household Counts**: `total_households`, `owner_occupied_households`, `renter_occupied_households`
- **Tenure Splits**: `owner_share_pct`, `renter_share_pct`
- **Bedroom Splits**: Counts and percentages for 0, 1, 2, 3, 4, 5+ bedrooms (total, owner, renter)
- **Income Splits**: 16 income bins (counts and shares), median income
- **Household Structure**: Structure type counts and shares (1-unit, 2-units, 3-4 units, etc.)
- **Household Size**: Average household size (total, owner, renter)
- **Population**: Total, owner, renter population

**Time Period**: 2000-2023 (all available ACS years)

**View**: `ANALYTICS_PROD.MODELED.V_ACS_NATIONAL_SUMMARY`

**Export**: Run final SELECT query and export to CSV

---

### 2. AMREG National Forecasts CSV

**Purpose**: Create national-level AMREG forecasts with uncertainty ranges for cone of expectations.

**File**: `sql/analytics/modeled/create_amreg_national_forecasts_csv.sql`

**Output Columns**:
- `year`: Forecast year
- `population_forecast`: Central forecast (millions)
- `population_upper`: Upper bound (80% CI)
- `population_lower`: Lower bound (80% CI)
- `household_forecast`: Household count forecast
- `household_upper`: Household upper bound
- `household_lower`: Household lower bound
- `uncertainty_pct`: Uncertainty percentage (scales with forecast horizon)
- `years_ahead`: Years from current date

**Uncertainty Scaling**:
- 0 years: 2% uncertainty
- 1-5 years: 2-7% uncertainty
- 6-10 years: 7-12% uncertainty
- 11-30 years: 12-20% uncertainty

**Time Period**: 2020-2050

**View**: `ANALYTICS_PROD.MODELED.V_AMREG_NATIONAL_FORECASTS`

**Export**: Run final SELECT query and export to CSV

---

### 3. Population Time Series Chart

**Purpose**: Create Strata-style Python chart of population 2000-2050 with cone of expectations.

**File**: `scripts/create_population_time_series_chart.py`

**Features**:
- Historical data (ACS): 2000-2023, blue line with markers
- Forecast data (AMREG): 2024-2050, purple dashed line
- Cone of expectations: Shaded area showing 80% confidence interval
- Vertical separator: Line at 2023 showing historical → forecast transition
- Annotations: Key milestones (2023 actual, 2050 forecast)
- Strata styling: White grid, professional colors, proper formatting

**Output**: `output/time_series/population_time_series_2000_2050.png` (300 DPI)

**Usage**:
```bash
# 1. Export ACS data to CSV
# Run: sql/analytics/modeled/create_acs_national_summary_csv.sql
# Export to: output/time_series/acs_national_summary.csv

# 2. Export AMREG forecasts to CSV
# Run: sql/analytics/modeled/create_amreg_national_forecasts_csv.sql
# Export to: output/time_series/amreg_national_forecasts.csv

# 3. Run Python script
python scripts/create_population_time_series_chart.py
```

---

## 📁 Files Created/Updated

### SQL Files
1. ✅ `sql/analytics/modeled/engineer_lodes_features.sql` - Fixed with CBSA join
2. ✅ `sql/analytics/modeled/engineer_amreg_features.sql` - Fixed with Oxford crosswalk
3. ✅ `sql/analytics/modeled/create_acs_national_summary_csv.sql` - New: ACS national summary
4. ✅ `sql/analytics/modeled/create_amreg_national_forecasts_csv.sql` - New: AMREG forecasts

### Python Files
1. ✅ `scripts/create_population_time_series_chart.py` - New: Time series chart generator

---

## 🔍 Crosswalk Details

### LODES Crosswalk
- **Method**: Join `V_TRACT_LODES_SUMMARY` with `V_TRACT_HOUSING_COHORT` on `ID_TRACT`
- **Result**: Gets `CBSA_CODE`, `CBSA_NAME`, `STATE_FIPS`, `COUNTY_FIPS`
- **Note**: Uses most recent `DATE_REFERENCE` from housing cohort

### AMREG Crosswalk
- **Table**: `TRANSFORM_PROD.REF.OXFORD_CBSA_CROSSWALK`
- **Join Key**: `LOCATION_CODE` (AMREG) = `LOCATION_CODE_OXFORD` (Crosswalk)
- **Output**: `ID_CBSA`, `NAME_CBSA`
- **Fallback**: If crosswalk doesn't match, uses existing `ID_CBSA` from AMREG table

---

## 📈 Next Steps

1. **Run SQL Exports**:
   - Execute `create_acs_national_summary_csv.sql` and export to CSV
   - Execute `create_amreg_national_forecasts_csv.sql` and export to CSV

2. **Generate Chart**:
   - Place CSVs in `output/time_series/`
   - Run `python scripts/create_population_time_series_chart.py`

3. **Review Output**:
   - Check chart: `output/time_series/population_time_series_2000_2050.png`
   - Review CSV files for data quality

4. **Extend Analysis**:
   - Add household time series chart
   - Add tenure split time series
   - Add bedroom distribution time series
   - Add income distribution time series

---

## ✅ Status Summary

| Task | Status | Notes |
|------|--------|-------|
| LODES CBSA Join | ✅ Complete | Using V_TRACT_HOUSING_COHORT |
| AMREG Oxford Crosswalk | ✅ Complete | Using OXFORD_CBSA_CROSSWALK |
| ACS National Summary SQL | ✅ Complete | Ready for export |
| AMREG Forecasts SQL | ✅ Complete | Ready for export |
| Time Series Chart Script | ✅ Complete | Ready to run after CSV exports |

---

**All fixes and time series analysis components are complete and ready for execution.**

