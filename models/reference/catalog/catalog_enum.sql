{{ config(
    materialized='table',
    alias='enum',
    tags=['reference', 'catalog']
) }}

{# Unified ENUM: merged seed rows + first-class dimension seeds still maintained as separate CSVs. #}
with merged as (
    select
        trim(enum_table)::varchar as enum_table,
        trim(code)::varchar as code,
        trim(label)::varchar as label,
        case
            when trim(sort_order) = '' or sort_order is null then null
            else try_cast(trim(sort_order) as integer)
        end as sort_order,
        case
            when trim(range_min) = '' or range_min is null then null
            else try_cast(trim(range_min) as double)
        end as range_min,
        case
            when trim(range_max) = '' or range_max is null then null
            else try_cast(trim(range_max) as double)
        end as range_max,
        case upper(trim(is_active))
            when 'TRUE' then true
            when 'FALSE' then false
            else coalesce(try_cast(trim(is_active) as boolean), true)
        end as is_active,
        coalesce(try_cast(trim(updated_at) as date), current_date())::date as updated_at
    from {{ ref('catalog_enum_source') }} as s
),

extra_frequency as (
    select
        'frequency'::varchar as enum_table,
        t.frequency_code::varchar as code,
        t.frequency_label::varchar as label,
        t.sort_order::integer as sort_order,
        null::double as range_min,
        null::double as range_max,
        t.is_active::boolean as is_active,
        current_date()::date as updated_at
    from {{ ref('frequency') }} as t
),

extra_asset_type as (
    select
        'asset_type'::varchar as enum_table,
        t.asset_type_code::varchar as code,
        t.asset_type_label::varchar as label,
        t.sort_order::integer as sort_order,
        null::double as range_min,
        null::double as range_max,
        t.is_active::boolean as is_active,
        current_date()::date as updated_at
    from {{ ref('asset_type') }} as t
),

extra_tenant_type as (
    select
        'tenant_type'::varchar as enum_table,
        t.tenant_type_code::varchar as code,
        t.tenant_type_label::varchar as label,
        t.sort_order::integer as sort_order,
        null::double as range_min,
        null::double as range_max,
        t.is_active::boolean as is_active,
        current_date()::date as updated_at
    from {{ ref('tenant_type') }} as t
)

select * from merged
union all
select * from extra_frequency
union all
select * from extra_asset_type
union all
select * from extra_tenant_type
