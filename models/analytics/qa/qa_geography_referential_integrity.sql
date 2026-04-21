-- Slug: **geography_referential_integrity** (6) — distinct `(geo_level_code, geo_id)` keys from market `CONCEPT_*` vs `REFERENCE.GEOGRAPHY_LATEST` (via `ref('geography_latest')`).
-- Unmapped rows (e.g. `property`, vendor-specific corridor codes) are expected until bridges exist; use for CBSA/ZIP/county fill‑rate triage.
-- Target: ANALYTICS.DBT_DEV.QA_GEOGRAPHY_REFERENTIAL_INTEGRITY
{{ config(
    materialized='view',
    alias='QA_GEOGRAPHY_REFERENTIAL_INTEGRITY',
    tags=['analytics', 'qa', 'semantic_validation', 'geography_referential_integrity'],
) }}

WITH keys AS (
    SELECT DISTINCT
        'concept_rent_market_monthly' AS concept_object,
        LOWER(TRIM(TO_VARCHAR(geo_level_code))) AS geo_level_code_norm,
        TRIM(TO_VARCHAR(geo_id)) AS geo_id_norm
    FROM {{ ref('concept_rent_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT
        'concept_rent_property_monthly',
        LOWER(TRIM(TO_VARCHAR(geo_level_code))),
        TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_rent_property_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_occupancy_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_occupancy_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_employment_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_employment_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_unemployment_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_unemployment_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_home_price_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_home_price_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_listings_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_listings_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_avm_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_avm_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_valuation_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_valuation_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_transactions_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_transactions_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_delinquency_market_monthly', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_delinquency_market_monthly') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL

    UNION
    SELECT DISTINCT 'concept_migration_market_annual', LOWER(TRIM(TO_VARCHAR(geo_level_code))), TRIM(TO_VARCHAR(geo_id))
    FROM {{ ref('concept_migration_market_annual') }}
    WHERE geo_id IS NOT NULL AND geo_level_code IS NOT NULL
)

SELECT
    k.concept_object,
    k.geo_level_code_norm,
    k.geo_id_norm,
    (gl.geo_id IS NOT NULL) AS in_geography_latest,
    (k.geo_level_code_norm = 'cbsa') AS is_cbsa_grain
FROM keys AS k
LEFT JOIN {{ ref('geography_latest') }} AS gl
    ON LOWER(TRIM(TO_VARCHAR(gl.geo_level_code))) = k.geo_level_code_norm
   AND TRIM(TO_VARCHAR(gl.geo_id)) = k.geo_id_norm
