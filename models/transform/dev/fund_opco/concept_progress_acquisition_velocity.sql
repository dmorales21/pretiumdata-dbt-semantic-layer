-- TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_VELOCITY
-- Fund canvas: Deploy — acquisition master × field history (stage-change velocity).
-- Grain: one row per history row with current acquisition snapshot columns.
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_acquisition_velocity',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'deploy',
    ],
) }}

SELECT
    {{ dbt_utils.star(from=ref('fact_sfdc_acquisition_c'), relation_alias='a', prefix='acquisition__') }},
    {{ dbt_utils.star(from=ref('fact_sfdc_acquisition_history'), relation_alias='h', prefix='acq_history__') }}
FROM {{ ref('fact_sfdc_acquisition_history') }} AS h
LEFT JOIN {{ ref('fact_sfdc_acquisition_c') }} AS a
    ON h.PARENTID = a.ID
