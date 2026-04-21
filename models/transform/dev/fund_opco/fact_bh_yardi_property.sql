-- Grain: (yardi_property_hkey) — current-state property master (BH). Source: TRANSFORM.YARDI.PROPERTY_BH.
{{ config(
    materialized='table',
    alias='fact_bh_yardi_property',
    enabled=var('transform_dev_enable_fund_opco_facts', true),
    cluster_by=['yardi_property_hkey'],
    tags=['transform', 'transform_dev', 'fund_opco', 'yardi', 'bh', 'fact_yardi', 'property'],
) }}

SELECT
    'BH' AS opco_code,
    'YARDI' AS vendor_name,
    'TRANSFORM.YARDI.PROPERTY_BH' AS source_dataset,
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
FROM {{ source('transform_yardi', 'PROPERTY_BH') }} AS p
