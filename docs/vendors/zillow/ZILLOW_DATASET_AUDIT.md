# Zillow Dataset Audit & Recommendations

**Date**: 2026-01-01  
**Status**: ✅ **COMPLETE AUDIT**

---

## Current Catalog Status

**Currently Registered**:
- `ZILLOW_ZHVI` → `SOURCE_PROD.ZILLOW.ZILLOW_ZHVI_*` (Home Value Index)
- `ZILLOW_ZORI` → `SOURCE_PROD.ZILLOW.ZILLOW_ZORI_*` (Observed Rent Index)

**Metrics Count**: 1 metric (should be 45+ based on vendor lineage)

---

## Discovered Zillow Datasets

### 🏆 **TIER 1: High-Value Core Datasets** (Add Immediately)

| Dataset ID | Source Table | Rows | Description | Priority | Geography |
|------------|--------------|------|-------------|----------|-----------|
| **ZILLOW_ZHVF** | `SOURCE_PROD.ZILLOW.ZILLOW_ZHVF_MSA`<br>`SOURCE_PROD.ZILLOW.ZILLOW_ZHVF_ZIPCODE` | 0 (empty) | **Home Value Forecast** - 1YR & 5YR forecasts | 🔥 **P0** | MSA, ZIP |
| **ZILLOW_ZORDI** | `SOURCE_PROD.ZILLOW.ZILLOW_ZORDI_MSA` | 0 (empty) | **Observed Days to Rent Index** - Rental velocity | 🔥 **P0** | MSA |
| **ZILLOW_ZORF** | `SOURCE_PROD.ZILLOW.ZILLOW_ZORF_NATIONAL` | 6 rows | **Rent Forecast** - National rent forecast | 🔥 **P0** | National |
| **ZILLOW_AFFORDABILITY** | `SOURCE_PROD.ZILLOW.ZILLOW_AFFORDABILITY_MSA` | 521K | **Affordability Index** - Income needed, down payment % | 🔥 **P0** | MSA |
| **ZILLOW_MARKET_TEMPERATURE** | `SOURCE_PROD.ZILLOW.ZILLOW_MARKET_TEMPERATURE_MSA` | 170K | **Market Temperature Index** - Hot/cold market signals | 🔥 **P0** | MSA |

**Rationale**: These are **forecast/leading indicators** critical for investment decisions. ZHVF and ZORF provide forward-looking signals, ZORDI measures rental velocity (BTR/MF demand), Affordability drives pricing strategy, and Market Temperature indicates competitive intensity.

---

### 🥈 **TIER 2: Supply & Inventory Metrics** (High Priority)

| Dataset ID | Source Table | Rows | Description | Priority | Geography |
|------------|--------------|------|-------------|----------|-----------|
| **ZILLOW_INVENTORY_SFR** | `SOURCE_PROD.ZILLOW.ZILLOW_INVENTORY_SFR_MSA` | 1.8M | **SFR Inventory Count** - Active listings, YoY change | ⭐ **P1** | MSA |
| **ZILLOW_INVENTORY_SFRCONDO** | `SOURCE_PROD.ZILLOW.ZILLOW_INVENTORY_SFRCONDO_MSA` | 1.8M | **SFR+Condo Inventory** - Combined inventory | ⭐ **P1** | MSA |
| **ZILLOW_LISTINGS_SFR** | `SOURCE_PROD.ZILLOW.ZILLOW_LISTINGS_SFR_MSA` | 0 (empty) | **SFR Listing Prices** - Median listing, price cuts | ⭐ **P1** | MSA |
| **ZILLOW_LISTINGS_SFRCONDO** | `SOURCE_PROD.ZILLOW.ZILLOW_LISTINGS_SFRCONDO_MSA` | 0 (empty) | **SFR+Condo Listings** - Combined listing metrics | ⭐ **P1** | MSA |
| **ZILLOW_NEW_CONSTRUCTION** | `SOURCE_PROD.ZILLOW.ZILLOW_NEW_CONSTRUCTION_MSA` | 150K | **New Construction Count** - Permits, YoY change | ⭐ **P1** | MSA |

**Rationale**: **Supply-side metrics** essential for absorption analysis. Inventory levels drive pricing pressure, new construction indicates future supply, and listing prices show seller expectations.

---

### 🥉 **TIER 3: Transaction Velocity & Market Dynamics** (Medium Priority)

| Dataset ID | Source Table | Rows | Description | Priority | Geography |
|------------|--------------|------|-------------|----------|-----------|
| **ZILLOW_DAYS_ON_MARKET** | `SOURCE_PROD.ZILLOW.ZILLOW_DAYS_ON_MARKET_MSA` | 1.7M | **Days to Close** - Mean/median DOM, pending | ⚡ **P2** | MSA |
| **ZILLOW_PENDING** | `SOURCE_PROD.ZILLOW.ZILLOW_PENDING_MSA` | 0 (empty) | **Pending Sales** - Count, YoY change, % of total | ⚡ **P2** | MSA |
| **ZILLOW_MORTGAGE_PAYMENT** | `SOURCE_PROD.ZILLOW.ZILLOW_MORTGAGE_PAYMENT_MSA` | 1M | **Mortgage Payment** - Payment amount, interest rate, YoY | ⚡ **P2** | MSA |

**Rationale**: **Transaction velocity** metrics indicate market liquidity. Days on market and pending sales show how quickly properties move, mortgage payments drive affordability calculations.

---

### 📊 **TIER 4: Unified & Raw Sources** (Reference/Backup)

| Dataset ID | Source Table | Rows | Description | Priority | Geography |
|------------|--------------|------|-------------|----------|-----------|
| **ZILLOW_ALL** | `SOURCE_PROD.ZILLOW.ZILLOW_ALL` | **901M** | **Unified Zillow Data** - All metrics, all geographies | 📚 **P3** | All |
| **ZILLOW_ALL_RAW** | `SOURCE_PROD.ZILLOW.ZILLOW_ALL_RAW` | 88M | **Raw Parquet Data** - Pre-cleaned variant format | 📚 **P3** | All |
| **ZILLOW_RAW** | `SOURCE_PROD.ZILLOW.ZILLOW_RAW` | 88M | **Raw Source** - Original parquet ingestion | 📚 **P3** | All |

**Rationale**: **Unified tables** are excellent for **ad-hoc analysis** and **data discovery**, but should be secondary to specific metric datasets for production use. `ZILLOW_ALL` is particularly valuable as it contains all metrics in normalized format.

---

### 🔍 **TIER 5: Geographic Expansions** (If Needed)

| Dataset ID | Source Table | Rows | Description | Priority | Geography |
|------------|--------------|------|-------------|----------|-----------|
| **ZILLOW_ZHVI_CITY** | `SOURCE_PROD.ZILLOW.ZILLOW_ZHVI_CITY` | 50M | **ZHVI City-level** - More granular than MSA | 🔍 **P4** | City |
| **ZILLOW_ZHVI_COUNTY** | `SOURCE_PROD.ZILLOW.ZILLOW_ZHVI_COUNTY` | 6.9M | **ZHVI County-level** - County granularity | 🔍 **P4** | County |
| **ZILLOW_ZORI_CITY** | `SOURCE_PROD.ZILLOW.ZILLOW_ZORI_CITY` | 772K | **ZORI City-level** | 🔍 **P4** | City |
| **ZILLOW_ZORI_COUNTY** | `SOURCE_PROD.ZILLOW.ZILLOW_ZORI_COUNTY` | 336K | **ZORI County-level** | 🔍 **P4** | County |

**Rationale**: **Geographic expansions** provide more granular analysis, but may be redundant if MSA/ZIP coverage is sufficient. Add if specific use cases require city/county granularity.

---

## TRANSFORM_PROD Layer Status

### ✅ **Already Transformed** (CLEANED Views)

- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_ZIP`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_CITY`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_COUNTY`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVI_STATE`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZORI_ZIP`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVF_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZHVF_ZIP`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZORDI_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_ZORF_NATIONAL`
- `TRANSFORM_PROD.CLEANED.ZILLOW_AFFORDABILITY_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_DAYS_ON_MARKET_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_INVENTORY_SFR_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_INVENTORY_SFRCONDO_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_LISTINGS_SFR_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_LISTINGS_SFRCONDO_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_MARKET_TEMPERATURE_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_MORTGAGE_PAYMENT_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_NEW_CONSTRUCTION_MSA`
- `TRANSFORM_PROD.CLEANED.ZILLOW_PENDING_MSA`

**✅ 20 CLEANED views already exist** - These are ready for catalog registration!

### ✅ **Already Joined** (JOINED Views)

- `TRANSFORM_PROD.JOINED.FACT_ZILLOW_CBSA_METRICS` (ZHVI, ZORI, ZHVF, ZODRI)
- `TRANSFORM_PROD.JOINED.FACT_ZILLOW_ZIP_METRICS` (ZHVI, ZORI)
- `TRANSFORM_PROD.JOINED.ZILLOW_ALL_METRICS_MSA`
- `TRANSFORM_PROD.JOINED.ZILLOW_ALL_METRICS_ZIP`

### ✅ **Already Factualized** (FACT Tables)

- `TRANSFORM_PROD.FACT.FACT_ZILLOW_CITY_TS` (100M rows)
- `TRANSFORM_PROD.FACT.FACT_ZILLOW_COUNTY_TS` (6.9M rows)
- `TRANSFORM_PROD.FACT.FACT_ZILLOW_MSA_TS` (7.4M rows)
- `TRANSFORM_PROD.FACT.FACT_ZILLOW_NATIONAL_TS` (12 rows)
- `TRANSFORM_PROD.FACT.FACT_ZILLOW_STATE_TS` (0 rows - empty)
- `TRANSFORM_PROD.FACT.FACT_ZILLOW_ZIP_TS` (60M rows)

---

## Recommended Action Plan

### **Phase 1: Add Tier 1 (P0) Datasets** 🔥

```sql
INSERT INTO ADMIN.CATALOG.DIM_DATASET VALUES
  ('ZILLOW_ZHVF', 'ZILLOW_DATA', 'Zillow Home Value Forecast', 'CLEANED', 'ZILLOW_ZHVF_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_ZORDI', 'ZILLOW_DATA', 'Zillow Observed Days to Rent Index', 'CLEANED', 'ZILLOW_ZORDI_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_ZORF', 'ZILLOW_DATA', 'Zillow Rent Forecast', 'CLEANED', 'ZILLOW_ZORF_NATIONAL', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_AFFORDABILITY', 'ZILLOW_DATA', 'Zillow Affordability Index', 'CLEANED', 'ZILLOW_AFFORDABILITY_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_MARKET_TEMPERATURE', 'ZILLOW_DATA', 'Zillow Market Temperature Index', 'CLEANED', 'ZILLOW_MARKET_TEMPERATURE_MSA', 'PROPERTY', 'MONTHLY');
```

### **Phase 2: Add Tier 2 (P1) Datasets** ⭐

```sql
INSERT INTO ADMIN.CATALOG.DIM_DATASET VALUES
  ('ZILLOW_INVENTORY_SFR', 'ZILLOW_DATA', 'Zillow SFR Inventory', 'CLEANED', 'ZILLOW_INVENTORY_SFR_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_INVENTORY_SFRCONDO', 'ZILLOW_DATA', 'Zillow SFR+Condo Inventory', 'CLEANED', 'ZILLOW_INVENTORY_SFRCONDO_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_LISTINGS_SFR', 'ZILLOW_DATA', 'Zillow SFR Listings', 'CLEANED', 'ZILLOW_LISTINGS_SFR_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_LISTINGS_SFRCONDO', 'ZILLOW_DATA', 'Zillow SFR+Condo Listings', 'CLEANED', 'ZILLOW_LISTINGS_SFRCONDO_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_NEW_CONSTRUCTION', 'ZILLOW_DATA', 'Zillow New Construction', 'CLEANED', 'ZILLOW_NEW_CONSTRUCTION_MSA', 'PROPERTY', 'MONTHLY');
```

### **Phase 3: Add Tier 3 (P2) Datasets** ⚡

```sql
INSERT INTO ADMIN.CATALOG.DIM_DATASET VALUES
  ('ZILLOW_DAYS_ON_MARKET', 'ZILLOW_DATA', 'Zillow Days on Market', 'CLEANED', 'ZILLOW_DAYS_ON_MARKET_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_PENDING', 'ZILLOW_DATA', 'Zillow Pending Sales', 'CLEANED', 'ZILLOW_PENDING_MSA', 'PROPERTY', 'MONTHLY'),
  ('ZILLOW_MORTGAGE_PAYMENT', 'ZILLOW_DATA', 'Zillow Mortgage Payment', 'CLEANED', 'ZILLOW_MORTGAGE_PAYMENT_MSA', 'PROPERTY', 'MONTHLY');
```

### **Phase 4: Add Unified Source (P3)** 📚

```sql
INSERT INTO ADMIN.CATALOG.DIM_DATASET VALUES
  ('ZILLOW_ALL', 'ZILLOW_DATA', 'Zillow Unified Dataset', 'SOURCE', 'ZILLOW_ALL', 'PROPERTY', 'MONTHLY');
```

---

## Summary

**Current**: 2 datasets  
**Recommended**: 14-18 datasets (Tier 1-3)  
**Total Available**: 26+ source tables, 20+ CLEANED views

**Impact**: 
- ✅ **45+ metrics** will be discoverable (currently only 1)
- ✅ **Forecast capabilities** enabled (ZHVF, ZORF)
- ✅ **Supply-side analysis** enabled (Inventory, New Construction)
- ✅ **Market dynamics** enabled (Temperature, Affordability, DOM)

---

**Next Step**: Execute Phase 1-3 SQL inserts to register high-priority datasets.

