-- FEATURE: County AI replacement / structural risk inputs (from TRANSFORM.DEV county fact).
-- Replaces pretium-ai-dbt `analytics_prod/features/feature_ai_replacement_risk_county.sql` which used
-- deprecated `h3_xwalk_6810_canon` + `feature_ai_replacement_risk_cbsa` (economy automation + household QCEW).
-- This version reads **`fact_county_ai_replacement_risk`** (O*NET × QCEW × Epoch stack) per
-- `docs/migration/LABOR_AUTOMATION_RISK_STACK_SEMANTIC_LAYER.md`.
--
-- Grain: (date_reference, county_fips). `date_reference` = last day of `data_year` from the fact snapshot.

{{ config(
    materialized='view',
    alias='feature_ai_replacement_risk_county',
    tags=['analytics', 'feature', 'ai_risk', 'county', 'structural_risk', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

select
    date_from_parts(f.data_year, 12, 31)              as date_reference,
    lpad(trim(f.county_fips::varchar), 5, '0')         as county_fips,
    f.combined_risk_score                              as ai_replacement_risk_score,
    f.deployment_adjusted_exposure,
    f.raw_susceptibility,
    f.shock_magnitude,
    f.risk_tier,
    f.total_employment                                 as county_employment_level,
    lpad(trim(f.cbsa_id::varchar), 5, '0')             as cbsa_id,
    current_timestamp()                                as created_at
from {{ ref('fact_county_ai_replacement_risk') }} as f
where f.combined_risk_score is not null

{% else %}

select
    cast(null as date)                                 as date_reference,
    cast(null as varchar)                              as county_fips,
    cast(null as float)                                as ai_replacement_risk_score,
    cast(null as float)                                as deployment_adjusted_exposure,
    cast(null as float)                                as raw_susceptibility,
    cast(null as float)                                as shock_magnitude,
    cast(null as varchar)                              as risk_tier,
    cast(null as float)                                as county_employment_level,
    cast(null as varchar)                              as cbsa_id,
    current_timestamp()                                as created_at
where 1 = 0

{% endif %}
