-- cleaned_onet_gwa_activity_risk.sql
-- Recomputes SOC-level GWA activity risk scores from scratch.
-- v2: Recalibrated floors to fix score compression — physical/interpersonal
--     floors were pulling all occupations toward 0.35–0.44. Now knowledge-work
--     reaches ~1.0; physical/social stay near 0.02–0.24.
--
-- Scoring logic (per GWA × SOC row):
--   importance 1-5 scales within each tier; activity_id sets the tier floor/ceiling

{{ config(
    alias='FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK',
    materialized='table',
    tags=['transform', 'transform_dev', 'onet', 'dol_onet', 'T-ANALYTICS-LABOR-AUTOMATION-RISK-STACK'],
) }}

with gwa_with_risk as (

    select
        wag.onet_soc_code,
        wag.activity_id,
        wag.activity_name,
        wag.importance,

        -- ── Cognitive exposure potential by GWA category ──────────────
        -- Information Input (4.A.1.*): getting/monitoring/identifying info
        -- Mental Processes (4.A.2.*): analysis, decision, creativity
        -- Work Output - Computer (4.A.3.b.*): computer-mediated tasks
        -- Interacting With Others (4.A.4.*): communication/social
        -- Work Output - Physical (4.A.3.a.*): manual/physical tasks

        case
            -- High cognitive, high AI exposure (v2: 0.70–1.0 so knowledge-work separates)
            when wag.activity_id in (
                '4.A.1.a.1',  -- Getting Information
                '4.A.2.a.2',  -- Processing Information
                '4.A.2.a.4',  -- Analyzing Data or Information
                '4.A.3.b.6',  -- Documenting/Recording Information
                '4.A.3.b.1',  -- Working with Computers
                '4.A.2.a.3',  -- Evaluating Information to Determine Compliance
                '4.A.1.b.3'   -- Estimating Quantifiable Characteristics
            ) then
                0.70 + (wag.importance - 1) * 0.075

            -- Moderate cognitive, mixed exposure (v2: 0.25 floor for mid-range separation)
            when wag.activity_id in (
                '4.A.2.b.1',  -- Making Decisions and Solving Problems
                '4.A.2.b.3',  -- Updating and Using Relevant Knowledge
                '4.A.2.b.6',  -- Organizing, Planning, and Prioritizing Work
                '4.A.2.b.5',  -- Scheduling Work and Activities
                '4.A.4.c.1',  -- Performing Administrative Activities
                '4.A.4.b.3',  -- Training and Teaching Others
                '4.A.4.a.1',  -- Interpreting the Meaning of Information for Others
                '4.A.1.b.1'   -- Identifying Objects, Actions, and Events
            ) then
                0.25 + (wag.importance - 1) * 0.08

            -- Social/interpersonal (v2: 0.04 floor — was primary compression source)
            when wag.activity_id in (
                '4.A.4.a.2',  -- Communicating with Supervisors/Peers/Subordinates
                '4.A.4.a.3',  -- Communicating with People Outside the Organization
                '4.A.4.a.4',  -- Establishing and Maintaining Interpersonal Relationships
                '4.A.4.a.6',  -- Selling or Influencing Others
                '4.A.4.a.7',  -- Resolving Conflicts and Negotiating with Others
                '4.A.4.a.8',  -- Performing for or Working Directly with the Public
                '4.A.4.b.4',  -- Guiding, Directing, and Motivating Subordinates
                '4.A.4.b.5',  -- Coaching and Developing Others
                '4.A.4.b.6',  -- Providing Consultation and Advice to Others
                '4.A.4.a.5'   -- Assisting and Caring for Others
            ) then
                0.04 + (wag.importance - 1) * 0.05

            -- Creative/strategic — high human judgment component
            when wag.activity_id in (
                '4.A.2.b.2',  -- Thinking Creatively
                '4.A.2.b.4',  -- Developing Objectives and Strategies
                '4.A.1.a.2'   -- Monitoring Processes, Materials, or Surroundings
            ) then
                0.25 + (wag.importance - 1) * 0.07

            -- Physical work (v2: 0.02 floor — cognitive AI ≠ robotic automation)
            when wag.activity_id in (
                '4.A.3.a.1',  -- Performing General Physical Activities
                '4.A.3.a.2',  -- Handling and Moving Objects
                '4.A.3.a.3',  -- Controlling Machines and Processes
                '4.A.3.a.4',  -- Operating Vehicles, Mechanized Devices, or Equipment
                '4.A.3.b.4',  -- Repairing and Maintaining Mechanical Equipment
                '4.A.3.b.5',  -- Repairing and Maintaining Electronic Equipment
                '4.A.1.b.2'   -- Inspecting Equipment, Structures, or Materials
            ) then
                0.02 + (wag.importance - 1) * 0.04

            -- Management/coordination
            when wag.activity_id in (
                '4.A.4.b.1',  -- Coordinating the Work and Activities of Others
                '4.A.4.b.2',  -- Developing and Building Teams
                '4.A.4.c.2',  -- Staffing Organizational Units
                '4.A.4.c.3'   -- Monitoring and Controlling Resources
            ) then
                0.25 + (wag.importance - 1) * 0.06

            -- Technical design
            when wag.activity_id in (
                '4.A.3.b.2'   -- Drafting, Laying Out, Specifying Technical Devices
            ) then
                0.30 + (wag.importance - 1) * 0.07

            else 0.15  -- fallback for unmapped activities (v2: was 0.40, inflated ~5 per SOC)
        end as activity_exposure_score,

        -- Sub-domain classification for sub-scores
        case
            when wag.activity_id like '4.A.1.%' then 'INFORMATION_INPUT'
            when wag.activity_id like '4.A.2.%' then 'MENTAL_PROCESS'
            when wag.activity_id like '4.A.3.%' then 'WORK_OUTPUT'
            when wag.activity_id like '4.A.4.%' then 'INTERACTING'
            else 'OTHER'
        end as gwa_domain,

        -- Importance as weight (normalized 0-1)
        wag.importance / 5.0 as importance_weight

    from {{ source('source_prod_onet', 'work_activities_general') }} wag
    where wag.importance is not null

),

soc_scores as (

    select
        onet_soc_code,
        -- Overall importance-weighted score
        sum(activity_exposure_score * importance_weight)
            / nullif(sum(importance_weight), 0)           as raw_activity_exposure,

        -- Sub-scores by GWA domain
        sum(case when gwa_domain = 'INFORMATION_INPUT'
            then activity_exposure_score * importance_weight else 0 end)
            / nullif(sum(case when gwa_domain = 'INFORMATION_INPUT'
            then importance_weight else 0 end), 0)        as information_input_risk,

        sum(case when gwa_domain = 'MENTAL_PROCESS'
            then activity_exposure_score * importance_weight else 0 end)
            / nullif(sum(case when gwa_domain = 'MENTAL_PROCESS'
            then importance_weight else 0 end), 0)        as mental_process_risk,

        sum(case when gwa_domain = 'INTERACTING'
            then activity_exposure_score * importance_weight else 0 end)
            / nullif(sum(case when gwa_domain = 'INTERACTING'
            then importance_weight else 0 end), 0)        as interacting_risk,

        sum(case when gwa_domain = 'WORK_OUTPUT'
            then activity_exposure_score * importance_weight else 0 end)
            / nullif(sum(case when gwa_domain = 'WORK_OUTPUT'
            then importance_weight else 0 end), 0)        as work_output_risk,

        count(*)                                           as scored_activity_count

    from gwa_with_risk
    group by onet_soc_code

)

select
    onet_soc_code,
    least(1.0, greatest(0.0, raw_activity_exposure))    as gwa_activity_risk_score,
    round(information_input_risk, 4)                    as information_input_risk,
    round(mental_process_risk, 4)                       as mental_process_risk,
    round(interacting_risk, 4)                          as interacting_risk,
    round(work_output_risk, 4)                          as work_output_risk,
    scored_activity_count,
    current_timestamp()                                 as updated_at
from soc_scores
