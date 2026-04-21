-- Grain: (yardi_property_hkey) — current-state property master (Progress).
-- Source: TRANSFORM.YARDI.PROPERTY_PROGRESS. vendor_time_grain SNAPSHOT; expected_source_refresh_frequency DAILY.
{{ config(
    materialized='table',
    alias='fact_progress_yardi_property',
    enabled=var('transform_dev_enable_fund_opco_facts', true),
    cluster_by=['yardi_property_hkey'],
    tags=['transform', 'transform_dev', 'fund_opco', 'yardi', 'progress', 'fact_yardi', 'property'],
) }}

SELECT
    'PROGRESS' AS opco_code,
    'YARDI' AS vendor_name,
    'TRANSFORM.YARDI.PROPERTY_PROGRESS' AS source_dataset,
    'SNAPSHOT' AS vendor_time_grain,
    'DAILY' AS expected_source_refresh_frequency,
    p.HMY AS yardi_property_hkey,
    NULLIF(TRIM(p.SCODE::VARCHAR), '') AS yardi_property_code,
    NULLIF(TRIM(p.SADDR1::VARCHAR), '') AS address_line_1,
    NULLIF(TRIM(p.SCITY::VARCHAR), '') AS city,
    NULLIF(TRIM(p.SSTATE::VARCHAR), '') AS state,
    NULLIF(TRIM(p.SZIPCODE::VARCHAR), '') AS zip_code,
    CAST(NULL AS VARCHAR) AS property_name,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM {{ source('transform_yardi', 'PROPERTY_PROGRESS') }} AS p
