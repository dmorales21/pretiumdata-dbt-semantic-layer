# Parcl ZIP Absorption Model ETL and Task Setup

**Date**: 2026-01-11  
**Status**: ✅ **Complete**

## Summary

Successfully created ETL process and automated task to load new Parcl ZIP absorption data from the validated view into the model table with full feature engineering.

## Implementation

### 1. ETL Script ✅

**File**: `sql/analytics/features/load_parcl_zip_absorption_model_v1_from_validated.sql`

**Purpose**: Process new data from validated view into model table with full feature engineering

**Features**:
- Reads from `VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED` (uses CLEANSED_* values, filters TIER_1/TIER_2)
- Joins with geography mapping (`H3_XWALK_6810_CANON`)
- Computes temporal features (1M ago, 12M ago, MoM, YoY)
- Computes moving averages (3M, 6M, 12M)
- Computes CBSA context (average, comparison, quintile)
- Computes scoring and categorization features
- Uses MERGE to update existing or insert new records
- Only processes dates not yet in model table

**Results**:
- ✅ November 2025 data loaded: 6,641 rows
- Latest date in model: 2025-11-30

### 2. Automated Task ✅

**File**: `sql/analytics/features/create_task_parcl_zip_absorption_model_etl.sql`

**Task Name**: `TASK_PARCL_ZIP_ABSORPTION_MODEL_ETL`

**Schedule**: Daily at 5:00 AM ET (`USING CRON 0 5 * * * America/New_York`)

**Status**: ✅ Started (active)

**Current Behavior**:
- Checks for new dates in validated view that aren't in model table
- Logs findings to `ADMIN.VALIDATION.AI_GOVERNANCE_SNAPSHOT`
- Status: `NEW_DATA_AVAILABLE` or `NO_NEW_DATA`

**Note**: Currently the task only monitors/logs. To fully automate, you can:
1. Create a stored procedure with the full MERGE logic
2. Call the stored procedure from the task
3. Or use an external scheduler (Airflow, etc.) to run the ETL script

## Data Flow

```
TRANSFORM_PROD.CLEANED.VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED
    ↓ [ETL: load_parcl_zip_absorption_model_v1_from_validated.sql]
ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1
    ↓ [Latest date filter]
ANALYTICS_PROD.FEATURES.VW_PARCL_ZIP_ABSORPTION_LATEST_V1
```

## Usage

### Manual ETL Execution

Run the ETL script manually when new data is available:

```bash
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM \
  --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/analytics/features/load_parcl_zip_absorption_model_v1_from_validated.sql
```

### Check Task Status

```sql
SHOW TASKS LIKE 'TASK_PARCL_ZIP_ABSORPTION_MODEL_ETL';
```

### Check for New Data

```sql
SELECT 
    COUNT(DISTINCT v.DATE_REFERENCE) AS new_dates_count,
    MIN(v.DATE_REFERENCE) AS earliest_new_date,
    MAX(v.DATE_REFERENCE) AS latest_new_date
FROM TRANSFORM_PROD.CLEANED.VW_PARCLLABS_ZIP_ABSORPTION_HISTORY_VALIDATED v
WHERE v.DATA_QUALITY_TIER IN ('TIER_1', 'TIER_2')
  AND v.DATE_REFERENCE >= '2023-01-01'
  AND v.DATE_REFERENCE <= '2025-12-31'
  AND NOT EXISTS (
      SELECT 1 
      FROM ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1 m
      WHERE m.DATE_REFERENCE = v.DATE_REFERENCE
      LIMIT 1
  );
```

### View Task Execution History

```sql
SELECT 
    TIMESTAMP,
    COMPONENT,
    OBJECT_NAME,
    OPERATION,
    METRIC_NAME,
    METRIC_VALUE,
    STATUS
FROM ADMIN.VALIDATION.AI_GOVERNANCE_SNAPSHOT
WHERE COMPONENT = 'PARCL_ZIP_ABSORPTION_MODEL_ETL'
ORDER BY TIMESTAMP DESC
LIMIT 10;
```

## Feature Engineering Details

The ETL computes the following features:

### Temporal Features
- `ABSORPTION_1M_AGO`: Absorption rate 1 month ago
- `ABSORPTION_12M_AGO`: Absorption rate 12 months ago
- `ABSORPTION_MOM_PCT`: Month-over-month percent change
- `ABSORPTION_YOY_PCT`: Year-over-year percent change

### Moving Averages
- `ABSORPTION_3M_MA`: 3-month moving average
- `ABSORPTION_6M_MA`: 6-month moving average
- `ABSORPTION_12M_MA`: 12-month moving average

### CBSA Context
- `CBSA_ABSORPTION_AVG`: Average absorption rate for CBSA
- `ABSORPTION_VS_CBSA`: Difference from CBSA average
- `ABSORPTION_QUINTILE`: Quintile rank within CBSA (1-5)

### Scoring and Categorization
- `SEASONAL_INDICATOR`: Month number (1-12)
- `INVENTORY_PRESSURE`: LOW, MODERATE, ELEVATED, HIGH
- `INVENTORY_REGIME`: SELLERS_MARKET, BALANCED, BUYERS_MARKET
- `ABSORPTION_SCORE_0_100`: Normalized score (0-100)
- `ABSORPTION_DAYS`: Days to absorb inventory (annualized)
- `ABSORPTION_SPEED_LABEL`: VERY_FAST, FAST, MODERATE, SLOW, VERY_SLOW
- `ABSORPTION_VOLATILITY_LABEL`: HIGH_VOLATILITY, MODERATE_VOLATILITY, LOW_VOLATILITY
- `ABSORPTION_VOL_12M`: 12-month standard deviation
- `NINE_BOX_LABEL`: 9-box matrix (absorption rate × months of supply)

## Next Steps

### Option 1: Enhance Task with Full ETL
Create a stored procedure with the full MERGE logic and call it from the task:

```sql
CREATE OR REPLACE PROCEDURE ANALYTICS_PROD.FEATURES.SP_LOAD_PARCL_ZIP_ABSORPTION_MODEL()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Full MERGE logic here (from load_parcl_zip_absorption_model_v1_from_validated.sql)
    -- ...
    RETURN 'Success';
END;
$$;

-- Update task to call procedure
ALTER TASK TASK_PARCL_ZIP_ABSORPTION_MODEL_ETL
SET DEFINITION = 'CALL ANALYTICS_PROD.FEATURES.SP_LOAD_PARCL_ZIP_ABSORPTION_MODEL()';
```

### Option 2: External Scheduler
Use Airflow, Prefect, or similar to:
1. Monitor validated view for new dates
2. Execute ETL script when new data detected
3. Send notifications on success/failure

### Option 3: Keep Current Approach
- Task monitors and logs new data availability
- Manual execution of ETL script when needed
- Simple and transparent

## Validation

After ETL runs, verify data:

```sql
-- Check latest date in model
SELECT 
    MAX(DATE_REFERENCE) AS latest_date,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT ID_ZIP) AS unique_zips
FROM ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1;

-- Check November 2025 data
SELECT 
    DATE_REFERENCE,
    COUNT(*) AS row_count,
    AVG(ABSORPTION_RATE) AS avg_absorption,
    AVG(MONTHS_OF_SUPPLY) AS avg_months_supply
FROM ANALYTICS_PROD.FEATURES.PARCL_ZIP_ABSORPTION_MODEL_V1
WHERE DATE_REFERENCE = '2025-11-30'
GROUP BY DATE_REFERENCE;
```

## Files Created

1. **ETL Script**: `sql/analytics/features/load_parcl_zip_absorption_model_v1_from_validated.sql`
2. **Task Creation**: `sql/analytics/features/create_task_parcl_zip_absorption_model_etl.sql`
3. **Documentation**: This file

## Status

✅ **November 2025 data loaded**: 6,641 rows  
✅ **Task created and started**: Daily monitoring at 5:00 AM ET  
✅ **ETL script ready**: Can be run manually or automated  
⚠️ **Full automation**: Task currently only monitors; ETL runs manually

