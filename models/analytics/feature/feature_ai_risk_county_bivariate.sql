-- FEATURE: County AI risk — bivariate spine (O*NET/QCEW/Epoch strand + optional AIGE).
-- Aligns with pretium-ai-dbt `feature_ai_risk_county_bivariate.sql` column contract for
-- `model_county_ai_risk_dual_index`. Strand A: **`ref('fact_county_ai_replacement_risk')`** (latest row per county).
-- Strand B: pivoted **`ref('fact_aige_counties')`** when **`aige_counties_enabled`**; else null AIGE columns.

{{ config(
    materialized='view',
    alias='feature_ai_risk_county_bivariate',
    tags=['analytics', 'feature', 'ai_risk', 'county', 'labor', 'aige', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

with replacement_latest as (
    select
        lpad(trim(f.county_fips::varchar), 5, '0')     as county_fips,
        f.county_name,
        f.state_fips,
        f.name_state,
        f.cbsa_code,
        lpad(trim(f.cbsa_id::varchar), 5, '0')       as cbsa_id,
        f.cbsa_name,
        f.raw_susceptibility,
        f.deployment_adjusted_exposure,
        f.combined_risk_score,
        f.risk_tier,
        f.total_employment,
        f.exposed_employment,
        f.exposed_wage_bill,
        f.shock_magnitude,
        f.wage_fragility_index,
        f.epoch_breadth_score,
        f.trend_8q_pct_change,
        f.trend_8q_direction,
        f.top_occupation_1,
        f.top_occupation_2,
        f.top_occupation_3,
        f.data_year,
        f.methodology_version,
        f.updated_at
    from {{ ref('fact_county_ai_replacement_risk') }} as f
    where f.county_fips is not null
    qualify row_number() over (
        partition by lpad(trim(f.county_fips::varchar), 5, '0')
        order by f.data_year desc nulls last, f.updated_at desc nulls last
    ) = 1
),

{% if var('aige_counties_enabled', false) %}
aige_pivot as (
    select
        lpad(trim(geo_id::varchar), 5, '0')          as county_fips,
        max(date_reference)                          as aige_date_reference,
        max(case when upper(trim(metric_id)) = 'AIGE_SCORE' then value end) as aige_score,
        max(case when upper(trim(metric_id)) = 'AIGE_PLOT' then value end) as aige_plot
    from {{ ref('fact_aige_counties') }}
    where lower(trim(geo_level_code)) = 'county_fips'
      and geo_id is not null
    group by lpad(trim(geo_id::varchar), 5, '0')
),
{% else %}
aige_pivot as (
    select
        cast(null as varchar) as county_fips,
        cast(null as date) as aige_date_reference,
        cast(null as double) as aige_score,
        cast(null as double) as aige_plot
    where 1 = 0
),
{% endif %}

spine as (
    select county_fips from replacement_latest
    union
    select county_fips from aige_pivot
)

select
    s.county_fips,
    r.county_name,
    r.state_fips,
    r.name_state,
    r.cbsa_code,
    r.cbsa_id,
    r.cbsa_name,
    r.raw_susceptibility,
    r.deployment_adjusted_exposure,
    r.combined_risk_score,
    r.risk_tier,
    r.total_employment,
    r.exposed_employment,
    r.exposed_wage_bill,
    r.shock_magnitude,
    r.wage_fragility_index,
    r.epoch_breadth_score,
    r.trend_8q_pct_change,
    r.trend_8q_direction,
    r.top_occupation_1,
    r.top_occupation_2,
    r.top_occupation_3,
    r.data_year                                        as onet_qcew_epoch_data_year,
    r.methodology_version                              as onet_qcew_epoch_methodology_version,
    r.updated_at                                       as onet_qcew_epoch_updated_at,
    a.aige_date_reference,
    a.aige_score,
    a.aige_plot,
    (r.county_fips is not null)                        as has_onet_qcew_epoch_replacement_risk,
    (a.aige_score is not null)                        as has_aige_score,
    current_timestamp()                                as feature_built_at
from spine as s
left join replacement_latest as r on r.county_fips = s.county_fips
left join aige_pivot as a on a.county_fips = s.county_fips

{% else %}

select
    cast(null as varchar) as county_fips,
    cast(null as varchar) as county_name,
    cast(null as varchar) as state_fips,
    cast(null as varchar) as name_state,
    cast(null as varchar) as cbsa_code,
    cast(null as varchar) as cbsa_id,
    cast(null as varchar) as cbsa_name,
    cast(null as double) as raw_susceptibility,
    cast(null as double) as deployment_adjusted_exposure,
    cast(null as double) as combined_risk_score,
    cast(null as varchar) as risk_tier,
    cast(null as double) as total_employment,
    cast(null as double) as exposed_employment,
    cast(null as double) as exposed_wage_bill,
    cast(null as double) as shock_magnitude,
    cast(null as double) as wage_fragility_index,
    cast(null as double) as epoch_breadth_score,
    cast(null as double) as trend_8q_pct_change,
    cast(null as varchar) as trend_8q_direction,
    cast(null as varchar) as top_occupation_1,
    cast(null as varchar) as top_occupation_2,
    cast(null as varchar) as top_occupation_3,
    cast(null as integer) as onet_qcew_epoch_data_year,
    cast(null as varchar) as onet_qcew_epoch_methodology_version,
    cast(null as timestamp_ntz) as onet_qcew_epoch_updated_at,
    cast(null as date) as aige_date_reference,
    cast(null as double) as aige_score,
    cast(null as double) as aige_plot,
    cast(null as boolean) as has_onet_qcew_epoch_replacement_risk,
    cast(null as boolean) as has_aige_score,
    current_timestamp() as feature_built_at
where 1 = 0

{% endif %}
