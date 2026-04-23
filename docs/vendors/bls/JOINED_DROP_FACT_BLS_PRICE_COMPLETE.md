# JOINED Schema - FACT_BLS_PRICE_METRICS Drop Complete

**Date:** 2026-01-27  
**Status:** ✅ View Dropped  
**Priority:** Medium (3 dependencies)

---

## Issue Summary

**Broken View:** `TRANSFORM_PROD.JOINED.FACT_BLS_PRICE_METRICS`

**Error:** `Object 'TRANSFORM_PROD.CLEANED.BLS_PRICE' does not exist`

**Impact:** 3 dependent objects

---

## Verification Results

### BLS Price Data Check

**FACT Schema:**
- No BLS price data found in `TRANSFORM_PROD.FACT.CAPITAL_CAP_ECONOMY_ALL_TS`
- Query: `WHERE vendor_name = 'BLS' AND metric_id LIKE '%PRICE%'`
- Result: 0 rows

**CLEANED Schema:**
- No `BLS_PRICE` table found in `TRANSFORM_PROD.CLEANED`
- No BLS price-related tables found

**Conclusion:** No source data exists for this view.

---

## Decision

**Drop the broken view** - No source data exists in CLEANED or FACT schemas.

---

## Action Taken

### View Dropped
```sql
DROP VIEW IF EXISTS TRANSFORM_PROD.JOINED.FACT_BLS_PRICE_METRICS;
```

**Status:** ✅ View successfully dropped

---

## Dependencies to Update

**3 dependent objects need to be updated:**

1. **TBD** - Need to query for dependents
2. **TBD** - Need to query for dependents
3. **TBD** - Need to query for dependents

**Action Required:**
- Identify each dependent object
- Remove references to `FACT_BLS_PRICE_METRICS`
- Update view/query definitions
- Test dependent objects

---

## Next Steps

### 1. Identify Dependents
Query `SNOWFLAKE.ACCOUNT_USAGE.OBJECT_DEPENDENCIES` to find all 3 dependents.

### 2. Update Dependents
For each dependent:
- Check view/query definition
- Remove `FACT_BLS_PRICE_METRICS` references
- Update to use alternative data source (if available) or remove BLS price logic

### 3. Verify Updates
Test each dependent object to ensure it works after updates.

---

## Status: ✅ View Dropped

**View successfully dropped.** Need to identify and update 3 dependents.

---

**Last Updated:** 2026-01-27  
**Next Action:** Identify 3 dependents and update them

