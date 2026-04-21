-- ANALYTICS — thin read surface for Zillow listings velocity (DOM / price cuts + for-sale listings).
-- Catalog: MET_042 / MET_043 and MDV_004 + metric_derived_input (WL_020 / P2 listings spine).
--
-- **Lineage note (Phase B):** Canonical market union is **`ref('concept_listings_market_monthly')`** (Zillow + Realtor CBSA).
-- This model still reads **`fact_zillow_*`** directly to preserve the historical **wide FACT column shape** (`f.*`) for
-- MET_042 / MET_043 consumers. **TODO:** reshape to `SELECT … FROM {{ ref('concept_listings_market_monthly') }}`
-- WHERE ``vendor_code = 'ZILLOW'`` (and equivalent metric slots) once downstream contracts are ported — see
-- ``docs/migration/QA_CONCEPT_PREFLIGHT_CHECKLIST.md`` §C.
{{ config(
    materialized='view',
    alias='feature_listings_velocity_monthly',
    tags=['analytics', 'feature', 'listings', 'zillow'],
) }}

SELECT
    'MET_042' AS catalog_metric_code,
    'listings' AS concept_code,
    f.*
FROM {{ ref('fact_zillow_days_on_market_and_price_cuts') }} AS f

UNION ALL

SELECT
    'MET_043' AS catalog_metric_code,
    'listings' AS concept_code,
    f.*
FROM {{ ref('fact_zillow_for_sale_listings') }} AS f
