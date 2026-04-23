# Realtor.com Factization - Complete

## Date: 2026-01-19
## Status: ✅ **Successfully Factized**

---

## ✅ Summary

Realtor.com pricing data has been successfully factized and routed to `TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS`.

### Results
- **Total Rows Routed**: 210,900 rows
- **Distinct Metrics**: 2 metrics
- **Distinct Geographies**: 925 CBSAs
- **Date Range**: 2016-07-01 to 2025-12-01
- **Product Type**: ALL (product-agnostic)
- **Tenancy**: OWN (listing price metrics)

---

## 📊 Metrics Factized

### 1. REALTOR_MEDIAN_LISTING_PRICE_CBSA
- **Row Count**: 105,450 rows
- **Geographies**: 925 CBSAs
- **Date Range**: 2016-07-01 to 2025-12-01
- **Value Range**: $19,900 to $5,972,500
- **Average Value**: $296,321.87

### 2. REALTOR_MEDIAN_LISTING_PRICE_PER_SQFT_CBSA
- **Row Count**: 105,450 rows
- **Geographies**: 925 CBSAs
- **Date Range**: 2016-07-01 to 2025-12-01
- **Value Range**: $22 to $1,778 per sqft
- **Average Value**: $158.31 per sqft

---

## 🔧 Implementation Details

### Approach
Due to stored procedure `SP_RESOLVE_METRIC_REGISTRATION` failing with `V_BATCH_ID` error, a **manual resolution approach** was used:

1. **Manual Resolution**: Created `WIP_REALTOR_PRICING_CBSA_ROUTED` table by directly joining tall table with `METRIC_NAME_MAP`
2. **Pattern Matching**: Used pattern matching for core metrics (base metrics only, excluding mm/yy variations)
3. **Direct Routing**: Routed resolved metrics directly to `HOUSING_HOU_PRICING_ALL_TS` using MERGE

### Scripts Used
- **Tall Table**: `sql/transform/fact/datasets/realtor/pricing_cbsa/20__tall.sql` ✅
- **Manual Resolution & Routing**: `sql/transform/fact/datasets/realtor/pricing_cbsa/21__resolve_and_route_manual.sql` ✅

### Resolution Results
- **TIER_A (Resolved)**: 293,211 rows → 2 metrics → 210,900 rows routed (after deduplication)
- **TIER_B (Unresolved)**: 3,787,083 rows (mm/yy variations and other metrics not yet registered)

---

## 📋 Unresolved Metrics (Future Work)

The following metrics were not routed because they don't have registered mappings yet:

1. `price_increased_share` (361,723 rows)
2. `price_increased_share_mm` (356,311 rows)
3. `price_increased_share_yy` (348,824 rows)
4. `median_listing_price_mm` (334,947 rows)
5. `price_increased_count` (282,488 rows)
6. `median_listing_price_yy` (253,848 rows)
7. `median_listing_price_per_square_foot_mm` (224,208 rows)
8. `average_listing_price_mm` (200,152 rows)
9. `price_reduced_share_mm` (186,312 rows)
10. `price_reduced_share_yy` (170,335 rows)

**Note**: These are variations (month-over-month, year-over-year) and additional metrics that can be registered in the future if needed.

---

## ✅ Validation

### Fact Table Verification
```sql
SELECT 
    'Realtor Pricing CBSA Factization Complete' AS STATUS,
    COUNT(*) AS total_rows_routed,
    COUNT(DISTINCT METRIC_ID) AS distinct_metrics,
    COUNT(DISTINCT GEO_KEY) AS distinct_geos,
    COUNT(DISTINCT PRODUCT_TYPE_CODE) AS distinct_product_types,
    MIN(DATE_REFERENCE) AS min_date,
    MAX(DATE_REFERENCE) AS max_date
FROM TRANSFORM_PROD.FACT.HOUSING_HOU_PRICING_ALL_TS
WHERE SOURCE = 'Realtor:PricingCBSA:v1.0'
  AND VENDOR_NAME = 'REALTOR'
  AND META_DATASET = 'PRICING_CBSA';
```

**Results**:
- ✅ 210,900 rows successfully routed
- ✅ 2 distinct metrics
- ✅ 925 distinct geographies
- ✅ Date range: 2016-07-01 to 2025-12-01

---

## 🎯 Next Steps (Optional)

### 1. Register Additional Metrics
If month-over-month and year-over-year variations are needed:
- Register `REALTOR_MEDIAN_LISTING_PRICE_MM_CBSA`
- Register `REALTOR_MEDIAN_LISTING_PRICE_YY_CBSA`
- Register `REALTOR_MEDIAN_LISTING_PRICE_PER_SQFT_MM_CBSA`
- Register `REALTOR_MEDIAN_LISTING_PRICE_PER_SQFT_YY_CBSA`
- Register price change metrics (increased/reduced share/count)

### 2. Fix Stored Procedure
Once `SP_RESOLVE_METRIC_REGISTRATION` is fixed, the standard routing script (`21__resolve_and_route.sql`) can be used for future updates.

### 3. Schedule Regular Updates
Set up automated pipeline to:
- Refresh `REALTOR_MEDIAN_PRICE_CBSA_TS` CLEANED view
- Re-run tall table creation
- Re-run manual resolution and routing

---

## 📁 Files

### Created/Modified
- ✅ `sql/transform/fact/datasets/realtor/pricing_cbsa/20__tall.sql` - Tall table creation
- ✅ `sql/transform/fact/datasets/realtor/pricing_cbsa/21__resolve_and_route_manual.sql` - Manual resolution and routing
- ✅ `sql/admin/catalog/register_realtor_pricing_metrics.sql` - Metric registration
- ✅ `sql/transform/cleaned/create_realtor_median_price_cbsa_ts.sql` - CLEANED view

### Work Tables
- `ADMIN.WORK.WIP_REALTOR_PRICING_CBSA_TALL` - Tall table (2,085,306 rows)
- `ADMIN.WORK.WIP_REALTOR_PRICING_CBSA_ROUTED` - Resolved metrics (293,211 TIER_A rows)

---

## ✅ Success Criteria Met

- [x] CLEANED view created
- [x] Metrics registered in `DIM_METRIC`
- [x] Metric mappings registered in `METRIC_NAME_MAP`
- [x] Tall table created with data
- [x] Metrics resolved to canonical `METRIC_ID`s
- [x] Data routed to `HOUSING_HOU_PRICING_ALL_TS`
- [x] Validation queries confirm data in fact table
- [x] Product type segmentation applied (`PRODUCT_TYPE_CODE = 'ALL'`)

---

## 🎉 Conclusion

Realtor.com pricing data is now successfully factized and available in the canonical fact table. The manual resolution approach successfully bypassed the stored procedure issue and routed 210,900 rows of core pricing metrics to the fact table.

