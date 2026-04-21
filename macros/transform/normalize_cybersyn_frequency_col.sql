{# Map Cybersyn attribute FREQUENCY strings to REFERENCE.CATALOG.frequency_code values. #}
{% macro normalize_cybersyn_frequency_col(table_alias, column_name) -%}
(
    case
        when nullif(trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})), '') is null then 'monthly'
        when trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%week%' then 'weekly'
        when trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%month%' then 'monthly'
        when trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%quarter%'
            or trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%qtr%' then 'quarterly'
        when trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%annual%'
            or trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%year%' then 'annual'
        when trim(lower({{ table_alias }}.{{ adapter.quote(column_name) }})) like '%day%' then 'daily'
        else 'monthly'
    end
)
{%- endmacro %}
