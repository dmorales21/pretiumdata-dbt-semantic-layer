-- TRANSFORM.DEV.FACT_ZILLOW_DAYS_ON_MARKET_AND_PRICE_CUTS — migrated from pretium-ai-dbt zillow_research
{{ config(
    alias='fact_zillow_days_on_market_and_price_cuts',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    cluster_by=['date_reference', 'geo_id'],
) }}

{{ zillow_research_fact_enriched('raw_days_on_market_and_price_cuts', 'days_on_market_and_price_cuts') }}
