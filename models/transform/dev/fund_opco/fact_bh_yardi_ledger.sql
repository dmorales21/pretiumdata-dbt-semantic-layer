-- Grain: (yardi_trans_hkey) — one row per Yardi transaction (BH).
-- Source: **TRANSFORM.YARDI.TRANS_BH** when `yardi_trans_bh_available: true` (grants + column parity confirmed).
--         Legacy **`yardi_bh.TRANS`** when `yardi_trans_bh_available: false` and `yardi_bh_available: true`.
-- Join: `UNIT_BH` on silver for `yardi_property_hkey` (same for both ledger sources).
{% set use_trans_bh = var('yardi_trans_bh_available', false) %}
{{ config(
    materialized='table',
    alias='fact_bh_yardi_ledger',
    enabled=(
        var('transform_dev_enable_fund_opco_facts', true)
        and (var('yardi_trans_bh_available', false) or var('yardi_bh_available', false))
    ),
    cluster_by=['yardi_property_hkey', 'trans_post_date'],
    tags=['transform', 'transform_dev', 'fund_opco', 'yardi', 'bh', 'fact_yardi', 'ledger'],
) }}

SELECT
    'BH' AS opco_code,
    'YARDI' AS vendor_name,
    {% if use_trans_bh %}
    'TRANSFORM.YARDI.TRANS_BH' AS source_dataset,
    {% else %}
    'DS_SOURCE_PROD_YARDI_BH.YARDI.TRANS' AS source_dataset,
    {% endif %}
    'EVENT' AS vendor_time_grain,
    'DAILY' AS expected_source_refresh_frequency,
    t.HMY AS yardi_trans_hkey,
    t.HUNIT AS yardi_unit_hkey,
    u.HPROPERTY AS yardi_property_hkey,
    t.HPERSON AS yardi_person_hkey,
    t.STOTALAMOUNT::FLOAT AS trans_total_amount,
    t.SAMOUNTPAID::FLOAT AS trans_amount_paid,
    t.UPOSTDATE::DATE AS trans_post_date,
    t.SDATEOCCURRED::DATE AS trans_occurred_date,
    t.ITYPE AS trans_type_code,
    t.BOPEN AS trans_open_flag,
    t.CREDIT AS trans_credit_flag,
    t.VOID AS trans_void_flag,
    t.SDATECREATED::TIMESTAMP_NTZ AS source_created_at,
    t.SDATEMODIFIED::TIMESTAMP_NTZ AS source_modified_at,
    CURRENT_TIMESTAMP() AS dbt_updated_at
{% if use_trans_bh %}
FROM {{ source('transform_yardi', 'TRANS_BH') }} AS t
{% else %}
FROM {{ source('yardi_bh', 'TRANS') }} AS t
{% endif %}
LEFT JOIN {{ source('transform_yardi', 'UNIT_BH') }} AS u
    ON t.HUNIT = u.HMY
