-- ============================================================================
-- FACT: Cherre Tax Assessor → unified stock snapshot at H3 R8 grain
-- Purpose: Aggregate all residential parcels (SFR + MF) to H3 R8 grain with
--          per-SF price signals. Primary outputs:
--            • median_assessed_ppsf   — feeds cbsa_ppsf_quartile reference model
--            • median_market_ppsf     — cross-state comparable (AZ LPV-safe)
--            • avg_land_value_share   — land cost signal for ASSETS concept
--            • decade vintage buckets — supply vintage composition
--
-- Source:  source('cherre', 'tax_assessor_v2')  — read direct; no dependency on
--          the existing dim-grain snapshot facts.
--
-- BUILDING_SQ_FT quality gate:
--   BUILDING_SQ_FT_CODE documents what area BUILDING_SQ_FT measures per county.
--   Include codes: L (Living), E (Heated/Conditioned), K (Finished), T (Total),
--                  R (Gross), 0 (Unknown/default), + (County-specific aggregate).
--   Exclude codes: G (Garage excluded), A (Attic excluded), 1 (1st floor only),
--                  M (Main floor), H (Heated excl. basement).
--   Floor/ceiling range: 100–50,000 sqft. Removes data-entry errors.
--
-- Arizona note: ASSESSED_VALUE_TOTAL is the Limited Property Value (LPV ≈ 10%
--   of market by statute). Use MARKET_VALUE_TOTAL for cross-state PPSF.
--
-- Grain:   (cbsa_id, h3_r8_hex, segment)  — 'SFR' | 'MF', one row per combo
-- Sibling: fact_cherre_stock_county — same metrics at (county_fips, cbsa_id, segment).
-- Feeds:   cbsa_ppsf_quartile (reference), feature_cherre_stock_h3_r8 (features),
--          membership_h3_product_types (membership spine blocker)
-- ============================================================================

-- TRANSFORM.DEV.FACT_CHERRE_STOCK_H3_R8 — Cherre assessor residential stock at H3 R8 × CBSA × segment.
{{ config(
    materialized = 'table',
    alias = 'fact_cherre_stock_h3_r8',
    tags = ['transform', 'transform_dev', 'cherre', 'cherre_read_surface', 'corridor', 'h3', 'ppsf'],
    cluster_by = ['cbsa_id', 'segment'],
) }}

{% set sfr_codes = [1001, 1002, 1003, 1007, 1009, 1013, 1016, 1017, 1018, 1022] %}
{% set mf_codes  = [1100, 1101, 1102, 1103, 1104, 1105, 1106, 1107, 1110, 1126] %}
{% set all_codes = sfr_codes + mf_codes %}

WITH parcels AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(CBSA_CODE)), 5, '0')                        AS cbsa_id,
        H3_INT_TO_STRING(H3_LATLNG_TO_CELL(
            LATITUDE  + 0e0,
            LONGITUDE + 0e0,
            8
        ))                                                               AS h3_r8_hex,

        CASE
            WHEN TRY_TO_NUMBER(PROPERTY_USE_STANDARDIZED_CODE) IN ({{ sfr_codes | join(', ') }})
                THEN 'SFR'
            WHEN TRY_TO_NUMBER(PROPERTY_USE_STANDARDIZED_CODE) IN ({{ mf_codes | join(', ') }})
                THEN 'MF'
        END                                                              AS segment,

        -- ── Value columns ───────────────────────────────────────────────────
        -- Keep as NUMBER — no cast required for MEDIAN input.
        -- MARKET_VALUE_TOTAL preferred for cross-state ppsf (AZ LPV-safe).
        IFF(ASSESSED_VALUE_TOTAL > 0,   ASSESSED_VALUE_TOTAL,   NULL)   AS assessed_value_total,
        IFF(MARKET_VALUE_TOTAL   > 0,   MARKET_VALUE_TOTAL,     NULL)   AS market_value_total,
        IFF(ASSESSED_VALUE_LAND  > 0,   ASSESSED_VALUE_LAND,    NULL)   AS assessed_value_land,

        -- ── BUILDING_SQ_FT quality gate ─────────────────────────────────────
        -- All Cherre numeric columns are NUMBER(38,9); + 0e0 coerces to FLOAT
        -- for arithmetic; BUILDING_SQ_FT range check uses + 0e0 accordingly.
        IFF(
            COALESCE(BUILDING_SQ_FT_CODE, 'L') IN ('L','E','K','T','R','0','+')
            AND BUILDING_SQ_FT + 0e0 > 100
            AND BUILDING_SQ_FT + 0e0 < 50000,
            BUILDING_SQ_FT + 0e0,
            NULL
        )                                                                AS building_sq_ft_clean,

        -- ── Vintage ─────────────────────────────────────────────────────────
        IFF(YEAR_BUILT BETWEEN 1800 AND 2030, YEAR_BUILT, NULL)         AS year_built,
        IFF(EFFECTIVE_YEAR_BUILT BETWEEN 1800 AND 2030,
            EFFECTIVE_YEAR_BUILT, NULL)                                  AS effective_year_built,

        -- ── Unit count ──────────────────────────────────────────────────────
        IFF(UNITS_COUNT > 0, UNITS_COUNT, NULL)                         AS units_count

    FROM {{ source('cherre', 'tax_assessor_v2') }}
    WHERE CHERRE_IS_DELETED = FALSE
      AND TRY_TO_NUMBER(PROPERTY_USE_STANDARDIZED_CODE) IN ({{ all_codes | join(', ') }})
      AND LATITUDE  IS NOT NULL
      AND LONGITUDE IS NOT NULL
      AND CBSA_CODE IS NOT NULL
),

agg AS (
    SELECT
        cbsa_id,
        h3_r8_hex,
        segment,

        -- ── Volume ──────────────────────────────────────────────────────────
        COUNT(*)                                                         AS parcel_count,
        SUM(COALESCE(units_count, 1))                                    AS unit_count,

        -- ── PPSF — assessed ─────────────────────────────────────────────────
        -- Primary signal feeding cbsa_ppsf_quartile. Null when sqft unavailable.
        -- Per-parcel cap at 25,000: extreme values (assessed / near-zero sqft)
        -- are data errors; P99.9 SFR=$1,538, P99.9 MF=$11,287 — cap is safe.
        MEDIAN(
            IFF(assessed_value_total IS NOT NULL AND building_sq_ft_clean IS NOT NULL
                AND (assessed_value_total / building_sq_ft_clean) <= 25000,
                assessed_value_total / building_sq_ft_clean, NULL)
        )                                                                AS median_assessed_ppsf,

        -- ── PPSF — market (AZ-safe) ─────────────────────────────────────────
        MEDIAN(
            IFF(market_value_total IS NOT NULL AND building_sq_ft_clean IS NOT NULL
                AND (market_value_total / building_sq_ft_clean) <= 25000,
                market_value_total / building_sq_ft_clean, NULL)
        )                                                                AS median_market_ppsf,

        -- ── Value ───────────────────────────────────────────────────────────
        MEDIAN(assessed_value_total)                                     AS median_assessed_value,
        MEDIAN(market_value_total)                                       AS median_market_value,

        -- ── Land value share ─────────────────────────────────────────────────
        -- Interpretation: high land share → development feasibility signal.
        AVG(
            IFF(assessed_value_total IS NOT NULL AND assessed_value_land IS NOT NULL
                AND assessed_value_total > 0,
                LEAST(assessed_value_land / assessed_value_total, 1.0), NULL)
        )                                                                AS avg_land_value_share,

        -- ── Sqft ────────────────────────────────────────────────────────────
        MEDIAN(building_sq_ft_clean)                                     AS median_sq_ft,
        COUNT_IF(building_sq_ft_clean IS NOT NULL) * 1.0 / COUNT(*)     AS sqft_fill_rate,

        -- ── Vintage buckets ─────────────────────────────────────────────────
        -- Decade-grain percentages (denominator = parcels with non-null year_built).
        COUNT_IF(year_built < 1980)
            * 1.0 / NULLIF(COUNT(year_built), 0)                        AS pct_pre_1980,
        COUNT_IF(year_built BETWEEN 1980 AND 1999)
            * 1.0 / NULLIF(COUNT(year_built), 0)                        AS pct_1980_1999,
        COUNT_IF(year_built BETWEEN 2000 AND 2009)
            * 1.0 / NULLIF(COUNT(year_built), 0)                        AS pct_2000s,
        COUNT_IF(year_built BETWEEN 2010 AND 2019)
            * 1.0 / NULLIF(COUNT(year_built), 0)                        AS pct_2010s,
        COUNT_IF(year_built >= 2020)
            * 1.0 / NULLIF(COUNT(year_built), 0)                        AS pct_post_2020,

        MEDIAN(year_built)                                               AS median_year_built,
        MEDIAN(effective_year_built)                                     AS median_effective_year_built,

        CURRENT_TIMESTAMP()                                              AS dbt_updated_at

    FROM parcels
    WHERE segment IS NOT NULL
      AND h3_r8_hex IS NOT NULL
    GROUP BY cbsa_id, h3_r8_hex, segment
)

SELECT * FROM agg
