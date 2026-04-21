-- TRANSFORM.DEV.FACT_PROGRESS_DISPOSITION
-- Same normalization contract as pretium-ai-dbt `fact_progress_disposition.sql`, but reads
-- **SOURCE_ENTITY.PROGRESS** (`sfdc_disposition__c`, `sfdc_bpo__c`) so the disposition yield stack
-- does not depend on pretium-ai-dbt having materialized this table first.
-- Canonical dbt path: **models/transform/dev/progress_crm/** (see docs/migration/TRANSFORM_DEV_DISPOSITION_PROGRESS_SNOWSQL_DIAGNOSTIC.md).
-- Gated: **`transform_dev_enable_disposition_yield_stack`** (with **concept_disposition_yield_property**).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='FACT_PROGRESS_DISPOSITION',
    enabled=var('transform_dev_enable_disposition_yield_stack', false),
    tags=['transform', 'transform_dev', 'progress_crm', 'progress', 'crm', 'disposition', 'source_entity_progress'],
) }}

{% set use_src = var('transform_dev_enable_disposition_yield_stack', false) %}

{% if use_src %}
WITH dispositions AS (
    SELECT
        ID                                                          AS disposition_id,
        PROPERTY__C                                                 AS property_sfdc_id,
        TRIBECA_NUMBER__C                                           AS tribeca_number,
        PROPERTIES__C_PROPERTY__R_PROPERTYNUMBER__C                 AS property_number,

        STAGE__C                                                    AS stage,
        DISPOSITION_STAGE__C                                      AS disposition_stage,
        SUB_STAGE__C                                                AS sub_stage,
        AWAITING_DECISION_TO_SELL__C                                AS awaiting_decision_to_sell,
        PROPOSED_FOR_DISPOSITION__C                                 AS proposed_for_disposition,

        REASON_FOR_DISPOSITION__C                                   AS reason_for_disposition,
        REASON_FOR_DISPOSITION_NOTES__C                             AS reason_for_disposition_notes,
        TYPE_OF_SALE__C                                             AS type_of_sale,
        CHANNEL__C                                                  AS channel,
        CHANNEL_TYPE__C                                             AS channel_type,
        X1031_EXCHANGE__C                                           AS is_1031_exchange,

        PROPOSED_AS_IS_MARKET_VALUE__C                              AS proposed_as_is_value,
        LISTING_AGENT_BPO_AS_IS_VALUE__C                            AS listing_agent_bpo_as_is_value,
        LISTING_AGENT_BPO_AS_REPAIRED_VALUE__C                      AS listing_agent_bpo_as_repaired_value,

        ORIGINAL_LIST_PRICE__C                                      AS original_list_price,
        LIST_PRICE__C                                               AS list_price,
        CURRENT_LIST_PRICE__C                                       AS current_list_price,
        CONTRACT_PRICE__C                                           AS contract_price,
        TRY_CAST(PROPERTY_SOLD_PRICE__C AS FLOAT)                   AS property_sold_price,
        BUYER_NAME__C                                               AS buyer_name,
        FINANCING_TYPE__C                                           AS financing_type,
        BUYER_CLOSING_CONTRIBUTION__C                               AS buyer_closing_contribution,
        BUYER_CREDIT__C                                             AS buyer_credit,
        EARNEST_MONEY_DEPOSIT__C                                    AS earnest_money_deposit,

        ESTIMATED_NET_PROCEEDS__C                                   AS sfdc_estimated_net_proceeds,
        ESTIMATED_CLOSING_COSTS__C                                  AS estimated_closing_costs,
        ACTUAL_CLOSING_COSTS__C                                     AS actual_closing_costs,

        DAYS_ON_MARKET__C                                           AS days_on_market,
        CAST(PROPERTY_LISTED_DATE__C AS DATE)                       AS property_listed_date,
        CAST(ESTIMATED_DISPOSITION_DATE__C AS DATE)                 AS estimated_disposition_date,
        TRY_CAST(PROPERTY_SOLD_DATE__C AS DATE)                     AS property_sold_date,
        CAST(LISTING_AGENT_BPO_ORDERED__C AS DATE)                  AS listing_agent_bpo_ordered_date,
        CAST(LISTING_AGENT_BPO_UPLOADED__C AS DATE)                 AS listing_agent_bpo_uploaded_date,
        CAST(OFFER_DATE__C AS DATE)                                 AS offer_date,
        CAST(INSPECTION_DEADLINE__C AS DATE)                        AS inspection_deadline,
        CAST(FINANCING_CONTINGENCY_DATE__C AS DATE)                 AS financing_contingency_date,
        CAST(DUE_DILIGENCE_END_DATE__C AS DATE)                     AS due_diligence_end_date,

        STATE__C                                                    AS sfdc_state,
        CITY__C                                                     AS sfdc_city,
        ZIP_CODE__C                                                 AS sfdc_zip_code,
        MSA__C                                                      AS sfdc_msa,

        CAST(CREATEDDATE AS DATE)                                   AS created_date,
        CAST(LASTMODIFIEDDATE AS DATE)                              AS last_modified_date

    FROM {{ source('source_entity_progress', 'sfdc_disposition__c') }}
    WHERE ISDELETED = 0
      AND PROPERTY__C IS NOT NULL
),

bpo_ranked AS (
    SELECT
        ID                                                          AS bpo_id,
        PROPERTY__C                                                 AS property_sfdc_id,
        AS_IS_MARKET_VALUE__C                                       AS bpo_as_is_value,
        BPO_VALUE__C                                                AS bpo_value,
        REPAIRED_MARKET_VALUE__C                                    AS bpo_repaired_value,
        X30_DAY_AS_IS_MARKET_VALUE__C                               AS bpo_30day_as_is_value,
        REVIEWER_S_RECOMMENDED_REPAIRED_VALUE__C                    AS bpo_reviewer_repaired_value,
        CAST(BPO_COMPLETED_DATE__C AS DATE)                         AS bpo_completed_date,
        CAST(BPO_ORDER_DATE__C AS DATE)                             AS bpo_order_date,
        ROW_NUMBER() OVER (
            PARTITION BY PROPERTY__C
            ORDER BY BPO_COMPLETED_DATE__C DESC NULLS LAST,
                     CREATEDDATE DESC NULLS LAST
        )                                                           AS rn
    FROM {{ source('source_entity_progress', 'sfdc_bpo__c') }}
    WHERE ISDELETED = 0
      AND PROPERTY__C IS NOT NULL
),

latest_bpo AS (
    SELECT * FROM bpo_ranked
    WHERE rn = 1
),

final AS (
    SELECT
        d.disposition_id,
        d.property_sfdc_id,
        d.tribeca_number,
        d.property_number,
        d.stage,
        d.disposition_stage,
        d.sub_stage,
        d.awaiting_decision_to_sell,
        d.proposed_for_disposition,
        d.reason_for_disposition,
        d.reason_for_disposition_notes,
        d.type_of_sale,
        d.channel,
        d.channel_type,
        d.is_1031_exchange,
        b.bpo_id,
        b.bpo_as_is_value,
        b.bpo_value,
        b.bpo_repaired_value,
        b.bpo_30day_as_is_value,
        b.bpo_reviewer_repaired_value,
        b.bpo_completed_date,
        b.bpo_order_date,
        d.proposed_as_is_value,
        d.listing_agent_bpo_as_is_value,
        d.listing_agent_bpo_as_repaired_value,
        d.original_list_price,
        d.list_price,
        d.current_list_price,
        d.contract_price,
        d.property_sold_price,
        d.buyer_name,
        d.financing_type,
        d.buyer_closing_contribution,
        d.buyer_credit,
        d.earnest_money_deposit,
        d.sfdc_estimated_net_proceeds,
        d.estimated_closing_costs,
        d.actual_closing_costs,
        d.days_on_market,
        d.property_listed_date,
        d.estimated_disposition_date,
        d.property_sold_date,
        d.listing_agent_bpo_ordered_date,
        d.listing_agent_bpo_uploaded_date,
        d.offer_date,
        d.inspection_deadline,
        d.financing_contingency_date,
        d.due_diligence_end_date,
        d.sfdc_state,
        d.sfdc_city,
        d.sfdc_zip_code,
        d.sfdc_msa,
        d.created_date,
        d.last_modified_date,
        CURRENT_TIMESTAMP()                                         AS dbt_updated_at
    FROM dispositions AS d
    LEFT JOIN latest_bpo AS b
        ON d.property_sfdc_id = b.property_sfdc_id
)

SELECT * FROM final

{% else %}
SELECT
    CAST(NULL AS VARCHAR)       AS disposition_id,
    CAST(NULL AS VARCHAR)       AS property_sfdc_id,
    CAST(NULL AS VARCHAR)       AS tribeca_number,
    CAST(NULL AS VARCHAR)       AS property_number,
    CAST(NULL AS VARCHAR)       AS stage,
    CAST(NULL AS VARCHAR)       AS disposition_stage,
    CAST(NULL AS VARCHAR)       AS sub_stage,
    CAST(NULL AS VARCHAR)       AS awaiting_decision_to_sell,
    CAST(NULL AS VARCHAR)       AS proposed_for_disposition,
    CAST(NULL AS VARCHAR)       AS reason_for_disposition,
    CAST(NULL AS VARCHAR)       AS reason_for_disposition_notes,
    CAST(NULL AS VARCHAR)       AS type_of_sale,
    CAST(NULL AS VARCHAR)       AS channel,
    CAST(NULL AS VARCHAR)       AS channel_type,
    CAST(NULL AS VARCHAR)       AS is_1031_exchange,
    CAST(NULL AS VARCHAR)       AS bpo_id,
    CAST(NULL AS FLOAT)         AS bpo_as_is_value,
    CAST(NULL AS FLOAT)         AS bpo_value,
    CAST(NULL AS FLOAT)         AS bpo_repaired_value,
    CAST(NULL AS FLOAT)         AS bpo_30day_as_is_value,
    CAST(NULL AS FLOAT)         AS bpo_reviewer_repaired_value,
    CAST(NULL AS DATE)          AS bpo_completed_date,
    CAST(NULL AS DATE)          AS bpo_order_date,
    CAST(NULL AS FLOAT)         AS proposed_as_is_value,
    CAST(NULL AS FLOAT)         AS listing_agent_bpo_as_is_value,
    CAST(NULL AS FLOAT)         AS listing_agent_bpo_as_repaired_value,
    CAST(NULL AS FLOAT)         AS original_list_price,
    CAST(NULL AS FLOAT)         AS list_price,
    CAST(NULL AS FLOAT)         AS current_list_price,
    CAST(NULL AS FLOAT)         AS contract_price,
    CAST(NULL AS FLOAT)         AS property_sold_price,
    CAST(NULL AS VARCHAR)       AS buyer_name,
    CAST(NULL AS VARCHAR)       AS financing_type,
    CAST(NULL AS FLOAT)         AS buyer_closing_contribution,
    CAST(NULL AS FLOAT)         AS buyer_credit,
    CAST(NULL AS FLOAT)         AS earnest_money_deposit,
    CAST(NULL AS FLOAT)         AS sfdc_estimated_net_proceeds,
    CAST(NULL AS FLOAT)         AS estimated_closing_costs,
    CAST(NULL AS FLOAT)         AS actual_closing_costs,
    CAST(NULL AS NUMBER)        AS days_on_market,
    CAST(NULL AS DATE)          AS property_listed_date,
    CAST(NULL AS DATE)          AS estimated_disposition_date,
    CAST(NULL AS DATE)          AS property_sold_date,
    CAST(NULL AS DATE)          AS listing_agent_bpo_ordered_date,
    CAST(NULL AS DATE)          AS listing_agent_bpo_uploaded_date,
    CAST(NULL AS DATE)          AS offer_date,
    CAST(NULL AS DATE)          AS inspection_deadline,
    CAST(NULL AS DATE)          AS financing_contingency_date,
    CAST(NULL AS DATE)          AS due_diligence_end_date,
    CAST(NULL AS VARCHAR)       AS sfdc_state,
    CAST(NULL AS VARCHAR)       AS sfdc_city,
    CAST(NULL AS VARCHAR)       AS sfdc_zip_code,
    CAST(NULL AS VARCHAR)       AS sfdc_msa,
    CAST(NULL AS DATE)          AS created_date,
    CAST(NULL AS DATE)          AS last_modified_date,
    CURRENT_TIMESTAMP()         AS dbt_updated_at
WHERE FALSE
{% endif %}
