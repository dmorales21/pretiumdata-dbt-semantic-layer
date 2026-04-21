{{ config(
    alias='fact_fhfa_mortgage_performance_county_monthly',
    tags=['transform', 'transform_dev', 'fhfa', 'fact_fhfa', 'cybersyn', 'serving_demo']
) }}

SELECT *
FROM {{ ref('fact_fhfa_mortgage_performance_county') }}
