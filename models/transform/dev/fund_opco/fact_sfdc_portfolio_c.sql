-- TRANSFORM.DEV.FACT_SFDC_PORTFOLIO_C — read-through of SOURCE_ENTITY.PROGRESS.SFDC_PORTFOLIO__C
-- SFDC_PORTFOLIO__C portfolio / strategy
-- Enable when role can SELECT SOURCE_ENTITY.PROGRESS: set `transform_dev_enable_source_entity_progress_facts: true`.
-- Differs from Jon-silver `fact_progress_yardi_*` / `fact_bh_yardi_*` (TRANSFORM.YARDI) where noted in sources YAML.
{{ config(
    materialized='view',
    alias='fact_sfdc_portfolio_c',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=['transform', 'transform_dev', 'fund_opco', 'source_entity_progress', 'source_entity_progress_fact', 'sfdc'],
) }}

SELECT *
FROM {{ source('source_entity_progress', 'sfdc_portfolio__c') }}
