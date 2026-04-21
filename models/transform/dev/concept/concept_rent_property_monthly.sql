{#-
  **Property** rent — monthly, three slots (``concept_metric_slot('rent', …)``):

  - **ApartmentIQ** — ``PROPERTYKPI_BH`` × ``PROPERTY_BH``; ``property_natural_key`` = property id string;
    ``geo_level_code = property``; **census** keys via same ZIP → **REFERENCE.GEOGRAPHY** spine as
    ``concept_rent_market_monthly`` (``zip_enriched``) for CBSA / county / state alignment.
  - **Yardi Matrix** — market/submarket performance has **no** property grain in ``TRANSFORM.YARDI_MATRIX`` today;
    ``yardi_matrix_property_stub`` is a typed zero-row branch so vendor parity stays explicit in SQL.
  - **Cherre** — typed zero-row scaffold until parcel/assessor rent is wired.

  Join market-level rent at CBSA via ``cbsa_id`` / ``county_fips`` shared with ``concept_rent_market_monthly``.

  **Contract + bridge QA:** ``docs/reference/CONTRACT_RENT_AVM_VALUATION.md``; ``QA_RENT_PROPERTY_MARKET_BRIDGE``.
-#}

{{ config(
    materialized='table',
    alias='concept_rent_property_monthly',
    tags=['semantic', 'concept', 'rent', 'rent_property', 'apartmentiq', 'yardi_matrix', 'cherre_stub']
) }}

WITH {{ reference_geo_zip_to_cbsa_ctes() }},

aiq_kpi_zip AS (
    SELECT
        k.PROPERTYID,
        DATE_TRUNC('month', k.MONTHDATE)::DATE AS month_start,
        k.RENTAVERAGE::DOUBLE AS rent_average,
        NULLIF(COALESCE(p.UNITCOUNT, 0), 0)::DOUBLE AS unit_count,
        LPAD(TRIM(TO_VARCHAR(p.ZIPCODE)), 5, '0') AS id_zip
    FROM {{ source('transform_apartmentiq', 'propertykpi_bh') }} AS k
    INNER JOIN {{ source('transform_apartmentiq', 'property_bh') }} AS p
        ON k.PROPERTYID = p.ID
    WHERE k.MONTHDATE IS NOT NULL
      AND p.ZIPCODE IS NOT NULL
      AND k.RENTAVERAGE IS NOT NULL
),

aiq_with_geo AS (
    SELECT
        x.PROPERTYID,
        x.month_start,
        x.rent_average,
        x.unit_count,
        ze.county_fips,
        ze.cbsa_id
    FROM aiq_kpi_zip AS x
    LEFT JOIN zip_enriched AS ze
        ON x.id_zip = ze.id_zip
),

aiq_base AS (
    SELECT
        'rent_property' AS concept_code,
        'APARTMENTIQ' AS vendor_code,
        c.month_start,
        TO_VARCHAR(c.PROPERTYID) AS property_natural_key,
        'property' AS geo_level_code,
        TO_VARCHAR(c.PROPERTYID) AS geo_id,
        LPAD(TRIM(TO_VARCHAR(c.cbsa_id)), 5, '0') AS cbsa_id,
        c.county_fips,
        CASE WHEN c.county_fips IS NOT NULL THEN LEFT(c.county_fips, 2) ELSE NULL END AS state_fips,
        (c.cbsa_id IS NOT NULL OR c.county_fips IS NOT NULL) AS has_census_geo,
        'apartmentiq_property_bh_zip_to_reference_geography' AS census_geo_source,
        'apartmentiq_rent_average_property' AS metric_id_observe,
        CAST(c.rent_average AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_average AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM aiq_with_geo AS c
    LEFT JOIN aiq_with_geo AS h
        ON c.PROPERTYID = h.PROPERTYID
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

cherre_stub AS (
    SELECT
        CAST('rent_property' AS VARCHAR(64)) AS concept_code,
        CAST('CHERRE' AS VARCHAR(32)) AS vendor_code,
        CAST(NULL AS DATE) AS month_start,
        CAST(NULL AS VARCHAR(128)) AS property_natural_key,
        CAST(NULL AS VARCHAR(64)) AS geo_level_code,
        CAST(NULL AS VARCHAR(64)) AS geo_id,
        CAST(NULL AS VARCHAR(8)) AS cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        CAST(NULL AS BOOLEAN) AS has_census_geo,
        CAST(NULL AS VARCHAR(128)) AS census_geo_source,
        CAST(NULL AS VARCHAR(512)) AS metric_id_observe,
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM (SELECT 1 AS stub_one) AS stub_from
    WHERE 1 = 0
),

yardi_matrix_property_stub AS (
    SELECT
        CAST('rent_property' AS VARCHAR(64)) AS concept_code,
        CAST('YARDI_MATRIX' AS VARCHAR(32)) AS vendor_code,
        CAST(NULL AS DATE) AS month_start,
        CAST(NULL AS VARCHAR(128)) AS property_natural_key,
        CAST(NULL AS VARCHAR(64)) AS geo_level_code,
        CAST(NULL AS VARCHAR(64)) AS geo_id,
        CAST(NULL AS VARCHAR(8)) AS cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        CAST(NULL AS BOOLEAN) AS has_census_geo,
        CAST(NULL AS VARCHAR(128)) AS census_geo_source,
        CAST(NULL AS VARCHAR(512)) AS metric_id_observe,
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM (SELECT 1 AS stub_one) AS stub_from
    WHERE 1 = 0
)

SELECT * FROM aiq_base
UNION ALL
SELECT * FROM cherre_stub
UNION ALL
SELECT * FROM yardi_matrix_property_stub
