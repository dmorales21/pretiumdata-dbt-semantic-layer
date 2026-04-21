-- TRANSFORM.DEV.FACT_REALTOR_INVENTORY_CBSA — Realtor.com inventory at **CBSA** grain (long metrics).
-- Ported from pretium-ai-dbt ``cleaned_realtor_inventory_cbsa`` + ``fact_realtor_inventory_cbsa`` (dynamic column
-- names on ``SOURCE_PROD.REALTOR.REALTOR_INVENTORY_MSA``). ``metric_id`` is normalized slug (uppercase + underscores).
{{ config(
    alias='fact_realtor_inventory_cbsa',
    materialized='view',
    tags=['transform', 'transform_dev', 'realtor', 'fact_realtor', 'housing_inventory'],
) }}

{% if execute %}
  {% set rel = source('source_prod_realtor', 'realtor_inventory_msa') %}
  {% set rel_try = adapter.get_relation(
    database=rel.database,
    schema=rel.schema,
    identifier=rel.identifier
  ) %}
  {% set cols = adapter.get_columns_in_relation(rel_try) | map(attribute='name') | list if rel_try else [] %}
  {% set cols_upper = cols | map('upper') | list %}
{% else %}
  {% set cols_upper = [] %}
{% endif %}

{% set date_col = 'MONTH_DATE' if 'MONTH_DATE' in cols_upper else 'DATE' if 'DATE' in cols_upper else none %}
{% set geo_col = 'CBSA_CODE' if 'CBSA_CODE' in cols_upper else 'METRO_CODE' if 'METRO_CODE' in cols_upper else 'METRO' if 'METRO' in cols_upper else 'REGION' if 'REGION' in cols_upper else none %}
{% set has_metric = 'METRIC' in cols_upper and 'METRIC_VALUE' in cols_upper %}
{% set has_required = date_col and geo_col %}

{% if has_required and has_metric %}
WITH cleaned AS (
    SELECT
        {{ date_col }}::DATE AS date_reference,
        TRIM({{ geo_col }}::VARCHAR) AS geo_id,
        'CBSA' AS geo_level_code,
        TRIM(METRIC::VARCHAR) AS metric_name,
        TRY_TO_DOUBLE(METRIC_VALUE::VARCHAR) AS metric_value
    FROM {{ source('source_prod_realtor', 'realtor_inventory_msa') }}
    WHERE {{ date_col }} IS NOT NULL
      AND TRIM({{ geo_col }}::VARCHAR) IS NOT NULL
      AND TRIM({{ geo_col }}::VARCHAR) <> ''
      AND METRIC IS NOT NULL
      AND TRIM(METRIC::VARCHAR) <> ''
      AND METRIC_VALUE IS NOT NULL
)
SELECT
    date_reference,
    geo_id,
    geo_level_code,
    UPPER(
        REPLACE(
            REPLACE(TRIM(metric_name), ' ', '_'),
            '-',
            '_'
        )
    ) AS metric_id,
    metric_value AS value,
    CASE
        WHEN LOWER(metric_name) LIKE '%pct%' OR LOWER(metric_name) LIKE '%percent%' THEN 'PCT'
        WHEN LOWER(metric_name) LIKE '%price%' OR LOWER(metric_name) LIKE '%list%' THEN 'USD'
        ELSE 'COUNT'
    END AS unit,
    'MONTHLY' AS frequency,
    'HOUSING' AS domain,
    'HOU_INVENTORY' AS taxon,
    'ALL' AS product_type_code,
    'REALTOR' AS vendor_name,
    'VALID' AS quality_flag,
    CURRENT_TIMESTAMP() AS created_at
FROM cleaned
{% else %}
SELECT
    CAST(NULL AS DATE) AS date_reference,
    CAST(NULL AS VARCHAR) AS geo_id,
    CAST(NULL AS VARCHAR) AS geo_level_code,
    CAST(NULL AS VARCHAR) AS metric_id,
    CAST(NULL AS DOUBLE) AS value,
    CAST(NULL AS VARCHAR) AS unit,
    CAST(NULL AS VARCHAR) AS frequency,
    CAST(NULL AS VARCHAR) AS domain,
    CAST(NULL AS VARCHAR) AS taxon,
    CAST(NULL AS VARCHAR) AS product_type_code,
    CAST(NULL AS VARCHAR) AS vendor_name,
    CAST(NULL AS VARCHAR) AS quality_flag,
    CAST(NULL AS TIMESTAMP_NTZ) AS created_at
FROM {{ source('source_prod_realtor', 'realtor_inventory_msa') }}
WHERE FALSE
{% endif %}
