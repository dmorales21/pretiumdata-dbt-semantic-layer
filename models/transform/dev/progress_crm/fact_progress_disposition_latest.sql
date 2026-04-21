-- TRANSFORM.DEV.FACT_PROGRESS_DISPOSITION_LATEST
-- Latest row per disposition_id from **fact_progress_disposition** (this repo — canonical build).
-- Canonical dbt path: **models/transform/dev/progress_crm/** (see docs/migration/TRANSFORM_DEV_DISPOSITION_PROGRESS_SNOWSQL_DIAGNOSTIC.md).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='FACT_PROGRESS_DISPOSITION_LATEST',
    enabled=var('transform_dev_enable_disposition_yield_stack', false),
    cluster_by=['disposition_id'],
    tags=['transform', 'transform_dev', 'progress_crm', 'fund_opco', 'progress', 'crm', 'disposition', 'source_entity_progress'],
) }}

SELECT
    disposition_id,
    property_sfdc_id,
    tribeca_number,
    property_number,

    stage,
    disposition_stage,
    sub_stage,
    awaiting_decision_to_sell,
    proposed_for_disposition,
    reason_for_disposition,
    reason_for_disposition_notes,
    type_of_sale,
    channel,
    channel_type,
    is_1031_exchange,

    bpo_id,
    bpo_as_is_value,
    bpo_value,
    bpo_repaired_value,
    bpo_30day_as_is_value,
    bpo_reviewer_repaired_value,
    bpo_completed_date,
    bpo_order_date,

    proposed_as_is_value,
    listing_agent_bpo_as_is_value,
    listing_agent_bpo_as_repaired_value,

    original_list_price,
    list_price,
    current_list_price,
    contract_price,
    property_sold_price,
    buyer_name,
    financing_type,
    buyer_closing_contribution,
    buyer_credit,
    earnest_money_deposit,

    sfdc_estimated_net_proceeds,
    estimated_closing_costs,
    actual_closing_costs,

    days_on_market,
    property_listed_date,
    estimated_disposition_date,
    property_sold_date,
    listing_agent_bpo_ordered_date,
    listing_agent_bpo_uploaded_date,
    offer_date,
    inspection_deadline,
    financing_contingency_date,
    due_diligence_end_date,

    sfdc_state,
    sfdc_city,
    sfdc_zip_code,
    sfdc_msa,

    created_date,
    last_modified_date,

    last_modified_date                                          AS date_reference,
    'PROGRESS'                                                  AS vendor_name,
    'DISPOSITION__C'                                            AS dataset_name,
    'VALID'                                                     AS quality_flag,
    dbt_updated_at,
    CURRENT_TIMESTAMP()                                       AS fact_materialized_at

FROM {{ ref('fact_progress_disposition') }}
WHERE disposition_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY disposition_id
    ORDER BY last_modified_date DESC NULLS LAST, created_date DESC NULLS LAST
) = 1
