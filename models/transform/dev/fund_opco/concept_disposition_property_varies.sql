-- TRANSFORM.DEV.CONCEPT_DISPOSITION_PROPERTY_VARIES
-- Canonical **disposition** concept surface: Progress **SFDC_DISPOSITION__C** exit / list-to-close economics
-- (one row per disposition record; time discipline from SFDC mod stamps — not vendor market panels).
-- Use with ``concept_progress_disposition_bpo`` when BPO triangulation is required. For Fund IV pricing APIs,
-- join ``geo_id`` / ``property_natural_key`` to ``concept_progress_property`` on ``PROPERTY__C`` ↔ property id.
-- **History:** true SCD2 requires ``SFDC_DISPOSITION__HISTORY`` (not modeled here); this object is current-state wide extract.
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_disposition_property_varies',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_disposition', 'returns', 'sensitivity',
    ],
) }}

SELECT
    'disposition' AS concept_code,
    'PROGRESS_SFDC' AS vendor_code,
    'property' AS geo_level_code,
    TRIM(TO_VARCHAR(d.{{ adapter.quote('PROPERTY__C') }})) AS geo_id,
    TRIM(TO_VARCHAR(d.{{ adapter.quote('PROPERTY__C') }})) AS property_natural_key,
    COALESCE(
        TRY_TO_TIMESTAMP(TO_VARCHAR(d.{{ adapter.quote('LASTMODIFIEDDATE') }})),
        TRY_TO_TIMESTAMP(TO_VARCHAR(d.{{ adapter.quote('SYSTEMMODSTAMP') }})),
        TRY_TO_TIMESTAMP(TO_VARCHAR(d.{{ adapter.quote('CREATEDDATE') }})),
        CURRENT_TIMESTAMP()
    )::DATE AS disposition_as_of_date,
    DATE_TRUNC(
        'month',
        COALESCE(
            TRY_TO_TIMESTAMP(TO_VARCHAR(d.{{ adapter.quote('LASTMODIFIEDDATE') }})),
            TRY_TO_TIMESTAMP(TO_VARCHAR(d.{{ adapter.quote('SYSTEMMODSTAMP') }})),
            TRY_TO_TIMESTAMP(TO_VARCHAR(d.{{ adapter.quote('CREATEDDATE') }})),
            CURRENT_TIMESTAMP()
        )
    )::DATE AS month_start,
    {{ dbt_utils.star(from=ref('fact_sfdc_disposition_c'), relation_alias='d', prefix='disposition__') }}
FROM {{ ref('fact_sfdc_disposition_c') }} AS d
