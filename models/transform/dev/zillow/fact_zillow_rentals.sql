-- TRANSFORM.DEV.FACT_ZILLOW_RENTALS — migrated from pretium-ai-dbt zillow_research
{{ config(
    alias='fact_zillow_rentals',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    cluster_by=['date_reference', 'geo_id'],
) }}

{{ zillow_research_fact_enriched('raw_rentals', 'rentals') }}
