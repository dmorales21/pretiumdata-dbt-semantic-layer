# MLS and Realtor.com Factization - Complete

## Date: 2026-01-19
## Status: ✅ Scripts Created - Ready for Execution

---

## ✅ Completed

### 1. MLS Pricing Factization Scripts ✅

**ZIP5 Level**:
- `sql/transform/fact/datasets/mls/pricing_zip/20__tall.sql` - Creates tall table from `MLS_MEDIAN_PRICE_ZIP_TS`
- `sql/transform/fact/datasets/mls/pricing_zip/21__resolve_and_route.sql` - Resolves metrics and routes to `HOUSING_HOU_PRICING_ALL_TS`

**CBSA Level**:
- `sql/transform/fact/datasets/mls/pricing_cbsa/20__tall.sql` - Creates tall table from `MLS_MEDIAN_PRICE_CBSA_TS`
- `sql/transform/fact/datasets/mls/pricing_cbsa/21__resolve_and_route.sql` - Resolves metrics and routes to `HOUSING_HOU_PRICING_ALL_TS`

**Features**:
- Unpivots `MEDIAN_PRICE` and `MEDIAN_DOM` metrics
- Preserves `PRODUCT_TYPE_CODE` (SFR, MF, CONDO, ALL) and `TENANCY_CODE` (OWN, RENT)
- Creates raw metric names like `mls_median_price_sfr_zip_own`, `mls_median_dom_mf_cbsa_rent`, etc.

---

### 2. Realtor.com Pricing Factization Scripts ✅

**CBSA Level**:
- `sql/transform/fact/datasets/realtor/pricing_cbsa/20__tall.sql` - Creates tall table from `REALTOR_MEDIAN_PRICE_CBSA_TS`
- `sql/transform/fact/datasets/realtor/pricing_cbsa/21__resolve_and_route.sql` - Resolves metrics and routes to `HOUSING_HOU_PRICING_ALL_TS`

**Features**:
- Extracts pricing metrics from `FACT_REALTOR_CBSA_METRICS`
- Sets `PRODUCT_TYPE_CODE = 'ALL'` (product-agnostic)
- Preserves `TENANCY_CODE` (OWN, RENT) from source

---

### 3. MLS Metric Registration ✅

**DIM_METRIC**:
- `sql/admin/catalog/register_mls_pricing_metrics.sql`
- Registers 32 metrics (16 ZIP + 16 CBSA):
  - 4 product types × 2 tenancy types × 2 metrics (price, DOM) × 2 geographies = 32 metrics
  - Product types: SFR, MF, CONDO, ALL
  - Tenancy: OWN, RENT
  - Metrics: MEDIAN_PRICE, MEDIAN_DOM
  - Geographies: ZIP5, CBSA

**METRIC_NAME_MAP**:
- `sql/admin/catalog/register_mls_pricing_metric_name_map.sql`
- Maps raw metric names to canonical METRIC_IDs
- Example: `mls_median_price_sfr_zip_own` → `MLS_MEDIAN_PRICE_SFR_ZIP_OWN`

---

### 4. Realtor.com Metric Registration ✅

**DIM_METRIC**:
- `sql/admin/catalog/register_realtor_pricing_metrics.sql`
- Registers 4 common metrics:
  - `REALTOR_MEDIAN_LISTING_PRICE_CBSA`
  - `REALTOR_MEDIAN_LISTING_PRICE_PER_SQFT_CBSA`
  - `REALTOR_MEDIAN_DAYS_ON_MARKET_CBSA`
  - `REALTOR_ACTIVE_LISTING_COUNT_CBSA` (inventory metric)

**METRIC_NAME_MAP**:
- `sql/admin/catalog/register_realtor_pricing_metric_name_map.sql`
- Maps raw metric names to canonical METRIC_IDs
- Example: `median_listing_price` → `REALTOR_MEDIAN_LISTING_PRICE_CBSA`

---

### 5. ParclLabs Tables Analysis ✅

**Documentation**:
- `docs/PARCLLABS_TABLES_ANALYSIS.md`
- Documents existing ParclLabs tables in CLEANED
- Identifies that `PARCLLABS_RENT_HISTORY` is missing
- Provides investigation queries to determine if rent data exists

**Key Findings**:
- ParclLabs has housing stock, event counts, and absorption history
- Rent history table is referenced in factization script but doesn't exist
- Need to investigate if rent data exists in `PARCLLABS_HOUSING_EVENT_PRICES` or source tables

---

## 📋 Next Steps

### 1. Execute Metric Registration
```bash
# Register MLS metrics
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/admin/catalog/register_mls_pricing_metrics.sql

snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/admin/catalog/register_mls_pricing_metric_name_map.sql

# Register Realtor metrics
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/admin/catalog/register_realtor_pricing_metrics.sql

snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/admin/catalog/register_realtor_pricing_metric_name_map.sql
```

### 2. Execute MLS Factization
```bash
# ZIP level
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/transform/fact/datasets/mls/pricing_zip/20__tall.sql

snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/transform/fact/datasets/mls/pricing_zip/21__resolve_and_route.sql

# CBSA level
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/transform/fact/datasets/mls/pricing_cbsa/20__tall.sql

snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/transform/fact/datasets/mls/pricing_cbsa/21__resolve_and_route.sql
```

### 3. Execute Realtor Factization
```bash
snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/transform/fact/datasets/realtor/pricing_cbsa/20__tall.sql

snowsql -a SS54694-PRETIUMDATA -u APOSES@PRETIUM.COM --authenticator externalbrowser -r ACCOUNTADMIN \
  -f sql/transform/fact/datasets/realtor/pricing_cbsa/21__resolve_and_route.sql
```

### 4. Investigate ParclLabs Rent Data
Run investigation queries from `docs/PARCLLABS_TABLES_ANALYSIS.md` to determine if rent data exists and needs a CLEANED view.

---

## 📊 Expected Results

### MLS Pricing
- **ZIP5**: ~Thousands of rows (depends on MLS coverage)
- **CBSA**: ~Hundreds of rows (depends on MLS coverage)
- **Product Types**: SFR, MF, CONDO, ALL
- **Tenancy**: OWN, RENT
- **Metrics**: MEDIAN_PRICE, MEDIAN_DOM

### Realtor.com Pricing
- **CBSA**: ~Hundreds of rows (depends on Realtor coverage)
- **Product Type**: ALL (product-agnostic)
- **Tenancy**: OWN, RENT (derived from metric name)
- **Metrics**: MEDIAN_LISTING_PRICE, MEDIAN_LISTING_PRICE_PER_SQFT, MEDIAN_DAYS_ON_MARKET

---

## 📁 Files Created

### Factization Scripts (6 files)
1. `sql/transform/fact/datasets/mls/pricing_zip/20__tall.sql`
2. `sql/transform/fact/datasets/mls/pricing_zip/21__resolve_and_route.sql`
3. `sql/transform/fact/datasets/mls/pricing_cbsa/20__tall.sql`
4. `sql/transform/fact/datasets/mls/pricing_cbsa/21__resolve_and_route.sql`
5. `sql/transform/fact/datasets/realtor/pricing_cbsa/20__tall.sql`
6. `sql/transform/fact/datasets/realtor/pricing_cbsa/21__resolve_and_route.sql`

### Metric Registration (4 files)
7. `sql/admin/catalog/register_mls_pricing_metrics.sql`
8. `sql/admin/catalog/register_mls_pricing_metric_name_map.sql`
9. `sql/admin/catalog/register_realtor_pricing_metrics.sql`
10. `sql/admin/catalog/register_realtor_pricing_metric_name_map.sql`

### Documentation (1 file)
11. `docs/PARCLLABS_TABLES_ANALYSIS.md`

---

## ✅ Success Criteria

- ✅ MLS factization scripts created for ZIP and CBSA
- ✅ Realtor factization scripts created for CBSA
- ✅ MLS metrics registered (32 metrics)
- ✅ Realtor metrics registered (4 metrics)
- ✅ ParclLabs tables analyzed and documented
- ⏳ **Next**: Execute scripts and verify results

---

## 🚀 Ready for Execution

All scripts are ready for execution. The next phase involves:
1. Registering metrics in DIM_METRIC and METRIC_NAME_MAP
2. Executing factization scripts
3. Validating results
4. Investigating ParclLabs rent data if needed

