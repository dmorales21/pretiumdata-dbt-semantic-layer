-- TRANSFORM.DEV.CONCEPT_PROGRESS_MARKET_SUBMARKET
-- Fund canvas: Allocate — market↔submarket bridge × submarket reference rows.
-- Grain: one row per bridge row with submarket attributes (orphan bridges without submarket kept via LEFT).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_market_submarket',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'allocate',
    ],
) }}

SELECT
    {{ dbt_utils.star(from=ref('fact_sfdc_market_to_submarket_c'), relation_alias='m2s', prefix='m2s__') }},
    {{ dbt_utils.star(from=ref('fact_sfdc_submarket_c'), relation_alias='sm', prefix='submarket__') }}
FROM {{ ref('fact_sfdc_market_to_submarket_c') }} AS m2s
LEFT JOIN {{ ref('fact_sfdc_submarket_c') }} AS sm
    ON m2s.SUBMARKET__C = sm.ID
