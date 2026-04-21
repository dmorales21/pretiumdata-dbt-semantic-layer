-- TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES_FORECASTS — migrated from pretium-ai-dbt zillow_research
{{ config(
    alias='fact_zillow_home_values_forecasts',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    cluster_by=['date_reference', 'geo_id'],
) }}

{{ zillow_research_fact_enriched('raw_home_values_forecasts', 'home_values_forecasts') }}
