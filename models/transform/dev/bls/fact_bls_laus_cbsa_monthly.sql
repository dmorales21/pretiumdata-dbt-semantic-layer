-- TRANSFORM.DEV.FACT_BLS_LAUS_CBSA_MONTHLY — read-through of TRANSFORM.BLS.LAUS_CBSA (observe-only).
-- Part C: `AREA_CODE` is a BLS metro series code — **not** guaranteed OMB CBSA FIPS. Do not join to
-- `CBSA_CODE` / `GEOID` without an explicit crosswalk; prefer `ref('fact_bls_laus_county')` + county→CBSA for OMB CBSA.
{{ config(
    alias='fact_bls_laus_cbsa_monthly',
    tags=['transform', 'transform_dev', 'bls', 'fact_bls', 'laus', 'observe_only'],
) }}

SELECT
    src.*,
    'cbsa'::varchar AS geo_level_code
FROM {{ source('bls_transform', 'laus_cbsa') }} AS src
