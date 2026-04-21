-- TRANSFORM.DEV.FACT_HUD_HOUSING_SERIES_CBSA — HUD series rows at CBSA grain only.
{{ config(
    alias='fact_hud_housing_series_cbsa',
    tags=['transform', 'transform_dev', 'hud', 'fact_hud', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_hud_housing_series') }}
WHERE lower(geo_level_code) = 'cbsa'
