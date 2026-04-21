{% macro concept_metric_slot(concept_code, temporality) -%}
  {#-
    Canonical wide-slot column names for cross-vendor concept objects.

    Naming: ``{concept}_{temporality}`` with concept slug lower_snake and temporality one of
    ``current`` | ``historical`` | ``forecast`` (extend callers if you add ``nowcast``, etc.).

    Examples: ``rent_current``, ``avm_current``, ``valuation_forecast``.

    Use in SELECT aliases so Zillow, Cherre, and future vendors expose the same surface for a
    given ``concept_code`` at the same geo grain.
  -#}
  {{- (concept_code | trim | lower | replace(' ', '_')) ~ '_' ~ (temporality | trim | lower) -}}
{%- endmacro %}


{% macro concept_zillow_geo_key_match(left_alias, right_alias) -%}
  {#- Equality on Zillow research enriched grain (within vendor). -#}
  {{ left_alias }}.geo_level_code = {{ right_alias }}.geo_level_code
  AND {{ left_alias }}.geo_id = {{ right_alias }}.geo_id
{%- endmacro %}
