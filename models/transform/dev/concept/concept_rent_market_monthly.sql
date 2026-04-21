{#-
  **Market** rent — monthly, three slots (``concept_metric_slot('rent', …)``):

  - **Zillow** — ``fact_zillow_rentals`` / forecasts (vendor-native ``geo_id`` + enriched census keys).
  - **ApartmentIQ** — ``PROPERTYKPI_BH`` × ``PROPERTY_BH``, ZIP → **REFERENCE.GEOGRAPHY** spine (same as Zillow),
    unit-count-weighted asking rent at **CBSA** (``geo_level_code = cbsa``, ``geo_id = cbsa_id``).
  - **Yardi Matrix** — ``ref('fact_yardi_matrix_marketperformance_bh')`` × ``ref('fact_yardi_matrix_submarketmatch_zipzcta_bh')``
    (read-throughs of Jon silver) → ZIP → same spine → CBSA; ``DATATYPE`` filter via var
    ``concept_rent_market_yardi_matrix_datatype_like`` (default ``%rent%``).
    Join keys: ``MARKET`` ↔ ``MARKETID``, ``SUBMARKET`` ↔ ``SUBMARKET`` (adjust if DESCRIBE shows drift).

  **Cherre:** typed zero-row scaffold.

  **Markerr** — ``ref('fact_markerr_rent_property_cbsa_monthly')`` (MF CBSA aggregates; bedroom/class filters via vars);
  ``ref('fact_markerr_rent_sfr')`` ZIP → same ``zip_enriched`` spine → CBSA (asking mean).

  **HUD** — ``ref('fact_hud_housing_series')`` when ``concept_rent_market_hud_include`` and
  ``REGEXP_LIKE(LOWER(VARIABLE), concept_rent_market_hud_variable_regex)`` (excludes ``parent`` / ``homeless`` noise).
  Many accounts only have continuum_of_care HUD variables → **0 CBSA rent rows** until ACS-style variables exist.

  **CoStar** — ``ref('fact_costar_scenarios')`` (read-through **TRANSFORM.COSTAR.SCENARIOS**): CBSA from ``CBSA_CODE``;
  quarter anchors = ``DATE_TRUNC('quarter', month(period))`` with average rent in-quarter, then **linear**
  interpolation between consecutive quarter values onto each calendar month (tail: carry last quarter value).
  Actuals vs forecasts split on ``IS_FORECAST``; ``rent_forecast`` uses ``FORECAST_SCENARIO`` LIKE
  ``concept_rent_market_costar_forecast_scenario_pattern``. Property type filter:
  ``concept_rent_market_costar_property_type_pattern``.

  Vars: ``concept_rent_market_zillow_metric_pattern``, ``concept_rent_market_yardi_matrix_datatype_like``,
  CoStar vars in ``dbt_project.yml``.
-#}

{{ config(
    materialized='table',
    alias='concept_rent_market_monthly',
    tags=['semantic', 'concept', 'rent', 'rent_market', 'zillow', 'apartmentiq', 'yardi_matrix', 'costar', 'markerr', 'hud', 'cherre_stub']
) }}

{% set _metric_like = var('concept_rent_market_zillow_metric_pattern', '%zori%') %}
{% set _ym_dtype = var('concept_rent_market_yardi_matrix_datatype_like', '%rent%') %}
{% set _cpt = var('concept_rent_market_costar_property_type_pattern', '%Multifamily%') | replace("'", "''") %}
{% set _cfs = var('concept_rent_market_costar_forecast_scenario_pattern', '%base%') | replace("'", "''") %}
{% set _costar_asking = var('concept_rent_market_costar_use_asking_rent', false) %}
{% set _mbr = var('concept_rent_market_markerr_mf_bedroom_category', 'Any') | replace("'", "''") %}
{% set _mcl = var('concept_rent_market_markerr_mf_class_category', 'A') | replace("'", "''") %}
{% set _hud_inc = var('concept_rent_market_hud_include', true) %}
{% set _hud_rx = var('concept_rent_market_hud_variable_regex', 'median_contract_rent|median_gross_rent|gross_rent') | replace("'", "''") %}

WITH {{ reference_geo_zip_to_cbsa_ctes() }},

rentals_ranked AS (
    SELECT
        r.*,
        DATE_TRUNC('month', r.date_reference)::DATE AS month_start,
        ROW_NUMBER() OVER (
            PARTITION BY
                r.geo_level_code,
                r.geo_id,
                DATE_TRUNC('month', r.date_reference)
            ORDER BY
                CASE
                    WHEN LOWER(r.metric_id) LIKE '%sm%' AND LOWER(r.metric_id) LIKE LOWER('{{ _metric_like }}') THEN 1
                    WHEN LOWER(r.metric_id) LIKE LOWER('{{ _metric_like }}') THEN 2
                    ELSE 3
                END,
                r.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_rentals') }} AS r
    WHERE LOWER(r.metric_id) LIKE LOWER('{{ _metric_like }}')
),

rentals_pick AS (
    SELECT *
    FROM rentals_ranked
    WHERE metric_rn = 1
),

forecasts_ranked AS (
    SELECT
        f.*,
        DATE_TRUNC('month', f.date_reference)::DATE AS month_start,
        ROW_NUMBER() OVER (
            PARTITION BY
                f.geo_level_code,
                f.geo_id,
                DATE_TRUNC('month', f.date_reference)
            ORDER BY
                CASE
                    WHEN LOWER(f.metric_id) LIKE '%sm%' AND LOWER(f.metric_id) LIKE LOWER('{{ _metric_like }}') THEN 1
                    WHEN LOWER(f.metric_id) LIKE LOWER('{{ _metric_like }}') THEN 2
                    ELSE 3
                END,
                f.metric_id
        ) AS metric_rn
    FROM {{ ref('fact_zillow_rental_forecasts') }} AS f
    WHERE LOWER(f.metric_id) LIKE LOWER('{{ _metric_like }}')
),

forecasts_pick AS (
    SELECT *
    FROM forecasts_ranked
    WHERE metric_rn = 1
),

forecasts_next AS (
    SELECT
        z.month_start AS observe_month_start,
        z.geo_level_code,
        z.geo_id,
        z.metric_id AS observe_metric_id,
        cf.metric_value AS forecast_metric_value,
        cf.metric_id AS forecast_metric_id,
        cf.month_start AS forecast_month_start
    FROM rentals_pick AS z
    INNER JOIN forecasts_pick AS cf
        ON {{ concept_zillow_geo_key_match('z', 'cf') }}
       AND cf.metric_id = z.metric_id
       AND cf.month_start > z.month_start
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY z.geo_level_code, z.geo_id, z.metric_id, z.month_start
        ORDER BY cf.month_start ASC
    ) = 1
),

zillow_base AS (
    SELECT
        'rent_market' AS concept_code,
        'ZILLOW' AS vendor_code,
        c.month_start,
        c.geo_level_code,
        c.geo_id,
        c.cbsa_id,
        c.county_fips,
        c.state_fips,
        c.has_census_geo,
        c.census_geo_source,
        c.metric_id AS metric_id_observe,
        CAST(c.metric_value AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.metric_value AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(fn.forecast_metric_value AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        fn.forecast_metric_id AS metric_id_forecast,
        fn.forecast_month_start AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM rentals_pick AS c
    LEFT JOIN rentals_pick AS h
        ON {{ concept_zillow_geo_key_match('c', 'h') }}
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
       AND h.metric_id = c.metric_id
    LEFT JOIN forecasts_next AS fn
        ON {{ concept_zillow_geo_key_match('c', 'fn') }}
       AND c.metric_id = fn.observe_metric_id
       AND c.month_start = fn.observe_month_start
),

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
      AND NULLIF(COALESCE(p.UNITCOUNT, 0), 0) IS NOT NULL
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
    INNER JOIN zip_enriched AS ze
        ON x.id_zip = ze.id_zip
    WHERE ze.cbsa_id IS NOT NULL
),

aiq_cbsa_month AS (
    SELECT
        month_start,
        LPAD(TRIM(cbsa_id::VARCHAR), 5, '0') AS cbsa_id,
        SUM(rent_average * unit_count) / NULLIF(SUM(unit_count), 0) AS rent_avg_w
    FROM aiq_with_geo
    GROUP BY month_start, LPAD(TRIM(cbsa_id::VARCHAR), 5, '0')
),

apartmentiq_market AS (
    SELECT
        'rent_market' AS concept_code,
        'APARTMENTIQ' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'apartmentiq_property_zip_to_reference_geography' AS census_geo_source,
        'apartmentiq_rent_average_cbsa_unit_weighted' AS metric_id_observe,
        CAST(c.rent_avg_w AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_avg_w AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM aiq_cbsa_month AS c
    LEFT JOIN aiq_cbsa_month AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

yardi_mp AS (
    SELECT
        TRIM(TO_VARCHAR(mp.MARKET)) AS market_key,
        TRIM(TO_VARCHAR(mp.SUBMARKET)) AS submarket_key,
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(mp.PERIOD)))::DATE AS month_start,
        TRIM(TO_VARCHAR(mp.DATATYPE)) AS datatype,
        TRY_TO_DOUBLE(TO_VARCHAR(mp.DATAVALUE)) AS datavalue
    FROM {{ ref('fact_yardi_matrix_marketperformance_bh') }} AS mp
    WHERE mp.PERIOD IS NOT NULL
      AND mp.DATAVALUE IS NOT NULL
      AND LOWER(TRIM(TO_VARCHAR(mp.DATATYPE))) LIKE LOWER('{{ _ym_dtype }}')
      AND TRY_TO_DOUBLE(TO_VARCHAR(mp.DATAVALUE)) IS NOT NULL
),

yardi_zip_rows AS (
    SELECT
        mp.market_key,
        mp.submarket_key,
        mp.month_start,
        mp.datatype,
        mp.datavalue,
        LPAD(TRIM(TO_VARCHAR(br.ZIPCODE)), 5, '0') AS id_zip
    FROM yardi_mp AS mp
    INNER JOIN {{ ref('fact_yardi_matrix_submarketmatch_zipzcta_bh') }} AS br
        ON TRIM(COALESCE(mp.market_key, '')) = TRIM(COALESCE(TO_VARCHAR(br.MARKETID), ''))
       AND TRIM(COALESCE(mp.submarket_key, '')) = TRIM(COALESCE(TO_VARCHAR(br.SUBMARKET), ''))
    WHERE br.ZIPCODE IS NOT NULL
),

yardi_sub_cbsa AS (
    SELECT
        z.month_start,
        LPAD(TRIM(ze.cbsa_id::VARCHAR), 5, '0') AS cbsa_id,
        z.market_key,
        z.submarket_key,
        z.datatype,
        MAX(z.datavalue) AS submarket_value
    FROM yardi_zip_rows AS z
    INNER JOIN zip_enriched AS ze
        ON z.id_zip = ze.id_zip
    WHERE ze.cbsa_id IS NOT NULL
    GROUP BY
        z.month_start,
        LPAD(TRIM(ze.cbsa_id::VARCHAR), 5, '0'),
        z.market_key,
        z.submarket_key,
        z.datatype
),

yardi_cbsa_month AS (
    SELECT
        month_start,
        cbsa_id,
        AVG(submarket_value) AS rent_avg_submarkets
    FROM yardi_sub_cbsa
    GROUP BY month_start, cbsa_id
),

yardi_matrix_market AS (
    SELECT
        'rent_market' AS concept_code,
        'YARDI_MATRIX' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'yardi_matrix_submarket_zip_to_reference_geography' AS census_geo_source,
        'yardi_matrix_rent_submarket_avg_to_cbsa' AS metric_id_observe,
        CAST(c.rent_avg_submarkets AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_avg_submarkets AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM yardi_cbsa_month AS c
    LEFT JOIN yardi_cbsa_month AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

costar_raw AS (
    SELECT
        LPAD(TRIM(CBSA_CODE::VARCHAR), 5, '0') AS cbsa_id,
        TRIM(PROPERTY_TYPE::VARCHAR) AS property_type,
        DATE_TRUNC('month', PERIOD::DATE)::DATE AS period_month,
        IS_FORECAST,
        COALESCE(TRIM(FORECAST_SCENARIO::VARCHAR), 'actual') AS forecast_scenario,
        {{ costar_rent_measure_column(_costar_asking) }}::DOUBLE AS rent_measure
    FROM {{ ref('fact_costar_scenarios') }}
    WHERE CBSA_CODE IS NOT NULL
      AND {{ costar_rent_measure_column(_costar_asking) }} IS NOT NULL
      AND TRIM(COALESCE(PROPERTY_TYPE::VARCHAR, '')) ILIKE '{{ _cpt }}'
),

costar_quarter_agg AS (
    SELECT
        cbsa_id,
        property_type,
        IS_FORECAST,
        forecast_scenario,
        DATE_TRUNC('quarter', period_month)::DATE AS quarter_start,
        AVG(rent_measure) AS rent_q
    FROM costar_raw
    GROUP BY cbsa_id, property_type, IS_FORECAST, forecast_scenario, DATE_TRUNC('quarter', period_month)::DATE
),

costar_q_ordered AS (
    SELECT
        cbsa_id,
        property_type,
        IS_FORECAST,
        forecast_scenario,
        quarter_start,
        rent_q,
        COALESCE(
            LEAD(quarter_start) OVER (
                PARTITION BY cbsa_id, property_type, IS_FORECAST, forecast_scenario
                ORDER BY quarter_start
            ),
            DATEADD('quarter', 1, quarter_start)
        ) AS quarter_start_next,
        COALESCE(
            LEAD(rent_q) OVER (
                PARTITION BY cbsa_id, property_type, IS_FORECAST, forecast_scenario
                ORDER BY quarter_start
            ),
            rent_q
        ) AS rent_q_next
    FROM costar_quarter_agg
),

costar_bounds AS (
    SELECT
        MIN(period_month) AS min_m,
        MAX(period_month) AS max_m
    FROM costar_raw
),

costar_month_spine AS (
    SELECT
        DATEADD('month', gs.n, b.min_m)::DATE AS month_start
    FROM costar_bounds AS b
    CROSS JOIN (
        SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS n
        FROM TABLE(GENERATOR(ROWCOUNT => 1200))
    ) AS gs
    WHERE DATEADD('month', gs.n, b.min_m) <= b.max_m
),

costar_interp_series AS (
    SELECT
        s.month_start,
        q.cbsa_id,
        q.property_type,
        q.IS_FORECAST,
        q.forecast_scenario,
        q.rent_q
        + (q.rent_q_next - q.rent_q) * (
            DATEDIFF('day', q.quarter_start, s.month_start)::FLOAT
            / NULLIF(DATEDIFF('day', q.quarter_start, q.quarter_start_next), 0)
        ) AS rent_monthly
    FROM costar_month_spine AS s
    INNER JOIN costar_q_ordered AS q
        ON s.month_start >= q.quarter_start
       AND s.month_start < q.quarter_start_next
),

costar_interp_actual AS (
    SELECT
        month_start,
        cbsa_id,
        property_type,
        rent_monthly
    FROM costar_interp_series
    WHERE IS_FORECAST IS DISTINCT FROM TRUE
),

costar_interp_forecast AS (
    SELECT
        month_start,
        cbsa_id,
        property_type,
        rent_monthly,
        forecast_scenario
    FROM costar_interp_series
    WHERE IS_FORECAST = TRUE
      AND TRIM(forecast_scenario) ILIKE '{{ _cfs }}'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY month_start, cbsa_id, property_type
        ORDER BY forecast_scenario ASC
    ) = 1
),

costar_market AS (
    SELECT
        'rent_market' AS concept_code,
        'COSTAR' AS vendor_code,
        a.month_start,
        'cbsa' AS geo_level_code,
        a.cbsa_id AS geo_id,
        a.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'costar_scenarios_quarter_linear_to_month' AS census_geo_source,
        {% if _costar_asking %}
        'costar_MARKET_ASKING_RENT_PER_UNIT_quarter_smoothed'
        {% else %}
        'costar_MARKET_EFFECTIVE_RENT_PER_UNIT_quarter_smoothed'
        {% endif %} AS metric_id_observe,
        CAST(a.rent_monthly AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_monthly AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(f.rent_monthly AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        f.forecast_scenario AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM costar_interp_actual AS a
    LEFT JOIN costar_interp_actual AS h
        ON a.cbsa_id = h.cbsa_id
       AND a.property_type = h.property_type
       AND h.month_start = ADD_MONTHS(a.month_start, -12)
    LEFT JOIN costar_interp_forecast AS f
        ON a.cbsa_id = f.cbsa_id
       AND a.property_type = f.property_type
       AND a.month_start = f.month_start
),

markerr_mf_base AS (
    SELECT
        DATE_TRUNC('month', m.MONTH_DATE)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(m.CBSA_ID)), 5, '0') AS cbsa_id,
        m.AVG_RENT_EFFECTIVE::DOUBLE AS rent_effective,
        m.AVG_RENT_ASKING::DOUBLE AS rent_asking
    FROM {{ ref('fact_markerr_rent_property_cbsa_monthly') }} AS m
    WHERE m.MONTH_DATE IS NOT NULL
      AND m.CBSA_ID IS NOT NULL
      AND TRIM(COALESCE(m.BEDROOM_CATEGORY::VARCHAR, '')) = '{{ _mbr }}'
      AND TRIM(COALESCE(m.CLASS_CATEGORY::VARCHAR, '')) = '{{ _mcl }}'
),

markerr_mf_market AS (
    SELECT
        'rent_market' AS concept_code,
        'MARKERR_MF' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'markerr_rent_property_cbsa_monthly' AS census_geo_source,
        'markerr_avg_rent_effective' AS metric_id_observe,
        CAST(c.rent_effective AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_effective AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM markerr_mf_base AS c
    LEFT JOIN markerr_mf_base AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

markerr_sfr_zip AS (
    SELECT
        DATE_TRUNC('month', s.DATE)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(s.ZIPCODE)), 5, '0') AS id_zip,
        s.RENT_ASKING_MEAN::DOUBLE AS rent_asking_mean
    FROM {{ ref('fact_markerr_rent_sfr') }} AS s
    WHERE UPPER(TRIM(TO_VARCHAR(s.GEOGRAPHY_TYPE))) = 'ZIPCODE'
      AND s.DATE IS NOT NULL
      AND s.ZIPCODE IS NOT NULL
      AND s.RENT_ASKING_MEAN IS NOT NULL
),

markerr_sfr_with_cbsa AS (
    SELECT
        z.month_start,
        LPAD(TRIM(ze.cbsa_id::VARCHAR), 5, '0') AS cbsa_id,
        z.rent_asking_mean
    FROM markerr_sfr_zip AS z
    INNER JOIN zip_enriched AS ze
        ON z.id_zip = ze.id_zip
    WHERE ze.cbsa_id IS NOT NULL
),

markerr_sfr_cbsa_month AS (
    SELECT
        month_start,
        cbsa_id,
        AVG(rent_asking_mean) AS rent_asking_avg
    FROM markerr_sfr_with_cbsa
    GROUP BY month_start, cbsa_id
),

markerr_sfr_market AS (
    SELECT
        'rent_market' AS concept_code,
        'MARKERR_SFR' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'markerr_rent_sfr_zip_to_reference_geography' AS census_geo_source,
        'markerr_rent_asking_mean_zip_agg_cbsa' AS metric_id_observe,
        CAST(c.rent_asking_avg AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_asking_avg AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM markerr_sfr_cbsa_month AS c
    LEFT JOIN markerr_sfr_cbsa_month AS h
        ON c.cbsa_id = h.cbsa_id
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),

{% if _hud_inc %}
hud_rent_base AS (
    SELECT
        DATE_TRUNC('month', f.DATE_REFERENCE)::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(f.GEO_ID)), 5, '0') AS cbsa_id,
        f.VARIABLE AS hud_variable,
        f.VALUE::DOUBLE AS rent_value
    FROM {{ ref('fact_hud_housing_series_cbsa_monthly') }} AS f
    WHERE f.GEO_LEVEL_CODE = 'cbsa'
      AND f.DATE_REFERENCE IS NOT NULL
      AND f.GEO_ID IS NOT NULL
      AND f.VALUE IS NOT NULL
      AND REGEXP_LIKE(LOWER(f.VARIABLE), '{{ _hud_rx }}')
      AND NOT REGEXP_LIKE(LOWER(f.VARIABLE), 'parent|homeless')
),

hud_rent_month AS (
    SELECT
        month_start,
        cbsa_id,
        hud_variable,
        AVG(rent_value) AS rent_avg
    FROM hud_rent_base
    GROUP BY month_start, cbsa_id, hud_variable
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY month_start, cbsa_id
        ORDER BY hud_variable ASC
    ) = 1
),

hud_rent_market AS (
    SELECT
        'rent_market' AS concept_code,
        'HUD_CYBERSYN' AS vendor_code,
        c.month_start,
        'cbsa' AS geo_level_code,
        c.cbsa_id AS geo_id,
        c.cbsa_id,
        CAST(NULL AS VARCHAR(8)) AS county_fips,
        CAST(NULL AS VARCHAR(4)) AS state_fips,
        TRUE AS has_census_geo,
        'fact_hud_housing_series_cbsa' AS census_geo_source,
        c.hud_variable AS metric_id_observe,
        CAST(c.rent_avg AS DOUBLE) AS {{ concept_metric_slot('rent', 'current') }},
        CAST(h.rent_avg AS DOUBLE) AS {{ concept_metric_slot('rent', 'historical') }},
        CAST(NULL AS DOUBLE) AS {{ concept_metric_slot('rent', 'forecast') }},
        CAST(NULL AS VARCHAR(512)) AS metric_id_forecast,
        CAST(NULL AS DATE) AS forecast_month_start,
        CURRENT_TIMESTAMP() AS dbt_updated_at
    FROM hud_rent_month AS c
    LEFT JOIN hud_rent_month AS h
        ON c.cbsa_id = h.cbsa_id
       AND c.hud_variable = h.hud_variable
       AND h.month_start = ADD_MONTHS(c.month_start, -12)
),
{% else %}
hud_rent_market AS (
    SELECT
        CAST('rent_market' AS VARCHAR(64)) AS concept_code,
        CAST('HUD_CYBERSYN' AS VARCHAR(32)) AS vendor_code,
        CAST(NULL AS DATE) AS month_start,
        CAST(NULL AS VARCHAR(32)) AS geo_level_code,
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
    FROM (SELECT 1 AS one_row) AS one_row_stub
    WHERE 1 = 0
),
{% endif %}

cherre_stub AS (
    SELECT
        CAST('rent_market' AS VARCHAR(64)) AS concept_code,
        CAST('CHERRE' AS VARCHAR(32)) AS vendor_code,
        CAST(NULL AS DATE) AS month_start,
        CAST(NULL AS VARCHAR(32)) AS geo_level_code,
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
    FROM (SELECT 1 AS one_row) AS one_row_stub
    WHERE 1 = 0
)

SELECT * FROM zillow_base
UNION ALL
SELECT * FROM apartmentiq_market
UNION ALL
SELECT * FROM yardi_matrix_market
UNION ALL
SELECT * FROM costar_market
UNION ALL
SELECT * FROM markerr_mf_market
UNION ALL
SELECT * FROM markerr_sfr_market
UNION ALL
SELECT * FROM hud_rent_market
UNION ALL
SELECT * FROM cherre_stub
