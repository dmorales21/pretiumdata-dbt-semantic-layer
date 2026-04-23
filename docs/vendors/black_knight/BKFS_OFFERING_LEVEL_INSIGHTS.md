# BKFS Signal Integration - Offering-Level Insights

**Date**: 2026-01-29  
**Purpose**: Map BKFS signals to specific mortgage offerings with offering-level monitoring views  
**Status**: Offering-specific logic and views designed

---

## Executive Summary

BKFS signals provide **ground-truth loan performance data** that directly supports mortgage offering gate decisions. This document maps each offering to relevant BKFS signals and creates offering-specific monitoring views.

**Key Innovation**: Offering-level signal aggregation enables **automated gate trigger alerts** based on actual loan performance data.

---

## I. Mortgage Offering → BKFS Signal Mapping

### REM (Residential Mortgage) Offerings

| Offering | Primary Signals | Gate Integration | Alert Thresholds |
|----------|----------------|------------------|------------------|
| **SELENE_PRIMARY_PERFORMING_V1** | DRG (primary), PVG, LMG | Gate 4: Ongoing operations | DRG >70 = delinquency spike alert |
| **DEEPHAVEN_NON_PRIME_V1** | DRG (critical), CMG, DPG, DOG | Gate 2: Credit layering, Gate 4: Monitoring | DRG >75, CMG >70 = credit migration |
| **DEEPHAVEN_NON_QM_EXPANDED_PRIME_V1** | CMG (critical), DRG, DPG | Gate 2: Compensating factors, Gate 4: Monitoring | CMG >70 = silent credit migration |
| **DEEPHAVEN_DSCR_INVESTOR_V1** | DRG, RRG, FRG | Gate 4: DSCR monitoring | DRG >65, FRG >60 = rental stress |

### RES (Residential Servicing) Offerings

| Offering | Primary Signals | Gate Integration | Alert Thresholds |
|----------|----------------|------------------|------------------|
| **SELENE_PRIMARY_PERFORMING_V1** | DRG, PVG, LMG | Gate 1: Portfolio health, Gate 4: Operations | DRG >70 or PVG >80 = fee duration risk |
| **SELENE_SPECIAL_SERVICING** | DPG, LMG, RRG, FRG | Gate 4: Loss mitigation, Gate 8: REO disposition | LMG effectiveness <50 = poor workouts |

---

## II. Offering-Specific Signal Views

### View 1: SELENE Primary Performing - Portfolio Health Dashboard

**Purpose**: Monitor servicing portfolio health with BKFS ground-truth data

**File**: `vw_bkfs_selene_primary_performing_health.sql`

```sql
-- =======================================================================
-- BI VIEW: SELENE Primary Performing - Portfolio Health Dashboard
-- Purpose: Monitor servicing portfolio health using BKFS signals
-- Alert Triggers: DRG spike, PVG acceleration, LMG volume increase
-- =======================================================================

{{ config(
    materialized='view',
    schema='bi',
    tags=['bi', 'bkfs', 'selene', 'servicing', 'offering']
) }}

WITH drg_portfolio AS (
    -- Delinquency Risk by geography (portfolio risk)
    SELECT
        date_reference,
        geo_id,
        geo_level_code,
        signal_score_universal AS delinquency_risk_score,
        signal AS delinquency_signal,
        component_30day_dq_rate,
        component_60day_dq_rate,
        component_90plus_dq_rate,
        component_roll_rate_value,
        component_cure_rate_value,
        sample_size AS loan_count
    FROM {{ ref('fct_delinquency_risk_signal') }}
),

offering_gates AS (
    -- Map to SELENE offering gates
    SELECT
        date_reference,
        geo_id,
        geo_level_code,
        
        -- =================================================================
        -- GATE 1: Portfolio Health (DQ / CPR)
        -- =================================================================
        delinquency_risk_score,
        delinquency_signal,
        
        -- Gate 1 assessment
        CASE 
            WHEN delinquency_risk_score >= 70 
            THEN 'FAIL: DQ trend implies transition to special servicing'
            WHEN delinquency_risk_score >= 60
            THEN 'WATCH: DQ elevated, monitor closely'
            WHEN delinquency_risk_score >= 40
            THEN 'PASS: DQ within policy'
            ELSE 'PASS: Strong performance'
        END AS gate_1_portfolio_health_status,
        
        -- =================================================================
        -- GATE 4: Ongoing Servicing Operations (Triggers)
        -- =================================================================
        
        -- Trigger 1: Delinquency spike
        CASE 
            WHEN delinquency_risk_score - LAG(delinquency_risk_score) OVER (PARTITION BY geo_id ORDER BY date_reference) > 15
            THEN TRUE ELSE FALSE
        END AS trigger_delinquency_spike,
        
        -- Trigger 2: Roll rate acceleration
        CASE 
            WHEN component_roll_rate_value > 30  -- >30% roll rate
            THEN TRUE ELSE FALSE
        END AS trigger_roll_rate_acceleration,
        
        -- Trigger 3: Cure rate deterioration
        CASE 
            WHEN component_cure_rate_value < 40  -- <40% cure rate
            THEN TRUE ELSE FALSE
        END AS trigger_cure_rate_deterioration,
        
        -- =================================================================
        -- SERVICING COST INDICATORS
        -- =================================================================
        
        -- Cost-to-serve proxy (higher DQ = higher cost)
        CASE 
            WHEN component_90plus_dq_rate > 5.0 THEN 'HIGH_COST'  -- >5% serious DQ
            WHEN component_60day_dq_rate + component_90plus_dq_rate > 3.0 THEN 'ELEVATED_COST'
            ELSE 'NORMAL_COST'
        END AS cost_to_serve_indicator,
        
        -- Fee duration risk (from prepayment - placeholder for PVG)
        NULL AS fee_duration_risk,  -- Will add when PVG implemented
        
        -- Operational load score (higher = more work)
        (component_60day_dq_rate * 2 + component_90plus_dq_rate * 5 + (100 - component_cure_rate_value)) / 3 AS operational_load_score,
        
        -- =================================================================
        -- PORTFOLIO METRICS
        -- =================================================================
        component_30day_dq_rate AS early_dq_rate,
        component_60day_dq_rate AS moderate_dq_rate,
        component_90plus_dq_rate AS serious_dq_rate,
        component_roll_rate_value AS roll_rate,
        component_cure_rate_value AS cure_rate,
        loan_count,
        
        -- Period-over-period changes
        delinquency_risk_score - LAG(delinquency_risk_score) OVER (PARTITION BY geo_id ORDER BY date_reference) AS drg_change_mom
        
    FROM drg_portfolio
),

portfolio_summary AS (
    -- Aggregate to portfolio level (weighted by loan count)
    SELECT
        date_reference,
        
        -- Portfolio-weighted signal score
        SUM(delinquency_risk_score * loan_count) / NULLIF(SUM(loan_count), 0) AS portfolio_weighted_drg,
        
        -- Portfolio-weighted DQ rates
        SUM(early_dq_rate * loan_count) / NULLIF(SUM(loan_count), 0) AS portfolio_30day_dq_rate,
        SUM(moderate_dq_rate * loan_count) / NULLIF(SUM(loan_count), 0) AS portfolio_60day_dq_rate,
        SUM(serious_dq_rate * loan_count) / NULLIF(SUM(loan_count), 0) AS portfolio_90plus_dq_rate,
        SUM(cure_rate * loan_count) / NULLIF(SUM(loan_count), 0) AS portfolio_cure_rate,
        
        -- Portfolio size
        SUM(loan_count) AS total_portfolio_loans,
        
        -- Alert counts
        SUM(CASE WHEN trigger_delinquency_spike THEN 1 ELSE 0 END) AS market_count_dq_spike,
        SUM(CASE WHEN trigger_roll_rate_acceleration THEN 1 ELSE 0 END) AS market_count_roll_acceleration,
        SUM(CASE WHEN trigger_cure_rate_deterioration THEN 1 ELSE 0 END) AS market_count_cure_deterioration,
        
        -- Gate status distribution
        SUM(CASE WHEN gate_1_portfolio_health_status LIKE 'FAIL:%' THEN loan_count ELSE 0 END) / NULLIF(SUM(loan_count), 0) * 100 AS pct_loans_failing_gate_1,
        SUM(CASE WHEN gate_1_portfolio_health_status LIKE 'WATCH:%' THEN loan_count ELSE 0 END) / NULLIF(SUM(loan_count), 0) * 100 AS pct_loans_watch_gate_1,
        
        -- Cost indicators
        SUM(CASE WHEN cost_to_serve_indicator = 'HIGH_COST' THEN loan_count ELSE 0 END) / NULLIF(SUM(loan_count), 0) * 100 AS pct_loans_high_cost,
        AVG(operational_load_score) AS avg_operational_load
        
    FROM offering_gates
    GROUP BY date_reference
)

SELECT
    og.date_reference,
    og.geo_id,
    og.geo_level_code,
    
    -- Offering context
    'SELENE_PRIMARY_PERFORMING_V1' AS offering_id,
    'RES' AS product_line,
    'SERVICING' AS investment_vehicle,
    
    -- Gate assessments
    og.gate_1_portfolio_health_status,
    
    -- Trigger flags
    og.trigger_delinquency_spike,
    og.trigger_roll_rate_acceleration,
    og.trigger_cure_rate_deterioration,
    
    -- Cost indicators
    og.cost_to_serve_indicator,
    og.operational_load_score,
    
    -- Performance metrics
    og.delinquency_risk_score,
    og.early_dq_rate,
    og.moderate_dq_rate,
    og.serious_dq_rate,
    og.roll_rate,
    og.cure_rate,
    og.loan_count,
    og.drg_change_mom,
    
    -- Portfolio context
    ps.portfolio_weighted_drg,
    ps.portfolio_30day_dq_rate,
    ps.portfolio_60day_dq_rate,
    ps.portfolio_90plus_dq_rate,
    ps.portfolio_cure_rate,
    ps.total_portfolio_loans,
    ps.market_count_dq_spike,
    ps.market_count_roll_acceleration,
    ps.market_count_cure_deterioration,
    ps.pct_loans_failing_gate_1,
    ps.pct_loans_watch_gate_1,
    ps.pct_loans_high_cost,
    ps.avg_operational_load,
    
    -- Recommendations
    CASE 
        WHEN og.trigger_delinquency_spike OR og.trigger_roll_rate_acceleration
        THEN 'IMMEDIATE_ACTION: Increase borrower outreach, review loss mitigation capacity'
        
        WHEN og.trigger_cure_rate_deterioration
        THEN 'ASSESS: Review workout strategies, may need servicer training'
        
        WHEN og.delinquency_risk_score >= 60
        THEN 'MONITOR: Elevated delinquency risk, track weekly'
        
        WHEN og.cost_to_serve_indicator = 'HIGH_COST'
        THEN 'COST_REVIEW: High operational load, assess fee adequacy'
        
        ELSE 'NORMAL_OPERATIONS: Continue standard monitoring'
    END AS operational_recommendation
    
FROM offering_gates og
CROSS JOIN portfolio_summary ps
    ON og.date_reference = ps.date_reference
ORDER BY og.date_reference DESC, og.delinquency_risk_score DESC
```

---

### View 2: DEEPHAVEN Non-QM - Credit Migration Monitor

**Purpose**: Monitor "expanded-prime" to "non-prime" credit migration (silent credit migration)

**File**: `vw_bkfs_deephaven_non_qm_credit_migration.sql`

```sql
-- =======================================================================
-- BI VIEW: DEEPHAVEN Non-QM - Credit Migration Monitor
-- Purpose: Monitor silent credit migration in expanded-prime portfolios
-- Alert Triggers: CMG spike, DRG elevation, payment behavior deterioration
-- =======================================================================

{{ config(
    materialized='view',
    schema='bi',
    tags=['bi', 'bkfs', 'deephaven', 'mortgage', 'offering']
) }}

WITH drg_data AS (
    SELECT
        date_reference,
        geo_id,
        signal_score_universal AS delinquency_risk_score,
        component_payment_vol_value AS payment_volatility,
        component_first_dq_rate AS first_time_dq_rate,
        component_30day_dq_rate,
        component_60day_dq_rate,
        component_90plus_dq_rate
    FROM {{ ref('fct_delinquency_risk_signal') }}
),

offering_gates AS (
    SELECT
        d.date_reference,
        d.geo_id,
        
        -- =================================================================
        -- GATE 2: Underwrite - Exception Governance / Compensating Factors
        -- =================================================================
        -- Use CMG (when available) or payment behavior as proxy
        
        -- Credit migration proxy (using payment behavior until CMG ready)
        CASE 
            WHEN d.first_time_dq_rate > 3.0  -- >3% new delinquencies
            THEN 'HIGH_MIGRATION_RISK'
            WHEN d.payment_volatility > 3.0  -- High payment instability
            THEN 'MODERATE_MIGRATION_RISK'
            ELSE 'STABLE_CREDIT_PROFILE'
        END AS credit_migration_indicator,
        
        -- Gate 2 assessment
        CASE 
            WHEN d.delinquency_risk_score >= 70 AND d.payment_volatility > 3
            THEN 'DENY: Multiple adverse layers without offsets (credit migrating)'
            WHEN d.delinquency_risk_score >= 60
            THEN 'REQUIRE_COMPENSATING_FACTORS: Elevated risk, need reserves/clean history'
            ELSE 'PASS: Credit profile stable'
        END AS gate_2_underwrite_status,
        
        -- =================================================================
        -- GATE 4: Ongoing Monitoring (Triggers)
        -- =================================================================
        
        -- Trigger: Silent credit migration detected
        CASE 
            WHEN d.first_time_dq_rate - LAG(d.first_time_dq_rate) OVER (PARTITION BY d.geo_id ORDER BY d.date_reference) > 1.5
            THEN TRUE ELSE FALSE
        END AS trigger_silent_credit_migration,
        
        -- Trigger: Payment behavior deterioration
        CASE 
            WHEN d.payment_volatility > 3.5
            THEN TRUE ELSE FALSE
        END AS trigger_payment_behavior_deterioration,
        
        -- Trigger: Affordability degradation (placeholder - needs external affordability data)
        NULL AS trigger_affordability_degradation,
        
        -- =================================================================
        -- RISK INDICATORS
        -- =================================================================
        d.delinquency_risk_score,
        d.payment_volatility,
        d.first_time_dq_rate,
        d.component_30day_dq_rate,
        d.component_60day_dq_rate,
        d.component_90plus_dq_rate,
        
        -- Silent credit migration score (composite)
        (d.first_time_dq_rate * 0.40 + 
         d.payment_volatility * 0.30 + 
         d.component_60day_dq_rate * 0.30) AS silent_migration_score
        
    FROM drg_data d
)

SELECT
    date_reference,
    geo_id,
    
    -- Offering context
    'DEEPHAVEN_NON_QM_EXPANDED_PRIME_V1' AS offering_id,
    'REM' AS product_line,
    'DEBT' AS investment_vehicle,
    'SF' AS product_type,
    
    -- Gate assessments
    gate_2_underwrite_status,
    
    -- Credit migration indicators
    credit_migration_indicator,
    silent_migration_score,
    
    -- Trigger flags
    trigger_silent_credit_migration,
    trigger_payment_behavior_deterioration,
    trigger_affordability_degradation,
    
    -- Performance metrics
    delinquency_risk_score,
    payment_volatility,
    first_time_dq_rate,
    component_30day_dq_rate,
    component_60day_dq_rate,
    component_90plus_dq_rate,
    
    -- Risk tier classification
    CASE 
        WHEN silent_migration_score >= 5.0 THEN 'TIER_1_AVOID'           -- Significant migration
        WHEN silent_migration_score >= 3.0 THEN 'TIER_2_REDUCE_EXPOSURE' -- Moderate migration
        WHEN silent_migration_score >= 1.5 THEN 'TIER_3_MONITOR'         -- Early signs
        ELSE 'TIER_4_STABLE'                                              -- Stable
    END AS risk_tier,
    
    -- Underwriting adjustments
    CASE 
        WHEN silent_migration_score >= 5.0
        THEN 'TIGHTEN: Increase FICO floor to 680+, reduce LTV to 75%, require 6mo reserves'
        
        WHEN silent_migration_score >= 3.0
        THEN 'ADJUST: Increase FICO floor to 660+, reduce LTV to 77%, require 3mo reserves'
        
        WHEN silent_migration_score >= 1.5
        THEN 'MONITOR: Standard underwriting with enhanced compensating factor review'
        
        ELSE 'STANDARD: Normal underwriting parameters'
    END AS underwriting_recommendation,
    
    -- Portfolio action
    CASE 
        WHEN trigger_silent_credit_migration
        THEN 'ALERT: Silent credit migration detected - review recent originations in this market'
        
        WHEN trigger_payment_behavior_deterioration
        THEN 'PROACTIVE_OUTREACH: Contact borrowers, offer workout options before delinquency'
        
        WHEN delinquency_risk_score >= 70
        THEN 'STOP_NEW_ORIGINATIONS: Market too risky for expanded-prime'
        
        ELSE 'CONTINUE_ORIGINATIONS: Market stable for expanded-prime'
    END AS portfolio_action
    
FROM offering_gates
ORDER BY date_reference DESC, silent_migration_score DESC
```

---

### View 3: DEEPHAVEN DSCR Investor - Rental Stress Monitor

**Purpose**: Monitor DSCR erosion risk from rent weakness and property distress

**File**: `vw_bkfs_deephaven_dscr_rental_stress.sql`

```sql
-- =======================================================================
-- BI VIEW: DEEPHAVEN DSCR Investor - Rental Stress Monitor
-- Purpose: Monitor DSCR erosion from delinquency and foreclosure pressure
-- Alert Triggers: DRG spike (rental payment stress), FRG elevation (collateral risk)
-- =======================================================================

{{ config(
    materialized='view',
    schema='bi',
    tags=['bi', 'bkfs', 'deephaven', 'dscr', 'offering']
) }}

WITH drg_data AS (
    SELECT
        date_reference,
        geo_id,
        signal_score_universal AS delinquency_risk_score,
        signal AS delinquency_signal,
        component_30day_dq_rate,
        component_60day_dq_rate,
        component_90plus_dq_rate
    FROM {{ ref('fct_delinquency_risk_signal') }}
),

frg_data AS (
    SELECT
        date_reference,
        geo_id,
        foreclosure_rate,
        foreclosure_start_rate,
        shadow_inventory_rate
    FROM {{ ref('feature_bkfs_foreclosure_metrics') }}
),

rrg_data AS (
    SELECT
        date_reference,
        geo_id,
        avg_cltv AS avg_ltv,
        property_value_trajectory_12m AS property_hpa_12m,
        avg_equity_cushion_pct
    FROM {{ ref('feature_bkfs_property_metrics') }}
),

offering_gates AS (
    SELECT
        COALESCE(d.date_reference, f.date_reference, r.date_reference) AS date_reference,
        COALESCE(d.geo_id, f.geo_id, r.geo_id) AS geo_id,
        
        -- =================================================================
        -- GATE 4: DSCR Monitoring
        -- =================================================================
        
        -- DSCR erosion proxy (rental payment stress)
        d.delinquency_risk_score AS rental_stress_score,
        
        -- DSCR risk assessment
        CASE 
            WHEN d.delinquency_risk_score >= 65 AND r.property_hpa_12m < 0
            THEN 'HIGH_DSCR_RISK: Rental stress + declining values'
            
            WHEN d.delinquency_risk_score >= 65
            THEN 'MODERATE_DSCR_RISK: Rental stress detected'
            
            WHEN r.property_hpa_12m < -5
            THEN 'COLLATERAL_RISK: Property values declining'
            
            ELSE 'STABLE_DSCR: Rental payments and values stable'
        END AS dscr_risk_assessment,
        
        -- Gate 4 assessment
        CASE 
            WHEN d.delinquency_risk_score >= 65 OR (f.foreclosure_rate + f.foreclosure_start_rate) > 3.0
            THEN 'TRIGGER: DSCR erosion or foreclosure pressure - review borrower finances'
            WHEN d.delinquency_risk_score >= 55
            THEN 'WATCH: Elevated rental stress - monitor cash flow'
            ELSE 'PASS: DSCR stable'
        END AS gate_4_dscr_monitoring_status,
        
        -- =================================================================
        -- RISK INDICATORS
        -- =================================================================
        
        -- Rental payment indicators
        d.delinquency_risk_score,
        d.component_30day_dq_rate AS early_payment_stress,
        d.component_60day_dq_rate AS moderate_payment_stress,
        d.component_90plus_dq_rate AS severe_payment_stress,
        
        -- Foreclosure/collateral indicators
        f.foreclosure_rate,
        f.foreclosure_start_rate,
        f.shadow_inventory_rate,
        r.avg_ltv,
        r.property_hpa_12m,
        r.avg_equity_cushion_pct,
        
        -- DSCR erosion score (composite)
        (d.delinquency_risk_score * 0.50 +
         (f.foreclosure_rate + f.foreclosure_start_rate) * 10 * 0.25 +
         CASE WHEN r.property_hpa_12m < 0 THEN ABS(r.property_hpa_12m) * 5 ELSE 0 END * 0.25) AS dscr_erosion_score
        
    FROM drg_data d
    LEFT JOIN frg_data f ON d.date_reference = f.date_reference AND d.geo_id = f.geo_id
    LEFT JOIN rrg_data r ON d.date_reference = r.date_reference AND d.geo_id = r.geo_id
)

SELECT
    date_reference,
    geo_id,
    
    -- Offering context
    'DEEPHAVEN_DSCR_INVESTOR_V1' AS offering_id,
    'REM' AS product_line,
    'DEBT' AS investment_vehicle,
    'SF' AS product_type,
    
    -- Gate assessments
    dscr_risk_assessment,
    gate_4_dscr_monitoring_status,
    
    -- DSCR erosion score
    dscr_erosion_score,
    
    -- Rental stress indicators
    rental_stress_score,
    early_payment_stress,
    moderate_payment_stress,
    severe_payment_stress,
    
    -- Collateral indicators
    foreclosure_rate,
    foreclosure_start_rate,
    shadow_inventory_rate,
    avg_ltv,
    property_hpa_12m,
    avg_equity_cushion_pct,
    
    -- Risk tier
    CASE 
        WHEN dscr_erosion_score >= 70 THEN 'TIER_1_HIGH_RISK'
        WHEN dscr_erosion_score >= 50 THEN 'TIER_2_ELEVATED_RISK'
        WHEN dscr_erosion_score >= 30 THEN 'TIER_3_MODERATE_RISK'
        ELSE 'TIER_4_LOW_RISK'
    END AS risk_tier,
    
    -- Underwriting adjustments
    CASE 
        WHEN dscr_erosion_score >= 70
        THEN 'TIGHTEN: Increase DSCR floor to 1.25×, reduce LTV to 75%, require 12mo reserves'
        
        WHEN dscr_erosion_score >= 50
        THEN 'ADJUST: Increase DSCR floor to 1.15×, reduce LTV to 77%, require 6mo reserves'
        
        WHEN dscr_erosion_score >= 30
        THEN 'MONITOR: Standard DSCR 1.00× with enhanced rent verification'
        
        ELSE 'STANDARD: Normal DSCR underwriting'
    END AS underwriting_recommendation,
    
    -- Portfolio action
    CASE 
        WHEN dscr_erosion_score >= 70
        THEN 'STOP_ORIGINATIONS: Market too risky for investor loans'
        
        WHEN rental_stress_score >= 65
        THEN 'PROACTIVE_REVIEW: Contact borrowers, verify rental income, assess occupancy'
        
        WHEN property_hpa_12m < -10
        THEN 'COLLATERAL_REVIEW: Declining market, assess collateral risk on pipeline'
        
        ELSE 'CONTINUE_ORIGINATIONS: Market stable for investor loans'
    END AS portfolio_action
    
FROM offering_gates
ORDER BY date_reference DESC, dscr_erosion_score DESC
```

---

## III. Offering-Level Gate Trigger Summary View

**Purpose**: Unified view across all mortgage offerings showing gate trigger status

**File**: `vw_bkfs_offering_gate_trigger_summary.sql`

```sql
-- =======================================================================
-- BI VIEW: BKFS Offering Gate Trigger Summary
-- Purpose: Unified view of all mortgage offering gate triggers
-- Use Case: Executive dashboard showing offering-level risk alerts
-- =======================================================================

{{ config(
    materialized='view',
    schema='bi',
    tags=['bi', 'bkfs', 'offering', 'executive', 'summary']
) }}

WITH selene_health AS (
    SELECT
        date_reference,
        offering_id,
        COUNT(DISTINCT geo_id) AS market_count,
        SUM(CASE WHEN trigger_delinquency_spike THEN 1 ELSE 0 END) AS markets_with_dq_spike,
        SUM(CASE WHEN trigger_roll_rate_acceleration THEN 1 ELSE 0 END) AS markets_with_roll_acceleration,
        AVG(delinquency_risk_score) AS avg_delinquency_risk,
        SUM(loan_count) AS total_loans
    FROM {{ ref('vw_bkfs_selene_primary_performing_health') }}
    GROUP BY date_reference, offering_id
),

deephaven_nqm AS (
    SELECT
        date_reference,
        offering_id,
        COUNT(DISTINCT geo_id) AS market_count,
        SUM(CASE WHEN trigger_silent_credit_migration THEN 1 ELSE 0 END) AS markets_with_credit_migration,
        SUM(CASE WHEN risk_tier = 'TIER_1_AVOID' THEN 1 ELSE 0 END) AS markets_avoid,
        AVG(silent_migration_score) AS avg_migration_score
    FROM {{ ref('vw_bkfs_deephaven_non_qm_credit_migration') }}
    GROUP BY date_reference, offering_id
),

deephaven_dscr AS (
    SELECT
        date_reference,
        offering_id,
        COUNT(DISTINCT geo_id) AS market_count,
        SUM(CASE WHEN risk_tier = 'TIER_1_HIGH_RISK' THEN 1 ELSE 0 END) AS markets_high_risk,
        AVG(dscr_erosion_score) AS avg_dscr_erosion_score
    FROM {{ ref('vw_bkfs_deephaven_dscr_rental_stress') }}
    GROUP BY date_reference, offering_id
),

all_offerings AS (
    SELECT
        date_reference,
        offering_id,
        market_count,
        markets_with_dq_spike AS alert_count,
        avg_delinquency_risk AS risk_score,
        total_loans AS loan_count,
        'Delinquency Spike' AS primary_alert_type
    FROM selene_health
    
    UNION ALL
    
    SELECT
        date_reference,
        offering_id,
        market_count,
        markets_with_credit_migration AS alert_count,
        avg_migration_score AS risk_score,
        NULL AS loan_count,
        'Credit Migration' AS primary_alert_type
    FROM deephaven_nqm
    
    UNION ALL
    
    SELECT
        date_reference,
        offering_id,
        market_count,
        markets_high_risk AS alert_count,
        avg_dscr_erosion_score AS risk_score,
        NULL AS loan_count,
        'DSCR Erosion' AS primary_alert_type
    FROM deephaven_dscr
)

SELECT
    date_reference,
    offering_id,
    market_count,
    alert_count,
    risk_score,
    loan_count,
    primary_alert_type,
    
    -- Alert severity
    CASE 
        WHEN alert_count > market_count * 0.20 THEN 'CRITICAL'  -- >20% of markets
        WHEN alert_count > market_count * 0.10 THEN 'HIGH'      -- >10% of markets
        WHEN alert_count > 0 THEN 'MODERATE'
        ELSE 'LOW'
    END AS alert_severity,
    
    -- Executive recommendation
    CASE 
        WHEN alert_count > market_count * 0.20 AND risk_score > 70
        THEN 'IMMEDIATE_ACTION: Suspend new originations, review existing portfolio'
        
        WHEN alert_count > market_count * 0.10 AND risk_score > 60
        THEN 'TIGHTEN_UNDERWRITING: Increase credit standards, reduce exposure'
        
        WHEN alert_count > 0
        THEN 'MONITOR: Watch affected markets closely'
        
        ELSE 'CONTINUE_OPERATIONS: Normal risk levels'
    END AS executive_recommendation
    
FROM all_offerings
ORDER BY date_reference DESC, alert_severity DESC, alert_count DESC
```

---

## IV. Implementation Summary

### Files Created (3 New BI Views)

1. **`vw_bkfs_selene_primary_performing_health.sql`** - Servicing portfolio health with gate triggers
2. **`vw_bkfs_deephaven_non_qm_credit_migration.sql`** - Silent credit migration monitoring
3. **`vw_bkfs_deephaven_dscr_rental_stress.sql`** - DSCR erosion and rental stress
4. **`vw_bkfs_offering_gate_trigger_summary.sql`** - Executive summary across all offerings

### Key Features

✅ **Gate-Specific Logic**: Each view maps directly to offering gate requirements  
✅ **Automated Triggers**: Alert flags for gate failures (DRG spike, credit migration, DSCR erosion)  
✅ **Offering-Level Aggregation**: Portfolio-weighted scores across all markets  
✅ **Action Recommendations**: Operational guidance (tighten underwriting, proactive outreach, suspend originations)  
✅ **Executive Summary**: Unified view for C-suite monitoring

### Business Value

- **SELENE**: Detect servicing portfolio deterioration before fee duration collapses
- **DEEPHAVEN Non-QM**: Catch silent credit migration before expanded-prime behaves like non-prime
- **DEEPHAVEN DSCR**: Monitor rental stress before DSCR falls below 1.0×
- **Executive Dashboard**: Single pane of glass for all mortgage offering risks

---

**Last Updated**: 2026-01-29  
**Status**: Offering-level views ready for deployment  
**Next Step**: Connect to production data and validate gate trigger logic


