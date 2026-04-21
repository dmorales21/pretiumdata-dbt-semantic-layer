-- MODEL: Supply pressure signal (CBSA) — universal gate from Realtor DOM proxy.
-- Port of pretium-ai-dbt ``analytics_prod/signals/p1_universal/model_signal_supply_pressure_cbsa.sql``;
-- reads **``ref('feature_supply_pressure_cbsa_monthly')``** (successor to legacy ``feature_supply_pressure_cbsa``).
-- **Polarity:** ``signal_score_universal`` — high = low supply (tight); ``signal_score_distressed`` — high = high supply.
{{ config(
    materialized='view',
    alias='model_signal_supply_pressure_cbsa',
    enabled=var('transform_dev_enable_feature_supply_pressure_cbsa', false),
    tags=['analytics', 'model', 'signal', 'supply_pressure', 'cbsa', 'universal_gate'],
) }}

WITH source AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        permits_12m_avg_monthly AS months_of_supply
    FROM {{ ref('feature_supply_pressure_cbsa_monthly') }}
    WHERE permits_12m_avg_monthly IS NOT NULL
),

scored AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        months_of_supply,
        ROUND((1 - PERCENT_RANK() OVER (ORDER BY months_of_supply)) * 100, 1) AS signal_score_universal,
        ROUND(PERCENT_RANK() OVER (ORDER BY months_of_supply) * 100, 1) AS signal_score_distressed
    FROM source
),

latest AS (
    SELECT
        geo_id,
        geo_level_code,
        date_reference,
        months_of_supply,
        signal_score_universal,
        signal_score_distressed
    FROM scored
    QUALIFY ROW_NUMBER() OVER (PARTITION BY geo_id ORDER BY date_reference DESC) = 1
)

SELECT
    geo_id,
    geo_level_code,
    date_reference,
    months_of_supply,
    signal_score_universal,
    signal_score_distressed,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM latest
