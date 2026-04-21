-- Lag-1 Pearson ACF on **`*_current`** slots for every **TRANSFORM.DEV** `CONCEPT_*` **market** table under
-- `models/transform/dev/concept/` (union → slices **C**, **A**, **B**).
-- **Out of scope here:** `models/transform/dev/fund_opco/concept_progress_*` (property / fund spine — different contracts).
-- **Catalog:** `seeds/reference/catalog/concept.csv` lists more domain concepts than are modeled; this script only hits **built** objects.
--
-- **Grain filter** (market rent path parity): `LOWER(TRIM(geo_level_code)) IN ('cbsa','county','place','zip')`,
-- plus **`property`** for `CONCEPT_RENT_PROPERTY_MONTHLY` only.
--
-- **Series key:** `series_id = COALESCE(NULLIF(TRIM(metric_id_observe),''), '*')` so multi-metric vendors
-- (e.g. **BLS_LAUS** unemployment rate vs count) do not merge into one broken lag track.
--
-- **Min pairs (slice B):** `24` month-steps for all objects except **`CONCEPT_MIGRATION_MARKET_ANNUAL`** (`5` year-steps).
--
-- **Caveats:**
--   - **`CONCEPT_AVM_MARKET_MONTHLY`** (Cherre snapshot) is often **one `month_start` per geo** → no lag pairs until
--     a true monthly AVM series exists; expect **empty / NULL** A–B.
--   - **`FHFA_UAD`** rows on **home price** / **valuation** are **excluded** here (`vendor_code <> 'FHFA_UAD'`): thousands of
--     narrow appraisal mix metrics → unusable ACF grid; run a **vendor-specific** slice if you need UAD QA.
--   - Requires tables to exist (run `dbt run -s models/transform/dev/concept` first). Edit **`TRANSFORM.DEV`** if your DB differs.
--
-- Run: snowsql -c pretium -f scripts/sql/validation/acf_lag1_all_transform_dev_concepts.sql
--
-- See: docs/reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md §3

-- ---------------------------------------------------------------------------
-- C) Row / geo counts by concept object, vendor, series, grain
-- ---------------------------------------------------------------------------
WITH all_series AS (
    SELECT
        'CONCEPT_RENT_MARKET_MONTHLY' AS concept_object,
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*') AS series_id,
        LOWER(TRIM(geo_level_code)) AS analysis_grain,
        geo_id,
        month_start,
        rent_current::DOUBLE AS x,
        'rent_current' AS value_slot
    FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
    WHERE rent_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_RENT_PROPERTY_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        'property',
        geo_id,
        month_start,
        rent_current::DOUBLE,
        'rent_current'
    FROM TRANSFORM.DEV.CONCEPT_RENT_PROPERTY_MONTHLY
    WHERE rent_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('property')

    UNION ALL

    SELECT
        'CONCEPT_OCCUPANCY_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        occupancy_current::DOUBLE,
        'occupancy_current'
    FROM TRANSFORM.DEV.CONCEPT_OCCUPANCY_MARKET_MONTHLY
    WHERE occupancy_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_EMPLOYMENT_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        employment_current::DOUBLE,
        'employment_current'
    FROM TRANSFORM.DEV.CONCEPT_EMPLOYMENT_MARKET_MONTHLY
    WHERE employment_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        unemployment_current::DOUBLE,
        'unemployment_current'
    FROM TRANSFORM.DEV.CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY
    WHERE unemployment_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_HOME_PRICE_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        homeprice_current::DOUBLE,
        'homeprice_current'
    FROM TRANSFORM.DEV.CONCEPT_HOME_PRICE_MARKET_MONTHLY
    WHERE homeprice_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND vendor_code <> 'FHFA_UAD'
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_LISTINGS_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        listings_current::DOUBLE,
        'listings_current'
    FROM TRANSFORM.DEV.CONCEPT_LISTINGS_MARKET_MONTHLY
    WHERE listings_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_AVM_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        avm_current::DOUBLE,
        'avm_current'
    FROM TRANSFORM.DEV.CONCEPT_AVM_MARKET_MONTHLY
    WHERE avm_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_VALUATION_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        valuation_current::DOUBLE,
        'valuation_current'
    FROM TRANSFORM.DEV.CONCEPT_VALUATION_MARKET_MONTHLY
    WHERE valuation_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND vendor_code <> 'FHFA_UAD'
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_TRANSACTIONS_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        transactions_current::DOUBLE,
        'transactions_current'
    FROM TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY
    WHERE transactions_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_DELINQUENCY_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        delinquency_current::DOUBLE,
        'delinquency_current'
    FROM TRANSFORM.DEV.CONCEPT_DELINQUENCY_MARKET_MONTHLY
    WHERE delinquency_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_MIGRATION_MARKET_ANNUAL',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        migration_current::DOUBLE,
        'migration_current'
    FROM TRANSFORM.DEV.CONCEPT_MIGRATION_MARKET_ANNUAL
    WHERE migration_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')
)
SELECT
    'C_all_concepts_coverage' AS slice,
    concept_object,
    concept_code,
    vendor_code,
    series_id,
    value_slot,
    analysis_grain,
    COUNT(*) AS n_rows,
    COUNT(DISTINCT geo_id) AS n_geos
FROM all_series
GROUP BY
    slice,
    concept_object,
    concept_code,
    vendor_code,
    series_id,
    value_slot,
    analysis_grain
ORDER BY concept_object, vendor_code, series_id, analysis_grain;

-- ---------------------------------------------------------------------------
-- A) Pooled lag-1 Pearson (sanity only), per concept / vendor / series / grain
-- ---------------------------------------------------------------------------
WITH all_series AS (
    SELECT
        'CONCEPT_RENT_MARKET_MONTHLY' AS concept_object,
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*') AS series_id,
        LOWER(TRIM(geo_level_code)) AS analysis_grain,
        geo_id,
        month_start,
        rent_current::DOUBLE AS x
    FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
    WHERE rent_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_RENT_PROPERTY_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        rent_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_RENT_PROPERTY_MONTHLY
    WHERE rent_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('property')

    UNION ALL

    SELECT
        'CONCEPT_OCCUPANCY_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        occupancy_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_OCCUPANCY_MARKET_MONTHLY
    WHERE occupancy_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_EMPLOYMENT_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        employment_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_EMPLOYMENT_MARKET_MONTHLY
    WHERE employment_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        unemployment_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY
    WHERE unemployment_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_HOME_PRICE_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        homeprice_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_HOME_PRICE_MARKET_MONTHLY
    WHERE homeprice_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND vendor_code <> 'FHFA_UAD'
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_LISTINGS_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        listings_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_LISTINGS_MARKET_MONTHLY
    WHERE listings_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_AVM_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        avm_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_AVM_MARKET_MONTHLY
    WHERE avm_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_VALUATION_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        valuation_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_VALUATION_MARKET_MONTHLY
    WHERE valuation_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND vendor_code <> 'FHFA_UAD'
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_TRANSACTIONS_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        transactions_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY
    WHERE transactions_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_DELINQUENCY_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        delinquency_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_DELINQUENCY_MARKET_MONTHLY
    WHERE delinquency_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_MIGRATION_MARKET_ANNUAL',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        migration_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_MIGRATION_MARKET_ANNUAL
    WHERE migration_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')
),
lagged AS (
    SELECT
        concept_object,
        concept_code,
        vendor_code,
        series_id,
        analysis_grain,
        geo_id,
        month_start,
        x,
        LAG(x) OVER (
            PARTITION BY concept_object, vendor_code, series_id, analysis_grain, geo_id
            ORDER BY month_start
        ) AS x_lag1
    FROM all_series
)
SELECT
    'A_pooled_acf_all_concepts' AS slice,
    concept_object,
    concept_code,
    vendor_code,
    series_id,
    analysis_grain,
    COUNT(*) AS n_pairs,
    CORR(x, x_lag1) AS acf_lag1_pearson
FROM lagged
WHERE x_lag1 IS NOT NULL
GROUP BY
    slice,
    concept_object,
    concept_code,
    vendor_code,
    series_id,
    analysis_grain
ORDER BY concept_object, vendor_code, series_id, analysis_grain;

-- ---------------------------------------------------------------------------
-- B) Per-geo ACF(1) distribution, summarized by concept / vendor / series / grain
-- ---------------------------------------------------------------------------
WITH all_series AS (
    SELECT
        'CONCEPT_RENT_MARKET_MONTHLY' AS concept_object,
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*') AS series_id,
        LOWER(TRIM(geo_level_code)) AS analysis_grain,
        geo_id,
        month_start,
        rent_current::DOUBLE AS x
    FROM TRANSFORM.DEV.CONCEPT_RENT_MARKET_MONTHLY
    WHERE rent_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_RENT_PROPERTY_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        rent_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_RENT_PROPERTY_MONTHLY
    WHERE rent_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('property')

    UNION ALL

    SELECT
        'CONCEPT_OCCUPANCY_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        occupancy_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_OCCUPANCY_MARKET_MONTHLY
    WHERE occupancy_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_EMPLOYMENT_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        employment_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_EMPLOYMENT_MARKET_MONTHLY
    WHERE employment_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        unemployment_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_UNEMPLOYMENT_MARKET_MONTHLY
    WHERE unemployment_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_HOME_PRICE_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        homeprice_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_HOME_PRICE_MARKET_MONTHLY
    WHERE homeprice_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND vendor_code <> 'FHFA_UAD'
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_LISTINGS_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        listings_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_LISTINGS_MARKET_MONTHLY
    WHERE listings_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_AVM_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        avm_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_AVM_MARKET_MONTHLY
    WHERE avm_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_VALUATION_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        valuation_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_VALUATION_MARKET_MONTHLY
    WHERE valuation_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND vendor_code <> 'FHFA_UAD'
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_TRANSACTIONS_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        transactions_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY
    WHERE transactions_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_DELINQUENCY_MARKET_MONTHLY',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        delinquency_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_DELINQUENCY_MARKET_MONTHLY
    WHERE delinquency_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')

    UNION ALL

    SELECT
        'CONCEPT_MIGRATION_MARKET_ANNUAL',
        concept_code,
        vendor_code,
        COALESCE(NULLIF(TRIM(metric_id_observe), ''), '*'),
        LOWER(TRIM(geo_level_code)),
        geo_id,
        month_start,
        migration_current::DOUBLE
    FROM TRANSFORM.DEV.CONCEPT_MIGRATION_MARKET_ANNUAL
    WHERE migration_current IS NOT NULL
      AND vendor_code IS NOT NULL
      AND LOWER(TRIM(geo_level_code)) IN ('cbsa', 'county', 'place', 'zip')
),
lagged AS (
    SELECT
        concept_object,
        concept_code,
        vendor_code,
        series_id,
        analysis_grain,
        geo_id,
        month_start,
        x,
        LAG(x) OVER (
            PARTITION BY concept_object, vendor_code, series_id, analysis_grain, geo_id
            ORDER BY month_start
        ) AS x_lag1
    FROM all_series
),
by_geo AS (
    SELECT
        concept_object,
        concept_code,
        vendor_code,
        series_id,
        analysis_grain,
        geo_id,
        CORR(x, x_lag1) AS acf_lag1_pearson,
        COUNT(*) AS n_pairs
    FROM lagged
    WHERE x_lag1 IS NOT NULL
    GROUP BY concept_object, concept_code, vendor_code, series_id, analysis_grain, geo_id
    HAVING COUNT(*) >= IFF(concept_object = 'CONCEPT_MIGRATION_MARKET_ANNUAL', 5, 24)
)
SELECT
    'B_per_geo_acf_summary_all_concepts' AS slice,
    concept_object,
    concept_code,
    vendor_code,
    series_id,
    analysis_grain,
    COUNT(*) AS n_geos,
    MIN(acf_lag1_pearson) AS acf_min,
    APPROX_PERCENTILE(acf_lag1_pearson, 0.25) AS acf_p25,
    MEDIAN(acf_lag1_pearson) AS acf_median,
    APPROX_PERCENTILE(acf_lag1_pearson, 0.75) AS acf_p75,
    MAX(acf_lag1_pearson) AS acf_max
FROM by_geo
GROUP BY
    slice,
    concept_object,
    concept_code,
    vendor_code,
    series_id,
    analysis_grain
ORDER BY concept_object, vendor_code, series_id, analysis_grain;
