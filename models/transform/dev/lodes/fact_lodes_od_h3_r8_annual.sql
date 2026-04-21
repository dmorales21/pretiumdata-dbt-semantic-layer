-- TRANSFORM.DEV.FACT_LODES_OD_H3_R8_ANNUAL — read-through of Jon silver TRANSFORM.LODES.OD_H3_R8 (~3.9M rows).
-- Grain: (vintage_year, h3_r8_residence, h3_r8_workplace). Feeds employment-center / commute-shed chain.
-- Migration: MIGRATION_RULES.md §3; corridor: MIGRATION_TASKS_CORRIDOR_PIPELINE_SOURCES.md §2.2–2.3.
{{ config(
    alias='fact_lodes_od_h3_r8_annual',
    tags=['transform', 'transform_dev', 'lodes', 'fact_lodes', 'lehd', 'corridor', 'h3'],
) }}

SELECT *
FROM {{ source('transform_lodes', 'od_h3_r8') }}
