-- Grain: (yardi_unit_hkey) — one row per unit (Progress). Source: TRANSFORM.YARDI.UNIT_PROGRESS.
{{ config(
    materialized='table',
    alias='fact_progress_yardi_unit',
    enabled=var('transform_dev_enable_fund_opco_facts', true),
    cluster_by=['yardi_property_hkey', 'yardi_unit_hkey'],
    tags=['transform', 'transform_dev', 'fund_opco', 'yardi', 'progress', 'fact_yardi', 'unit'],
) }}

SELECT
    'PROGRESS' AS opco_code,
    'YARDI' AS vendor_name,
    'TRANSFORM.YARDI.UNIT_PROGRESS' AS source_dataset,
    'SNAPSHOT' AS vendor_time_grain,
    'DAILY' AS expected_source_refresh_frequency,
    u.HPROPERTY AS yardi_property_hkey,
    u.HMY AS yardi_unit_hkey,
    NULLIF(TRIM(u.SCODE::VARCHAR), '') AS unit_number,
    u.IBEDROOMS AS bedroom_count,
    u.DSQFT::FLOAT AS sqft,
    NULLIF(TRIM(u.SSTATUS::VARCHAR), '') AS unit_status,
    u.SRENT::FLOAT AS contract_rent,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM {{ source('transform_yardi', 'UNIT_PROGRESS') }} AS u
