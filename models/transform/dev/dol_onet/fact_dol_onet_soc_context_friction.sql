-- DOL / O*NET: SOC-level work-context friction index (physical substitution / presence).
-- Port of pretium-ai-dbt `cleaned_onet_context_friction.sql`.
-- Grain: one row per `onet_soc_code`.

{{ config(
    alias='FACT_DOL_ONET_SOC_CONTEXT_FRICTION',
    materialized='table',
    tags=['transform', 'transform_dev', 'onet', 'dol_onet', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

with raw_context as (

    select
        onet_soc_code,

        max(case when context_category = 'Physical Proximity'
            then frequency / 100.0 end)                   as physical_proximity_raw,

        max(case when context_category = 'Face-to-Face Discussions with Individuals and Within Teams'
            then frequency / 100.0 end)                   as face_to_face_raw,

        max(case when context_category = 'In an Open Vehicle or Operating Equipment'
            then frequency / 100.0 end)                   as open_vehicle_raw,

        max(case when context_category = 'In an Enclosed Vehicle or Operate Enclosed Equipment'
            then frequency / 100.0 end)                   as enclosed_vehicle_raw,

        max(case when context_category = 'Spend Time Using Your Hands to Handle, Control, or Feel Objects, Tools, or Controls'
            then frequency / 100.0 end)                   as hands_raw,

        max(case when context_category = 'Spend Time Walking or Running'
            then frequency / 100.0 end)                   as walking_raw,

        max(case when context_category = 'Spend Time Kneeling, Crouching, Stooping, or Crawling'
            then frequency / 100.0 end)                   as kneeling_raw,

        max(case when context_category = 'Exposed to Hazardous Equipment'
            then frequency / 100.0 end)                   as hazard_equip_raw,

        max(case when context_category = 'Exposed to Disease or Infections'
            then frequency / 100.0 end)                   as disease_raw,

        max(case when context_category = 'Contact With Others'
            then frequency / 100.0 end)                   as contact_others_raw,

        max(case when context_category = 'Deal With External Customers or the Public in General'
            then frequency / 100.0 end)                   as public_contact_raw,

        max(case when context_category = 'Dealing with Violent or Physically Aggressive People'
            then frequency / 100.0 end)                   as violent_people_raw

    from {{ source('source_prod_onet', 'work_context') }}
    group by onet_soc_code

),

friction_components as (

    select
        onet_soc_code,

        coalesce(physical_proximity_raw, 0.0)             as physical_proximity_score,
        coalesce(face_to_face_raw, 0.0)                   as face_to_face_score,

        greatest(
            coalesce(open_vehicle_raw, 0.0),
            coalesce(enclosed_vehicle_raw, 0.0)
        )                                                 as outdoor_environment_score,

        (
            coalesce(hands_raw, 0.0) * 0.50 +
            coalesce(walking_raw, 0.0) * 0.30 +
            coalesce(kneeling_raw, 0.0) * 0.20
        )                                                 as physical_body_score,

        greatest(
            coalesce(hazard_equip_raw, 0.0),
            coalesce(disease_raw, 0.0)
        )                                                 as hazard_score,

        greatest(
            coalesce(contact_others_raw, 0.0),
            coalesce(public_contact_raw, 0.0),
            coalesce(violent_people_raw, 0.0)
        )                                                 as public_contact_score

    from raw_context

)

select
    onet_soc_code,

    least(1.0, greatest(0.0,
        physical_proximity_score  * 0.25 +
        face_to_face_score        * 0.25 +
        outdoor_environment_score * 0.15 +
        physical_body_score       * 0.20 +
        hazard_score              * 0.05 +
        public_contact_score      * 0.10
    ))                                                    as friction_index,

    round(physical_proximity_score, 4)                   as physical_proximity_score,
    round(face_to_face_score, 4)                         as face_to_face_score,
    round(outdoor_environment_score, 4)                  as outdoor_environment_score,
    round(physical_body_score, 4)                       as physical_body_score,
    round(hazard_score, 4)                               as hazard_score,
    round(public_contact_score, 4)                       as public_contact_score,

    current_timestamp()                                  as updated_at

from friction_components
