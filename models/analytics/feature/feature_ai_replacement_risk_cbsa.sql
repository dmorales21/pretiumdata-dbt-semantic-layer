-- FEATURE: CBSA × NAICS aggregate row for AI replacement risk (employment-weighted from county fact).
-- Legacy pretium-ai-dbt mixed `fact_economy_automation_risk` + `fact_household_labor_qcew_naics` at CBSA grain.
-- Canonical semantic layer: **one synthetic NAICS bucket `'ALL'`** per (date_reference, cbsa_code) from
-- `fact_county_ai_replacement_risk` so LDI / consumers can keep a NAICS-shaped join key until a real
-- CBSA × NAICS industry stack is ported.
--
-- Grain: (date_reference, cbsa_code, naics_code) with naics_code = 'ALL'.

{{ config(
    materialized='view',
    alias='feature_ai_replacement_risk_cbsa',
    tags=['analytics', 'feature', 'ai_risk', 'cbsa', 'naics', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

with base as (
    select
        date_from_parts(f.data_year, 12, 31)          as date_reference,
        lpad(trim(f.cbsa_id::varchar), 5, '0')        as cbsa_code,
        f.total_employment                             as employment_level,
        f.combined_risk_score,
        f.raw_susceptibility,
        f.deployment_adjusted_exposure,
        f.shock_magnitude
    from {{ ref('fact_county_ai_replacement_risk') }} as f
    where f.cbsa_id is not null
      and f.total_employment is not null
      and f.total_employment > 0
      and f.combined_risk_score is not null
),

agg as (
    select
        date_reference,
        cbsa_code,
        'ALL'::varchar(10)                             as naics_code,
        sum(employment_level)                        as employment_level,
        sum(combined_risk_score * employment_level)
            / nullif(sum(employment_level), 0)       as combined_ai_risk_score,
        sum(raw_susceptibility * employment_level)
            / nullif(sum(employment_level), 0)     as occupation_risk_score,
        sum(shock_magnitude * employment_level)
            / nullif(sum(employment_level), 0)     as industry_risk_score
    from base
    group by date_reference, cbsa_code
)

select
    date_reference,
    cbsa_code,
    naics_code,
    employment_level,
    occupation_risk_score,
    industry_risk_score,
    combined_ai_risk_score,
    case
        when combined_ai_risk_score >= 0.7          then 'HIGH'
        when combined_ai_risk_score >= 0.5         then 'MEDIUM'
        else                                           'LOW'
    end                                                as risk_tier,
    current_timestamp()                              as created_at
from agg
where combined_ai_risk_score is not null

{% else %}

select
    cast(null as date)                                 as date_reference,
    cast(null as varchar)                              as cbsa_code,
    cast(null as varchar)                              as naics_code,
    cast(null as float)                                as employment_level,
    cast(null as float)                                as occupation_risk_score,
    cast(null as float)                                as industry_risk_score,
    cast(null as float)                                as combined_ai_risk_score,
    cast(null as varchar)                              as risk_tier,
    current_timestamp()                                as created_at
where 1 = 0

{% endif %}
