{% macro unpivot_zillow_research_long(raw_source_table, dataset_slug) %}
{#-
  Wide Zillow research VARIANT (v) → long rows: one row per (region × calendar period × metric file).
  Reads SOURCE_PROD.ZILLOW via source('zillow', raw_source_table).
-#}
WITH src AS (
    SELECT
        v,
        file_name,
        snapshot_date,
        loaded_at
    FROM {{ source('zillow', raw_source_table) }}
),

flattened AS (
    SELECT
        s.v               AS v,
        s.file_name       AS file_name,
        s.snapshot_date   AS batch_snapshot_date,
        s.loaded_at       AS loaded_at,
        f.key             AS attr_key,
        f.value           AS attr_val
    FROM src AS s,
    LATERAL FLATTEN(INPUT => s.v) AS f
),

with_date_keys AS (
    SELECT
        v,
        file_name,
        batch_snapshot_date,
        loaded_at,
        attr_key,
        attr_val
    FROM flattened
    WHERE attr_key::STRING REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
)

SELECT
    NULLIF(TRIM(v:RegionID::STRING), '')                                              AS geo_id,
    CASE
        WHEN LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%zip%' THEN 'zip'
        WHEN LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%county%' THEN 'county'
        WHEN LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%metro%' THEN 'metro'
        WHEN LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%city%' THEN 'city'
        WHEN LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%state%' THEN 'state'
        WHEN LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%national%'
            OR LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%__u_s%'
            OR LOWER(SPLIT_PART(file_name, '/', -1)) LIKE '%_us.%' THEN
            CASE
                WHEN NULLIF(TRIM(v:RegionType::STRING), '') IS NOT NULL
                    AND LOWER(TRIM(v:RegionType::STRING)) <> 'country'
                    THEN LOWER(TRIM(v:RegionType::STRING))
                ELSE 'country'
            END
        ELSE 'zillow_region'
    END                                                                               AS geo_level_code,
    TRY_TO_DATE(attr_key::STRING)                                                     AS date_reference,
    UPPER(
        REPLACE(
            REPLACE(LOWER(SPLIT_PART(file_name, '/', -1)), '.parquet', ''),
            '.csv', ''
        )
    )                                                                                 AS metric_id,
    TRY_TO_DOUBLE(attr_val::STRING)                                                   AS metric_value,
    'ZILLOW'                                                                          AS vendor_name,
    '{{ dataset_slug }}'                                                              AS dataset_slug,
    NULLIF(TRIM(v:RegionName::STRING), '')                                            AS region_name,
    TRY_TO_NUMBER(NULLIF(TRIM(v:SizeRank::STRING), ''))                               AS size_rank,
    NULLIF(TRIM(v:RegionType::STRING), '')                                            AS region_type,
    NULLIF(TRIM(v:StateName::STRING), '')                                             AS state_name,
    file_name                                                                         AS source_file_name,
    batch_snapshot_date,
    loaded_at
FROM with_date_keys
WHERE TRY_TO_DATE(attr_key::STRING) IS NOT NULL

{% endmacro %}
