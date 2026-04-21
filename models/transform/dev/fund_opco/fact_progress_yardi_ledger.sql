-- Grain: (yardi_trans_hkey) — one row per Yardi transaction (Progress). Source: TRANSFORM.YARDI.TRANS_PROGRESS.
{{ config(
    materialized='table',
    alias='fact_progress_yardi_ledger',
    enabled=var('transform_dev_enable_fund_opco_facts', true),
    cluster_by=['yardi_property_hkey', 'trans_post_date'],
    tags=['transform', 'transform_dev', 'fund_opco', 'yardi', 'progress', 'fact_yardi', 'ledger'],
) }}

SELECT
    'PROGRESS' AS opco_code,
    'YARDI' AS vendor_name,
    'TRANSFORM.YARDI.TRANS_PROGRESS' AS source_dataset,
    'EVENT' AS vendor_time_grain,
    'DAILY' AS expected_source_refresh_frequency,
    t.HMY AS yardi_trans_hkey,
    t.HUNIT AS yardi_unit_hkey,
    u.HPROPERTY AS yardi_property_hkey,
    t.HPERSON AS yardi_person_hkey,
    t.STOTALAMOUNT::FLOAT AS trans_total_amount,
    t.SAMOUNTPAID::FLOAT AS trans_amount_paid,
    t.UPOSTDATE::DATE AS trans_post_date,
    CAST(NULL AS DATE) AS trans_occurred_date,
    t.ITYPE AS trans_type_code,
    t.BOPEN AS trans_open_flag,
    t.CREDIT AS trans_credit_flag,
    t.VOID AS trans_void_flag,
    t.SDATECREATED::TIMESTAMP_NTZ AS source_created_at,
    t.SDATEMODIFIED::TIMESTAMP_NTZ AS source_modified_at,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM {{ source('transform_yardi', 'TRANS_PROGRESS') }} AS t
LEFT JOIN {{ source('transform_yardi', 'UNIT_PROGRESS') }} AS u
    ON t.HUNIT = u.HMY
