{{ config(
    alias='fact_hud_housing_series_cbsa_monthly',
    tags=['transform', 'transform_dev', 'hud', 'fact_hud', 'cybersyn', 'serving_demo']
) }}

SELECT *
FROM {{ ref('fact_hud_housing_series_cbsa') }}
