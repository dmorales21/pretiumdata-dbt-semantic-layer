-- TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY
-- Fund canvas: property spine — SFDC property master × Yardi property attributes (SOURCE_ENTITY.PROGRESS).
-- Grain: one row per SFDC property row × matching Yardi prop-attribute row (LEFT join; orphan SFDC rows kept).
-- Join keys: vet with pretium-ai-dbt `scripts/sql/migration/vet_source_entity_progress_fund_objects.sql`; override vars in dbt_project / CLI if names differ.
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_property',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'allocate', 'sensitivity',
    ],
) }}

SELECT
    {{ dbt_utils.star(from=ref('fact_sfdc_properties_c'), relation_alias='p', prefix='sf_properties__') }},
    {{ dbt_utils.star(from=ref('fact_se_yardi_property_attribute'), relation_alias='y', prefix='yardi_propattr__') }}
FROM {{ ref('fact_sfdc_properties_c') }} AS p
LEFT JOIN {{ ref('fact_se_yardi_property_attribute') }} AS y
    ON NULLIF(TRIM(p.{{ adapter.quote(var('concept_progress_sfdc_yardi_property_code_column')) }}::VARCHAR), '')
        = NULLIF(TRIM(y.{{ adapter.quote(var('concept_progress_yardi_propattr_property_code_column')) }}::VARCHAR), '')
