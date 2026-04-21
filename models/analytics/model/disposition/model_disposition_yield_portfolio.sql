-- ANALYTICS.DBT_DEV.MODEL_DISPOSITION_YIELD_PORTFOLIO
-- Replaces pretium-ai-dbt **EDW_PROD.MART.MART_DISPOSITION_YIELD_PORTFOLIO** (grain: fund_id × cbsa_code × disposition_stage).
-- Rolls up **concept_disposition_yield_property** — no EDW refs. Gated: **`transform_dev_enable_disposition_yield_stack`**.
{{ config(
    materialized='table',
    tags=['analytics', 'model', 'disposition', 'ic_market_analysis', 'replaces_edw_mart'],
    cluster_by=['disposition_stage', 'fund_id'],
    enabled=var('transform_dev_enable_disposition_yield_stack', false),
) }}

WITH property_concept AS (
    SELECT * FROM {{ ref('concept_disposition_yield_property') }}
),

aggregated AS (
    SELECT
        fund_id,
        fund_name,
        cbsa_code,
        cbsa_title,
        state,
        disposition_stage,

        COUNT(*)                                                    AS total_properties,
        COUNT(CASE WHEN is_sold THEN 1 END)                        AS sold_count,
        COUNT(CASE WHEN NOT is_sold THEN 1 END)                    AS active_pipeline_count,
        COUNT(CASE WHEN valuation_avm IS NOT NULL THEN 1 END)      AS properties_with_valuation,
        COUNT(CASE WHEN monthly_rent IS NOT NULL AND monthly_rent > 0 THEN 1 END) AS properties_with_rent,

        SUM(valuation_avm)                                          AS total_valuation_avm,
        AVG(valuation_avm)                                          AS avg_valuation_avm,
        MEDIAN(valuation_avm)                                       AS median_valuation_avm,
        MIN(valuation_avm)                                          AS min_valuation_avm,
        MAX(valuation_avm)                                          AS max_valuation_avm,

        SUM(net_proceeds)                                           AS total_net_proceeds,
        AVG(net_proceeds)                                           AS avg_net_proceeds,

        SUM(purchase_price)                                         AS total_purchase_price,
        AVG(purchase_price)                                         AS avg_purchase_price,

        SUM(gain_loss)                                              AS total_gain_loss,
        AVG(gain_loss)                                              AS avg_gain_loss,
        AVG(gain_loss_pct)                                          AS avg_gain_loss_pct,
        SUM(net_gain_loss)                                          AS total_net_gain_loss,

        SUM(annual_rent)                                            AS total_annual_rent,
        AVG(monthly_rent)                                           AS avg_monthly_rent,
        MEDIAN(monthly_rent)                                        AS median_monthly_rent,

        AVG(gross_yield_on_avm_pct)                                 AS avg_gross_yield_on_avm_pct,
        MEDIAN(gross_yield_on_avm_pct)                              AS median_gross_yield_on_avm_pct,
        AVG(gross_yield_on_cost_pct)                                AS avg_gross_yield_on_cost_pct,

        CASE
            WHEN SUM(valuation_avm) IS NOT NULL AND SUM(valuation_avm) > 0
                AND SUM(annual_rent) IS NOT NULL
            THEN ROUND(SUM(annual_rent) / SUM(valuation_avm) * 100, 4)
        END                                                         AS portfolio_gross_yield_pct,

        AVG(days_on_market)                                         AS avg_days_on_market,
        MEDIAN(CAST(days_on_market AS FLOAT))                       AS median_days_on_market,

        COUNT(CASE WHEN valuation_source = 'BPO_AS_IS' THEN 1 END)          AS count_bpo_as_is,
        COUNT(CASE WHEN valuation_source = 'PROPOSED_AS_IS' THEN 1 END)     AS count_proposed_as_is,
        COUNT(CASE WHEN valuation_source = 'LISTING_AGENT_BPO' THEN 1 END) AS count_listing_agent_bpo,
        COUNT(CASE WHEN valuation_source IS NULL THEN 1 END)                AS count_no_valuation,

        AVG(bedrooms)                                               AS avg_bedrooms,
        AVG(square_feet)                                            AS avg_square_feet,
        AVG(avm_per_sqft)                                           AS avg_avm_per_sqft

    FROM property_concept
    GROUP BY
        fund_id,
        fund_name,
        cbsa_code,
        cbsa_title,
        state,
        disposition_stage
)

SELECT
    aggregated.*,
    MD5(
        COALESCE(fund_id, 'NULL')
        || '|' || COALESCE(cbsa_code, 'NULL')
        || '|' || COALESCE(disposition_stage, 'NULL')
    )                                                               AS row_id,
    CURRENT_TIMESTAMP()                                             AS dbt_updated_at
FROM aggregated
