-- TRANSFORM.DEV.FACT_BPS_PERMITS_COUNTY — read-through of Jon silver TRANSFORM.BPS.PERMITS_COUNTY.
-- Migration: pretiumdata-dbt-semantic-layer per MIGRATION_RULES.md §3 (source(), no hardcoded FQNs).
-- Grain contract: **CBSA** (not county FIPS) per MIGRATION_TASKS_TRANSFORM_BPS_CENSUS_BLS_LODES.md Part A.
{{ config(
    alias='fact_bps_permits_county',
    tags=['transform', 'transform_dev', 'bps', 'fact_bps', 'permits'],
) }}

SELECT *
FROM {{ source('transform_bps', 'permits_county') }}
