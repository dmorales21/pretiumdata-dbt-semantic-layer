-- TRANSFORM.DEV.FACT_ZILLOW_HOME_VALUES — migrated from pretium-ai-dbt zillow_research (large unpivot)
-- Use LOAD_WH when available to avoid dev warehouse timeouts on full refresh.
{{ config(
    alias='fact_zillow_home_values',
    tags=['transform', 'transform_dev', 'zillow', 'zillow_research', 'fact_zillow'],
    snowflake_warehouse=var('zillow_home_values_warehouse', 'LOAD_WH'),
) }}

{{ zillow_research_fact_enriched('raw_home_values', 'home_values') }}
