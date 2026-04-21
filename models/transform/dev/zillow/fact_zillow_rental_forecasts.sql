-- TRANSFORM.DEV.FACT_ZILLOW_RENTAL_FORECASTS — migrated from pretium-ai-dbt zillow_research
{{ config(
    alias='fact_zillow_rental_forecasts',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    cluster_by=['date_reference', 'geo_id'],
) }}

{{ zillow_research_fact_enriched('raw_rental_forecasts', 'rental_forecasts') }}
