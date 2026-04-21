-- MODEL: County dual-index — AIGE × O*NET/Epoch/QCEW replacement risk (rank blend).
-- Port of pretium-ai-dbt `model_county_ai_risk_dual_index.sql`; reads **`ref('feature_ai_risk_county_bivariate')`**.
-- When only the O*NET strand is present, `dual_index_0_100` follows that strand’s percentile (legacy behavior).

{{ config(
    materialized='view',
    alias='model_county_ai_risk_dual_index',
    tags=['analytics', 'model', 'ai_risk', 'county', 'labor', 'aige', 'onet', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

{% if var('onet_soc_naics_enabled', false) %}

with base as (
    select *
    from {{ ref('feature_ai_risk_county_bivariate') }}
),

ranked as (
    select
        b.*,
        case
            when b.deployment_adjusted_exposure is not null
            then percent_rank() over (
                order by b.deployment_adjusted_exposure nulls last
            )
        end as pct_rank_onet_epoch_qcew_exposure,
        case
            when b.aige_score is not null
            then percent_rank() over (
                order by b.aige_score nulls last
            )
        end as pct_rank_aige_score
    from base as b
),

scored as (
    select
        r.*,
        case
            when r.pct_rank_onet_epoch_qcew_exposure is not null
                 and r.pct_rank_aige_score is not null
            then (r.pct_rank_onet_epoch_qcew_exposure + r.pct_rank_aige_score) / 2.0
            when r.pct_rank_onet_epoch_qcew_exposure is not null
            then r.pct_rank_onet_epoch_qcew_exposure
            when r.pct_rank_aige_score is not null
            then r.pct_rank_aige_score
        end as dual_index_percentile,
        case
            when r.pct_rank_onet_epoch_qcew_exposure is not null
                 and r.pct_rank_aige_score is not null
            then 100.0 * (
                (r.pct_rank_onet_epoch_qcew_exposure + r.pct_rank_aige_score) / 2.0
            )
            when r.pct_rank_onet_epoch_qcew_exposure is not null
            then 100.0 * r.pct_rank_onet_epoch_qcew_exposure
            when r.pct_rank_aige_score is not null
            then 100.0 * r.pct_rank_aige_score
        end as dual_index_0_100
    from ranked as r
)

select
    county_fips,
    county_name,
    state_fips,
    cbsa_code,
    cbsa_id,
    has_onet_qcew_epoch_replacement_risk,
    has_aige_score,
    deployment_adjusted_exposure,
    aige_score,
    combined_risk_score,
    shock_magnitude,
    pct_rank_onet_epoch_qcew_exposure,
    pct_rank_aige_score,
    round(dual_index_percentile, 4)                    as dual_index_percentile,
    round(dual_index_0_100, 2)                        as dual_index_0_100,
    case
        when coalesce(has_onet_qcew_epoch_replacement_risk, false) = false
             and coalesce(has_aige_score, false) = false
            then 'INSUFFICIENT'
        when coalesce(has_onet_qcew_epoch_replacement_risk, false)
             and coalesce(has_aige_score, false)
             and pct_rank_onet_epoch_qcew_exposure >= 0.67
             and pct_rank_aige_score >= 0.67
            then 'BOTH_HIGH'
        when greatest(
                coalesce(pct_rank_onet_epoch_qcew_exposure, 0),
                coalesce(pct_rank_aige_score, 0)
            ) >= 0.67
            then 'ELEVATED'
        when coalesce(has_onet_qcew_epoch_replacement_risk, false)
             or coalesce(has_aige_score, false)
            then 'MODERATE'
        else 'INSUFFICIENT'
    end                                                as dual_index_tier,
    onet_qcew_epoch_methodology_version,
    aige_date_reference,
    current_timestamp()                                as model_built_at
from scored

{% else %}

select
    cast(null as varchar) as county_fips,
    cast(null as varchar) as county_name,
    cast(null as varchar) as state_fips,
    cast(null as varchar) as cbsa_code,
    cast(null as varchar) as cbsa_id,
    cast(null as boolean) as has_onet_qcew_epoch_replacement_risk,
    cast(null as boolean) as has_aige_score,
    cast(null as double) as deployment_adjusted_exposure,
    cast(null as double) as aige_score,
    cast(null as double) as combined_risk_score,
    cast(null as double) as shock_magnitude,
    cast(null as double) as pct_rank_onet_epoch_qcew_exposure,
    cast(null as double) as pct_rank_aige_score,
    cast(null as double) as dual_index_percentile,
    cast(null as double) as dual_index_0_100,
    cast(null as varchar) as dual_index_tier,
    cast(null as varchar) as onet_qcew_epoch_methodology_version,
    cast(null as date) as aige_date_reference,
    current_timestamp() as model_built_at
where 1 = 0

{% endif %}
