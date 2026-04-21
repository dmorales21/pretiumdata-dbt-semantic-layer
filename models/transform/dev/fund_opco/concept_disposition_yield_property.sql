-- TRANSFORM.DEV.CONCEPT_DISPOSITION_YIELD_PROPERTY
-- Canonical replacement for pretium-ai-dbt **EDW_PROD.MART.MART_DISPOSITION_YIELD_PROPERTY**:
-- property-level disposition × portfolio context + IC yield / valuation helpers (same grain: disposition_id).
-- Upstream: **TRANSFORM.DEV** `fact_progress_disposition_latest` (built here from **SOURCE_ENTITY** disposition + BPO)
-- plus **SOURCE_ENTITY.PROGRESS.SFDC_PROPERTIES__C** for fund / purchase / ZIP fallbacks;
-- **FACT_OPCO_PROPERTY_PRESENCE** still via pretium-ai-dbt `source('transform_dev_pretium_ai_dbt', …)` until OpCo lands natively.
-- Enable when Snowflake role can SELECT those objects: `transform_dev_enable_disposition_yield_stack: true`.
-- See **docs/governance/DISPOSITION_UPSTREAM_FACT_AND_CONCEPT_PLAN.md** (pretium-ai-dbt) and ARCHITECTURE_RULES.
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_disposition_yield_property',
    enabled=var('transform_dev_enable_disposition_yield_stack', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'disposition', 'ic_market_analysis',
        'concept_disposition', 'replaces_edw_mart',
    ],
    cluster_by=['disposition_stage', 'fund_id', 'cbsa_code'],
) }}

WITH disposition AS (
    SELECT * FROM {{ ref('fact_progress_disposition_latest') }}
),

portfolio AS (
    SELECT
        property_id         AS property_id,
        opco_id             AS opco_id,
        fund_id             AS fund_id,
        fund_name           AS fund_name,
        cbsa_code           AS cbsa_code,
        CAST(NULL AS VARCHAR) AS cbsa_title,
        county_fips         AS county_fips,
        county_name         AS county_name,
        state               AS state,
        state_name          AS state_name,
        city                AS city,
        zip_code            AS zip_code,
        property_type       AS property_type,
        bedrooms            AS bedrooms,
        bathrooms           AS bathrooms,
        square_feet         AS square_feet,
        year_built          AS year_built,
        purchase_price      AS purchase_price,
        rent_amount         AS rent_amount,
        loan_amount         AS loan_amount,
        is_active           AS is_active,
        status              AS property_status,
        offering_id         AS offering_id
    FROM {{ source('transform_dev_pretium_ai_dbt', 'fact_opco_property_presence') }}
),

fund_dim AS (
    SELECT
        fund_id             AS fund_id,
        opco_id             AS opco_id,
        MAX(fund_name)      AS fund_name
    FROM {{ source('transform_dev_pretium_ai_dbt', 'fact_opco_property_presence') }}
    WHERE fund_id IS NOT NULL
    GROUP BY fund_id, opco_id
),

progress_prop AS (
    SELECT
        TRIM(TO_VARCHAR(p.{{ adapter.quote('ID') }}))                   AS property_sfdc_id,
        TRIM(TO_VARCHAR(p.{{ adapter.quote('FUND__C') }}))              AS fund_sfdc_id,
        TRY_TO_NUMBER(p.{{ adapter.quote('PURCHASE_PRICE__C') }})       AS purchase_price_sfdc,
        TRIM(TO_VARCHAR(p.{{ adapter.quote('STATE__C') }}))             AS state_sfdc,
        TRIM(TO_VARCHAR(p.{{ adapter.quote('CITY__C') }}))              AS city_sfdc,
        NULLIF(TRIM(TO_VARCHAR(p.{{ adapter.quote('ZIP_CODE__C') }})), '') AS zip_code_sfdc
    FROM {{ source('source_entity_progress', 'sfdc_properties__c') }} AS p
    WHERE COALESCE(p.{{ adapter.quote('ISDELETED') }}, FALSE) = FALSE
),

computed AS (
    SELECT
        d.disposition_id,
        d.property_sfdc_id,
        d.tribeca_number,
        d.property_number,

        COALESCE(p.opco_id, fd.opco_id)                             AS opco_id,
        COALESCE(p.fund_id, sp.fund_sfdc_id)                        AS fund_id,
        COALESCE(p.fund_name, fd.fund_name)                           AS fund_name,
        p.offering_id,
        p.cbsa_code,
        p.cbsa_title,
        COALESCE(p.state, sp.state_sfdc, d.sfdc_state)               AS state,
        COALESCE(p.state_name, CAST(NULL AS VARCHAR))                 AS state_name,
        COALESCE(p.county_fips, CAST(NULL AS VARCHAR))               AS county_fips,
        COALESCE(p.county_name, CAST(NULL AS VARCHAR))               AS county_name,
        COALESCE(p.city, sp.city_sfdc, d.sfdc_city)                  AS city,
        COALESCE(p.zip_code, sp.zip_code_sfdc, d.sfdc_zip_code)      AS zip_code,

        p.property_type,
        p.bedrooms,
        p.bathrooms,
        p.square_feet,
        p.year_built,
        p.is_active,
        p.property_status,

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
        CASE
            WHEN UPPER(d.channel_type) IN ('BULK', 'PORTFOLIO') THEN 0.03
            WHEN UPPER(d.channel_type) = 'AUCTION' THEN 0.04
            ELSE 0.06
        END                                         AS transaction_cost_pct,

        d.bpo_as_is_value,
        d.bpo_value,
        d.bpo_repaired_value,
        d.bpo_30day_as_is_value,
        d.bpo_completed_date,
        d.proposed_as_is_value,
        d.listing_agent_bpo_as_is_value,
        d.bpo_reviewer_repaired_value,

        COALESCE(
            d.bpo_as_is_value,
            d.proposed_as_is_value,
            d.listing_agent_bpo_as_is_value,
            d.bpo_reviewer_repaired_value
        )                                           AS valuation_avm,

        COALESCE(p.purchase_price, sp.purchase_price_sfdc)              AS purchase_price,

        p.rent_amount                               AS monthly_rent,

        d.original_list_price,
        d.list_price,
        d.current_list_price,
        d.contract_price,
        d.property_sold_price,
        d.buyer_name,
        d.financing_type,
        d.earnest_money_deposit,
        d.sfdc_estimated_net_proceeds,
        d.estimated_closing_costs,
        d.actual_closing_costs,

        d.days_on_market,
        d.property_listed_date,
        d.estimated_disposition_date,
        d.property_sold_date,
        d.offer_date,
        d.inspection_deadline,
        d.financing_contingency_date,

        d.bpo_id,
        d.bpo_order_date,

        d.created_date,
        d.last_modified_date,
        d.dbt_updated_at
    FROM disposition AS d
    LEFT JOIN portfolio AS p
        ON d.property_sfdc_id = p.property_id
    LEFT JOIN progress_prop AS sp
        ON d.property_sfdc_id = sp.property_sfdc_id
    LEFT JOIN fund_dim AS fd
        ON sp.fund_sfdc_id = fd.fund_id
),

final AS (
    SELECT
        c.*,
        CASE
            WHEN c.valuation_avm IS NOT NULL AND c.valuation_avm > 0
            THEN ROUND(c.valuation_avm * (1.0 - c.transaction_cost_pct), 2)
        END                                         AS net_proceeds,
        CASE
            WHEN c.valuation_avm IS NOT NULL AND c.purchase_price IS NOT NULL AND c.purchase_price > 0
            THEN ROUND(c.valuation_avm - c.purchase_price, 2)
        END                                         AS gain_loss,
        CASE
            WHEN c.valuation_avm IS NOT NULL AND c.purchase_price IS NOT NULL AND c.purchase_price > 0
            THEN ROUND((c.valuation_avm - c.purchase_price) / c.purchase_price * 100, 2)
        END                                         AS gain_loss_pct,
        CASE
            WHEN c.valuation_avm IS NOT NULL AND c.purchase_price IS NOT NULL AND c.purchase_price > 0
            THEN ROUND(c.valuation_avm * (1.0 - c.transaction_cost_pct) - c.purchase_price, 2)
        END                                         AS net_gain_loss,
        CASE
            WHEN c.monthly_rent IS NOT NULL AND c.monthly_rent > 0
            THEN ROUND(c.monthly_rent * 12, 2)
        END                                         AS annual_rent,
        CASE
            WHEN c.monthly_rent IS NOT NULL AND c.monthly_rent > 0
                AND c.valuation_avm IS NOT NULL AND c.valuation_avm > 0
            THEN ROUND((c.monthly_rent * 12) / c.valuation_avm * 100, 4)
        END                                         AS gross_yield_on_avm_pct,
        CASE
            WHEN c.monthly_rent IS NOT NULL AND c.monthly_rent > 0
                AND c.purchase_price IS NOT NULL AND c.purchase_price > 0
            THEN ROUND((c.monthly_rent * 12) / c.purchase_price * 100, 4)
        END                                         AS gross_yield_on_cost_pct,
        CASE
            WHEN c.valuation_avm IS NOT NULL AND c.valuation_avm > 0
                AND c.square_feet IS NOT NULL AND c.square_feet > 0
            THEN ROUND(c.valuation_avm / c.square_feet, 2)
        END                                         AS avm_per_sqft,
        CASE
            WHEN c.bpo_as_is_value IS NOT NULL THEN 'BPO_AS_IS'
            WHEN c.proposed_as_is_value IS NOT NULL THEN 'PROPOSED_AS_IS'
            WHEN c.listing_agent_bpo_as_is_value IS NOT NULL THEN 'LISTING_AGENT_BPO'
            WHEN c.bpo_reviewer_repaired_value IS NOT NULL THEN 'BPO_REVIEWER_REPAIRED'
        END                                         AS valuation_source,
        CASE
            WHEN c.disposition_stage = 'Closed'
                OR (c.property_sold_date IS NOT NULL) THEN TRUE
            ELSE FALSE
        END                                         AS is_sold,
        MD5(COALESCE(c.disposition_id, ''))         AS row_id,
        CURRENT_TIMESTAMP()                         AS dbt_updated_at
    FROM computed AS c
)

SELECT * FROM final
