-- TRANSFORM.DEV.FACT_SE_YARDI_UNIT_STATUS_HISTORY — read-through SOURCE_ENTITY.PROGRESS.YARDI_UNIT_HISTORY
-- Unit status over time — occupancy and turn signals (Deploy).
-- `se` = SOURCE_ENTITY.PROGRESS Yardi mirror (fund modeling). Not Jon silver on TRANSFORM.YARDI (`fact_progress_yardi_*` / `fact_bh_yardi_*`).
-- Enable: `transform_dev_enable_source_entity_progress_facts: true` + grants on SOURCE_ENTITY.PROGRESS.
{{ config(
    materialized='view',
    alias='fact_se_yardi_unit_status_history',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=['transform', 'transform_dev', 'fund_opco', 'source_entity_progress', 'source_entity_progress_fact', 'yardi_entity'],
) }}

SELECT *
FROM {{ source('source_entity_progress', 'yardi_unit_history') }}
