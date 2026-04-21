-- TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW
-- Fund canvas: Returns + Sensitivity — acquisition economics × finance due diligence scenarios.
-- Grain: one row per finance due diligence row with acquisition attributes (UW / scenario stack).
-- Join: default `ENTITY__C` → `ID` (Progress landings); set vars if your org uses `Acquisition__c` or another FK.
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_acquisition_uw',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'returns', 'sensitivity',
    ],
) }}

SELECT
    {{ dbt_utils.star(from=ref('fact_sfdc_acquisition_c'), relation_alias='a', prefix='acquisition__') }},
    {{ dbt_utils.star(from=ref('fact_sfdc_finance_due_diligence_c'), relation_alias='fdd', prefix='fdd__') }}
FROM {{ ref('fact_sfdc_finance_due_diligence_c') }} AS fdd
LEFT JOIN {{ ref('fact_sfdc_acquisition_c') }} AS a
    ON fdd.{{ adapter.quote(var('concept_progress_fdd_acquisition_fk_column')) }}
        = a.{{ adapter.quote(var('concept_progress_sfdc_acquisition_id_column')) }}
