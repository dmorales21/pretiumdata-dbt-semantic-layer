# AMREG Integration: Complete ✅

**Date**: 2025-12-30  
**Status**: Materialization Complete, Ready for Signal Integration  
**Last Reviewed**: 2026-01-27

---

## ✅ Materialization Complete

### Table Created

**Name**: `TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED`

**Purpose**: Materialize recent AMREG data (2020+) to avoid view timeout issues

**Statistics**:
- **Total Rows**: 35,581,472
- **Unique CBSAs**: 296
- **Unique Dates**: 31 (2020-2050)
- **Unique Metrics**: 657
- **Date Range**: 2020-12-31 to 2050-12-31
- **Forecast Rows**: 28.7M (future dates)
- **Historical Rows**: 6.9M (2020-2025)

**Performance**:
- ✅ Query time: **0.688s** (vs timeout with view)
- ✅ Indexes: ID_CBSA, DATE_REFERENCE, META_METRIC
- ✅ Primary key: (ID_CBSA, DATE_REFERENCE, META_METRIC)

---

## 📊 Metric Categories

| Category | Metrics | Rows | Use Case |
|----------|---------|------|----------|
| **EMPLOYMENT** | 336 | 18.1M | MOMENTUM signal, employment trends |
| **OTHER_ECONOMIC** | 178 | 9.3M | General economic indicators |
| **ECONOMIC_OUTPUT** | 83 | 5.0M | GDP, output metrics |
| **WAGES_INCOME** | 23 | 1.2M | Income/wage trends |
| **HOUSING_RE** | 19 | 1.0M | Real estate indicators |
| **DEMOGRAPHICS** | 18 | 974K | Population trends |

---

## 🔧 Integration Plan

### Phase 1: MOMENTUM Signal Enhancement ✅ READY

**File**: `sql/transform/create_amreg_momentum_integration.sql`

**Changes**:
1. Create `AMREG_EMPLOYMENT_CBSA` view from materialized table
2. Update `FACT_MOMENTUM_CBSA` to use AMREG as primary, BLS as fallback
3. Add employment source tracking

**Benefits**:
- More recent data (AMREG has forecasts through 2050)
- Better coverage (296 CBSAs)
- Forward-looking momentum signals

### Phase 2: GOLD Layer (Future)

**Create**: `TRANSFORM_PROD.GOLD.GOLD_AMREG_CBSA_ECONOMICS`

**Purpose**: Standardized economic indicators for all signals

**Metrics**:
- Employment (total, by sector)
- GDP growth
- Wage growth
- Population forecasts

### Phase 3: New Economic Signals (Future)

**Potential Signals**:
- Economic Growth Signal (GDP + Employment)
- Wage Pressure Signal (Wage growth vs inflation)
- Population Momentum Signal (Demographics)

---

## 📋 Usage Examples

### Query AMREG Employment Data

```sql
SELECT 
  ID_CBSA,
  NAME_CBSA,
  DATE_REFERENCE,
  VALUE AS employment_level,
  INDICATOR_FULL_NAME
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
WHERE META_METRIC LIKE '%EMPLOYMENT%TOTAL%'
  AND DATE_REFERENCE >= '2024-01-01'
  AND ID_CBSA = '12060'  -- Phoenix
ORDER BY DATE_REFERENCE DESC;
```

### Compare AMREG vs BLS Coverage

```sql
SELECT 
  COUNT(DISTINCT am.ID_CBSA) AS amreg_cbsas,
  COUNT(DISTINCT bls.ID_CBSA) AS bls_cbsas,
  MAX(am.DATE_REFERENCE) AS amreg_latest,
  MAX(bls.DATE_REFERENCE) AS bls_latest
FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED am
FULL OUTER JOIN TRANSFORM_PROD.CLEANED.BLS_EMPLOYMENT_CBSA bls
  ON am.ID_CBSA = bls.ID_CBSA;
```

---

## 🔄 Refresh Strategy

### Current: Manual Refresh

**Command**:
```sql
TRUNCATE TABLE TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED;

INSERT INTO TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
SELECT * FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS
WHERE DATE_REFERENCE >= '2020-01-01';
```

### Future: Automated Task

**Recommended**: Monthly refresh after AMREG source update

**Task Definition**:
```sql
CREATE TASK REFRESH_AMREG_MATERIALIZED
  WAREHOUSE = 'COMPUTE_WH'
  SCHEDULE = 'USING CRON 0 2 1 * * UTC'  -- 1st of month, 2 AM UTC
AS
  TRUNCATE TABLE TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED;
  
  INSERT INTO TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS_MATERIALIZED
  SELECT * FROM TRANSFORM_PROD.CLEANED.AMREG_CBSA_ECONOMICS
  WHERE DATE_REFERENCE >= '2020-01-01';
```

---

## ✅ Next Steps

1. ✅ **Materialization**: Complete
2. ⏳ **MOMENTUM Integration**: Execute `create_amreg_momentum_integration.sql`
3. ⏳ **Demand Forecasting Integration**: Explore demographics metrics for household projections (see `AMREG_DEMAND_FORECASTING_REVIEW.md`)
4. ⏳ **Testing**: Validate MOMENTUM signal with AMREG data
5. ⏳ **Monitoring**: Set up refresh schedule
6. ⏳ **Documentation**: Update signal documentation

---

**Status**: AMREG materialization complete. Ready for signal integration.

