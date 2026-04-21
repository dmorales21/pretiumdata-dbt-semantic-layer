{% macro normalize_cybersyn_geo_id(column_sql) -%}
  trim(
    case
      when {{ column_sql }} ilike 'geoId/%' then replace({{ column_sql }}, 'geoId/', '')
      when {{ column_sql }} ilike 'zip/%' then substr({{ column_sql }}, 5)
      else trim({{ column_sql }})
    end
  )
{%- endmacro %}
