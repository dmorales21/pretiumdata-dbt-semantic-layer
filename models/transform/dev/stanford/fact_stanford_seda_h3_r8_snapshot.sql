-- ============================================================================
-- FACT: Stanford SEDA v6.0 — school quality signals at H3 R8 grain + CBSA
-- Grain:  one row per (cbsa_id, h3_r8_hex)  — static snapshot (SEDA vintage ~2yr)
--
-- Source chain:
--   source('source_prod_stanford', 'stanford_seda_admindist_parquet')  ← raw pool file (SOURCE_PROD)
--   source('source_prod_stanford', 'stanford_seda_crosswalk_parquet')  ← raw crosswalk (SOURCE_PROD)
--     → polygon-fill via SOURCE_PROD.GEO.MAP_SCHOOLDISTRICT_H3 (same rows as ref_school_district_h3_xwalk)
--       → cbsa_id hydration via source('h3_polyfill_bridges', 'cbsa_h3_r8_polyfill')
--
-- District-level unpacking is inlined here (no intermediate TRANSFORM layer).
-- All VARIANT → typed column logic lives in the pool_raw / xwalk_raw CTEs below.
--
-- H3 aggregation pattern (district → hex):
--   One district polygon may overlap multiple H3 cells (polygon fill).
--   Boundary H3 cells may be touched by >1 district.
--   Resolution: enrollment-weighted average for continuous signals;
--               dominant district (highest enrollment) for scalar labels
--               (stateabb, fips_state, urbanicity).
--
-- Null rates:
--   ~7.3% of districts lack geoid_7 (no crosswalk match) → excluded by inner join.
--   ~10–15% of populated hexes will have NULL school_score_avg (score_suppressed).
--   Downstream consumers should COALESCE to a fallback (e.g., metro median).
--
-- Key metric definitions (SEDA 6.0 codebook):
--   avgrdall : Average achievement, grade-equivalent units (4.0 ≈ 4th-grade level).
--   sesavgall: SES composite, standardized (higher = higher socioeconomic status).
--   perfrl   : % free or reduced-price lunch (poverty proxy).
--   perecd   : % economically disadvantaged (NCES composite).
--   totenrl  : Total enrollment (pool-period average).
--
-- Quintile breakpoints (national distribution, pool period):
--   Q5 ≥ 4.5 | Q4 ≥ 3.8 | Q3 ≥ 3.1 | Q2 ≥ 2.3 | Q1 < 2.3
--
-- DE Task 4 resolved 2026-04-06. Source migrated from CLEANED layer to direct
-- SOURCE_PROD.STANFORD parquet reads; no intermediate transform table.
--
-- avgrd_all scale (pool_raw): normalize VARIANT to grade-equivalent units (codebook ~2–8 typical).
--   • raw > 5000 → ÷1000 (observed max ~1e4 in audits — thousandths / mis-scaled pulls)
--   • raw > 25  → ÷100 (same ×100 hundredths as fact_stanford_seda_county_snapshot county pool)
--   • else      → pass through (already grade-equiv)
-- ============================================================================

-- TRANSFORM.DEV.FACT_STANFORD_SEDA_H3_R8_SNAPSHOT — SEDA pool signals at H3 R8 (enrollment-weighted).
{{ config(
    materialized = 'table',
    alias = 'fact_stanford_seda_h3_r8_snapshot',
    tags = ['transform', 'transform_dev', 'stanford', 'seda', 'education', 'corridor', 'h3'],
    cluster_by = ['cbsa_id', 'h3_r8_hex'],
) }}

WITH

-- ── 1a. Pool file: one row per sedaadmin ────────────────────────────────────
-- Filter to pool file only (FILE_NAME ILIKE '%pool%') — one pooled cross-section
-- per district. Annual panel rows are in a separate file and not used here.
pool_raw AS (
    SELECT
        TRY_TO_NUMBER(V:sedaadmin::STRING)                                   AS sedaadmin,
        TRIM(V:sedaadminname::STRING)                                        AS sedaadminname,
        TRY_TO_NUMBER(V:fips::STRING)                                        AS fips_state,
        TRIM(V:stateabb::STRING)                                             AS stateabb,
        TRIM(V:gslo::STRING)                                                 AS gslo,
        TRY_TO_NUMBER(V:gshi::STRING)                                        AS gshi,
        TRY_TO_DOUBLE(V:urban::STRING)                                       AS pct_urban,
        TRY_TO_DOUBLE(V:suburb::STRING)                                      AS pct_suburb,
        TRY_TO_DOUBLE(V:town::STRING)                                        AS pct_town,
        TRY_TO_DOUBLE(V:rural::STRING)                                       AS pct_rural,
        TRIM(V:urbanicity::STRING)                                           AS urbanicity,
        TRY_TO_DOUBLE(V:totenrl::STRING)                                     AS total_enrollment,
        IFF(
            TRY_TO_DOUBLE(V:avgrdall::STRING) IS NULL,
            NULL,
            IFF(
                TRY_TO_DOUBLE(V:avgrdall::STRING) > 5000,
                TRY_TO_DOUBLE(V:avgrdall::STRING) / 1000.0,
                IFF(
                    TRY_TO_DOUBLE(V:avgrdall::STRING) > 25,
                    TRY_TO_DOUBLE(V:avgrdall::STRING) / 100.0,
                    TRY_TO_DOUBLE(V:avgrdall::STRING)
                )
            )
        )                                                                    AS avgrd_all,
        TRY_TO_DOUBLE(V:sesavgall::STRING)                                   AS ses_avg_all,
        TRY_TO_DOUBLE(V:sesavgblk::STRING)                                   AS ses_avg_blk,
        TRY_TO_DOUBLE(V:sesavghsp::STRING)                                   AS ses_avg_hsp,
        TRY_TO_DOUBLE(V:sesavgwht::STRING)                                   AS ses_avg_wht,
        TRY_TO_DOUBLE(V:sesavgwhtblk::STRING)                                AS ses_gap_wht_blk,
        TRY_TO_DOUBLE(V:sesavgwhthsp::STRING)                                AS ses_gap_wht_hsp,
        TRY_TO_DOUBLE(V:lninc50avgall::STRING)                               AS ln_inc50_all,
        TRY_TO_DOUBLE(V:baplusavgall::STRING)                                AS pct_ba_plus_all,
        TRY_TO_DOUBLE(V:povertyavgall::STRING)                               AS pct_poverty_all,
        TRY_TO_DOUBLE(V:perfrl::STRING)                                      AS pct_free_reduced_lunch,
        TRY_TO_DOUBLE(V:perecd::STRING)                                      AS pct_econ_disadvantaged,
        TRY_TO_DOUBLE(V:perell::STRING)                                      AS pct_ell,
        TRY_TO_DOUBLE(V:perspeced::STRING)                                   AS pct_special_ed,
        TRY_TO_DOUBLE(V:perwht::STRING)                                      AS pct_white,
        TRY_TO_DOUBLE(V:perblk::STRING)                                      AS pct_black,
        TRY_TO_DOUBLE(V:perhsp::STRING)                                      AS pct_hispanic,
        TRY_TO_DOUBLE(V:perasn::STRING)                                      AS pct_asian,
        TRY_TO_DOUBLE(V:pernam::STRING)                                      AS pct_native_american,
        TRY_TO_DOUBLE(V:diffexpecd_blkwht::STRING)                          AS gap_blk_wht,
        TRY_TO_DOUBLE(V:diffexpecd_hspwht::STRING)                          AS gap_hsp_wht
    FROM {{ source('source_prod_stanford', 'stanford_seda_admindist_parquet') }}
    WHERE FILE_NAME ILIKE '%pool%'
      AND V:sedaadmin IS NOT NULL
),

-- ── 1b. Crosswalk: sedaadmin → (leaid, geoid_7), deduplicated ───────────────
-- School × year panel; many rows per sedaadmin. Reduce to one preferred
-- (leaid, geoid_7) pair per sedaadmin: latest panel year, then min leaid for ties.
xwalk_raw AS (
    SELECT
        TRY_TO_NUMBER(V:sedaadmin::STRING)                                   AS sedaadmin,
        TRIM(V:leaid::STRING)                                                AS leaid,
        LPAD(TRIM(V:geoid::STRING), 7, '0')                                  AS geoid_7,
        TRY_TO_NUMBER(V:year::STRING)                                        AS panel_year,
        TRIM(V:leatype::STRING)                                              AS leatype,
        TRIM(V:admintype::STRING)                                            AS admintype
    FROM {{ source('source_prod_stanford', 'stanford_seda_crosswalk_parquet') }}
    WHERE V:sedaadmin IS NOT NULL
      AND V:leaid     IS NOT NULL
      AND V:geoid     IS NOT NULL
      AND TRIM(V:geoid::STRING) <> ''
),

xwalk_dedup AS (
    SELECT DISTINCT
        sedaadmin,
        FIRST_VALUE(leaid) OVER (
            PARTITION BY sedaadmin
            ORDER BY panel_year DESC, leaid ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS leaid,
        FIRST_VALUE(geoid_7) OVER (
            PARTITION BY sedaadmin
            ORDER BY panel_year DESC, leaid ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS geoid_7,
        FIRST_VALUE(leatype) OVER (
            PARTITION BY sedaadmin
            ORDER BY panel_year DESC, leaid ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS leatype,
        FIRST_VALUE(admintype) OVER (
            PARTITION BY sedaadmin
            ORDER BY panel_year DESC, leaid ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS admintype
    FROM xwalk_raw
),

-- ── 1c. District-grain join: pool + crosswalk, quintile assignment ───────────
-- ~7.3% of districts have no crosswalk match → geoid_7 IS NULL.
-- These are excluded in district_h3 below (INNER JOIN on xwalk).
lea AS (
    SELECT
        p.sedaadmin,
        LPAD(TRIM(TO_VARCHAR(p.fips_state)), 2, '0')                         AS fips_state,
        p.stateabb,
        p.urbanicity,
        p.total_enrollment,
        p.avgrd_all,
        CASE
            WHEN p.avgrd_all IS NULL THEN NULL
            WHEN p.avgrd_all >= 4.5  THEN 5
            WHEN p.avgrd_all >= 3.8  THEN 4
            WHEN p.avgrd_all >= 3.1  THEN 3
            WHEN p.avgrd_all >= 2.3  THEN 2
            ELSE                          1
        END                                                                  AS avgrd_quintile,
        p.ses_avg_all,
        p.pct_free_reduced_lunch,
        p.pct_econ_disadvantaged,
        p.pct_white,
        p.pct_black,
        p.pct_hispanic,
        p.gap_blk_wht,
        p.gap_hsp_wht,
        IFF(p.avgrd_all IS NULL, TRUE, FALSE)                                AS score_suppressed,
        x.geoid_7
    FROM pool_raw AS p
    LEFT JOIN xwalk_dedup AS x
        ON p.sedaadmin = x.sedaadmin
    WHERE x.geoid_7 IS NOT NULL
),

-- District GEOID (7) → H3 cells — read landing directly so this fact does not depend on a separate
-- REFERENCE.GEOGRAPHY build of ref_school_district_h3_xwalk (avoids ordering / grant gaps on small selects).
school_district_h3_xwalk AS (
    SELECT
        nullif(trim(id_geo), '') AS id_geo,
        nullif(trim(h3_6_hex), '') AS h3_6_hex,
        nullif(trim(h3_8_hex), '') AS h3_8_hex
    FROM {{ source('source_prod_geo', 'map_schooldistrict_h3') }}
    WHERE nullif(trim(id_geo), '') is not null
      AND nullif(trim(h3_8_hex), '') is not null
),

-- ── 2. Explode district → H3-8 cells via polygon-fill crosswalk ─────────────
-- One district maps to many H3 cells. Multiple districts may share a boundary cell.
district_h3 AS (
    SELECT
        l.sedaadmin,
        l.stateabb,
        l.fips_state,
        l.urbanicity,
        l.total_enrollment,
        l.avgrd_all,
        l.avgrd_quintile,
        l.ses_avg_all,
        l.pct_free_reduced_lunch,
        l.pct_econ_disadvantaged,
        l.pct_white,
        l.pct_black,
        l.pct_hispanic,
        l.gap_blk_wht,
        l.gap_hsp_wht,
        l.score_suppressed,
        LOWER(TRIM(x.h3_8_hex))                                              AS h3_r8_hex,
        LOWER(TRIM(x.h3_6_hex))                                              AS h3_r6_hex
    FROM lea AS l
    INNER JOIN school_district_h3_xwalk AS x
        ON l.geoid_7 = x.id_geo
    WHERE x.h3_8_hex IS NOT NULL
),

-- ── 3. Dominant district per hex (for scalar labels) ────────────────────────
-- Dominant = highest enrollment in hex. Used for stateabb, fips_state, urbanicity.
dominant AS (
    SELECT DISTINCT
        h3_r8_hex,
        FIRST_VALUE(stateabb) OVER (
            PARTITION BY h3_r8_hex
            ORDER BY COALESCE(total_enrollment, 0) DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS stateabb,
        FIRST_VALUE(fips_state) OVER (
            PARTITION BY h3_r8_hex
            ORDER BY COALESCE(total_enrollment, 0) DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS fips_state,
        FIRST_VALUE(urbanicity) OVER (
            PARTITION BY h3_r8_hex
            ORDER BY COALESCE(total_enrollment, 0) DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                    AS urbanicity
    FROM district_h3
),

-- ── 4. Enrollment-weighted aggregate to H3 grain ────────────────────────────
agg AS (
    SELECT
        h3_r8_hex,
        h3_r6_hex,

        COUNT(DISTINCT sedaadmin)                                            AS district_count,

        -- school_score_avg: enrollment-weighted avgrd_all (grade-equiv units)
        SUM(avgrd_all * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(avgrd_all IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS school_score_avg,

        -- school_score_quintile: enrollment-weighted (rounded; 1–5 scale)
        ROUND(
            SUM(IFF(avgrd_quintile IS NOT NULL,
                    avgrd_quintile * COALESCE(total_enrollment, 1), 0))
            / NULLIF(SUM(IFF(avgrd_quintile IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)
        )::NUMBER                                                            AS school_score_quintile,

        -- school_score_max: best district in hex
        MAX(avgrd_all)                                                       AS school_score_max,

        -- SES (enrollment-weighted)
        SUM(ses_avg_all * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(ses_avg_all IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS ses_avg,

        -- Poverty / disadvantage (enrollment-weighted)
        SUM(pct_free_reduced_lunch * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(pct_free_reduced_lunch IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS pct_free_reduced_lunch,
        SUM(pct_econ_disadvantaged * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(pct_econ_disadvantaged IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS pct_econ_disadvantaged,

        -- Demographic composition (enrollment-weighted)
        SUM(pct_white * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(pct_white IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS pct_white,
        SUM(pct_black * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(pct_black IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS pct_black,
        SUM(pct_hispanic * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(pct_hispanic IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS pct_hispanic,

        -- Equity gaps (enrollment-weighted)
        SUM(gap_blk_wht * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(gap_blk_wht IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS gap_blk_wht,
        SUM(gap_hsp_wht * COALESCE(total_enrollment, 1))
            / NULLIF(SUM(IFF(gap_hsp_wht IS NOT NULL,
                             COALESCE(total_enrollment, 1), 0)), 0)         AS gap_hsp_wht,

        ROUND(SUM(COALESCE(total_enrollment, 0)))::NUMBER                   AS hex_total_enrollment,
        BOOLOR_AGG(NOT score_suppressed)                                    AS has_score

    FROM district_h3
    GROUP BY h3_r8_hex, h3_r6_hex
),

-- ── 5. Hydrate cbsa_id from H3 bridge ───────────────────────────────────────
h3_cbsa AS (
    SELECT
        h3_r8_hex,
        cbsa_id
    FROM {{ source('h3_polyfill_bridges', 'cbsa_h3_r8_polyfill') }}
    WHERE h3_r8_hex IS NOT NULL
      AND cbsa_id   IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY h3_r8_hex ORDER BY weight DESC) = 1
)

SELECT
    h.cbsa_id,
    a.h3_r8_hex,
    a.h3_r6_hex,
    d.stateabb,
    d.fips_state,
    d.urbanicity,
    a.district_count,
    a.school_score_avg,
    a.school_score_quintile,
    a.school_score_max,
    a.ses_avg,
    a.pct_free_reduced_lunch,
    a.pct_econ_disadvantaged,
    a.pct_white,
    a.pct_black,
    a.pct_hispanic,
    a.gap_blk_wht,
    a.gap_hsp_wht,
    a.hex_total_enrollment,
    a.has_score,
    CURRENT_TIMESTAMP()                                                      AS dbt_updated_at
FROM agg AS a
INNER JOIN h3_cbsa  AS h  ON a.h3_r8_hex = h.h3_r8_hex
INNER JOIN dominant AS d  ON a.h3_r8_hex = d.h3_r8_hex
