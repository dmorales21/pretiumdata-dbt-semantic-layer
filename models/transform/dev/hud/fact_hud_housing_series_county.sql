-- TRANSFORM.DEV.FACT_HUD_HOUSING_SERIES_COUNTY — HUD series rows at county grain only.
{{ config(
    alias='fact_hud_housing_series_county',
    tags=['transform', 'transform_dev', 'hud', 'fact_hud', 'cybersyn'],
) }}

SELECT *
FROM {{ ref('fact_hud_housing_series') }}
WHERE lower(geo_level_code) = 'county'
