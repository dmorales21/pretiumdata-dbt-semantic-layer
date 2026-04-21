-- ANALYTICS.DBT_* — CBSA supply-pressure inputs from **TRANSFORM.DEV.FACT_REALTOR_INVENTORY_CBSA**.
-- Port of pretium-ai-dbt ``feature_supply_pressure_cbsa``: DOM proxy + active listings for scorecard / signals.
-- Default **disabled**: requires `fact_realtor_inventory_cbsa` built + SOURCE_PROD.REALTOR landings; set
-- `transform_dev_enable_feature_supply_pressure_cbsa: true` when that chain is available.
--
-- **Lineage note (Phase B):** Realtor CBSA series also land in ``concept_listings_market_monthly`` (vendor ``REALTOR``).
-- **TODO:** switch to ``ref('concept_listings_market_monthly')`` + vendor filter when column contract is aligned — §C checklist.
{{ config(
    materialized='view',
    alias='feature_supply_pressure_cbsa_monthly',
    enabled=var('transform_dev_enable_feature_supply_pressure_cbsa', false),
    tags=['analytics', 'feature', 'supply_pressure', 'realtor', 'cbsa'],
) }}

WITH src AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        metric_id,
        value
    FROM {{ ref('fact_realtor_inventory_cbsa') }}
    WHERE metric_id IN (
        'MEDIAN_DAYS_ON_MARKET',
        'ACTIVE_LISTING_COUNT'
    )
),

pivoted AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        MAX(CASE WHEN metric_id = 'MEDIAN_DAYS_ON_MARKET' THEN value END) AS median_days_on_market,
        MAX(CASE WHEN metric_id = 'ACTIVE_LISTING_COUNT' THEN value END) AS active_listing_count
    FROM src
    GROUP BY 1, 2, 3
),

with_signal_cols AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        'ALL' AS product_type_code,
        median_days_on_market,
        active_listing_count,
        median_days_on_market AS permits_12m_avg_monthly,
        COALESCE(active_listing_count, 0) AS permits_12m_sum,
        CAST(NULL AS NUMBER(18, 2)) AS permit_momentum_yoy
    FROM pivoted
    WHERE median_days_on_market IS NOT NULL
)

SELECT
    geo_id,
    geo_level_code,
    date_reference,
    product_type_code,
    permits_12m_avg_monthly,
    permits_12m_sum,
    permit_momentum_yoy,
    median_days_on_market,
    active_listing_count,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM with_signal_cols
