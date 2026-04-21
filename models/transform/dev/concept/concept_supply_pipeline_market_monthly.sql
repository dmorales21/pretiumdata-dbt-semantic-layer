{#-
  **Supply pipeline** — monthly CBSA spine for **inventory tightness / construction flow** signals that are *not*
  the same as **listings** DOM / active-count semantics (see ``concept_listings_market_monthly``).

  **Zillow Research — new construction** (``fact_zillow_new_construction``): CBSA rows only. Primary series is chosen
  by ``vars.concept_supply_pipeline_zillow_nc_metric_pattern`` (default prefers **sales count** long ``metric_id``).

  **Realtor.com — CBSA inventory** (``fact_realtor_inventory_cbsa``): rows whose ``metric_id`` matches
  ``vars.concept_supply_pipeline_realtor_metric_pattern`` (default: months-of-supply style slugs).

  **Markerr** — ``FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY`` aggregated to CBSA × month (**listing_count** sum).
  **RCA** — ``FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY`` aggregated to CBSA × month (**units_under_construction** sum).

  **Zonda SFR** — ``FACT_ZONDA_SFR_H3_R8_MONTHLY`` aggregated to CBSA × month (**sfr_inventory_uc_wavg** sum across H3 rows).
  Disable: ``vars.concept_supply_pipeline_include_zonda_sfr: false``.

  **Cherre vacant** — county snapshot without observation month; keep out of this monthly mart until a dated FACT lands.

  Disable Markerr + RCA branches: ``vars.concept_supply_pipeline_include_markerr_rca: false``.
-#}

{{ config(
    materialized='table',
    alias='concept_supply_pipeline_market_monthly',
    tags=['semantic', 'concept', 'supply_pipeline', 'pipeline', 'zillow', 'realtor', 'markerr', 'rca', 'zonda'],
) }}

{% set _zrx = var('concept_supply_pipeline_zillow_nc_metric_pattern', '%SALES_COUNT%RAW_ALL_HOMES%') | replace("'", "''") %}
{% set _rrx = var('concept_supply_pipeline_realtor_metric_pattern', '%MONTH%SUPPLY%') | replace("'", "''") %}
{% set _mrca = var('concept_supply_pipeline_include_markerr_rca', true) %}
{% set _zsf = var('concept_supply_pipeline_include_zonda_sfr', true) %}

WITH realtor_base AS (
    SELECT
        DATE_TRUNC('month', r.date_reference)::DATE AS month_start,
        COALESCE(
            NULLIF(LPAD(LEFT(REGEXP_REPLACE(TRIM(TO_VARCHAR(r.geo_id)), '[^0-9]', ''), 5), 5, '0'), '00000'),
            TRIM(TO_VARCHAR(r.geo_id))
        ) AS cbsa_id,
        TRIM(TO_VARCHAR(r.metric_id)) AS metric_id_observe,
        TRY_TO_DOUBLE(TO_VARCHAR(r.value)) AS metric_value
    FROM {{ ref('fact_realtor_inventory_cbsa') }} AS r
    WHERE r.date_reference IS NOT NULL
      AND r.geo_id IS NOT NULL
      AND r.value IS NOT NULL
),

realtor_pipeline AS (
    SELECT
        'supply_pipeline' AS concept_code,
        'REALTOR' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        (LENGTH(c.cbsa_id) = 5) AS has_census_geo,
        'fact_realtor_inventory_cbsa' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM realtor_base AS c
    LEFT JOIN realtor_base AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
    WHERE UPPER(REPLACE(c.metric_id_observe, ' ', '_')) ILIKE '{{ _rrx }}'
),

zillow_nc_ranked AS (
    SELECT
        DATE_TRUNC('month', z.date_reference)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0') AS cbsa_id,
        z.metric_id AS metric_id_observe,
        z.metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC('month', z.date_reference)::DATE, LPAD(TRIM(TO_VARCHAR(z.geo_id)), 5, '0')
            ORDER BY
                CASE
                    WHEN UPPER(REPLACE(z.metric_id, ' ', '_')) ILIKE '{{ _zrx }}' THEN 1
                    ELSE 2
                END,
                z.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_new_construction') }} AS z
    WHERE LOWER(z.geo_level_code) = 'cbsa'
      AND z.date_reference IS NOT NULL
      AND z.geo_id IS NOT NULL
      AND z.metric_value IS NOT NULL
),

zillow_nc_pick AS (
    SELECT *
    FROM zillow_nc_ranked
    WHERE metric_rn = 1
      AND UPPER(REPLACE(metric_id_observe, ' ', '_')) ILIKE '{{ _zrx }}'
),

zillow_nc AS (
    SELECT
        'supply_pipeline' AS concept_code,
        'ZILLOW_NEW_CONSTRUCTION' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zillow_new_construction' AS census_geo_source,
        c.metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zillow_nc_pick AS c
    LEFT JOIN zillow_nc_pick AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.metric_id_observe = h.metric_id_observe
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

markerr_list_cbsa AS (
    SELECT
        DATE_TRUNC('month', m.as_of_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(m.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(m.listing_count)::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_markerr_rent_listings_county_monthly') }} AS m
    WHERE m.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(m.cbsa_id)) != ''
      AND m.as_of_month IS NOT NULL
    GROUP BY 1, 2
),

markerr_listings_out AS (
    SELECT
        'supply_pipeline' AS concept_code,
        'MARKERR_RENT_LISTINGS' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_markerr_rent_listings_county_monthly' AS census_geo_source,
        'concept_supply_pipeline_markerr_listings_count_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM markerr_list_cbsa AS c
    LEFT JOIN markerr_list_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

rca_construction_cbsa AS (
    SELECT
        DATE_TRUNC('month', c.as_of_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(c.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(c.units_under_construction)::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_rca_mf_construction_county_monthly') }} AS c
    WHERE c.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(c.cbsa_id)) != ''
      AND c.as_of_month IS NOT NULL
    GROUP BY 1, 2
),

rca_construction_out AS (
    SELECT
        'supply_pipeline' AS concept_code,
        'RCA_MF_CONSTRUCTION' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_rca_mf_construction_county_monthly' AS census_geo_source,
        'concept_supply_pipeline_rca_mf_uc_units_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM rca_construction_cbsa AS c
    LEFT JOIN rca_construction_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

zonda_sfr_cbsa AS (
    SELECT
        DATE_TRUNC('month', s.as_of_month)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(s.cbsa_id)), 5, '0') AS cbsa_id,
        SUM(COALESCE(TRY_TO_DOUBLE(TO_VARCHAR(s.sfr_inventory_uc_wavg)), 0::DOUBLE))::DOUBLE AS metric_value
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_zonda_sfr_h3_r8_monthly') }} AS s
    WHERE s.cbsa_id IS NOT NULL
      AND TRIM(TO_VARCHAR(s.cbsa_id)) != ''
      AND s.as_of_month IS NOT NULL
    GROUP BY 1, 2
),

zonda_sfr_out AS (
    SELECT
        'supply_pipeline' AS concept_code,
        'ZONDA_SFR' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_zonda_sfr_h3_r8_monthly' AS census_geo_source,
        'concept_supply_pipeline_zonda_sfr_inventory_uc_wsum_cbsa_monthly' AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('supply_pipeline', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM zonda_sfr_cbsa AS c
    LEFT JOIN zonda_sfr_cbsa AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
)

SELECT * FROM realtor_pipeline
UNION ALL
SELECT * FROM zillow_nc
{% if _mrca %}
UNION ALL
SELECT * FROM markerr_listings_out
UNION ALL
SELECT * FROM rca_construction_out
{% endif %}
{% if _zsf %}
UNION ALL
SELECT * FROM zonda_sfr_out
{% endif %}
