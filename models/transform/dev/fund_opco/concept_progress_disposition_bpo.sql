-- TRANSFORM.DEV.CONCEPT_PROGRESS_DISPOSITION_BPO
-- Fund canvas: Returns + Sensitivity — disposition economics × BPO mark-to-market (property-level bridge).
-- Grain: one row per disposition row with matching BPO rows on PROPERTY__C (adjust join after vet if BPO keys off acquisition or opportunity instead).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_disposition_bpo',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'returns', 'sensitivity',
    ],
) }}

SELECT
    {{ dbt_utils.star(from=ref('fact_sfdc_disposition_c'), relation_alias='d', prefix='disposition__') }},
    {{ dbt_utils.star(from=ref('fact_sfdc_bpo_c'), relation_alias='b', prefix='bpo__') }}
FROM {{ ref('fact_sfdc_disposition_c') }} AS d
LEFT JOIN {{ ref('fact_sfdc_bpo_c') }} AS b
    ON d.PROPERTY__C = b.PROPERTY__C
