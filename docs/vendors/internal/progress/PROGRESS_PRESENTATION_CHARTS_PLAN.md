# Progress Presentation Charts Plan

**Date**: 2026-01-27  
**Purpose**: Plan and evaluate chart types for Progress presentation concepts using STRATA style

---

## STRATA Style Guidelines

**Color Palette**:
- UI Base: `#0E1E38` (Dark Navy)
- UI Accent: `#327ca3` (Blue)
- Verified: `#1E4022` (Deep Hunter Green)
- Stable: `#2D3F5F` (Slate Blue)
- Watch: `#C9A227` (Golden Ochre)
- Concern: `#B7352C` (Brick Red)
- Failing: `#272727` (Charcoal)
- Surface: `#FDFDFE` (White)
- Text Primary: `#2E2E33` (Graphite Gray)
- Text Secondary: `rgba(46, 46, 51, 0.7)`
- Border: `rgba(46, 46, 51, 0.15)`

**Typography**: `system-ui, -apple-system, sans-serif`

**Chart Libraries**: Plotly (preferred) or matplotlib with seaborn whitegrid style

---

## Chart Plans by Presentation Section

### 1. Progress Homes Are Affordable

#### Chart 1.1: Cost to Own vs. Cost to Rent (Stacked Area Chart)
**Concept**: Show monthly cost components over time (2019-2025)
**Proposed Chart**: Stacked area chart showing rent vs mortgage + taxes + insurance
**X-Axis**: Time (months/years)
**Y-Axis**: Monthly cost (USD)
**Stacks**:
  - Rent (ZORI)
  - Mortgage payment (calculated from ZHVI)
  - Taxes (yearly / 12)
  - Insurance (yearly / 12)
**Color Scheme**: 
  - Rent: `ui_accent` (blue)
  - Mortgage: `stable` (slate blue)
  - Taxes: `watch` (golden)
  - Insurance: `concern` (brick red)
**Alternative Consideration**: 
  - ✅ **BEST**: Stacked area chart - shows total cost and component breakdown
  - Alternative: Grouped bar chart (less effective for time series)
  - Alternative: Line chart with multiple lines (harder to see total cost)

#### Chart 1.2: Owner vs Renter Income Comparison (Grouped Bar Chart)
**Concept**: Median owner income vs median renter income by market
**Proposed Chart**: Grouped bar chart
**X-Axis**: Markets (top 10-15 CBSAs)
**Y-Axis**: Income (USD)
**Bars**: Owner income vs Renter income side-by-side
**Color Scheme**: 
  - Owner: `verified` (green)
  - Renter: `ui_accent` (blue)
**Alternative Consideration**:
  - ✅ **BEST**: Grouped bar chart - clear comparison
  - Alternative: Diverging bar chart (less intuitive for income comparison)

#### Chart 1.3: Rent vs Own Monthly Cost Gap (Line Chart with Shaded Area)
**Concept**: Monthly cost gap (own - rent) over time by market
**Proposed Chart**: Multi-line chart with shaded area showing gap
**X-Axis**: Time (months)
**Y-Axis**: Cost gap (USD)
**Lines**: One line per market (top 5-10 markets)
**Shaded Area**: Fill between rent line and own line
**Color Scheme**: Different `ui_accent` shades per market
**Alternative Consideration**:
  - ✅ **BEST**: Multi-line with shaded area - shows gap clearly
  - Alternative: Heatmap (less intuitive for time series)

#### Chart 1.4: Owner Burden vs Renter Burden (Stacked Bar Chart)
**Concept**: Percentage of households burdened by housing costs
**Proposed Chart**: Stacked horizontal bar chart
**X-Axis**: Percentage burdened
**Y-Axis**: Markets or time periods
**Stacks**: 
  - Not burdened (<30%)
  - Moderately burdened (30-50%)
  - Severely burdened (50%+)
**Color Scheme**:
  - Not burdened: `verified` (green)
  - Moderate: `watch` (golden)
  - Severe: `concern` (brick red)
**Alternative Consideration**:
  - ✅ **BEST**: Stacked bar - shows distribution clearly
  - Alternative: Grouped bar (loses total context)

#### Chart 1.5: Renter Income Distribution by Bracket (Waterfall or Stacked Bar)
**Concept**: Distribution of renters across income brackets
**Proposed Chart**: Stacked bar chart or waterfall chart
**X-Axis**: Income brackets (16 brackets from <$10K to $200K+)
**Y-Axis**: Count or percentage of renters
**Color Scheme**: Gradient from `concern` (low income) to `verified` (high income)
**Alternative Consideration**:
  - ✅ **BEST**: Stacked bar - shows distribution clearly
  - Alternative: Histogram (less clear for discrete brackets)

#### Chart 1.6: Effective Rent vs Market Rent (Scatter Plot with Reference Line)
**Concept**: Progress effective rent vs market rent for similar homes
**Proposed Chart**: Scatter plot
**X-Axis**: Market rent (USD)
**Y-Axis**: Effective rent paid (USD)
**Reference Line**: y = x (1:1 line)
**Color**: Distance from reference line (discount/premium)
**Size**: Number of properties
**Alternative Consideration**:
  - ✅ **BEST**: Scatter with reference line - shows discount/premium clearly
  - Alternative: Bar chart (loses property-level granularity)

---

### 2. Safe and Well-Maintained

#### Chart 2.1: Work Order Response Time Distribution (Box Plot + Violin Plot)
**Concept**: Distribution of work order response times
**Proposed Chart**: Violin plot or box plot
**X-Axis**: Priority level (Emergency, Routine, etc.)
**Y-Axis**: Response time (hours)
**Color Scheme**: `ui_accent` with opacity gradient
**Alternative Consideration**:
  - ✅ **BEST**: Violin plot - shows distribution shape
  - Alternative: Bar chart (loses distribution information)

#### Chart 2.2: Emergency Work Orders % Resolved Within X Hours (Bar Chart with Target Line)
**Concept**: Percentage of emergencies resolved within SLA
**Proposed Chart**: Horizontal bar chart with target line
**X-Axis**: Percentage resolved
**Y-Axis**: Time thresholds (1hr, 4hr, 24hr, etc.)
**Target Line**: 95% or 100% target
**Color Scheme**: 
  - Above target: `verified` (green)
  - Below target: `concern` (red)
**Alternative Consideration**:
  - ✅ **BEST**: Horizontal bar with target - clear performance visualization
  - Alternative: Line chart (less intuitive for thresholds)

#### Chart 2.3: Maintenance Spend as % of Household Income (Scatter Plot)
**Concept**: Maintenance cost vs household income
**Proposed Chart**: Scatter plot
**X-Axis**: Household income (USD)
**Y-Axis**: Maintenance spend (USD or %)
**Color**: Property age or condition
**Size**: Property value
**Alternative Consideration**:
  - ✅ **BEST**: Scatter plot - shows relationship
  - Alternative: Bar chart (loses property-level detail)

---

### 3. Family-Sized

#### Chart 3.1: Unit Size Distribution (Histogram with Overlay)
**Concept**: Distribution of Progress unit sizes vs market
**Proposed Chart**: Overlaid histogram
**X-Axis**: Square feet
**Y-Axis**: Frequency (count or density)
**Series**: Progress properties vs Market average
**Color Scheme**: 
  - Progress: `ui_accent` (blue)
  - Market: `stable` (slate blue, lighter)
**Alternative Consideration**:
  - ✅ **BEST**: Overlaid histogram - clear comparison
  - Alternative: Box plot (loses distribution shape)

#### Chart 3.2: Bedroom Distribution (Stacked Bar Chart)
**Concept**: Number of bedrooms in Progress properties vs market
**Proposed Chart**: Grouped bar chart
**X-Axis**: Number of bedrooms (0, 1, 2, 3, 4+)
**Y-Axis**: Count or percentage
**Bars**: Progress vs Market side-by-side
**Color Scheme**: 
  - Progress: `ui_accent` (blue)
  - Market: `stable` (slate blue)
**Alternative Consideration**:
  - ✅ **BEST**: Grouped bar - clear comparison
  - Alternative: Stacked bar (harder to compare)

---

### 4. Located Near Opportunity

#### Chart 4.1: Distance to Work - Commute Time Distribution (Stacked Area Chart)
**Concept**: Distribution of commute times for Progress properties
**Proposed Chart**: Stacked area or bar chart
**X-Axis**: Commute time brackets (<5min, 5-9min, etc.)
**Y-Axis**: Percentage of workers
**Color Scheme**: Gradient from `verified` (short) to `concern` (long)
**Alternative Consideration**:
  - ✅ **BEST**: Stacked area - shows distribution clearly
  - Alternative: Line chart (less intuitive for brackets)

#### Chart 4.2: Job Accessibility Map (Choropleth Map)
**Concept**: Jobs within X km of Progress properties
**Proposed Chart**: Choropleth map with property markers
**Base**: ZIP or tract boundaries
**Color**: Job density or accessibility score
**Markers**: Progress property locations
**Color Scale**: `verified` (high) to `concern` (low)
**Alternative Consideration**:
  - ✅ **BEST**: Choropleth map - spatial visualization
  - Alternative: Bar chart (loses spatial context)

---

### 5. Renters Cannot Afford Ownership Due To

#### Chart 5.1: Owner Costs Over Time - Stacked Bar Chart (2019-2025)
**Concept**: Stacked bar showing owner cost components over time
**Proposed Chart**: Stacked bar chart
**X-Axis**: Year (2019-2025)
**Y-Axis**: Monthly cost (USD)
**Stacks**: Mortgage, Taxes, Insurance, Maintenance
**Color Scheme**: Different colors per component
**Alternative Consideration**:
  - ✅ **BEST**: Stacked bar - shows component breakdown
  - Alternative: Stacked area (also good, but bar emphasizes discrete years)

#### Chart 5.2: DTI Requirements Over Time (Line Chart)
**Concept**: Average DTI requirements from HMDA data
**Proposed Chart**: Line chart with confidence bands
**X-Axis**: Time (years)
**Y-Axis**: DTI ratio (%)
**Lines**: Average DTI, P25, P75
**Color Scheme**: `ui_accent` with shaded confidence band
**Alternative Consideration**:
  - ✅ **BEST**: Line with confidence bands - shows trend and uncertainty
  - Alternative: Bar chart (loses trend smoothness)

#### Chart 5.3: Downpayment Required as % of Income (Heatmap)
**Concept**: Income required to afford 20% down by market and time
**Proposed Chart**: Heatmap
**X-Axis**: Markets (CBSAs)
**Y-Axis**: Time (years)
**Color**: Income required as % of median income
**Color Scale**: `verified` (low %) to `concern` (high %)
**Alternative Consideration**:
  - ✅ **BEST**: Heatmap - shows market × time patterns
  - Alternative: Line chart (too many lines for many markets)

#### Chart 5.4: Single-Family Supply Reduction (Line Chart with Dual Y-Axis)
**Concept**: SFR as % of new supply over time
**Proposed Chart**: Dual-axis line chart
**X-Axis**: Time (years)
**Y-Axis (Left)**: SFR units (count)
**Y-Axis (Right)**: SFR as % of total supply
**Lines**: 
  - SFR units (left axis)
  - Total supply (left axis)
  - SFR % (right axis)
**Color Scheme**: 
  - SFR: `ui_accent` (blue)
  - Total: `stable` (slate blue)
  - %: `watch` (golden)
**Alternative Consideration**:
  - ✅ **BEST**: Dual-axis - shows both absolute and relative
  - Alternative: Two separate charts (loses relationship)

---

### 6. Why Progress Helps

#### Chart 6.1: Progress SFR Portfolio Size by Market (Horizontal Bar Chart)
**Concept**: Number of Progress SFR properties by market
**Proposed Chart**: Horizontal bar chart
**X-Axis**: Property count
**Y-Axis**: Markets (CBSAs)
**Color**: Market size or growth rate
**Color Scheme**: Gradient from `verified` (large) to `stable` (small)
**Alternative Consideration**:
  - ✅ **BEST**: Horizontal bar - easy to read market names
  - Alternative: Vertical bar (names harder to read)

#### Chart 6.2: Progress Acquisition Volume vs Market Supply (Stacked Area Chart)
**Concept**: Progress acquisitions as portion of market supply
**Proposed Chart**: Stacked area chart
**X-Axis**: Time (quarters/years)
**Y-Axis**: Units (count)
**Stacks**: 
  - Progress acquisitions
  - Other market supply
**Color Scheme**: 
  - Progress: `ui_accent` (blue)
  - Other: `stable` (slate blue, lighter)
**Alternative Consideration**:
  - ✅ **BEST**: Stacked area - shows Progress share clearly
  - Alternative: Line chart (loses share context)

---

### 7. Progress Organize Ops - Tenant Data

#### Chart 7.1: Tenant Income Distribution (Internal vs Public) (Overlaid Histogram)
**Concept**: Compare tenant income from Salesforce vs ZIP-level ACS
**Proposed Chart**: Overlaid histogram or density plot
**X-Axis**: Income (USD)
**Y-Axis**: Density or frequency
**Series**: 
  - Internal (Salesforce) - actual tenant data
  - Public (ACS ZIP) - geographic average
**Color Scheme**: 
  - Internal: `ui_accent` (blue, solid)
  - Public: `stable` (slate blue, dashed)
**Alternative Consideration**:
  - ✅ **BEST**: Overlaid density - shows distribution comparison
  - Alternative: Box plot (loses distribution shape)

#### Chart 7.2: FICO Score Distribution (Histogram)
**Concept**: Distribution of tenant FICO scores (internal only)
**Proposed Chart**: Histogram with normal curve overlay
**X-Axis**: FICO score (300-850)
**Y-Axis**: Frequency (count)
**Overlay**: Normal distribution curve (if applicable)
**Color Scheme**: `ui_accent` with gradient
**Alternative Consideration**:
  - ✅ **BEST**: Histogram - standard for credit scores
  - Alternative: Box plot (loses distribution detail)

#### Chart 7.3: Tenant Profile Clustering by ZIP (Scatter Plot Matrix)
**Concept**: Cluster tenant profiles by ZIP code characteristics
**Proposed Chart**: Scatter plot matrix or parallel coordinates
**Dimensions**: Income, FICO, household size, etc.
**Color**: Institutional ownership level
**Alternative Consideration**:
  - ✅ **BEST**: Scatter plot matrix - shows relationships
  - Alternative: Parallel coordinates (good for many dimensions)

---

### 8. Debunk: Not Crowding Out Homeowners

#### Chart 8.1: Institutional Ownership Over Time (Line Chart)
**Concept**: Institutional ownership % (100+, 1000+) over time
**Proposed Chart**: Multi-line chart
**X-Axis**: Time (years, 2018-2025)
**Y-Axis**: Institutional ownership % of total stock
**Lines**: 
  - 100+ units
  - 1000+ units
  - All portfolios
**Color Scheme**: 
  - 100+: `watch` (golden)
  - 1000+: `concern` (brick red)
  - All: `stable` (slate blue)
**Reference Line**: 1%, 5% thresholds
**Alternative Consideration**:
  - ✅ **BEST**: Multi-line with reference - shows trend and context
  - Alternative: Stacked area (less clear for %)

#### Chart 8.2: Portfolio Size Distribution (Pie or Donut Chart)
**Concept**: Distribution of portfolio ownership by size
**Proposed Chart**: Donut chart
**Segments**: 
  - 2-9 units
  - 10-99 units
  - 100-999 units
  - 1000+ units
**Color Scheme**: Gradient from `verified` (small) to `concern` (large)
**Alternative Consideration**:
  - ✅ **BEST**: Donut chart - shows composition clearly
  - Alternative: Stacked bar (also good, but pie is more intuitive for composition)

#### Chart 8.3: Institutional Ownership by Market (Horizontal Bar Chart)
**Concept**: Top markets by institutional ownership %
**Proposed Chart**: Horizontal bar chart
**X-Axis**: Institutional ownership %
**Y-Axis**: Markets (CBSAs)
**Color**: Ownership level (gradient)
**Reference Line**: National average
**Alternative Consideration**:
  - ✅ **BEST**: Horizontal bar - easy to read market names
  - Alternative: Map (also good for spatial context)

---

### 9. Value 1: Affording SF Rentership

#### Chart 9.1: Working People Location Map (Choropleth + Scatter)
**Concept**: Where working people live and work
**Proposed Chart**: Map with dual layers
**Base**: Job density choropleth
**Overlay**: Progress property locations (scatter)
**Color Scale**: Job density (high = `verified`, low = `concern`)
**Alternative Consideration**:
  - ✅ **BEST**: Map - spatial visualization essential
  - Alternative: Bar chart (loses spatial context)

#### Chart 9.2: Renter Profile Attributes (Radar Chart)
**Concept**: Typical renter profile across multiple dimensions
**Proposed Chart**: Radar/spider chart
**Axes**: 
  - Income level
  - Credit score
  - Household size
  - Education
  - Occupation type
**Shapes**: Progress tenants vs Market average
**Color Scheme**: 
  - Progress: `ui_accent` (blue)
  - Market: `stable` (slate blue, lighter)
**Alternative Consideration**:
  - ✅ **BEST**: Radar chart - multi-dimensional comparison
  - Alternative: Small multiples (also good but more space)

---

### 10. Value 2: Increase of Housing Supply

#### Chart 10.1: Institutional Capacity vs Market Size (Scatter Plot)
**Concept**: Institutional ownership vs total housing stock
**Proposed Chart**: Scatter plot with size encoding
**X-Axis**: Total housing stock (units)
**Y-Axis**: Institutional ownership (units)
**Size**: Institutional ownership %
**Color**: Market growth rate
**Reference Line**: y = x (if 100% institutional)
**Alternative Consideration**:
  - ✅ **BEST**: Scatter with size - shows relationship and scale
  - Alternative: Bar chart (loses relationship)

#### Chart 10.2: Market Share Comparison (Grouped Bar Chart)
**Concept**: Institutional % vs Progress % vs Other portfolios
**Proposed Chart**: Grouped bar chart
**X-Axis**: Markets (top 10-15)
**Y-Axis**: Market share %
**Bars**: Institutional, Progress, Other portfolios
**Color Scheme**: 
  - Institutional: `concern` (red)
  - Progress: `ui_accent` (blue)
  - Other: `stable` (slate blue)
**Alternative Consideration**:
  - ✅ **BEST**: Grouped bar - clear comparison
  - Alternative: Stacked bar (harder to compare Progress specifically)

---

### 11. Impact of Dissolution

#### Chart 11.1: Affordability Post-Dissolution (Before/After Comparison)
**Concept**: Rent burden before vs after institutional dissolution
**Proposed Chart**: Paired bar chart or slope graph
**X-Axis**: Markets or scenarios
**Y-Axis**: Rent burden %
**Bars**: Before vs After (paired)
**Color Scheme**: 
  - Before: `stable` (slate blue)
  - After: `concern` (brick red)
**Alternative Consideration**:
  - ✅ **BEST**: Paired bar or slope graph - clear before/after
  - Alternative: Line chart (less clear for discrete scenarios)

#### Chart 11.2: Supply and Liquidity Impact (Dual-Axis Line Chart)
**Concept**: Supply levels and market liquidity over time
**Proposed Chart**: Dual-axis line chart
**X-Axis**: Time
**Y-Axis (Left)**: Supply (units or months)
**Y-Axis (Right)**: Liquidity (absorption rate or DOM)
**Lines**: 
  - Supply (left)
  - Liquidity (right)
**Color Scheme**: 
  - Supply: `ui_accent` (blue)
  - Liquidity: `watch` (golden)
**Alternative Consideration**:
  - ✅ **BEST**: Dual-axis - shows relationship
  - Alternative: Two separate charts (loses relationship)

---

### 12. Place-Based Opportunity

#### Chart 12.1: Future Income Forecast (Line Chart with Confidence Bands)
**Concept**: Income growth forecasts with uncertainty
**Proposed Chart**: Line chart with shaded confidence bands
**X-Axis**: Time (years, historical + forecast)
**Y-Axis**: Income (USD)
**Lines**: 
  - Historical (solid)
  - Forecast (dashed)
**Shaded Area**: Confidence interval (P10-P90)
**Color Scheme**: `ui_accent` with opacity gradient
**Alternative Consideration**:
  - ✅ **BEST**: Line with confidence bands - shows forecast uncertainty
  - Alternative: Bar chart (loses trend)

#### Chart 12.2: Professions by Market (Stacked Bar Chart)
**Concept**: Employment by profession type (muni gov, healthcare, education)
**Proposed Chart**: Stacked horizontal bar chart
**X-Axis**: Employment count or %
**Y-Axis**: Markets
**Stacks**: 
  - Municipal government
  - Healthcare
  - Education
  - Other
**Color Scheme**: 
  - Muni gov: `stable` (slate blue)
  - Healthcare: `verified` (green)
  - Education: `ui_accent` (blue)
  - Other: `watch` (golden)
**Alternative Consideration**:
  - ✅ **BEST**: Stacked horizontal bar - shows composition
  - Alternative: Grouped bar (harder to see total)

---

### 13. Value of Scale / Serving the Role of Government

#### Chart 13.1: Maintenance Capacity at Scale (Scatter Plot with Size)
**Concept**: Maintenance spend vs portfolio size
**Proposed Chart**: Scatter plot
**X-Axis**: Portfolio size (property count)
**Y-Axis**: Maintenance spend per property (USD)
**Size**: Total maintenance capacity (USD)
**Color**: Market
**Trend Line**: Efficiency curve (economies of scale)
**Alternative Consideration**:
  - ✅ **BEST**: Scatter with size - shows scale effects
  - Alternative: Bar chart (loses relationship)

#### Chart 13.2: Disaster Relief Response (Timeline or Gantt Chart)
**Concept**: Disaster response timeline and capacity
**Proposed Chart**: Timeline or Gantt chart
**X-Axis**: Time (days/weeks)
**Y-Axis**: Disaster events or properties affected
**Bars**: Response duration
**Color**: Response speed or effectiveness
**Alternative Consideration**:
  - ✅ **BEST**: Timeline - shows temporal sequence
  - Alternative: Bar chart (loses temporal context)

---

## Implementation Priority

### High Priority Charts (Core Narrative)
1. Cost to Own vs Rent (Stacked Area) - **Chart 1.1**
2. Owner vs Renter Income (Grouped Bar) - **Chart 1.2**
3. Rent vs Own Cost Gap (Multi-line) - **Chart 1.3**
4. Institutional Ownership Over Time (Line) - **Chart 8.1**
5. Portfolio Size Distribution (Donut) - **Chart 8.2**
6. Effective Rent vs Market Rent (Scatter) - **Chart 1.6**

### Medium Priority Charts (Supporting Evidence)
7. Work Order Response Time (Violin) - **Chart 2.1**
8. Unit Size Distribution (Histogram) - **Chart 3.1**
9. Tenant Income Distribution (Overlaid) - **Chart 7.1**
10. FICO Score Distribution (Histogram) - **Chart 7.2**
11. Supply Reduction (Dual-axis) - **Chart 5.4**

### Lower Priority Charts (Detailed Analysis)
12. All remaining charts for comprehensive coverage

---

## Chart Evaluation Summary

**Best Chart Types Selected**:
- ✅ Stacked area/bar for component breakdowns
- ✅ Multi-line with confidence bands for trends
- ✅ Scatter plots for relationships
- ✅ Horizontal bar charts for market comparisons
- ✅ Maps for spatial data
- ✅ Overlaid histograms for distribution comparisons

**Alternatives Considered but Rejected**:
- ❌ Too many line charts (use stacked/grouped bars for composition)
- ❌ Vertical bars for markets (horizontal better for readability)
- ❌ Pie charts (donut better for composition with center space)

---

**Next Step**: Implement charts using Plotly with STRATA color scheme

