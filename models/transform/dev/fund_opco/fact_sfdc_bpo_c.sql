-- TRANSFORM.DEV.FACT_SFDC_BPO_C — read-through of SOURCE_ENTITY.PROGRESS.SFDC_BPO__C
-- SFDC_BPO__C broker price opinion
-- Enable when role can SELECT SOURCE_ENTITY.PROGRESS: set `transform_dev_enable_source_entity_progress_facts: true`.
-- Differs from Jon-silver `fact_progress_yardi_*` / `fact_bh_yardi_*` (TRANSFORM.YARDI) where noted in sources YAML.
{{ config(
    materialized='view',
    alias='fact_sfdc_bpo_c',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=['transform', 'transform_dev', 'fund_opco', 'source_entity_progress', 'source_entity_progress_fact', 'sfdc'],
) }}

SELECT *
FROM {{ source('source_entity_progress', 'sfdc_bpo__c') }}
