-- TRANSFORM.DEV.FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY — **TRANSFORM.MARKERR.RENT_PROPERTY_CBSA_MONTHLY** with CBSA / rent typing.
-- Feeds ``concept_rent_market_monthly`` Markerr MF branch; keeps Jon column names the concept expects.
{{ config(
    alias='fact_markerr_rent_property_cbsa_monthly',
    materialized='view',
    tags=['transform', 'transform_dev', 'markerr', 'fact_markerr'],
) }}

SELECT
    s.MONTH_DATE::DATE                                              AS MONTH_DATE,
    LPAD(TRIM(TO_VARCHAR(s.CBSA_ID)), 5, '0')                       AS CBSA_ID,
    TRIM(TO_VARCHAR(s.BEDROOM_CATEGORY))                            AS BEDROOM_CATEGORY,
    TRIM(TO_VARCHAR(s.CLASS_CATEGORY))                             AS CLASS_CATEGORY,
    (s.AVG_RENT_EFFECTIVE + 0e0)::DOUBLE                            AS AVG_RENT_EFFECTIVE,
    (s.AVG_RENT_ASKING + 0e0)::DOUBLE                               AS AVG_RENT_ASKING
FROM {{ source('transform_markerr', 'rent_property_cbsa_monthly') }} AS s
WHERE s.MONTH_DATE IS NOT NULL
  AND s.CBSA_ID IS NOT NULL
