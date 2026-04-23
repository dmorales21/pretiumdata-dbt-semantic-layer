# Progressive Signal Development Plan
**Date**: 2026-01-31  
**Status**: ✅ **PLAN COMPLETE**  
**Purpose**: Progressive development of signals based on investment relevance, national coverage, and H3 geography support

---

## Executive Summary

This plan prioritizes signal development based on:
1. **Investment Relevance** (40% weight) - How critical the signal is for investment decisions
2. **Data Availability** (30% weight) - Metrics available and coverage
3. **Product Coverage** (20% weight) - Support for multiple product types
4. **Opportunity Score** (10% weight) - Overall development readiness

**Geography Support**: All signals will support multiple geography levels (CBSA, ZIP, H3) for national coverage and map visualizations.

---

## Development Framework

### Priority Tiers

| Tier | Score Range | Description | Development Timeline |
|------|-------------|------------|---------------------|
| **TIER_1_CRITICAL** | 80-100 | Critical for investment decisions | Immediate (1-2 weeks) |
| **TIER_2_HIGH** | 65-79 | High investment relevance | High Priority (2-4 weeks) |
| **TIER_3_MEDIUM** | 50-64 | Moderate investment relevance | Medium Priority (1-2 months) |
| **TIER_4_LOW** | <50 | Low investment relevance | Low Priority (backlog) |

---

## Geography Level Requirements

### Standard Geography Support

All signals should support:

1. **CBSA Level** (939 markets)
   - Primary market-level analysis
   - Investment decision support
   - Portfolio-level comparisons

2. **ZIP Level** (33,000+ ZIPs)
   - Submarket analysis
   - Property-level context
   - Granular market intelligence

3. **H3 Level** (H3_6 or H3_8)
   - Map visualizations
   - Submarket boundaries
   - Computational geography

### H3 Support Requirements

**H3_8 Resolution** (required for):
- Place signals (safety, education, amenities)
- Housing demand/pricing signals
- High-investment-relevance signals (relevance ≥ 0.7)

**H3_6 Resolution** (sufficient for):
- Capital signals
- Governance signals
- Lower-investment-relevance signals

---

## Development Phases

### Phase 1: Feature Model
**Geography Levels**: Start with highest available (typically ZIP or CBSA)
**H3 Support**: Add H3 aggregation using `dim_h3_geography` crosswalk

**Example Pattern**:
```sql
-- Feature model with H3 support
WITH base_features AS (
    SELECT
        date_reference,
        geo_id,
        geo_level_code,
        metric_value
    FROM fact_table
    WHERE geo_level_code IN ('CBSA', 'ZIP')
),
h3_features AS (
    SELECT
        bf.date_reference,
        h3.h3_hex AS geo_id,
        'H3_8' AS geo_level_code,
        AVG(bf.metric_value * h3.weight) AS metric_value  -- Weighted average
    FROM base_features bf
    INNER JOIN {{ ref('dim_h3_geography') }} h3
        ON bf.geo_id = h3.cbsa_code  -- or zip_code
        AND h3.h3_resolution = 8
    GROUP BY bf.date_reference, h3.h3_hex
)
SELECT * FROM base_features
UNION ALL
SELECT * FROM h3_features
```

### Phase 2: Signal Model
**Geography Levels**: Support all required levels (CBSA, ZIP, H3)
**Product Types**: Support all suggested product types
**Tenancy**: Include tenancy_code

**Example Pattern**:
```sql
-- Signal model with multi-geography support
SELECT
    date_reference,
    geo_id,
    geo_level_code,  -- CBSA, ZIP, H3_8, etc.
    product_type_code,
    tenancy_code,
    signal_score_universal,
    signal_score_sf,
    signal_score_mf,
    -- ... other scores
FROM feature_model
CROSS JOIN product_types
WHERE geo_level_code IN ('CBSA', 'ZIP', 'H3_8')
```

### Phase 3: Registration
**Schema Registration**: Register in `schema.yml` with geography levels
**Catalog Registration**: Register in `ADMIN.CATALOG.DIM_SIGNAL`
**H3 Support**: Document H3 resolution and coverage

---

## Investment Relevance Framework

### Relevance Scoring

Signals are scored by their relevance to investment offerings:

| Relevance Score | Description | Investment Impact |
|----------------|-------------|-------------------|
| 0.9-1.0 | Critical | Primary decision driver |
| 0.7-0.89 | High | Strong influence on decisions |
| 0.5-0.69 | Moderate | Important but not primary |
| 0.3-0.49 | Low | Supporting metric |
| 0.0-0.29 | Minimal | Rarely used |

### Top Investment-Relevant Signals

Based on `SIGNAL_OFFERING_RELEVANCE_MATRIX`:

1. **VELOCITY** (0.85-0.90 relevance)
   - Critical for: REQ, RED, REM offerings
   - Geography: CBSA, ZIP, H3_8
   - Status: ✅ Built

2. **ABSORPTION** (0.80-0.85 relevance)
   - Critical for: REQ, RED, REM offerings
   - Geography: CBSA, ZIP, H3_8
   - Status: ✅ Built

3. **SUPPLY_PRESSURE** (0.70-0.80 relevance)
   - Critical for: REQ, RED, REM offerings
   - Geography: CBSA, ZIP, H3_8
   - Status: ✅ Built

4. **AFFORDABILITY** (0.60-0.90 relevance)
   - Critical for: DEEPHAVEN offerings, AFFORDABLE product
   - Geography: CBSA, ZIP, H3_8
   - Status: ⏳ Needs H3 support

5. **PLACE_SAFETY** (0.70-0.85 relevance)
   - Critical for: SFR, BTR offerings
   - Geography: ZIP, H3_8 (fine-grained)
   - Status: ⏳ Needs development

6. **PLACE_EDUCATION** (0.65-0.80 relevance)
   - Critical for: SFR, BTR offerings
   - Geography: ZIP, H3_8 (fine-grained)
   - Status: ⏳ Needs development

---

## National Coverage Goals

### Coverage Targets

| Geography Level | Target Coverage | Current Status |
|----------------|----------------|----------------|
| **CBSA** | 939 markets (100%) | ✅ 893 markets (95%) |
| **ZIP** | 33,000+ ZIPs (100%) | ✅ 27,460 ZIPs (83%) |
| **H3_8** | 500,000+ hexagons | ⏳ Partial support |
| **H3_6** | 100,000+ hexagons | ⏳ Partial support |

### Coverage Expansion Strategy

1. **Existing Signals**: Add H3 support to existing signals
2. **New Signals**: Build with multi-geography support from start
3. **Aggregation**: Use `dim_h3_geography` for H3 aggregation
4. **Validation**: Ensure coverage meets targets

---

## Development Roadmap

### Immediate (TIER_1_CRITICAL)

1. **PLACE_SAFETY_SIGNAL** ⭐
   - Investment Relevance: 0.75 (SFR, BTR)
   - Geography: ZIP, H3_8
   - Data: ✅ Available (FACT_PLACE_PLC_SAFETY_ALL_TS)
   - Status: Ready to build

2. **PLACE_EDUCATION_SIGNAL** ⭐
   - Investment Relevance: 0.70 (SFR, BTR)
   - Geography: ZIP, H3_8
   - Data: ✅ Available (FACT_PLACE_PLC_EDUCATION_ALL_TS)
   - Status: Ready to build

3. **HOUSING_DEMAND_SIGNAL** ⭐
   - Investment Relevance: 0.80 (All offerings)
   - Geography: CBSA, ZIP, H3_8
   - Data: ✅ Available (HOUSING_HOU_DEMAND_ALL_TS)
   - Status: Ready to build

### High Priority (TIER_2_HIGH)

4. **HOUSING_PRICING_SIGNAL**
   - Investment Relevance: 0.75 (All offerings)
   - Geography: CBSA, ZIP, H3_8
   - Data: ⏳ Needs verification

5. **HOUSING_OWNERSHIP_SIGNAL**
   - Investment Relevance: 0.65 (REQ offerings)
   - Geography: CBSA, ZIP, H3_8
   - Data: ⏳ Needs verification

6. **HH_DEMAND_SIGNAL** (Household Formation)
   - Investment Relevance: 0.70 (REQ, RED offerings)
   - Geography: CBSA, ZIP
   - Data: ⏳ Needs alternative source

### Medium Priority (TIER_3_MEDIUM)

7. **CAPITAL_ECONOMY_SIGNAL**
   - Investment Relevance: 0.60 (All offerings)
   - Geography: CBSA
   - Data: ⏳ Needs verification

8. **HOUSING_OPERATIONS_SIGNAL**
   - Investment Relevance: 0.55 (REQ offerings)
   - Geography: CBSA, ZIP
   - Data: ⏳ Needs verification

---

## H3 Implementation Pattern

### Step 1: Add H3 to Feature Models

```sql
-- Add H3 aggregation to existing feature models
WITH base_features AS (
    -- Existing feature logic
    SELECT geo_id, geo_level_code, metric_value
    FROM fact_table
),
h3_aggregated AS (
    SELECT
        h3.h3_hex AS geo_id,
        'H3_8' AS geo_level_code,
        AVG(bf.metric_value * h3.weight) AS metric_value
    FROM base_features bf
    INNER JOIN {{ ref('dim_h3_geography') }} h3
        ON bf.geo_id = h3.cbsa_code  -- or zip_code
        AND h3.h3_resolution = 8
    GROUP BY h3.h3_hex
)
SELECT * FROM base_features
UNION ALL
SELECT * FROM h3_aggregated
```

### Step 2: Update Signal Models

```sql
-- Signal models support all geography levels
SELECT
    date_reference,
    geo_id,
    geo_level_code,  -- Now includes H3_8, H3_6
    product_type_code,
    tenancy_code,
    signal_score_universal
FROM feature_model
WHERE geo_level_code IN ('CBSA', 'ZIP', 'H3_8', 'H3_6')
```

### Step 3: Register H3 Support

```yaml
# schema.yml
meta:
  geography_levels: ["CBSA", "ZIP", "H3_8"]
  h3_resolution: 8
  h3_coverage: "National"
```

---

## Next Steps

1. ✅ **Run Investment Priority Analysis**
   ```sql
   SELECT * FROM ANALYTICS_PROD.INTEL.VW_SIGNAL_DEVELOPMENT_ROADMAP
   WHERE development_priority_tier = 'TIER_1_CRITICAL'
   ORDER BY investment_priority_score DESC;
   ```

2. ⏳ **Start TIER_1 Development**
   - PLACE_SAFETY_SIGNAL
   - PLACE_EDUCATION_SIGNAL
   - HOUSING_DEMAND_SIGNAL

3. ⏳ **Add H3 Support to Existing Signals**
   - Update feature models
   - Update signal models
   - Register H3 support

4. ⏳ **Validate National Coverage**
   - Check CBSA coverage (target: 939)
   - Check ZIP coverage (target: 33,000+)
   - Check H3 coverage (target: 500,000+ H3_8)

---

**Last Updated**: 2026-01-31  
**Status**: ✅ Plan Complete - Ready for Execution  
**Next**: Run investment priority analysis to identify TIER_1 signals

