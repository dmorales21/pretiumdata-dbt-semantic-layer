-- County-level AI automation risk (structural FEATURE + optional AIGE).
-- Port of pretium-ai-dbt `mart_county_ai_automation_risk.sql` grain; modeled as FACT_* per
-- `docs/rules/ARCHITECTURE_RULES.md` (typed observational table in **TRANSFORM.DEV**).

{{ config(
    materialized='table',
    alias='fact_county_ai_automation_risk',
    tags=['transform', 'transform_dev', 'semantic', 'entity', 'ai_risk', 'county', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

with structural_latest as (
    select
        county_fips,
        date_reference                                    as structural_risk_date_reference,
        structural_unemployment_risk_score,
        risk_tier                                         as structural_unemployment_risk_tier
    from {{ ref('feature_structural_unemployment_risk_county') }}
    where county_fips is not null
      and structural_unemployment_risk_score is not null
    qualify row_number() over (
        partition by county_fips
        order by date_reference desc
    ) = 1
),

{% if var('aige_counties_enabled', false) %}
aige_latest as (
    select
        lpad(trim(geo_id::varchar), 5, '0')               as county_fips,
        date_reference                                    as aige_date_reference,
        max(case when upper(trim(metric_id)) = 'AIGE_SCORE' then value end) as aige_score,
        max(case when upper(trim(metric_id)) = 'AIGE_PLOT' then value end) as aige_plot
    from {{ ref('fact_aige_counties') }}
    where geo_id is not null
      and lower(trim(geo_level_code)) = 'county_fips'
    group by lpad(trim(geo_id::varchar), 5, '0'), date_reference
    qualify row_number() over (
        partition by lpad(trim(geo_id::varchar), 5, '0')
        order by date_reference desc
    ) = 1
),
{% else %}
aige_latest as (
    select
        cast(null as varchar) as county_fips,
        cast(null as date) as aige_date_reference,
        cast(null as double) as aige_score,
        cast(null as double) as aige_plot
    where 1 = 0
),
{% endif %}

county_spine as (
    select county_fips from structural_latest
    union
    select county_fips from aige_latest
)

select
    s.county_fips,
    st.structural_risk_date_reference,
    st.structural_unemployment_risk_score,
    st.structural_unemployment_risk_tier,
    a.aige_date_reference,
    a.aige_score,
    a.aige_plot,
    current_timestamp()                                 as dbt_updated_at
from county_spine as s
left join structural_latest as st on st.county_fips = s.county_fips
left join aige_latest as a on a.county_fips = s.county_fips

{% else %}

select
    cast(null as varchar) as county_fips,
    cast(null as date) as structural_risk_date_reference,
    cast(null as double) as structural_unemployment_risk_score,
    cast(null as varchar) as structural_unemployment_risk_tier,
    cast(null as date) as aige_date_reference,
    cast(null as double) as aige_score,
    cast(null as double) as aige_plot,
    current_timestamp() as dbt_updated_at
where 1 = 0

{% endif %}
