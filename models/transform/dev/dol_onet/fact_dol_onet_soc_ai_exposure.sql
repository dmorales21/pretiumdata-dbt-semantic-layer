-- DOL / O*NET: SOC-level AI exposure (GWA activity × work-context friction × Epoch breadth).
-- Port of pretium-ai-dbt `cleaned_onet_soc_ai_exposure.sql`; refs vendor-scoped FACT_ names here.
-- Grain: one row per `onet_soc_code`.

{{ config(
    alias='FACT_DOL_ONET_SOC_AI_EXPOSURE',
    materialized='table',
    tags=['transform', 'transform_dev', 'onet', 'dol_onet', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

with activity as (
    select * from {{ ref('fact_dol_onet_soc_gwa_activity_risk') }}
),

friction as (
    select * from {{ ref('fact_dol_onet_soc_context_friction') }}
),

occupations as (
    select onet_soc_code, title as occupation_title
    from {{ source('source_prod_onet', 'occupation_base') }}
),

gwa_crosswalk as (
    select * from {{ ref('ref_epoch_to_gwa_crosswalk') }}
),

aug_sub_weights as (
    select
        wag.onet_soc_code,
        avg(case when xwalk.is_augmentation_primary = true  then xwalk.exposure_weight end) as aug_weight,
        avg(case when xwalk.is_augmentation_primary = false then xwalk.exposure_weight end) as sub_weight
    from {{ source('source_prod_onet', 'work_activities_general') }} wag
    left join gwa_crosswalk xwalk
        on wag.activity_id = xwalk.gwa_activity_id
    where wag.importance is not null
    group by wag.onet_soc_code
),

top_activity as (
    select
        wag.onet_soc_code,
        first_value(wag.activity_name) over (
            partition by wag.onet_soc_code
            order by wag.importance * coalesce(xwalk.exposure_weight, 0) desc
        ) as top_exposed_activity
    from {{ source('source_prod_onet', 'work_activities_general') }} wag
    left join gwa_crosswalk xwalk
        on wag.activity_id = xwalk.gwa_activity_id
    where wag.importance is not null
    qualify row_number() over (partition by wag.onet_soc_code order by wag.importance * coalesce(xwalk.exposure_weight, 0) desc) = 1
),

augmentation_signal as (
    select
        w.onet_soc_code,
        w.aug_weight,
        w.sub_weight,
        t.top_exposed_activity
    from aug_sub_weights w
    join top_activity t using (onet_soc_code)
),

epoch_coverage as (
    select
        soc_dim.onet_soc_code,
        count(distinct soc_dim.capability_dimension)       as epoch_covered_dimensions,
        round(
            least(1.0, sum(soc_dim.dim_max_score) / 6.12),
            4
        )                                                  as epoch_capability_coverage
    from (
        select
            w.onet_soc_code,
            x.capability_dimension,
            max((w.importance / 5.0) * x.exposure_weight) as dim_max_score
        from {{ source('source_prod_onet', 'work_activities_general') }} w
        inner join gwa_crosswalk x
            on w.activity_id = x.gwa_activity_id
        where w.importance is not null
        group by w.onet_soc_code, x.capability_dimension
    ) soc_dim
    group by soc_dim.onet_soc_code
),

combined as (

    select
        a.onet_soc_code,
        left(a.onet_soc_code, 7)                           as soc_code,
        o.occupation_title,
        a.gwa_activity_risk_score                          as raw_activity_exposure,
        f.friction_index,

        round(
            a.gwa_activity_risk_score * (1.0 - f.friction_index),
            4
        )                                                  as friction_adjusted_exposure,

        a.information_input_risk,
        a.mental_process_risk,
        a.interacting_risk,
        a.work_output_risk,
        f.physical_proximity_score,
        f.face_to_face_score,
        f.outdoor_environment_score,
        f.physical_body_score,

        coalesce(aug.aug_weight, 0) > coalesce(aug.sub_weight, 0) as is_augmentation_dominant,
        aug.top_exposed_activity,

        coalesce(ec.epoch_covered_dimensions, 0)           as epoch_covered_dimensions,
        coalesce(ec.epoch_capability_coverage, 0.0)        as epoch_capability_coverage,

        a.scored_activity_count,
        current_timestamp()                                as updated_at,
        'v2_gwa_pilot'                                     as methodology_version

    from activity a
    left join friction f using (onet_soc_code)
    left join occupations o using (onet_soc_code)
    left join augmentation_signal aug using (onet_soc_code)
    left join epoch_coverage ec using (onet_soc_code)

),

tier_floors as (
    select
        percentile_cont(0.90) within group (order by friction_adjusted_exposure) as tier_very_high_floor,
        percentile_cont(0.75) within group (order by friction_adjusted_exposure) as tier_high_floor,
        percentile_cont(0.40) within group (order by friction_adjusted_exposure) as tier_medium_floor
    from combined
)

select
    c.onet_soc_code,
    c.soc_code,
    c.occupation_title,
    c.raw_activity_exposure,
    c.friction_index,
    c.friction_adjusted_exposure,

    case
        when c.friction_adjusted_exposure >= t.tier_very_high_floor then 'VERY_HIGH'
        when c.friction_adjusted_exposure >= t.tier_high_floor    then 'HIGH'
        when c.friction_adjusted_exposure >= t.tier_medium_floor then 'MEDIUM'
        else                                                      'LOW'
    end                                                    as exposure_tier,

    round(t.tier_very_high_floor, 4)                       as tier_very_high_floor,
    round(t.tier_high_floor, 4)                            as tier_high_floor,
    round(t.tier_medium_floor, 4)                         as tier_medium_floor,

    c.information_input_risk,
    c.mental_process_risk,
    c.interacting_risk,
    c.work_output_risk,
    c.physical_proximity_score,
    c.face_to_face_score,
    c.outdoor_environment_score,
    c.physical_body_score,
    c.is_augmentation_dominant,
    c.top_exposed_activity,
    c.epoch_covered_dimensions,
    c.epoch_capability_coverage,
    c.scored_activity_count,
    c.updated_at,
    c.methodology_version

from combined c
cross join tier_floors t
