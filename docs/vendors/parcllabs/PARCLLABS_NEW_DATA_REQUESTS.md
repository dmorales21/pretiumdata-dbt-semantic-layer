# ParclLabs API Enhancement - New Data Requests for STRATA

**Date**: 2026-01-28  
**Purpose**: Ideate and document new ParclLabs data requests for enhanced market intelligence  
**Target**: STRATA front-end real-time updates

---

## 🎯 Executive Summary

ParclLabs provides institutional-grade real estate data through their API. To enhance STRATA's real-time market intelligence capabilities, we recommend requesting the following additional data streams that complement our existing MLS (Cherre) and ownership data.

---

## 📋 Current ParclLabs Data Assets

### ✅ Currently Integrated
1. **Rent Listings** (`SOURCE_PROD.PARCLLABS.RENT_LISTINGS`)
   - Rental pricing by ZIP/bedroom
   - Unit-level characteristics (sqft, owner info)
   - **Frequency**: Real-time API updates

2. **Comps** (`SOURCE_PROD.PARCLLABS.COMPS`)
   - Comparable properties for Progress portfolio
   - Progress property-specific analysis
   - **Frequency**: On-demand

3. **Market Data** (`SOURCE_PROD.PARCLLABS.MARKET_DATA`)
   - Aggregated market metrics
   - **Frequency**: Monthly

4. **Ownership Data** (via Cherre integration)
   - Portfolio concentration (100-999, 1000+ units)
   - Housing stock counts
   - **Frequency**: Monthly

---

## 🚀 Recommended New Data Requests

### **1. Real-Time Price Feeds (Highest Priority)**

**Data Stream**: `parcl_price_feed_v2`

**Description**: Daily price index and price per square foot at ZIP/CBSA level

**Key Metrics**:
- `parcl_price_index`: Normalized price index (base = 100)
- `price_per_sqft_median`: Median $/sqft for SFR
- `price_change_30d`: 30-day price momentum (%)
- `price_change_90d`: 90-day price momentum (%)
- `price_volatility_30d`: 30-day rolling volatility

**Use Cases**:
- Real-time price momentum signals
- Cross-vendor validation with Cherre MLS pricing
- Price volatility scoring for risk assessment
- Sub-market pricing trends for STRATA dashboards

**Geography**: ZIP5, CBSA  
**Frequency**: Daily  
**Estimated Cost**: $500/month (Tier 2 API plan)

**Implementation**:
```sql
-- New cleaned model
models/20_cleaned/cleaned_parcllabs_price_feed.sql

-- New fact model
models/30_fact/fact_housing_pricing_parcllabs_price_feed.sql

-- Integration into signal
models/analytics_prod/scores/fct_parcllabs_price_momentum_signal.sql
```

---

### **2. Rental Market Velocity Metrics (High Priority)**

**Data Stream**: `parcl_rental_velocity`

**Description**: Rental listing absorption and turnover metrics

**Key Metrics**:
- `listing_to_lease_days`: Days from listing to lease signing
- `concession_rate_pct`: % of listings offering concessions
- `renewal_rate_pct`: Tenant renewal rate
- `rent_growth_yoy`: Year-over-year rent growth (%)
- `occupancy_rate_pct`: Estimated occupancy rate
- `absorption_velocity_score`: Proprietary absorption metric (0-100)

**Use Cases**:
- Rental velocity signal for BTR/MF markets
- Concession tracking (market stress indicator)
- Renewal rate forecasting for portfolio planning
- Occupancy benchmarking vs. Progress properties

**Geography**: ZIP5, CBSA  
**Frequency**: Weekly  
**Estimated Cost**: $300/month

**Implementation**:
```sql
-- New cleaned model
models/20_cleaned/cleaned_parcllabs_rental_velocity.sql

-- New fact model
models/30_fact/fact_housing_inventory_parcllabs_rental_velocity.sql

-- New signal
models/analytics_prod/scores/fct_parcllabs_rental_velocity_signal.sql
```

---

### **3. Investor Purchase Activity (High Priority)**

**Data Stream**: `parcl_investor_activity`

**Description**: Institutional and investor purchase activity tracking

**Key Metrics**:
- `investor_purchase_count`: # of investor purchases (monthly)
- `investor_purchase_volume_usd`: Total $ volume
- `investor_share_of_purchases_pct`: % of all purchases by investors
- `institutional_buyer_count`: # of institutional buyers (>100 properties)
- `avg_purchase_price_investor`: Avg price paid by investors
- `cash_purchase_rate_pct`: % of purchases all-cash

**Use Cases**:
- Institutional buying pressure signal
- Competition tracking for acquisitions
- Market heat detection (investor FOMO indicator)
- Cash buyer dominance (distressed market signal)

**Geography**: ZIP5, CBSA, County  
**Frequency**: Monthly  
**Estimated Cost**: $400/month

**Implementation**:
```sql
-- New cleaned model
models/20_cleaned/cleaned_parcllabs_investor_activity.sql

-- New fact model
models/30_fact/fact_housing_demand_parcllabs_investor_activity.sql

-- New signal
models/analytics_prod/scores/fct_parcllabs_investor_pressure_signal.sql
```

---

### **4. New Construction Pipeline (Medium Priority)**

**Data Stream**: `parcl_construction_pipeline`

**Description**: New construction tracking (permits to completion)

**Key Metrics**:
- `units_permitted`: Units permitted (monthly)
- `units_under_construction`: Active construction count
- `units_completed`: Completed units (monthly)
- `construction_pipeline_months`: Months of supply in pipeline
- `sfr_vs_mf_ratio`: SFR vs MF construction mix
- `completion_rate_pct`: % of permitted units completed

**Use Cases**:
- Supply pipeline signal
- Construction timing forecasts
- Market saturation risk assessment
- SFR vs MF competition analysis

**Geography**: CBSA, County  
**Frequency**: Monthly  
**Estimated Cost**: $250/month

**Implementation**:
```sql
-- New cleaned model
models/20_cleaned/cleaned_parcllabs_construction_pipeline.sql

-- New fact model
models/30_fact/fact_housing_supply_parcllabs_construction.sql

-- New signal
models/analytics_prod/scores/fct_parcllabs_supply_pipeline_signal.sql
```

---

### **5. Mortgage Rate Impact Index (Medium Priority)**

**Data Stream**: `parcl_mortgage_rate_sensitivity`

**Description**: Market-specific mortgage rate sensitivity

**Key Metrics**:
- `rate_sensitivity_index`: 0-100 (higher = more sensitive)
- `rate_change_impact_pct`: Expected demand change per 1% rate move
- `cash_buyer_ratio`: % of cash buyers (insulated from rates)
- `avg_dti_ratio`: Average debt-to-income ratio
- `affordability_index`: Housing affordability score (0-100)

**Use Cases**:
- Rate sensitivity signal for Fed policy impact
- Market resilience scoring
- Affordability crisis detection
- Investment strategy (rate-sensitive vs insulated markets)

**Geography**: CBSA  
**Frequency**: Quarterly  
**Estimated Cost**: $200/month

**Implementation**:
```sql
-- New cleaned model
models/20_cleaned/cleaned_parcllabs_rate_sensitivity.sql

-- New fact model
models/30_fact/fact_capital_cap_economy_parcllabs_rate_sensitivity.sql

-- New signal
models/analytics_prod/scores/fct_parcllabs_rate_sensitivity_signal.sql
```

---

## 💰 Cost-Benefit Analysis

| Data Stream | Priority | Monthly Cost | Use Cases | ROI |
|-------------|----------|--------------|-----------|-----|
| **Price Feeds** | Highest | $500 | Real-time price momentum, volatility scoring | ⭐⭐⭐⭐⭐ |
| **Rental Velocity** | High | $300 | Absorption tracking, concession monitoring | ⭐⭐⭐⭐⭐ |
| **Investor Activity** | High | $400 | Competition tracking, institutional pressure | ⭐⭐⭐⭐ |
| **Construction Pipeline** | Medium | $250 | Supply forecasting, saturation risk | ⭐⭐⭐⭐ |
| **Rate Sensitivity** | Medium | $200 | Fed policy impact, market resilience | ⭐⭐⭐ |
| **TOTAL** | | **$1,650/mo** | | |

**Annual Investment**: $19,800  
**Expected Value**: 5-7 new real-time signals, 15-20 new ML features, enhanced STRATA dashboard capabilities

---

## 📊 Implementation Roadmap

### **Phase 1: High-Priority Data (Months 1-2)**
1. ✅ Negotiate ParclLabs API access for price feeds & rental velocity
2. ✅ Create cleaned models for both data streams
3. ✅ Factize to canonical FACT tables
4. ✅ Build real-time signals (price momentum, rental velocity)
5. ✅ Integrate into STRATA dashboard

### **Phase 2: Investor & Supply Data (Months 3-4)**
1. ✅ Add investor activity & construction pipeline streams
2. ✅ Create cleaned + fact models
3. ✅ Build investor pressure & supply pipeline signals
4. ✅ Add to STRATA dashboard

### **Phase 3: Advanced Analytics (Months 5-6)**
1. ✅ Add mortgage rate sensitivity data
2. ✅ Build rate sensitivity signal
3. ✅ Create cross-vendor correlation analysis (ParclLabs vs Cherre MLS)
4. ✅ Implement auto-ML feature selection for new data

---

## 🔗 Data Governance

All new ParclLabs data will follow existing governance framework:

### **Access Tiers**:
- **Price Feeds**: `INTERNAL` (all Pretium teams)
- **Rental Velocity**: `INTERNAL` (all Pretium teams)
- **Investor Activity**: `RESTRICTED` (Investments, Analytics only)
- **Construction Pipeline**: `INTERNAL` (all teams)
- **Rate Sensitivity**: `INTERNAL` (all teams)

### **Sensitivity Levels**:
- **Price Feeds**: `LOW`
- **Rental Velocity**: `LOW`
- **Investor Activity**: `MEDIUM` (competitive intelligence)
- **Construction Pipeline**: `LOW`
- **Rate Sensitivity**: `LOW`

### **Quality Standards**:
- All data validated against Cherre MLS (where overlap exists)
- Outlier detection (z-score > 3)
- Freshness monitoring (stale if > 7 days old for daily feeds)
- Completeness thresholds (>80% non-null for key metrics)

---

## 🤖 AI/LLM Integration

All new data streams will be automatically ingested into STRATA's AI layer:

1. **Signal Registry** (`ADMIN.CATALOG.SIGNAL_REGISTRY`)
   - Auto-register new signals with weights and definitions

2. **Metric Registry** (`ADMIN.CATALOG.DIM_METRIC`)
   - Auto-catalog new ParclLabs metrics

3. **Feature Registry** (`ADMIN.CATALOG.FEATURE_REGISTRY`)
   - Track new ML features derived from ParclLabs data

4. **MCP Server** (ChatGPT Integration)
   - Expose new signals via `query_signal_scores()` function
   - Enable natural language queries: "What's the investor pressure in Austin?"

---

## 📞 Next Steps

1. **Immediate**: Schedule call with ParclLabs account manager to discuss data access
2. **Week 1**: Negotiate pricing & SLA for high-priority data streams
3. **Week 2**: Provision API keys & test data ingestion
4. **Week 3-4**: Build cleaned models & factization
5. **Week 5-6**: Deploy signals & integrate into STRATA dashboard

**Contact**: ParclLabs API Support - `api-support@parcllabs.com`  
**Account Manager**: [Your Account Manager Name]

---

## 📚 References

- [ParclLabs API Documentation](https://docs.parcllabs.com/api/v2)
- [STRATA Architecture](../STRATA_ARCHITECTURE.md)
- [Signal Framework Documentation](../ai/04_Functions/SIGNAL_FUNCTIONS.md)
- [Feature Engineering Standards](../FEATURE_ENGINEERING_STANDARDS.md)

