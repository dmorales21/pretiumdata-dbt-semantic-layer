{% macro generate_schema_name(custom_schema_name, node) -%}

  {#-
    Schema resolution for pretiumdata_dbt_semantic_layer
    Rules:
    - Seeds under reference/catalog → always CATALOG (no env variation)
    - Seeds under reference/draft   → always DRAFT (no env variation)
    - Analytics models              → DBT_DEV / DBT_STAGE / DBT_PROD by target
    - Semantic CONCEPT_* / entity   → DEV via dbt_project (+schema: DEV on transform/dev/concept|entity)
    - Intermediate models           → INTERMEDIATE (always)
    - SERVING demo models           → DEMO (always)
    - No default schema fallback    → explicit config required on all paths
  -#}

  {%- set analytics_schema_map = {
    'dev':        'DBT_DEV',
    'staging':    'DBT_STAGE',
    'prod':       'DBT_PROD',
    'reference':  'DBT_DEV',
    'semantic_dev': 'DBT_DEV'
  } -%}

  {%- if custom_schema_name is none -%}
    {{ target.schema }}

  {%- elif custom_schema_name == 'CATALOG' -%}
    CATALOG

  {%- elif custom_schema_name == 'DRAFT' -%}
    DRAFT

  {%- elif custom_schema_name == 'SEMANTIC' -%}
    SEMANTIC

  {%- elif custom_schema_name == 'INTERMEDIATE' -%}
    INTERMEDIATE

  {%- elif custom_schema_name == 'DEMO' -%}
    DEMO

  {%- elif custom_schema_name in ['DBT_DEV', 'DBT_STAGE', 'DBT_PROD'] -%}
    {{ analytics_schema_map[target.name] | default('DBT_DEV') }}

  {%- else -%}
    {{ custom_schema_name }}

  {%- endif -%}

{%- endmacro %}
