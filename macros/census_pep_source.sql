{#-
  Census PEP annual population — Jon may publish under **TRANSFORM.FACT** or **TRANSFORM.CENSUS**.
  Catalog **dataset.csv** DS_005/DS_006 describe the logical dataset as CENSUS; physical FQN varies by account.

  Vars:
  - **`census_pep_silver_location`**: `transform_fact` (default) or `transform_census`
  - **`census_pep_cbsa_annual_identifier`** / **`census_pep_county_annual_identifier`**: physical table identifiers (defaults: CENSUS_PEP_*)
-#}
{% macro census_pep_source(grain) -%}
  {%- set g = grain | lower -%}
  {%- set loc = var('census_pep_silver_location', 'transform_fact') | lower -%}
  {%- if loc == 'transform_census' -%}
    {%- if g == 'cbsa' -%}
      {{ source('transform_census', 'census_pep_cbsa_annual') }}
    {%- elif g == 'county' -%}
      {{ source('transform_census', 'census_pep_county_annual') }}
    {%- else -%}
      {{ exceptions.raise_compiler_error("census_pep_source: grain must be cbsa or county, got " ~ grain) }}
    {%- endif -%}
  {%- else -%}
    {%- if g == 'cbsa' -%}
      {{ source('transform_fact', 'census_pep_cbsa_annual') }}
    {%- elif g == 'county' -%}
      {{ source('transform_fact', 'census_pep_county_annual') }}
    {%- else -%}
      {{ exceptions.raise_compiler_error("census_pep_source: grain must be cbsa or county, got " ~ grain) }}
    {%- endif -%}
  {%- endif -%}
{%- endmacro %}
