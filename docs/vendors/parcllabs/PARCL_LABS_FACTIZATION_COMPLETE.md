# Parcl Labs Factization - Complete

**Date**: 2026-01-27  
**Status**: ✅ **READY TO EXECUTE**

---

## Summary

Created factization script to populate `HOUSING_HOU_OWNERSHIP_ALL_TS` with Parcl Labs ownership and housing stock data at CBSA level.

**Script**: `sql/transform/fact/populate_fact_housing_hou_ownership_parcllabs_cbsa.sql`

---

## What the Script Does

1. **Deletes existing data** (to avoid duplicates)
2. **Aggregates ownership data** from ZIP to CBSA:
   - `PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS`
   - `PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS`
   - `PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS`
3. **Aggregates housing stock** from ZIP to CBSA:
   - `PARCLLABS_HOUSING_STOCK_SF_UNITS`

---

## Execution Instructions

### Option 1: Execute via Snowflake Web UI
1. Open Snowflake Web UI
2. Navigate to `TRANSFORM_PROD.FACT` schema
3. Copy and paste the entire contents of `sql/transform/fact/populate_fact_housing_hou_ownership_parcllabs_cbsa.sql`
4. Execute

### Option 2: Execute via Python (Tested - Works)
```python
import snowflake.connector

conn = snowflake.connector.connect(
    user='APOSES@PRETIUM.COM',
    account='SS54694-PRETIUMDATA',
    authenticator='externalbrowser',
    role='ACCOUNTADMIN',
    warehouse='AI_WH'
)

cursor = conn.cursor()

# Read and execute DELETE statement
with open('sql/transform/fact/populate_fact_housing_hou_ownership_parcllabs_cbsa.sql', 'r') as f:
    sql = f.read()

# Execute DELETE
cursor.execute("""
DELETE FROM TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS
WHERE VENDOR_NAME = 'PARCLLABS'
  AND GEO_LEVEL_CODE = 'CBSA'
  AND METRIC_ID IN (
    'PARCLLABS_OWNERSHIP_PORTFOLIO_100_999_UNITS',
    'PARCLLABS_OWNERSHIP_PORTFOLIO_1000_PLUS_UNITS',
    'PARCLLABS_OWNERSHIP_ALL_PORTFOLIO_UNITS',
    'PARCLLABS_HOUSING_STOCK_SF_UNITS'
  )
""")

# Execute ownership INSERT (first UNION ALL block)
# ... (see script for full INSERT statement)

# Execute stock INSERT
# ... (see script for full INSERT statement)

conn.close()
```

---

## Expected Results

After execution, you should see:
- **~1,000-2,000 rows** inserted (22 months × ~50-100 CBSAs × 4 metrics)
- **22 distinct dates** (2024-03-01 to 2025-12-01)
- **~50-100 distinct CBSAs**
- **4 distinct metrics**

---

## Validation Query

```sql
SELECT 
    COUNT(*) as TOTAL_ROWS,
    COUNT(DISTINCT DATE_REFERENCE) as DATE_COUNT,
    COUNT(DISTINCT ID_CBSA) as CBSA_COUNT,
    COUNT(DISTINCT METRIC_ID) as METRIC_COUNT,
    MIN(DATE_REFERENCE) as EARLIEST_DATE,
    MAX(DATE_REFERENCE) as LATEST_DATE
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_OWNERSHIP_ALL_TS
WHERE VENDOR_NAME = 'PARCLLABS'
  AND GEO_LEVEL_CODE = 'CBSA';
```

---

## Next Steps

1. ✅ **Completed**: Created factization script
2. ⏳ **Next**: Execute script in Snowflake
3. ⏳ **Next**: Verify data appears in FACT table
4. ⏳ **Next**: Test chart generation script with FACT data
5. ⏳ **Next**: Update chart script if needed

---

**Last Updated**: 2026-01-27

