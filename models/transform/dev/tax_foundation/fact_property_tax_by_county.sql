-- TRANSFORM.DEV.FACT_PROPERTY_TAX_BY_COUNTY — Tax Foundation county property tax (long).
-- Migrated from pretium-ai-dbt **fact_property_tax_by_county**; reads **tax_foundation_property_taxes_by_county** (wide + FIPS).

{{ config(
    alias='fact_property_tax_by_county',
    materialized='view',
    tags=['transform', 'transform_dev', 'tax_foundation', 'place', 'pit_i', 'policy'],
) }}

WITH resolved AS (
    SELECT
        COALESCE(CAST(c.load_date AS DATE), CURRENT_DATE()) AS date_reference,
        c.county_fips AS geo_id,
        'COUNTY_FIPS' AS geo_level_code,
        c.state_code,
        c.county_name,
        c.effective_property_tax_rate_2023 AS effective_property_tax_rate,
        c.median_housing_value_2023 AS median_housing_value,
        c.median_property_taxes_paid_2023 AS median_property_taxes_paid,
        c.vendor_name,
        UPPER(c.source_table) AS source_dataset
    FROM {{ ref('tax_foundation_property_taxes_by_county') }} AS c
),

unpivoted AS (
    SELECT
        date_reference,
        geo_id,
        geo_level_code,
        'TAX_FOUNDATION_EFFECTIVE_RATE_PCT' AS metric_id,
        effective_property_tax_rate::DOUBLE AS value,
        'PCT' AS unit,
        vendor_name,
        source_dataset
    FROM resolved
    WHERE effective_property_tax_rate IS NOT NULL
    UNION ALL
    SELECT date_reference, geo_id, geo_level_code, 'TAX_FOUNDATION_MEDIAN_HOUSING_VALUE',
        median_housing_value::DOUBLE, 'USD', vendor_name, source_dataset
    FROM resolved WHERE median_housing_value IS NOT NULL
    UNION ALL
    SELECT date_reference, geo_id, geo_level_code, 'TAX_FOUNDATION_MEDIAN_TAX_PAID',
        median_property_taxes_paid::DOUBLE, 'USD', vendor_name, source_dataset
    FROM resolved WHERE median_property_taxes_paid IS NOT NULL
)

SELECT
    date_reference,
    geo_id,
    geo_level_code,
    metric_id,
    value,
    unit,
    vendor_name,
    'VALID' AS quality_flag,
    source_dataset,
    CURRENT_TIMESTAMP() AS created_at,
    CURRENT_TIMESTAMP() AS updated_at
FROM unpivoted
WHERE value IS NOT NULL
