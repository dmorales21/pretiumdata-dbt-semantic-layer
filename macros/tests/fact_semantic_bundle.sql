{#
  Shared **FACT_* semantic bundle** for dbt data tests: time sanity, key nulls, and optional
  **REFERENCE** spine join to ``ref('geography_latest')`` for geo coverage / xwalk QA.

  **Generic test (attach in model YAML):**

  ```yaml
  tests:
    - fact_semantic_bundle:
        date_column: date_reference
        geo_id_column: geo_id
        geo_level_column: geo_level_code
        enforce_geography_join: true
        max_future_days: 0
        min_calendar_year: 1900
  ```

  **Call SQL from a singular / analysis (advanced):**

  ``{{ fact_semantic_bundle_sql(ref('fact_example'), ...) }}``

  Snowflake: identifiers are matched case-insensitively when unquoted; pass names as emitted by the model.
#}

{% macro fact_semantic_bundle__sql_list(levels) %}
    {%- for l in levels -%}
        lower('{{ l | replace("'", "''") }}'){% if not loop.last %}, {% endif %}
    {%- endfor -%}
{% endmacro %}

{% macro fact_semantic_bundle_sql(
    model,
    date_column='date_reference',
    geo_id_column='geo_id',
    geo_level_column='geo_level_code',
    include_geo_level_checks=true,
    enforce_geography_join=true,
    geography_spine_geo_levels=none,
    skip_geography_join_geo_levels=['property', 'unmapped', 'corridor_h3'],
    max_future_days=0,
    min_calendar_year=none,
    require_geo_level_when_geo_id_present=true
) %}
    {%- set _default_spine = [
        'zip', 'county', 'cbsa', 'state', 'zcta', 'tract', 'block_group',
        'metro_division', 'city', 'neighborhood', 'place', 'country',
        'census_region', 'census_division', 'national',
    ] -%}
    {%- set spine = geography_spine_geo_levels if geography_spine_geo_levels is not none else _default_spine -%}
    {%- set skip_levels = skip_geography_join_geo_levels if skip_geography_join_geo_levels is not none else [] -%}
    {%- set _max_future = max_future_days | int -%}

WITH
base AS (
    SELECT * FROM {{ model }}
),

v_null_geo_id AS (
    SELECT
        'null_geo_id' AS violation_type,
        COUNT(*)::BIGINT AS violation_count
    FROM base
    WHERE {{ geo_id_column }} IS NULL
),

v_null_date AS (
    SELECT
        'null_date' AS violation_type,
        COUNT(*)::BIGINT AS violation_count
    FROM base
    WHERE {{ date_column }} IS NULL
),

{% if include_geo_level_checks and require_geo_level_when_geo_id_present %}
v_null_geo_level AS (
    SELECT
        'null_geo_level_when_geo_id_present' AS violation_type,
        COUNT(*)::BIGINT AS violation_count
    FROM base
    WHERE {{ geo_id_column }} IS NOT NULL
      AND {{ geo_level_column }} IS NULL
),
{% else %}
v_null_geo_level AS (
    SELECT CAST(NULL AS VARCHAR) AS violation_type, CAST(0 AS BIGINT) AS violation_count WHERE 1 = 0
),
{% endif %}

{% if min_calendar_year is not none %}
v_year_floor AS (
    SELECT
        'date_before_min_calendar_year' AS violation_type,
        COUNT(*)::BIGINT AS violation_count
    FROM base
    WHERE {{ date_column }} IS NOT NULL
      AND YEAR({{ date_column }}::DATE) < {{ min_calendar_year | int }}
),
{% else %}
v_year_floor AS (
    SELECT CAST(NULL AS VARCHAR) AS violation_type, CAST(0 AS BIGINT) AS violation_count WHERE 1 = 0
),
{% endif %}

v_future_date AS (
    SELECT
        'date_in_future' AS violation_type,
        COUNT(*)::BIGINT AS violation_count
    FROM base
    WHERE {{ date_column }} IS NOT NULL
      AND {{ date_column }}::DATE > DATEADD(
            day,
            {{ _max_future }},
            CURRENT_DATE()
        )
),

{% if enforce_geography_join and include_geo_level_checks and spine | length > 0 %}
v_geo_spine_miss AS (
    SELECT
        'geography_spine_miss' AS violation_type,
        COUNT(*)::BIGINT AS violation_count
    FROM base AS b
    LEFT JOIN {{ ref('geography_latest') }} AS gl
        ON TRIM(TO_VARCHAR(b.{{ geo_id_column }})) = TRIM(TO_VARCHAR(gl.geo_id))
       AND LOWER(TRIM(TO_VARCHAR(b.{{ geo_level_column }}))) = LOWER(TRIM(TO_VARCHAR(gl.geo_level_code)))
    WHERE b.{{ geo_id_column }} IS NOT NULL
      AND b.{{ geo_level_column }} IS NOT NULL
      AND LOWER(TRIM(TO_VARCHAR(b.{{ geo_level_column }}))) IN ({{ fact_semantic_bundle__sql_list(spine) }})
      {% if skip_levels | length > 0 %}
      AND LOWER(TRIM(TO_VARCHAR(b.{{ geo_level_column }}))) NOT IN ({{ fact_semantic_bundle__sql_list(skip_levels) }})
      {% endif %}
      AND gl.geo_id IS NULL
),
{% else %}
v_geo_spine_miss AS (
    SELECT CAST(NULL AS VARCHAR) AS violation_type, CAST(0 AS BIGINT) AS violation_count WHERE 1 = 0
),
{% endif %}

checks AS (
    SELECT * FROM v_null_geo_id
    UNION ALL SELECT * FROM v_null_date
    UNION ALL SELECT * FROM v_null_geo_level
    UNION ALL SELECT * FROM v_year_floor
    UNION ALL SELECT * FROM v_future_date
    UNION ALL SELECT * FROM v_geo_spine_miss
)

SELECT violation_type, violation_count
FROM checks
WHERE violation_type IS NOT NULL
  AND violation_count > 0

{% endmacro %}

{% test fact_semantic_bundle(
    model,
    date_column='date_reference',
    geo_id_column='geo_id',
    geo_level_column='geo_level_code',
    include_geo_level_checks=true,
    enforce_geography_join=true,
    geography_spine_geo_levels=none,
    skip_geography_join_geo_levels=['property', 'unmapped', 'corridor_h3'],
    max_future_days=0,
    min_calendar_year=none,
    require_geo_level_when_geo_id_present=true
) %}
    {{ fact_semantic_bundle_sql(
        model,
        date_column=date_column,
        geo_id_column=geo_id_column,
        geo_level_column=geo_level_column,
        include_geo_level_checks=include_geo_level_checks,
        enforce_geography_join=enforce_geography_join,
        geography_spine_geo_levels=geography_spine_geo_levels,
        skip_geography_join_geo_levels=skip_geography_join_geo_levels,
        max_future_days=max_future_days,
        min_calendar_year=min_calendar_year,
        require_geo_level_when_geo_id_present=require_geo_level_when_geo_id_present
    ) }}
{% endtest %}
