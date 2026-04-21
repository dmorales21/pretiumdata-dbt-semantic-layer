-- TRANSFORM.DEV.CONCEPT_PROGRESS_RENT
-- Fund canvas: Progress **rent** — one curated row per `concept_progress_property` spine row.
-- **Objects wired:** `concept_progress_property` (SFDC × Yardi prop-attributes),
-- `fact_se_yardi_unit_type_market_rent` (SOURCE_ENTITY YARDI_UNITTYPE),
-- `fact_se_yardi_unit_master` (SOURCE_ENTITY YARDI_UNIT),
-- optional Jon silver `TRANSFORM.YARDI.UNIT_PROGRESS` roll-ups (same feed as `fact_progress_yardi_unit`;
-- gated with `transform_dev_enable_fund_opco_facts` so this model does not inherit that fact’s disable graph).
-- Grain: same as `concept_progress_property` (one row per SFDC property × matching Yardi prop-attribute row).
{{ config(
    materialized='table',
    database='TRANSFORM',
    schema='DEV',
    alias='concept_progress_rent',
    enabled=var('transform_dev_enable_source_entity_progress_facts', false),
    tags=[
        'transform', 'transform_dev', 'fund_opco', 'source_entity_progress',
        'source_entity_progress_concept', 'concept_progress', 'allocate', 'sensitivity',
    ],
) }}

{% set _fund_opco = var('transform_dev_enable_fund_opco_facts', true) %}
{% set _sfdc_prop_code = 'sf_properties__' ~ var('concept_progress_sfdc_yardi_property_code_column') %}

WITH spine AS (
    SELECT *
    FROM {{ ref('concept_progress_property') }}
),

unittype_by_scode AS (
    SELECT
        NULLIF(TRIM({{ adapter.quote('SCODE') }}::VARCHAR), '') AS join_scode,
        AVG(TRY_TO_DOUBLE({{ adapter.quote('SRENT') }})) AS entity_avg_unittype_srent_by_scode,
        COUNT(*)::BIGINT AS entity_unittype_row_count_by_scode
    FROM {{ ref('fact_se_yardi_unit_type_market_rent') }}
    GROUP BY 1
),

unittype_by_hproperty AS (
    SELECT
        TRY_TO_NUMBER(NULLIF(TRIM({{ adapter.quote('HPROPERTY') }}::VARCHAR), '')) AS yardi_property_hkey,
        AVG(TRY_TO_DOUBLE({{ adapter.quote('SRENT') }})) AS entity_avg_unittype_srent_by_hproperty
    FROM {{ ref('fact_se_yardi_unit_type_market_rent') }}
    WHERE NULLIF(TRIM({{ adapter.quote('HPROPERTY') }}::VARCHAR), '') IS NOT NULL
    GROUP BY 1
),

entity_unit_agg AS (
    SELECT
        TRY_TO_NUMBER(NULLIF(TRIM({{ adapter.quote('HPROPERTY') }}::VARCHAR), '')) AS yardi_property_hkey,
        AVG(TRY_TO_DOUBLE({{ adapter.quote('SRENT') }})) AS entity_avg_unit_srent,
        COUNT(*)::BIGINT AS entity_unit_row_count
    FROM {{ ref('fact_se_yardi_unit_master') }}
    WHERE NULLIF(TRIM({{ adapter.quote('HPROPERTY') }}::VARCHAR), '') IS NOT NULL
    GROUP BY 1
),

{% if _fund_opco %}
silver_unit_agg AS (
    SELECT
        u.HPROPERTY AS yardi_property_hkey,
        AVG(u.SRENT::FLOAT) AS silver_avg_unit_contract_rent,
        COUNT(*)::BIGINT AS silver_unit_row_count
    FROM {{ source('transform_yardi', 'UNIT_PROGRESS') }} AS u
    GROUP BY 1
)
{% else %}
silver_unit_agg AS (
    SELECT
        CAST(NULL AS NUMBER(38, 0)) AS yardi_property_hkey,
        CAST(NULL AS FLOAT) AS silver_avg_unit_contract_rent,
        CAST(NULL AS BIGINT) AS silver_unit_row_count
    WHERE FALSE
)
{% endif %}

SELECT
    'progress_rent' AS concept_code,
    'PROGRESS' AS vendor_code,
    TO_VARCHAR(s.sf_properties__ID) AS property_natural_key,
    NULLIF(TRIM(s.{{ adapter.quote(_sfdc_prop_code) }}::VARCHAR), '') AS progress_property_code,
    TRY_TO_NUMBER(NULLIF(TRIM(s.yardi_propattr__HPROPERTY::VARCHAR), '')) AS yardi_property_hkey,

    TRY_TO_DOUBLE(s.sf_properties__APPROVED_RENT__C) AS rent_approved_amount,
    TRY_TO_DOUBLE(s.sf_properties__MARKET_RENT__C) AS rent_market_amount,
    TRY_TO_DOUBLE(s.sf_properties__YARDI_MARKET_RENT__C) AS rent_yardi_market_amount,
    TRY_TO_DOUBLE(s.sf_properties__ACTUAL_RENT__C) AS rent_actual_amount,
    TRY_TO_DOUBLE(s.sf_properties__RENT__C) AS rent_generic_amount,
    TRY_TO_DOUBLE(s.sf_properties__UNDERWRITTEN_RENT__C) AS rent_underwritten_amount,
    TRY_TO_DOUBLE(s.sf_properties__ESTIMATED_SPOT_RENT__C) AS rent_estimated_spot_amount,
    TRY_TO_DOUBLE(s.sf_properties__DAM_APPROVED_RENT__C) AS rent_dam_approved_amount,
    TRY_TO_DOUBLE(s.sf_properties__RENT_IF_OCCUPIED__C) AS rent_if_occupied_amount,
    TRY_TO_DOUBLE(s.sf_properties__PRICING_TOOL_RENT__C) AS rent_pricing_tool_amount,
    TRY_TO_DOUBLE(s.sf_properties__PMC_ESTIMATED_SPOT_RENT__C) AS rent_pmc_estimated_spot_amount,
    TRY_TO_DOUBLE(s.sf_properties__PMC_MARKETING_RENT__C) AS rent_pmc_marketing_amount,
    TRY_TO_DOUBLE(s.sf_properties__MAX_TENANT_RENT__C) AS rent_max_tenant_amount,
    TRY_TO_DOUBLE(s.sf_properties__YARDI_TENANT_RENT__C) AS rent_yardi_tenant_amount,
    TRY_TO_DOUBLE(s.sf_properties__ORIGINAL_YARDI_MARKET_RENT__C) AS rent_original_yardi_market_amount,
    TRY_TO_DOUBLE(s.sf_properties__PREVIOUS_YARDI_MARKET_RENT__C) AS rent_previous_yardi_market_amount,
    TRY_TO_DOUBLE(s.sf_properties__AFFORDABLE_UNDERWRITTEN_RENT__C) AS rent_affordable_underwritten_amount,
    TRY_TO_DOUBLE(s.sf_properties__RENT_PER_SF__C) AS rent_per_sf,
    TRY_TO_DOUBLE(s.sf_properties__YARDI_TENANT_RENT_PER_SF__C) AS rent_yardi_tenant_per_sf,
    TRY_TO_DOUBLE(s.sf_properties__SEASONALLY_ADJUSTED_RENT__C) AS rent_seasonally_adjusted_amount,
    TRY_TO_DOUBLE(s.sf_properties__ANNUALIZED_RENTAL_INCOME__C) AS annualized_rental_income_amount,

    TRY_TO_DATE(s.sf_properties__APPROVED_RENT_DATE__C::VARCHAR) AS rent_approved_effective_date,
    TRY_TO_DATE(s.sf_properties__MARKET_RENT_DATE__C::VARCHAR) AS rent_market_effective_date,
    TRY_TO_DATE(s.sf_properties__RENT_VERIFIED_DATE__C::VARCHAR) AS rent_verified_date,
    TRY_TO_TIMESTAMP_NTZ(s.sf_properties__YARDI_MARKET_RENT_LAST_CHANGED__C::VARCHAR) AS yardi_market_rent_last_changed_at,

    COALESCE(ut_h.entity_avg_unittype_srent_by_hproperty, ut_s.entity_avg_unittype_srent_by_scode)
        AS entity_unittype_market_rent_srent_avg,
    ut_s.entity_unittype_row_count_by_scode,
    eu.entity_avg_unit_srent,
    eu.entity_unit_row_count,
    su.silver_avg_unit_contract_rent,
    su.silver_unit_row_count,

    COALESCE(
        TRY_TO_DOUBLE(s.sf_properties__APPROVED_RENT__C),
        TRY_TO_DOUBLE(s.sf_properties__MARKET_RENT__C),
        TRY_TO_DOUBLE(s.sf_properties__YARDI_MARKET_RENT__C),
        TRY_TO_DOUBLE(s.sf_properties__ACTUAL_RENT__C),
        TRY_TO_DOUBLE(s.sf_properties__RENT__C)
    ) AS {{ concept_metric_slot('rent', 'current') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
    CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},

    CURRENT_TIMESTAMP() AS dbt_updated_at,

    {{ dbt_utils.star(from=ref('concept_progress_property'), relation_alias='s') }}

FROM spine AS s
LEFT JOIN unittype_by_scode AS ut_s
    ON NULLIF(TRIM(s.{{ adapter.quote(_sfdc_prop_code) }}::VARCHAR), '') = ut_s.join_scode
LEFT JOIN unittype_by_hproperty AS ut_h
    ON TRY_TO_NUMBER(NULLIF(TRIM(s.yardi_propattr__HPROPERTY::VARCHAR), '')) = ut_h.yardi_property_hkey
LEFT JOIN entity_unit_agg AS eu
    ON TRY_TO_NUMBER(NULLIF(TRIM(s.yardi_propattr__HPROPERTY::VARCHAR), '')) = eu.yardi_property_hkey
LEFT JOIN silver_unit_agg AS su
    ON TRY_TO_NUMBER(NULLIF(TRIM(s.yardi_propattr__HPROPERTY::VARCHAR), '')) = su.yardi_property_hkey
