-- FEATURE: Structural unemployment risk label at county (IC / LDI input).
-- Legacy: pass-through from `feature_ai_replacement_risk_county` with fixed HIGH/MEDIUM/LOW cutoffs on score.
-- Canonical: uses **`ai_replacement_risk_score`** (= `combined_risk_score` on county feature) and **re-applies**
-- numeric cutoffs for consumers that expect 0.5 / 0.7 thresholds; see YAML for drift vs `fact_county_ai_replacement_risk.risk_tier`
-- (percentile-based on the fact).

{{ config(
    materialized='view',
    alias='feature_structural_unemployment_risk_county',
    tags=['analytics', 'feature', 'structural_risk', 'county', 'ic_input', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

select
    c.date_reference,
    c.county_fips,
    c.ai_replacement_risk_score                        as structural_unemployment_risk_score,
    case
        when c.ai_replacement_risk_score >= 0.7       then 'HIGH'
        when c.ai_replacement_risk_score >= 0.5       then 'MEDIUM'
        else                                             'LOW'
    end                                                as risk_tier,
    current_timestamp()                                as created_at
from {{ ref('feature_ai_replacement_risk_county') }} as c
where c.ai_replacement_risk_score is not null

{% else %}

select
    cast(null as date)                                 as date_reference,
    cast(null as varchar)                              as county_fips,
    cast(null as float)                                as structural_unemployment_risk_score,
    cast(null as varchar)                              as risk_tier,
    current_timestamp()                                as created_at
where 1 = 0

{% endif %}
