{#-
  **LAUS county FIPS vs REFERENCE spine (low-frequency QA)**

  Distinct **county_fips** on ``ref('fact_bls_laus_county')`` (already 5-digit padded in the FACT) are
  left-joined to ``ref('geography_latest')`` at ``geo_level_code = county``. **Fails** when the share of
  keys missing a spine row is **≥** ``var('laus_county_geography_spine_miss_rate_max')`` (default **0.001**).

  **Gated:** default ``enable_laus_county_geography_spine_miss_rate_test: false`` so PR CI stays light.
  Run on a schedule (e.g. monthly) with:

  ``dbt test --select assert_fact_bls_laus_county_geography_spine_miss_rate_lt_threshold --vars '{"enable_laus_county_geography_spine_miss_rate_test": true}'``

  Or use selector ``monthly_geography_spine_qa`` with the same ``--vars``.
-#}
{{ config(
    tags=['spine_coverage', 'bls', 'laus', 'geography', 'monthly_qa'],
    enabled=var('enable_laus_county_geography_spine_miss_rate_test', false),
) }}

WITH laus_keys AS (
    SELECT DISTINCT LPAD(TRIM(TO_VARCHAR(county_fips)), 5, '0') AS county_fips
    FROM {{ ref('fact_bls_laus_county') }}
    WHERE county_fips IS NOT NULL
),
per_key AS (
    SELECT
        k.county_fips,
        MAX(IFF(gl.geo_id IS NOT NULL, 1, 0))::INTEGER AS has_spine_row
    FROM laus_keys AS k
    LEFT JOIN {{ ref('geography_latest') }} AS gl
        ON TRIM(TO_VARCHAR(k.county_fips)) = TRIM(TO_VARCHAR(gl.geo_id))
       AND LOWER(TRIM(TO_VARCHAR(gl.geo_level_code))) = 'county'
    GROUP BY k.county_fips
),
spine_check AS (
    SELECT
        COUNT(*)::BIGINT AS n_distinct_keys,
        COUNT_IF(has_spine_row = 0)::BIGINT AS n_missing_spine
    FROM per_key
)
SELECT
    s.n_distinct_keys,
    s.n_missing_spine,
    (s.n_missing_spine::DOUBLE / NULLIF(s.n_distinct_keys::DOUBLE, 0)) AS miss_rate,
    {{ var('laus_county_geography_spine_miss_rate_max', 0.001) }}::DOUBLE AS max_allowed_miss_rate
FROM spine_check AS s
WHERE s.n_distinct_keys > 0
  AND (s.n_missing_spine::DOUBLE / NULLIF(s.n_distinct_keys::DOUBLE, 0))
      >= {{ var('laus_county_geography_spine_miss_rate_max', 0.001) }}
