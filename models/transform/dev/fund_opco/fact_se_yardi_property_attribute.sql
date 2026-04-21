-- TRANSFORM.DEV.FACT_SE_YARDI_PROPERTY_ATTRIBUTE — read-through SOURCE_ENTITY.PROGRESS.YARDI_PROPATTRIBUTES
-- Property-level attributes and risk-tier inputs (Allocate / Sensitivity).
-- `se` = SOURCE_ENTITY.PROGRESS Yardi mirror (fund modeling). Not Jon silver on TRANSFORM.YARDI (`fact_progress_yardi_*` / `fact_bh_yardi_*`).
-- Enable: `transform_dev_enable_source_entity_progress_facts: true` + grants on SOURCE_ENTITY.PROGRESS.
{{ config(
    materialized='view',
    alias='fact_se_yardi_property_attribute',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=['transform', 'transform_dev', 'fund_opco', 'source_entity_progress', 'source_entity_progress_fact', 'yardi_entity'],
) }}

SELECT *
FROM {{ source('source_entity_progress', 'yardi_propattributes') }}
