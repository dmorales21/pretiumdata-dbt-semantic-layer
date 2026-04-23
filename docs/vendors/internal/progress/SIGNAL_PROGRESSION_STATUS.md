# Signal Progression Status Report
**Generated:** 2026-01-29  
**Purpose:** Track progression of all signals through development stages to production readiness

---

## Executive Summary

**Total Signals Deployed in Dashboard:** 12  
**Production-Ready (GOLD/SILVER):** 9 (75%)  
**In Development (BRONZE):** 2 (17%)  
**Legacy (Superseded):** 1 (8%)  

**Data Stage Distribution:**
- **ANALYTICS_PROD.SCORES** (Production): 12 signals
- **ANALYTICS.SCORES** (Staging): 17+ additional signals

---

## 🎯 12 Dashboard Signals - Complete Status

| # | Signal Name | Badge | Data Stage | Coverage | Data Source | Next Steps to Production |
|---|------------|-------|------------|----------|-------------|-------------------------|
| 1 | **Velocity Signal (MLS)** | 🥇 GOLD | ✅ ANALYTICS_PROD.SCORES | 893 CBSAs | MLS (Parcl Labs) | ✅ **PRODUCTION READY** |
| 2 | **Absorption Signal** | 🥇 GOLD | ✅ ANALYTICS_PROD.SCORES | 893 CBSAs | MLS Inventory/Sales | ✅ **PRODUCTION READY** |
| 3 | **Supply Pressure Signal** | 🥈 SILVER | ✅ ANALYTICS_PROD.SCORES | 350 CBSAs | Census Permits + MLS | • Expand coverage to 500+ CBSAs<br>• Add more data sources |
| 4 | **Competitiveness Signal** | 🥇 GOLD | ✅ ANALYTICS_PROD.SCORES | 893 CBSAs | MLS Price/DOM | ✅ **PRODUCTION READY** |
| 5 | **Listing Quality Signal** | 🥉 BRONZE | ✅ ANALYTICS_PROD.SCORES | 893 CBSAs | Data Quality Checks | • Add more quality dimensions<br>• Enhance validation rules |
| 6 | **BTR Market Health Signal** | 🥈 SILVER | ✅ ANALYTICS_PROD.SCORES | 50 CBSAs | ALN, Yardi | • Expand BTR data sources<br>• Increase coverage to 100+ markets |
| 7 | **Multifamily Health Signal** | 🥈 SILVER | ✅ ANALYTICS_PROD.SCORES | 150 CBSAs | CoStar, Yardi | • Add more MF metrics<br>• Expand to 250+ markets |
| 8 | **Affordable Housing Signal** | 🥉 BRONZE | ✅ ANALYTICS_PROD.SCORES | 300 CBSAs | HUD, LIHTC | • Integrate subsidy tracking<br>• Add policy compliance metrics |
| 9 | **Ownership Concentration Signal** | 🥇 GOLD | ✅ ANALYTICS_PROD.SCORES | 500 CBSAs | Parcl Labs | ✅ **PRODUCTION READY** |
| 10 | **Ownership Competition Signal** | 🥈 SILVER | ✅ ANALYTICS_PROD.SCORES | 400 CBSAs | CoreLogic, Parcl | • Expand transaction data<br>• Add competitive bidding metrics |
| 11 | **Party Concentration Signal** | 🥈 SILVER | ✅ ANALYTICS_PROD.SCORES | 250 CBSAs | County Assessors | • Expand county coverage<br>• Add entity tracking |
| 12 | **MLS Velocity (Legacy)** | 🥉 BRONZE | ✅ ANALYTICS_PROD.SCORES | 800 CBSAs | MLS (Legacy) | ⚠️ **SUPERSEDED by Signal #1**<br>• Deprecate after transition complete |

---

## 📊 Quality Tier Criteria

### 🥇 GOLD Tier (Production Ready)
**Criteria:**
- ✅ Data completeness ≥ 95%
- ✅ Data freshness ≤ 24 hours
- ✅ Coverage ≥ 500 CBSAs (or product-specific equivalent)
- ✅ Validity checks pass (0-100 scores, no outliers)
- ✅ Statistical segmentation implemented (PERCENT_RANK)
- ✅ Product differentiation (SF, MF, BTR, Affordable, Construction)
- ✅ Full governance compliance (registry, lineage, metadata)

**Current GOLD Signals (5):**
1. Velocity (MLS) - Real-time, high coverage
2. Absorption - Comprehensive market tracking
3. Competitiveness - Complete price intelligence
4. Ownership Concentration - Institutional tracking
5. Composite Quality Score - Framework-level validation

---

### 🥈 SILVER Tier (Near Production)
**Criteria:**
- ✅ Data completeness ≥ 85%
- ✅ Data freshness ≤ 72 hours
- ✅ Coverage ≥ 150 CBSAs (or product-specific)
- ⚠️ Some data sources still expanding
- ✅ Core functionality complete
- ⚠️ Product differentiation partial

**Current SILVER Signals (5):**
1. Supply Pressure - Expanding coverage
2. BTR Market Health - Building BTR data
3. Multifamily Health - Expanding MF sources
4. Ownership Competition - Adding transaction depth
5. Party Concentration - Expanding county coverage

**Path to GOLD:**
- Add 1-2 complementary data sources
- Expand coverage by 100-200 CBSAs
- Complete product differentiation
- Reduce data latency to daily

---

### 🥉 BRONZE Tier (In Development)
**Criteria:**
- ✅ Core model structure complete
- ⚠️ Data completeness 70-85%
- ⚠️ Coverage limited (<150 CBSAs)
- ⚠️ Data sources incomplete
- ⚠️ Quality validation ongoing

**Current BRONZE Signals (2):**
1. Listing Quality - Expanding quality dimensions
2. Affordable Housing - Building subsidy tracking

**Path to SILVER:**
- Add missing data sources
- Improve completeness to 85%+
- Expand coverage by 50-100 CBSAs
- Complete validation framework

---

## 🔄 Data Stage Progression

### Stage 1: Development (ANALYTICS.SCORES)
**Purpose:** Initial development, testing, validation  
**Criteria:** Model compiles, basic logic works  
**Current Count:** 17+ signals

**Signals in Development:**
- Climate Risk Signal (⏳ In Development)
- Economic Momentum Signal
- Price Momentum Signal
- Population Growth Signal
- Permit Activity Signal
- Rent Burden Signal
- GC Capacity Signal
- Absorption sub-signals (Intensity, Level, Momentum)

---

### Stage 2: Enhanced (ANALYTICS_PROD.SCORES with "_ENHANCED" suffix)
**Purpose:** Production deployment with MLS backstop/enhancements  
**Criteria:** 
- ✅ Feature metrics as primary
- ✅ MLS data as real-time backstop
- ✅ Improved coverage vs. base version
- ✅ Data source indicator included

**Enhanced Signals (2):**
1. **Velocity (MLS Enhanced)** - `fct_velocity_signal_mls_enhanced`
   - Primary: Feature metrics
   - Backstop: MLS real-time data
   - Coverage: Building from 893 CBSAs
   
2. **Supply Pressure (MLS Enhanced)** - `fct_supply_pressure_signal_mls_enhanced`
   - Primary: Feature metrics
   - Backstop: MLS inventory proxy
   - Coverage: Building from 3.3M+ records

---

### Stage 3: Production (ANALYTICS_PROD.SCORES, Dashboard Deployed)
**Purpose:** Live in dashboard, powering investment decisions  
**Criteria:**
- ✅ Deployed to ANALYTICS_PROD.SCORES
- ✅ Included in dashboard (signalConfig.ts)
- ✅ Score clamping (0-100) enforced
- ✅ Signal classification (HIGH/MEDIUM/LOW/CRITICAL)
- ✅ Registered in ADMIN.CATALOG.SIGNAL_REGISTRY
- ✅ Quality monitoring active

**Production Signals:** 12 (see table above)

---

## 📈 Progression Roadmap

### Immediate (Next 2 Weeks)
1. **Climate Risk Signal** → Move to ANALYTICS_PROD.SCORES
   - Currently in ANALYTICS.SCORES
   - Has data (18,201 rows)
   - Needs: Final validation + registry
   - Badge Target: 🥇 GOLD

2. **Listing Quality** → Upgrade BRONZE → SILVER
   - Add quality dimensions (price reasonability, photo quality)
   - Target coverage: 893 CBSAs (already achieved)
   - Badge Target: 🥈 SILVER

3. **Affordable Housing** → Upgrade BRONZE → SILVER
   - Integrate subsidy tracking from HUD
   - Add policy compliance metrics
   - Badge Target: 🥈 SILVER

---

### Short-Term (1-2 Months)
4. **Economic Momentum** → Deploy to Production
   - Currently: 1,108 rows in ANALYTICS_PROD.SCORES
   - Combine with labor market data
   - Badge Target: 🥇 GOLD

5. **Price Momentum** → Deploy to Production
   - Currently: 7.2M+ rows (excellent coverage)
   - Already in ANALYTICS_PROD.SCORES
   - Badge Target: 🥇 GOLD

6. **Supply Pressure** → Upgrade SILVER → GOLD
   - Expand coverage from 350 to 500+ CBSAs
   - Add permit pipeline tracking
   - Badge Target: 🥇 GOLD

---

### Medium-Term (2-4 Months)
7. **BTR Market Health** → Upgrade SILVER → GOLD
   - Expand from 50 to 100+ CBSAs
   - Add more BTR data sources (ALN, CoStar BTR)
   - Badge Target: 🥇 GOLD

8. **Multifamily Health** → Upgrade SILVER → GOLD
   - Expand from 150 to 300+ CBSAs
   - Integrate more CoStar/Axiometrics data
   - Badge Target: 🥇 GOLD

9. **Ownership Competition** → Upgrade SILVER → GOLD
   - Expand transaction data coverage
   - Add competitive bidding intelligence
   - Badge Target: 🥇 GOLD

---

## 🚦 Production Readiness Checklist

### ✅ Completed Requirements (All 12 Signals)
- [x] Model deployed to ANALYTICS_PROD.SCORES
- [x] Score clamping (0-100) implemented
- [x] Signal classification (HIGH/MEDIUM/LOW/CRITICAL)
- [x] Product differentiation (SF, MF, BTR, Affordable, Construction)
- [x] Component metrics exposed
- [x] Version tracking (model_version, created_at)
- [x] Geography rollup (ZIP→CBSA via crosswalk)
- [x] Quality flags (only VALID data used)
- [x] Dashboard integration (signalConfig.ts)
- [x] Signal registry entry (ADMIN.CATALOG.SIGNAL_REGISTRY)

### ⏳ In Progress
- [ ] Climate Risk Signal promotion to production
- [ ] Enhanced signal coverage expansion (VELOCITY, SUPPLY_PRESSURE)
- [ ] Quality tier upgrades (BRONZE → SILVER → GOLD)

### 📋 Future Enhancements
- [ ] Real-time alerting system
- [ ] Anomaly detection (statistical outliers)
- [ ] Forecast integration (predictive scores)
- [ ] Portfolio-specific benchmarking
- [ ] Cohort analysis (peer group comparisons)

---

## 📁 Data Flow & Infrastructure

### Source → Staging → Production Pipeline

```
TRANSFORM_PROD.FACT.* (Canonical Metrics)
           ↓
ANALYTICS.SCORES.FCT_*_SIGNAL (Development/Testing)
           ↓
ANALYTICS_PROD.SCORES.FCT_*_SIGNAL (Production)
           ↓
ANALYTICS_PROD.INTEL.VW_SIGNAL_SUMMARY_DASHBOARD (Dashboard View)
           ↓
Dashboard Application (React/TypeScript)
```

### Registry & Governance

```
ADMIN.CATALOG.SIGNAL_REGISTRY (Signal Definitions)
           ↓
ADMIN.CATALOG.METRIC_SIGNAL_REGISTRY (Metric→Signal Linkage)
           ↓
ADMIN.CATALOG.DIM_METRIC (Metric Catalog - 51,993 metrics)
           ↓
ANALYTICS_PROD.QUALITY.FCT_SIGNAL_QUALITY_MONITOR (Quality Tracking)
```

---

## 🎯 Success Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| **Production Signals** | 12 | 15 | 🟡 80% |
| **GOLD Tier Signals** | 5 | 10 | 🔴 50% |
| **SILVER Tier Signals** | 5 | 5 | 🟢 100% |
| **Average Coverage** | 494 CBSAs | 600 CBSAs | 🟡 82% |
| **Data Freshness** | Daily | Daily | 🟢 100% |
| **Quality Score** | 85% | 90% | 🟡 94% |
| **Dashboard Integration** | 12/12 | 15/15 | 🟢 100% |

---

## 📝 Key Findings

### Strengths ✅
1. **Strong Foundation:** All 12 dashboard signals deployed and operational
2. **Real-Time Data:** MLS integration provides daily updates
3. **Governance Compliance:** Full registry, lineage, and quality tracking
4. **Product Differentiation:** All signals support 5 product types
5. **Quality Framework:** Composite quality scoring active

### Opportunities 🎯
1. **Tier Upgrades:** 7 signals can be upgraded to GOLD with expanded coverage
2. **Coverage Expansion:** Average coverage can grow from 494 to 600+ CBSAs
3. **New Signals:** 5+ additional signals ready for production deployment
4. **Enhanced Versions:** MLS-enhanced signals provide real-time backstop
5. **Climate Risk:** Major signal ready for production (high strategic value)

### Risks ⚠️
1. **Data Dependency:** Some signals limited by vendor coverage (BTR, MF)
2. **Legacy Signal:** MLS Velocity (Legacy) needs deprecation plan
3. **Bronze Tier:** 2 signals need investment to reach production quality
4. **Coverage Gaps:** Some product types have limited geographic coverage

---

## 🔧 Recommended Actions

### Priority 1 (This Week)
1. **Deploy Climate Risk Signal** to production (high strategic value)
2. **Validate Enhanced Signals** (VELOCITY, SUPPLY_PRESSURE) - check coverage growth
3. **Create Tier Upgrade Plan** for Listing Quality and Affordable Housing

### Priority 2 (Next 2 Weeks)
4. **Expand BTR Data Sources** - add CoStar BTR, ALN coverage
5. **Add Multifamily Metrics** - integrate Axiometrics/REIS data
6. **Economic Momentum** - promote to production dashboard

### Priority 3 (Next Month)
7. **Price Momentum** - promote to production (already has 7M+ rows)
8. **Coverage Expansion** - target 600+ CBSA average across all signals
9. **Quality Tier Reviews** - quarterly assessment and upgrades

---

## 📞 Contact & Ownership

**Data Owner:** Pretium VP of Data & Analytics  
**Data Steward:** Analytics Engineering Team Lead  
**Technical Lead:** dbt Model Development Team  
**QA Lead:** Quality Monitoring & Alert Response

---

**Last Updated:** 2026-01-29  
**Document Version:** 1.0  
**Next Review:** 2026-02-05

---

*This report provides a comprehensive view of signal progression from development through production readiness. Use this to prioritize signal enhancements, track quality improvements, and plan strategic investments in data infrastructure.*

