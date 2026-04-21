{% macro costar_rent_measure_column(use_asking) -%}
  {%- if use_asking -%}
    MARKET_ASKING_RENT_PER_UNIT
  {%- else -%}
    MARKET_EFFECTIVE_RENT_PER_UNIT
  {%- endif -%}
{%- endmacro %}
