-- TRANSFORM.DEV.FACT_LODES_OD_BG — read-through of Jon silver TRANSFORM.LODES.OD_BG (~64M rows).
-- View only (no duplicate physical table). Migration: MIGRATION_RULES.md §3 / §5.
-- Governance: confirm read path vs SOURCE_PROD.LEHD / cleaned LODES (MIGRATION_TASKS… Part E).
{{ config(
    alias='fact_lodes_od_bg',
    tags=['transform', 'transform_dev', 'lodes', 'fact_lodes', 'lehd'],
) }}

SELECT *
FROM {{ source('transform_lodes', 'od_bg') }}
