{{ config(
    alias='fact_fhfa_house_price_county_monthly',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn', 'serving_demo']
) }}

SELECT *
FROM {{ ref('fact_fhfa_house_price_county') }}
