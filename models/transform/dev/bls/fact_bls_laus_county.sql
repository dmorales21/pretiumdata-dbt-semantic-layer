-- TRANSFORM.DEV.FACT_BLS_LAUS_COUNTY — read-through of Jon silver TRANSFORM.BLS.LAUS_COUNTY.
-- Migration: pretiumdata-dbt-semantic-layer per MIGRATION_RULES.md §3 / §5 (source(), no hardcoded FQNs).
-- Grain: date_reference × county_fips × measure_code. Prefer this path over LAUS_CBSA for OMB CBSA joins.
{{ config(
    alias='fact_bls_laus_county',
    tags=['transform', 'transform_dev', 'bls', 'fact_bls', 'laus'],
) }}

SELECT *
FROM {{ source('bls_transform', 'laus_county') }}
