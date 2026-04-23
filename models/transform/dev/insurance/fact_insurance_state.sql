-- TRANSFORM.DEV.FACT_INSURANCE_STATE — Bankrate + Quadrant state home insurance (long).
-- Migrated from pretium-ai-dbt **fact_insurance_state**; reads cleaned Bankrate / Quadrant models.

{{ config(
    alias='fact_insurance_state',
    materialized='view',
    tags=['transform', 'transform_dev', 'insurance', 'place', 'pit_i', 'bankrate', 'quadrant'],
) }}

WITH quadrant_long AS (
    SELECT date_reference, state_code, 'QUADRANT_AVGRATE_200K' AS metric_id, avgrate_200k::DOUBLE AS value, 'USD' AS metric_unit, vendor_name, source_table
    FROM {{ ref('cleaned_quadrant_insurance_state_rates') }} WHERE avgrate_200k IS NOT NULL
    UNION ALL
    SELECT date_reference, state_code, 'QUADRANT_AVGRATE_300K', avgrate_300k::DOUBLE, 'USD', vendor_name, source_table FROM {{ ref('cleaned_quadrant_insurance_state_rates') }} WHERE avgrate_300k IS NOT NULL
    UNION ALL
    SELECT date_reference, state_code, 'QUADRANT_AVGRATE_400K', avgrate_400k::DOUBLE, 'USD', vendor_name, source_table FROM {{ ref('cleaned_quadrant_insurance_state_rates') }} WHERE avgrate_400k IS NOT NULL
    UNION ALL
    SELECT date_reference, state_code, 'QUADRANT_AVGRATE_600K', avgrate_600k::DOUBLE, 'USD', vendor_name, source_table FROM {{ ref('cleaned_quadrant_insurance_state_rates') }} WHERE avgrate_600k IS NOT NULL
    UNION ALL
    SELECT date_reference, state_code, 'QUADRANT_AVGRATE_1000K', avgrate_1000k::DOUBLE, 'USD', vendor_name, source_table FROM {{ ref('cleaned_quadrant_insurance_state_rates') }} WHERE avgrate_1000k IS NOT NULL
),

bankrate_long AS (
    SELECT date_reference, state_code, 'BANKRATE_AVG_ANNUAL_PREMIUM' AS metric_id, average_annual_premium::DOUBLE AS value, 'USD' AS metric_unit, vendor_name, source_table
    FROM {{ ref('cleaned_bankrate_insurance_state') }} WHERE average_annual_premium IS NOT NULL
    UNION ALL
    SELECT date_reference, state_code, 'BANKRATE_AVG_MONTHLY_PREMIUM', average_monthly_premium::DOUBLE, 'USD', vendor_name, source_table FROM {{ ref('cleaned_bankrate_insurance_state') }} WHERE average_monthly_premium IS NOT NULL
    UNION ALL
    SELECT date_reference, state_code, 'BANKRATE_DIFF_NATIONAL_AVG', difference_from_national_avg::DOUBLE, 'USD', vendor_name, source_table FROM {{ ref('cleaned_bankrate_insurance_state') }} WHERE difference_from_national_avg IS NOT NULL
),

unioned AS (
    SELECT date_reference, state_code, metric_id, value, metric_unit, vendor_name, source_table FROM quadrant_long
    UNION ALL
    SELECT date_reference, state_code, metric_id, value, metric_unit, vendor_name, source_table FROM bankrate_long
)

SELECT
    date_reference,
    state_code AS geo_id,
    'STATE' AS geo_level_code,
    metric_id,
    value,
    vendor_name,
    'OK' AS quality_flag
FROM unioned
WHERE value IS NOT NULL
