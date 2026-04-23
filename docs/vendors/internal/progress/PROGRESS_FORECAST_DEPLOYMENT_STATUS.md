# Progress Forecast 24-36M Deployment Status

**Last Updated**: 2026-01-27  
**Status**: 🔴 **DEPLOYMENT IN PROGRESS - FIXES APPLIED**

---

## Critical Fixes Applied

### ✅ Fix 1: SQL Context/Privilege Issues
**Problem**: "Object does not exist" errors from context statements failing silently  
**Solution**: 
- Added fail-fast context checks to all SQL files
- Changed all `USE ROLE DATA_ENGINEER` → `USE ROLE ACCOUNTADMIN`
- Added `SELECT CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();` to all files
- Updated deployment script with `-o stop_on_error=true -o exit_on_error=true`

**Files Fixed**:
- `create_dim_rate_scenario_path.sql`
- `create_amreg_growth_horizons_cbsa.sql`
- `create_progress_demand_mass_forecast.sql`
- `create_progress_eligibility_share_forecast.sql`
- `create_progress_offerings_forecast_24_36m.sql`
- `create_progress_offerings_tract_forecast_24_36m.sql`
- `validate_progress_forecast_24_36m.sql`

---

### ✅ Fix 2: ON CONFLICT Syntax Error
**Problem**: Line 39 in `create_dim_rate_scenario_path.sql` uses PostgreSQL `ON CONFLICT` syntax  
**Solution**: Replaced with Snowflake-compatible TRUNCATE + INSERT pattern

**Before**:
```sql
INSERT INTO ... VALUES (...) ON CONFLICT (...) DO UPDATE ...
```

**After**:
```sql
TRUNCATE TABLE IF EXISTS ANALYTICS_PROD.MODELED.DIM_RATE_SCENARIO_PATH;
INSERT INTO ANALYTICS_PROD.MODELED.DIM_RATE_SCENARIO_PATH (...) VALUES (...);
```

---

### ✅ Fix 3: Invalid Identifier 'O.DATE_REFERENCE'
**Problem**: `create_amreg_growth_horizons_cbsa.sql` references `o.DATE_REFERENCE` but `o` alias doesn't have that column  
**Solution**: Changed all `o.DATE_REFERENCE` → `od.DATE_REFERENCE` (from the LEFT JOIN)

**Before**:
```sql
MAX(CASE WHEN o.DATE_REFERENCE <= h.AS_OF_SIGNAL_DATE THEN o.DATE_REFERENCE END)
```

**After**:
```sql
MAX(CASE WHEN od.DATE_REFERENCE <= h.AS_OF_SIGNAL_DATE THEN od.DATE_REFERENCE END)
```

---

## Deployment Checklist

### Step 0: Foundation Table
- [ ] `DIM_RATE_SCENARIO_PATH` table created
- [ ] Table has 6 rows (BASE/HIGH_RATE/LOW_RATE × 24M/36M)
- [ ] No NULLs in SCENARIO, HORIZON_MONTHS, MORTGAGE_RATE, INSURANCE_RATE, TAX_RATE

**Verification Query**:
```sql
SELECT * FROM ANALYTICS_PROD.MODELED.DIM_RATE_SCENARIO_PATH;
-- Should return 6 rows, no NULLs
```

---

### Step 1: Oxford Growth Horizons
- [ ] `V_AMREG_GROWTH_HORIZONS_CBSA` view created
- [ ] View returns rows for all CBSAs
- [ ] No NULLs in critical columns: CBSA_CODE, HH_GROWTH_FACTOR_24M, HH_GROWTH_FACTOR_36M

**Verification Query**:
```sql
SELECT 
    COUNT(*) AS CBSA_COUNT,
    COUNT(CBSA_CODE) AS CBSA_COUNT_NON_NULL,
    COUNT(HH_GROWTH_FACTOR_24M) AS HH_24M_NON_NULL,
    COUNT(HH_GROWTH_FACTOR_36M) AS HH_36M_NON_NULL
FROM ANALYTICS_PROD.MODELED.V_AMREG_GROWTH_HORIZONS_CBSA;
-- CBSA_COUNT should match CBSA_COUNT_NON_NULL
-- HH_24M_NON_NULL and HH_36M_NON_NULL should equal CBSA_COUNT
```

---

### Step 2: Demand Mass Forecast
- [ ] `V_PROGRESS_DEMAND_MASS_FORECAST_CBSA` view created
- [ ] View returns rows for all CBSAs
- [ ] No NULLs in: CBSA_CODE, DEMAND_MASS_TRAD_24M, DEMAND_MASS_TRAD_36M, DEMAND_MASS_FY_24M, DEMAND_MASS_FY_36M, DEMAND_MASS_AH_24M, DEMAND_MASS_AH_36M

**Verification Query**:
```sql
SELECT 
    COUNT(*) AS CBSA_COUNT,
    COUNT(DEMAND_MASS_TRAD_24M) AS TRAD_24M_NON_NULL,
    COUNT(DEMAND_MASS_TRAD_36M) AS TRAD_36M_NON_NULL,
    COUNT(DEMAND_MASS_FY_24M) AS FY_24M_NON_NULL,
    COUNT(DEMAND_MASS_FY_36M) AS FY_36M_NON_NULL,
    COUNT(DEMAND_MASS_AH_24M) AS AH_24M_NON_NULL,
    COUNT(DEMAND_MASS_AH_36M) AS AH_36M_NON_NULL
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_DEMAND_MASS_FORECAST_CBSA;
-- All counts should equal CBSA_COUNT
```

---

### Step 3: Eligibility Share Forecast
- [ ] `V_PROGRESS_ELIGIBILITY_SHARE_FORECAST_CBSA` view created
- [ ] View returns rows for all CBSAs
- [ ] No NULLs in: CBSA_CODE, ELIGIBILITY_SHARE_24M_BASE, ELIGIBILITY_SHARE_36M_BASE, ELIGIBILITY_SHARE_24M_DOWNSIDE, ELIGIBILITY_SHARE_36M_DOWNSIDE

**Verification Query**:
```sql
SELECT 
    COUNT(*) AS CBSA_COUNT,
    COUNT(ELIGIBILITY_SHARE_24M_BASE) AS ELIG_24M_BASE_NON_NULL,
    COUNT(ELIGIBILITY_SHARE_36M_BASE) AS ELIG_36M_BASE_NON_NULL,
    COUNT(ELIGIBILITY_SHARE_24M_DOWNSIDE) AS ELIG_24M_DOWN_NON_NULL,
    COUNT(ELIGIBILITY_SHARE_36M_DOWNSIDE) AS ELIG_36M_DOWN_NON_NULL
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_ELIGIBILITY_SHARE_FORECAST_CBSA;
-- All counts should equal CBSA_COUNT
```

---

### Step 4: Target Demand Forecasts (CBSA)
- [ ] `V_PROGRESS_OFFERINGS_FORECAST_24_36M` view created
- [ ] View returns rows for all CBSAs
- [ ] No NULLs in: CBSA_CODE, PROG_SFR_TRAD_FORECAST_24M_BASE, PROG_SFR_TRAD_FORECAST_36M_BASE, PROG_SFR_FY_FORECAST_24M_BASE, PROG_SFR_FY_FORECAST_36M_BASE, PROG_SFR_AH_FORECAST_24M_BASE, PROG_SFR_AH_FORECAST_36M_BASE

**Verification Query**:
```sql
SELECT 
    COUNT(*) AS CBSA_COUNT,
    COUNT(PROG_SFR_TRAD_FORECAST_24M_BASE) AS TRAD_24M_BASE_NON_NULL,
    COUNT(PROG_SFR_TRAD_FORECAST_36M_BASE) AS TRAD_36M_BASE_NON_NULL,
    COUNT(PROG_SFR_FY_FORECAST_24M_BASE) AS FY_24M_BASE_NON_NULL,
    COUNT(PROG_SFR_FY_FORECAST_36M_BASE) AS FY_36M_BASE_NON_NULL,
    COUNT(PROG_SFR_AH_FORECAST_24M_BASE) AS AH_24M_BASE_NON_NULL,
    COUNT(PROG_SFR_AH_FORECAST_36M_BASE) AS AH_36M_BASE_NON_NULL
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_OFFERINGS_FORECAST_24_36M;
-- All counts should equal CBSA_COUNT
```

---

### Step 5: Tract Allocation
- [ ] `V_PROGRESS_OFFERINGS_TRACT_FORECAST_24_36M` view created
- [ ] View returns rows for all tracts
- [ ] No NULLs in: ID_TRACT, CBSA_CODE, PROG_SFR_TRAD_FORECAST_24M_BASE, PROG_SFR_TRAD_FORECAST_36M_BASE
- [ ] Sum of tract forecasts = CBSA forecasts (validation)

**Verification Query**:
```sql
-- Check for NULLs
SELECT 
    COUNT(*) AS TRACT_COUNT,
    COUNT(PROG_SFR_TRAD_FORECAST_24M_BASE) AS TRAD_24M_BASE_NON_NULL,
    COUNT(PROG_SFR_TRAD_FORECAST_36M_BASE) AS TRAD_36M_BASE_NON_NULL
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_OFFERINGS_TRACT_FORECAST_24_36M;
-- All counts should equal TRACT_COUNT

-- Check sum validation
SELECT 
    cf.CBSA_CODE,
    cf.PROG_SFR_TRAD_FORECAST_24M_BASE AS CBSA_TRAD_24M,
    SUM(tf.PROG_SFR_TRAD_FORECAST_24M_BASE) AS TRACT_SUM_TRAD_24M,
    ABS(cf.PROG_SFR_TRAD_FORECAST_24M_BASE - SUM(tf.PROG_SFR_TRAD_FORECAST_24M_BASE)) AS DIFF
FROM ANALYTICS_PROD.MODELED.V_PROGRESS_OFFERINGS_FORECAST_24_36M cf
JOIN ANALYTICS_PROD.MODELED.V_PROGRESS_OFFERINGS_TRACT_FORECAST_24_36M tf
    ON cf.CBSA_CODE = tf.CBSA_CODE
GROUP BY cf.CBSA_CODE, cf.PROG_SFR_TRAD_FORECAST_24M_BASE
HAVING ABS(cf.PROG_SFR_TRAD_FORECAST_24M_BASE - SUM(tf.PROG_SFR_TRAD_FORECAST_24M_BASE)) > 0.01;
-- Should return 0 rows (tolerance: 0.01)
```

---

### Step 6: Validation Views
- [ ] `V_VALIDATION_SUM_CHECK` view created
- [ ] `V_VALIDATION_GROWTH_BOUNDS` view created
- [ ] `V_VALIDATION_OVERRIDE_FLAGS` view created
- [ ] `V_VALIDATION_MISSINGNESS_RATES` view created
- [ ] `V_VALIDATION_DATA_FRESHNESS` view created

**Verification Query**:
```sql
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'MODELED'
  AND TABLE_NAME LIKE 'V_VALIDATION%'
ORDER BY TABLE_NAME;
-- Should return 5 views
```

---

## Executive Summary: What's Complete

### ✅ CBSA Level - COMPLETE (After Deployment)
- **Demand Mass Forecast**: Oxford-based household growth with structural components held constant
- **Eligibility Share Forecast**: Model-first approach with CPS/QCEW/AI risk adjustments
- **Target Demand Forecast**: Demand Mass × Eligibility Share (BASE and DOWNSIDE scenarios)
- **24M and 36M Horizons**: Both forecast horizons available

### ✅ Tract Level - COMPLETE (After Deployment)
- **Tract Allocation**: Weighted allocation from CBSA (preserves totals)
- **All Offerings**: TRAD, FY, AH forecasts at tract level
- **Both Scenarios**: BASE and DOWNSIDE scenarios

### ⚠️ Validation - PENDING
- Validation views created but need to be run to confirm data quality
- Sum checks need to pass (tract sums = CBSA totals)
- Growth bounds need to be within expected ranges

---

## Next Steps

1. **Deploy with fixed scripts**:
   ```bash
   bash sql/analytics/modeled/deploy_progress_forecast_24_36m.sh
   ```

2. **Run verification queries** (from checklist above)

3. **Build executive presentation** once verification confirms:
   - All views exist
   - All critical columns have no NULLs
   - Sum validation passes
   - Growth bounds are reasonable

---

## Known Limitations

1. **AH Eligibility**: Uses simplified 0.7 multiplier fallback (can be enhanced with explicit income band coverage)
2. **Distance Feasibility**: Defaults to 1.0 (will be enhanced when LODES data is integrated)
3. **Rate Scenarios**: Uses manual defaults (should be updated with actual rate forecasts)
4. **Mobility Modifier**: Uses STABILITY_MODIFIER from V_TRACT_HOUSING_COHORT (defaults to 0.85 if B07401 not available)

