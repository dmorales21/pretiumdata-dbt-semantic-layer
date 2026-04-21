-- Lag-1 Pearson ACF on **ZILLOW** `rent_current` in `CONCEPT_RENT_MARKET_MONTHLY` by **analysis grain**:
--   **cbsa** | **county** | **place** | **zip**
-- **zip** has large **N_GEOS** (~7k+ typical) — slice **B** scans every zip with ≥24 pairs; expect higher **wall time** than CBSA/county.
-- Pooled slice **A** for zip mixes thousands of markets (sanity only; interpret like other grains).
-- (`place` = rows where `LOWER(TRIM(geo_level_code)) = 'place'`; if absent, see slice **C** and extend the `IN` list.)
--
-- Run: snowsql -c pretium -f scripts/sql/validation/acf_lag1_concept_rent_zillow_cbsa.sql
--
-- Doc: docs/reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md §3

-- ---------------------------------------------------------------------------
-- C) Diagnostic — ZILLOW non-null rent rows by normalized geo_level_code
-- ---------------------------------------------------------------------------
SELECT
    'C_zillow_rent_rows_by_grain' AS slice,
    LOWER(TRIM(geo_level_code)) AS geo_level_normalized,
    COUNT(*) AS n_rows,
    COUNT(DISTINCT geo_id) AS n_geos
FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
WHERE vendor_code = 'ZILLOW'
  AND rent_current IS NOT NULL
GROUP BY 1, 2
ORDER BY n_rows DESC;

-- ---------------------------------------------------------------------------
-- A) Pooled lag-1 Pearson (all geos × months mixed — sanity only), per grain
-- ---------------------------------------------------------------------------
WITH base AS (
    SELECT
        vendor_code,
        LOWER(TRIM(geo_level_code)) AS analysis_grain,
        geo_id,
        month_start,
        rent_current::DOUBLE AS x
    FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')
),
lagged AS (
    SELECT
        vendor_code,
        analysis_grain,
        geo_id,
        month_start,
        x,
        LAG(x) OVER (
            PARTITION BY vendor_code, analysis_grain, geo_id
            ORDER BY month_start
        ) AS x_lag1
    FROM base
)
SELECT
    'A_pooled_acf_by_grain' AS slice,
    vendor_code,
    analysis_grain,
    COUNT(*) AS n_pairs,
    CORR(x, x_lag1) AS acf_lag1_pearson
FROM lagged
WHERE x_lag1 IS NOT NULL
GROUP BY slice, vendor_code, analysis_grain
ORDER BY analysis_grain;

-- ---------------------------------------------------------------------------
-- B) Per-geo ACF(1) distribution (≥24 month-pairs per geo), summarized by grain
-- ---------------------------------------------------------------------------
WITH base AS (
    SELECT
        vendor_code,
        LOWER(TRIM(geo_level_code)) AS analysis_grain,
        geo_id,
        month_start,
        rent_current::DOUBLE AS x
    FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
    WHERE vendor_code = 'ZILLOW'
      AND rent_current IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')
),
lagged AS (
    SELECT
        vendor_code,
        analysis_grain,
        geo_id,
        month_start,
        x,
        LAG(x) OVER (
            PARTITION BY vendor_code, analysis_grain, geo_id
            ORDER BY month_start
        ) AS x_lag1
    FROM base
),
by_geo AS (
    SELECT
        analysis_grain,
        geo_id,
        CORR(x, x_lag1) AS acf_lag1_pearson,
        COUNT(*) AS n_pairs
    FROM lagged
    WHERE x_lag1 IS NOT NULL
    GROUP BY analysis_grain, geo_id
    HAVING COUNT(*) >= 24
)
SELECT
    'B_per_geo_acf_summary_by_grain' AS slice,
    analysis_grain,
    COUNT(*) AS n_geos,
    MIN(acf_lag1_pearson) AS acf_min,
    APPROX_PERCENTILE(acf_lag1_pearson, 0.25) AS acf_p25,
    MEDIAN(acf_lag1_pearson) AS acf_median,
    APPROX_PERCENTILE(acf_lag1_pearson, 0.75) AS acf_p75,
    MAX(acf_lag1_pearson) AS acf_max
FROM by_geo
GROUP BY slice, analysis_grain
ORDER BY analysis_grain;
