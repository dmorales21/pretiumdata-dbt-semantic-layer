-- TRANSFORM.DEV.CONCEPT_PROGRESS_FUND_ALLOCATION
-- Fund canvas: Allocate — fund header × fund×market allocation rows.
-- Grain: one row per fund_market row with fund attributes repeated (LEFT from fund_market to fund is wrong — use fund LEFT fund_market).
-- Grain: one row per fund_market row, plus fund-only rows when a fund has no markets (LEFT from fund).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_fund_allocation',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'allocate',
    ],
) }}

SELECT
    {{ dbt_utils.star(from=ref('fact_sfdc_fund_c'), relation_alias='f', prefix='fund__') }},
    {{ dbt_utils.star(from=ref('fact_sfdc_fund_market_c'), relation_alias='fm', prefix='fund_market__') }}
FROM {{ ref('fact_sfdc_fund_c') }} AS f
LEFT JOIN {{ ref('fact_sfdc_fund_market_c') }} AS fm
    ON fm.FUND__C = f.ID
