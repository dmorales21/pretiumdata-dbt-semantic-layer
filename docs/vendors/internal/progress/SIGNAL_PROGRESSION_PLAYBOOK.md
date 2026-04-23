# Signal Progression Playbook
**Purpose:** Step-by-step guide to progress each signal through quality tiers  
**Date:** 2026-01-29

---

## Overview

This playbook provides specific, actionable steps to progress each of the 12 deployed signals toward GOLD tier status and prepare 5 additional signals for production deployment.

---

## 📊 Current State Summary

**Dashboard Deployed:** 12 signals  
**Quality Distribution:**
- 🥇 GOLD (Production Ready): 5 signals (42%)
- 🥈 SILVER (Near Production): 5 signals (42%)
- 🥉 BRONZE (In Development): 2 signals (16%)

**Target State (60 days):**
- 🥇 GOLD: 10 signals (67%)
- 🥈 SILVER: 5 signals (33%)
- 🥉 BRONZE: 0 signals (0%)

---

## 🥇 GOLD TIER SIGNALS (Maintain Excellence)

### 1. Velocity Signal (MLS) ✅
**Current Status:** GOLD - Production Ready  
**Coverage:** 893 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_VELOCITY_SIGNAL_MLS_ENHANCED`

**Maintenance Actions:**
- ✅ Monitor daily refresh (last updated: 2026-01-29)
- ✅ Validate score distribution (0-100 range)
- ✅ Track coverage stability (target: maintain 893+)
- 🔄 Quarterly review of component weights

**Enhancement Opportunities:**
- Add predictive velocity forecasts (30/60/90 day)
- Integrate builder spec home inventory
- Add seasonal adjustment factors

---

### 2. Absorption Signal ✅
**Current Status:** GOLD - Production Ready  
**Coverage:** 893 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_ABSORPTION_SIGNAL_MLS_ENHANCED`

**Maintenance Actions:**
- ✅ Monitor pending ratio accuracy
- ✅ Validate inventory drawdown calculations
- 🔄 Monthly calibration of absorption thresholds

**Enhancement Opportunities:**
- Add product-type specific absorption rates
- Integrate pre-construction absorption
- Add cohort-based benchmarking

---

### 3. Competitiveness Signal ✅
**Current Status:** GOLD - Production Ready  
**Coverage:** 893 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_MARKET_COMPETITIVENESS_SIGNAL`

**Maintenance Actions:**
- ✅ Monitor bid/ask spread accuracy
- ✅ Validate price change patterns
- 🔄 Quarterly review of DOM thresholds

**Enhancement Opportunities:**
- Add competitive bid tracking
- Integrate institutional buyer activity
- Add market share concentration metrics

---

### 4. Ownership Concentration Signal ✅
**Current Status:** GOLD - Production Ready  
**Coverage:** 500 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_PARCLLABS_OWNERSHIP_SIGNAL`

**Maintenance Actions:**
- ✅ Monitor HHI calculation accuracy
- ✅ Validate institutional entity tracking
- 🔄 Monthly update of ownership records

**Enhancement Opportunities:**
- Expand coverage from 500 to 700+ CBSAs
- Add entity type classification (REIT, PE, Family Office)
- Add transaction velocity by owner type

---

### 5. Composite Quality Score ✅
**Current Status:** GOLD - Framework Level  
**Coverage:** All signals  
**Table:** `ANALYTICS_PROD.QUALITY.FCT_SIGNAL_QUALITY_MONITOR`

**Maintenance Actions:**
- ✅ Daily quality score calculation
- ✅ Alert on quality degradation
- 🔄 Weekly quality report to stakeholders

---

## 🥈 SILVER TIER SIGNALS (Path to GOLD)

### 6. Supply Pressure Signal ⬆️
**Current Status:** SILVER  
**Coverage:** 350 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_SUPPLY_PRESSURE_SIGNAL_MLS_ENHANCED`

**Path to GOLD (8 weeks):**

**Week 1-2: Expand Data Sources**
```sql
-- Add construction pipeline data
-- Source: Dodge Construction Network
-- Expected: +150 CBSAs
INSERT INTO supply_pressure_component 
SELECT cbsa_code, construction_pipeline_units, permit_valuation
FROM transform_prod.cleaned.dodge_construction_pipeline;
```

**Week 3-4: Add Permit Tracking**
```sql
-- Integrate building permit velocity
-- Source: Census Building Permits
-- Expected: +100 CBSAs
WITH permit_velocity AS (
  SELECT 
    cbsa_code,
    SUM(permit_units_3mo) / SUM(permit_units_12mo) AS velocity_ratio
  FROM transform_prod.fact.housing_hou_permits_all_ts
  GROUP BY cbsa_code
)
```

**Week 5-6: Enhance MLS Backstop**
- Improve months-of-supply proxy calculation
- Add new listing velocity component
- Validate against known markets

**Week 7-8: Quality Validation**
- Target: 95%+ completeness
- Target: 500+ CBSA coverage
- Target: Daily refresh confirmed

**GOLD Criteria Check:**
- ✅ Completeness ≥ 95%
- ✅ Coverage ≥ 500 CBSAs
- ✅ Freshness ≤ 24 hours
- ✅ 2+ data sources

**Estimated Effort:** 80 hours (2 analysts, 4 weeks)

---

### 7. BTR Market Health Signal ⬆️
**Current Status:** SILVER  
**Coverage:** 50 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_BTR_MARKET_SIGNAL`

**Path to GOLD (10 weeks):**

**Week 1-3: Expand BTR Data Sources**
```sql
-- Add CoStar BTR database
-- Expected: +30 CBSAs
-- Add John Burns BTR Tracker
-- Expected: +20 CBSAs
```

**Week 4-6: Add Operational Metrics**
- Integrate Yardi BTR occupancy data
- Add rent growth by BTR property age
- Add absorption rate for BTR lease-ups

**Week 7-8: Add Market Fundamentals**
- BTR vs MF rent premium tracking
- BTR construction pipeline visibility
- BTR institutional ownership concentration

**Week 9-10: Quality Validation**
- Target: 95%+ completeness
- Target: 100+ CBSA coverage
- Target: Quarterly refresh confirmed

**GOLD Criteria Check:**
- ✅ Completeness ≥ 95%
- ⚠️ Coverage ≥ 100 CBSAs (BTR-specific threshold)
- ✅ Freshness ≤ 72 hours (quarterly acceptable for BTR)
- ✅ 3+ data sources (CoStar, Yardi, John Burns)

**Estimated Effort:** 120 hours (2 analysts, 6 weeks)

---

### 8. Multifamily Health Signal ⬆️
**Current Status:** SILVER  
**Coverage:** 150 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_MULTIFAMILY_HEALTH_SIGNAL`

**Path to GOLD (8 weeks):**

**Week 1-2: Add CoStar Comprehensive Data**
```sql
-- Expand CoStar apartment inventory
-- Expected: +100 CBSAs
-- Add submarket granularity
```

**Week 3-4: Add Axiometrics/RealPage**
- Add real-time occupancy feeds
- Add asking vs effective rent tracking
- Add concession tracking

**Week 5-6: Add Operational Benchmarks**
- Add NOI growth by property class (A/B/C)
- Add expense ratio benchmarking
- Add renovation impact tracking

**Week 7-8: Quality Validation**
- Target: 95%+ completeness
- Target: 250+ CBSA coverage
- Target: Monthly refresh confirmed

**GOLD Criteria Check:**
- ✅ Completeness ≥ 95%
- ✅ Coverage ≥ 250 CBSAs
- ✅ Freshness ≤ 30 days (monthly acceptable for MF ops)
- ✅ 3+ data sources

**Estimated Effort:** 100 hours (2 analysts, 5 weeks)

---

### 9. Ownership Competition Signal ⬆️
**Current Status:** SILVER  
**Coverage:** 400 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_OWNERSHIP_PARTY_COMPETITION_SIGNAL`

**Path to GOLD (6 weeks):**

**Week 1-2: Expand Transaction Data**
```sql
-- Add CoreLogic institutional buyer flags
-- Expected: +100 CBSAs
-- Add Parcl Labs buyer intelligence
-- Expected: same markets, deeper data
```

**Week 3-4: Add Competitive Intelligence**
- Bid frequency by buyer type
- Time-on-market by buyer competition level
- Premium paid vs list price by competition

**Week 5-6: Quality Validation**
- Target: 95%+ completeness
- Target: 500+ CBSA coverage
- Target: Monthly refresh confirmed

**GOLD Criteria Check:**
- ✅ Completeness ≥ 95%
- ✅ Coverage ≥ 500 CBSAs
- ✅ Freshness ≤ 30 days
- ✅ 2+ data sources

**Estimated Effort:** 60 hours (1 analyst, 6 weeks)

---

### 10. Party Concentration Signal ⬆️
**Current Status:** SILVER  
**Coverage:** 250 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_OWNERSHIP_PARTY_CONCENTRATION_SIGNAL`

**Path to GOLD (8 weeks):**

**Week 1-3: Expand County Assessor Coverage**
- Add 150+ counties (targeting high-growth markets)
- Expected: +150 CBSAs

**Week 4-5: Add Entity Tracking**
```sql
-- Link ownership entities across properties
-- Add parent company roll-ups
-- Track portfolio size by entity
```

**Week 6-7: Add Market Share Metrics**
- Market share by top 10 entities per CBSA
- Market share trends (6mo/12mo changes)
- New entrant tracking

**Week 8: Quality Validation**
- Target: 95%+ completeness
- Target: 400+ CBSA coverage
- Target: Quarterly refresh confirmed

**GOLD Criteria Check:**
- ✅ Completeness ≥ 95%
- ⚠️ Coverage ≥ 400 CBSAs (data-dependent)
- ✅ Freshness ≤ 90 days (quarterly acceptable)
- ✅ Entity linkage complete

**Estimated Effort:** 80 hours (2 analysts, 4 weeks)

---

## 🥉 BRONZE TIER SIGNALS (Path to SILVER)

### 11. Listing Quality Signal ⬆️
**Current Status:** BRONZE  
**Coverage:** 893 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_LISTING_QUALITY_SIGNAL`

**Path to SILVER (4 weeks):**

**Week 1: Add Quality Dimensions**
```sql
-- Current: Expired/withdrawn ratio, DOM
-- Add: Price reasonability (list vs comparable sales)
ALTER TABLE fct_listing_quality_signal 
ADD COLUMN component_price_reasonability FLOAT;

-- Add: Photo quality score (photo count, quality flags)
ADD COLUMN component_photo_quality FLOAT;

-- Add: Description completeness
ADD COLUMN component_description_completeness FLOAT;
```

**Week 2: Implement Validation Rules**
- Price reasonability: flag listings >20% above comparables
- Photo quality: require 5+ photos for quality flag
- Description: require 50+ words for completeness

**Week 3: Recalibrate Weights**
```sql
signal_score_universal = (
  expired_withdrawn_ratio * 0.30 +
  dom_normalized * 0.25 +
  price_reasonability * 0.25 +
  photo_quality * 0.10 +
  description_completeness * 0.10
)
```

**Week 4: Quality Validation**
- Target: 85%+ completeness
- Target: 893 CBSA coverage maintained
- Target: Daily refresh confirmed

**SILVER Criteria Check:**
- ✅ Completeness ≥ 85%
- ✅ Coverage ≥ 150 CBSAs (already 893)
- ✅ Freshness ≤ 72 hours (daily achieved)
- ✅ 5 quality dimensions

**Estimated Effort:** 40 hours (1 analyst, 4 weeks)

---

### 12. Affordable Housing Signal ⬆️
**Current Status:** BRONZE  
**Coverage:** 300 CBSAs  
**Table:** `ANALYTICS_PROD.SCORES.FCT_AFFORDABLE_HOUSING_SIGNAL`

**Path to SILVER (6 weeks):**

**Week 1-2: Add HUD Subsidy Tracking**
```sql
-- Integrate HUD LIHTC database
-- Expected: Same 300 CBSAs, deeper subsidy data
INSERT INTO affordable_housing_component
SELECT 
  cbsa_code,
  COUNT(DISTINCT project_id) AS lihtc_project_count,
  SUM(total_units) AS lihtc_units,
  AVG(placed_in_service_year) AS avg_project_age
FROM transform_prod.cleaned.hud_lihtc_projects
GROUP BY cbsa_code;
```

**Week 3-4: Add Voucher Program Data**
```sql
-- Add Section 8 voucher utilization
-- Add payment standard tracking
-- Add voucher wait list indicators
```

**Week 5: Add Policy Compliance Metrics**
- Rent ceiling compliance (% at/below FMR)
- Occupancy requirements (income verification)
- Property condition standards (REAC scores)

**Week 6: Quality Validation**
- Target: 85%+ completeness
- Target: 300+ CBSA coverage maintained
- Target: Quarterly refresh confirmed

**SILVER Criteria Check:**
- ✅ Completeness ≥ 85%
- ✅ Coverage ≥ 150 CBSAs (already 300)
- ✅ Freshness ≤ 90 days (quarterly acceptable)
- ✅ 3+ subsidy program dimensions

**Estimated Effort:** 60 hours (1 analyst, 6 weeks)

---

## 🆕 NEW SIGNALS FOR PRODUCTION DEPLOYMENT

### 13. Climate Risk Signal 🚀 PRIORITY 1
**Current Status:** Development (ANALYTICS.SCORES)  
**Coverage:** 18,201 records  
**Source:** First Street Foundation, FEMA NRI

**Deployment Path (2 weeks):**

**Week 1: Validation & Testing**
```sql
-- Validate data quality
SELECT 
  COUNT(*) as total_rows,
  COUNT(DISTINCT geo_id) as unique_geos,
  AVG(signal_score_universal) as avg_score,
  MIN(date_reference) as min_date,
  MAX(date_reference) as max_date
FROM analytics.scores.fct_climate_risk_signal;

-- Check for outliers
SELECT * FROM analytics.scores.fct_climate_risk_signal
WHERE signal_score_universal NOT BETWEEN 0 AND 100;
```

**Week 2: Promote to Production**
```bash
# Move model to analytics_prod directory
mv models/analytics/scores/fct_climate_risk_signal.sql \
   models/analytics_prod/scores/fct_climate_risk_signal.sql

# Update dbt_project.yml schema mapping
# Run production build
dbt run --select fct_climate_risk_signal --target prod

# Register in signal catalog
INSERT INTO admin.catalog.signal_registry (
  signal_id, signal_name, category, status, ...
) VALUES (
  'CLIMATE_RISK', 'Climate Risk Signal', 'RISK', 'ACTIVE', ...
);
```

**Badge Target:** 🥇 GOLD (high strategic value, comprehensive data)

**Estimated Effort:** 20 hours (1 analyst, 2 weeks)

---

### 14. Economic Momentum Signal 🚀 PRIORITY 2
**Current Status:** Production (ANALYTICS_PROD.SCORES), not in dashboard  
**Coverage:** 1,108 CBSAs  
**Table:** `FCT_ECONOMIC_MOMENTUM_SIGNAL`

**Dashboard Integration (1 week):**

**Step 1: Add to signalConfig.ts**
```typescript
{
  id: 'economic_momentum',
  name: 'Economic Momentum Signal',
  description: 'Population growth, income growth, spending growth composite',
  source: 'MARKERR Population, AMREG Income/Spending',
  frequency: 'Monthly',
  coverage: '1108',
  model: 'Weighted Composite Index',
  quality_tier: 'GOLD',
  is_ready: true,
  table_name: 'fct_economic_momentum_signal'
}
```

**Step 2: Update Dashboard Query**
- Add to signal summary view
- Add to circular signal grid (expand to 13 signals)

**Badge Target:** 🥇 GOLD (strong coverage, established model)

**Estimated Effort:** 8 hours (1 developer, 1 week)

---

### 15. Price Momentum Signal 🚀 PRIORITY 3
**Current Status:** Production (ANALYTICS_PROD.SCORES), not in dashboard  
**Coverage:** 7,179,862 records (7.2M+!)  
**Table:** `FCT_PRICE_MOMENTUM_SIGNAL`

**Dashboard Integration (1 week):**

**Step 1: Add to signalConfig.ts**
```typescript
{
  id: 'price_momentum',
  name: 'Price Momentum Signal',
  description: 'Home price appreciation velocity and acceleration',
  source: 'Redfin Sale & List Prices',
  frequency: 'Monthly',
  coverage: '50000+',
  model: 'MoM & YoY Growth Composite',
  quality_tier: 'GOLD',
  is_ready: true,
  table_name: 'fct_price_momentum_signal'
}
```

**Badge Target:** 🥇 GOLD (exceptional coverage, proven methodology)

**Estimated Effort:** 8 hours (1 developer, 1 week)

---

### 16. Population Growth Signal
**Current Status:** Production (ANALYTICS_PROD.SCORES), not in dashboard  
**Coverage:** 4,720,029 records (4.7M+!)  
**Table:** `FCT_POPULATION_GROWTH_SIGNAL`

**Dashboard Integration (1 week):**
- Same process as signals 14-15

**Badge Target:** 🥇 GOLD (massive coverage, fundamental demand driver)

---

### 17. Permit Activity Signal
**Current Status:** Production (ANALYTICS_PROD.SCORES), not in dashboard  
**Coverage:** 137,793 records  
**Table:** `FCT_PERMIT_ACTIVITY_SIGNAL`

**Dashboard Integration (1 week):**
- Same process as signals 14-15

**Badge Target:** 🥈 SILVER (good coverage, supply-side indicator)

---

## 📋 Master Timeline (Next 90 Days)

### Month 1 (Weeks 1-4)
**Week 1:**
- 🚀 Deploy Climate Risk Signal to production
- 🚀 Integrate Economic Momentum to dashboard
- ⬆️ Start Listing Quality upgrade (BRONZE → SILVER)

**Week 2:**
- 🚀 Integrate Price Momentum to dashboard
- ⬆️ Start Affordable Housing upgrade (BRONZE → SILVER)

**Week 3:**
- ⬆️ Start Supply Pressure expansion (SILVER → GOLD)
- ⬆️ Continue Listing Quality development

**Week 4:**
- ⬆️ Continue all active upgrades
- 📊 Sprint review & priority adjustment

---

### Month 2 (Weeks 5-8)
**Week 5:**
- ✅ Complete Listing Quality upgrade → SILVER
- ⬆️ Start BTR Market Health expansion (SILVER → GOLD)
- ⬆️ Start Multifamily Health expansion (SILVER → GOLD)

**Week 6:**
- ✅ Complete Affordable Housing upgrade → SILVER
- ⬆️ Start Ownership Competition expansion (SILVER → GOLD)

**Week 7:**
- ⬆️ Continue BTR, MF, Competition expansions
- ⬆️ Start Party Concentration expansion (SILVER → GOLD)

**Week 8:**
- ✅ Complete Supply Pressure upgrade → GOLD
- 📊 Sprint review & priority adjustment

---

### Month 3 (Weeks 9-12)
**Week 9:**
- ✅ Complete BTR Market Health upgrade → GOLD
- ⬆️ Continue MF, Competition, Party expansions

**Week 10:**
- ✅ Complete Multifamily Health upgrade → GOLD

**Week 11:**
- ✅ Complete Ownership Competition upgrade → GOLD
- ✅ Complete Party Concentration upgrade → GOLD

**Week 12:**
- 📊 Final validation & testing
- 📄 Update documentation
- 🎉 **Target State Achieved: 10 GOLD, 5 SILVER, 0 BRONZE**

---

## 📊 Resource Requirements

### Personnel (90-Day Program)
- **2 Senior Data Analysts** (full-time): Data source integration, model development
- **1 Analytics Engineer** (full-time): dbt model development, testing, deployment
- **1 Data Engineer** (50% time): Data pipeline setup, Snowflake optimization
- **1 Frontend Developer** (25% time): Dashboard integration
- **1 QA Analyst** (25% time): Quality validation, testing

**Total Effort:** ~1,200 hours over 90 days

---

### Budget Estimates

**Data Licenses:**
- CoStar BTR Database: $15K/year
- Dodge Construction Network: $12K/year
- John Burns BTR Tracker: $8K/year
- Axiometrics/RealPage Feeds: $10K/year
- **Total:** $45K/year

**Personnel Costs:**
- Labor: $150K for 90-day program

**Infrastructure:**
- Snowflake compute: $5K/month increase
- **Total:** $15K for 90 days

**Grand Total:** ~$210K for complete signal progression program

---

## 🎯 Success Metrics

| Metric | Baseline | Target | Status |
|--------|----------|--------|--------|
| **GOLD Tier Signals** | 5 | 10 | 🎯 In Progress |
| **SILVER Tier Signals** | 5 | 5 | ✅ Maintain |
| **BRONZE Tier Signals** | 2 | 0 | 🎯 Phase Out |
| **Dashboard Signals** | 12 | 17 | 🎯 +5 New |
| **Average Coverage** | 494 CBSAs | 650 CBSAs | 🎯 +32% |
| **Data Freshness** | Daily | Real-Time | 🎯 Enhance |
| **Quality Score** | 85% | 95% | 🎯 +10pts |

---

## 📝 Governance & Approvals

**Approval Chain:**
1. **Technical Review:** Analytics Engineering Lead
2. **Business Review:** VP of Data & Analytics
3. **Budget Approval:** CFO (for data licenses)
4. **Go-Live Approval:** CTO

**Quality Gates:**
- All signals must pass completeness checks (85%+ for SILVER, 95%+ for GOLD)
- All signals must maintain or improve coverage
- All signals must meet or beat refresh frequency targets
- All signals must have full documentation and lineage tracking

---

**Document Owner:** Analytics Engineering Team  
**Last Updated:** 2026-01-29  
**Next Review:** 2026-02-05  
**Version:** 1.0

---

*This playbook provides actionable, time-bound steps to achieve signal progression goals. Follow this roadmap to systematically upgrade signal quality and expand production capabilities.*

