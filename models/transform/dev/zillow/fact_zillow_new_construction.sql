-- TRANSFORM.DEV.FACT_ZILLOW_NEW_CONSTRUCTION — migrated from pretium-ai-dbt zillow_research
{{ config(
    alias='fact_zillow_new_construction',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    cluster_by=['date_reference', 'geo_id'],
) }}

{{ zillow_research_fact_enriched('raw_new_construction', 'new_construction') }}
