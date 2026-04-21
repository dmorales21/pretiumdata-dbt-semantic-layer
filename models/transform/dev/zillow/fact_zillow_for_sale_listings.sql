-- TRANSFORM.DEV.FACT_ZILLOW_FOR_SALE_LISTINGS — migrated from pretium-ai-dbt zillow_research
{{ config(
    alias='fact_zillow_for_sale_listings',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    cluster_by=['date_reference', 'geo_id'],
) }}

{{ zillow_research_fact_enriched('raw_for_sale_listings', 'for_sale_listings') }}
