-- ============================================================================
-- FACT: ACS 2024 Block-Group Demographics → H3 R8 (national)
-- Purpose: Foundation demand signal layer for BTR/SFR/GMF/MFR corridor scoring.
--          Captures renter profile, income distribution, rent burden, housing
--          type, bedroom demand, affordability stress, education, age cohorts,
--          race/ethnicity, mobility, commute mode/time, HH composition, and
--          employment — all at block_group grain, area-weighted to H3 R8.
-- Sources:
--   housing_base        → source('transform_census','acs5') block_group pivot (B25001–B25042 housing set)
--   pop_income_acs5     → source('transform_census','acs5') B01001/B19013 (pop, age, HHI)
--   tenure_b25119       → source('transform_census','acs5') B25119 (renter/owner income, 52 states)
--   race_ethnicity      → source('transform_census','acs5') B02001 + B03003
--   mobility_acs5       → source('transform_census','acs5') B07001 (mobility)
--   commute_mode_acs5   → source('transform_census','acs5') B08101 (coarse commute mode)
--   commute_detail_acs5 → source('transform_census','acs5') B08301 (bike/walk/transit/carpool/WFH)
--   commute_time_acs5   → source('transform_census','acs5') B08303 (commute time buckets)
--   hh_type_acs5        → source('transform_census','acs5') B11001 (HH type)
--   hh_size_acs5        → source('transform_census','acs5') B11016 (HH size)
--   education_acs5      → source('transform_census','acs5') B15003 (education; all-state)
--   income_dist_acs5    → source('transform_census','acs5') B19001 (HH income brackets; all-state)
--   employment_acs5     → source('transform_census','acs5') B23025 (employment; all-state)
--   demo_supplemental_acs5 → source('transform_census','acs5') B25070/B25064/B25077/B25071/B25106
-- Crosswalk: block_group → H3 R8 via source('h3_polyfill_bridges','bridge_bg_h3_r8_polyfill') (area-weighted)
--            National scope — no pilot CBSA filter.
-- Grain:   (cbsa_id, h3_r8_hex) — latest ACS vintage per block group
-- Join key: GEO_ID (12-digit FIPS) across all sources
-- Replaces: TRANSFORM_PROD.CLEANED.CLEANED_ACS5_DEMOGRAPHICS_H3_R8 (pilot CBSAs)
-- Feeds:   All G-signal families (G1 renter, G2 income, G3 housing, G8 demo, etc.)
--
-- TODO (still pending DE ingestion):
--   [ ] B17001 poverty             → poverty_share (verify fill at BG)
--   [ ] B09001 children in HH      → children_in_hh_per_hh (verify fill at BG)
--   [ ] B19019 income by HH size   → median_income_3person_hh (verify fill at BG)
--   [ ] B25070 rent burden         → rent_burden_30plus_share (non-AZ)
--   [ ] B25064 median gross rent   → median_gross_rent_wavg (non-AZ)
--   [ ] B25077 median home value   → median_home_value_wavg (non-AZ)
-- ============================================================================

-- TRANSFORM.DEV.FACT_CENSUS_ACS5_H3_R8_SNAPSHOT — ACS5 block-group pivots area-weighted to H3 R8 (national).
{{ config(
    materialized = 'table',
    alias = 'fact_census_acs5_h3_r8_snapshot',
    tags = ['transform', 'transform_dev', 'census', 'pep', 'fact_census', 'corridor', 'h3', 'acs'],
    cluster_by = ['cbsa_id', 'h3_r8_hex'],
) }}

WITH xw AS (
    SELECT
        h3_r8_hex,
        cbsa_id,
        bg_geoid  AS block_group_id,
        weight    AS w
    FROM {{ source('h3_polyfill_bridges', 'bridge_bg_h3_r8_polyfill') }}
    -- National scope: pilot CBSA filter removed
    WHERE h3_r8_hex IS NOT NULL
      AND bg_geoid  IS NOT NULL
),

-- ── HOUSING FOUNDATION (block_group via TRANSFORM.CENSUS.ACS5 EAV) ───────────
-- Pivots housing structure, tenure, vacancy, bedrooms, and year-built.
-- Join key = GEO_ID (12-digit census block group FIPS).
-- Dedup: latest YEAR per (GEO_ID, VARIABLE_ID).
housing_base AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B25001_001E' THEN VALUE END)                  AS total_housing_units,
        MAX(CASE WHEN VARIABLE_ID = 'B25002_002E' THEN VALUE END)                  AS occupied_units,
        MAX(CASE WHEN VARIABLE_ID = 'B25003_001E' THEN VALUE END)                  AS total_households,
        MAX(CASE WHEN VARIABLE_ID = 'B25003_002E' THEN VALUE END)                  AS owner_occ_units,
        MAX(CASE WHEN VARIABLE_ID = 'B25003_003E' THEN VALUE END)                  AS renter_occ_units,
        MAX(CASE WHEN VARIABLE_ID = 'B25002_003E' THEN VALUE END)                  AS total_vacant_units,
        MAX(CASE WHEN VARIABLE_ID = 'B25004_002E' THEN VALUE END)                  AS vacant_for_rent,
        MAX(CASE WHEN VARIABLE_ID = 'B25004_004E' THEN VALUE END)                  AS vacant_for_sale,
        MAX(CASE WHEN VARIABLE_ID = 'B25024_001E' THEN VALUE END)                  AS total_structure_units,
        MAX(CASE WHEN VARIABLE_ID = 'B25024_002E' THEN VALUE END)                  AS sfr_detached_units,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25034_002E' THEN VALUE END), 0)
            + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25034_003E' THEN VALUE END), 0) AS built_2010_plus,
        MAX(CASE WHEN VARIABLE_ID = 'B25042_009E' THEN VALUE END)                  AS renter_units_total,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25042_011E' THEN VALUE END), 0)     AS renter_units_1br,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25042_012E' THEN VALUE END), 0)     AS renter_units_2br,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25042_013E' THEN VALUE END), 0)
            + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25042_014E' THEN VALUE END), 0)
            + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25042_015E' THEN VALUE END), 0) AS renter_units_3br_plus
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL = 'block_group'
          AND VARIABLE_ID IN (
            'B25001_001E', 'B25002_002E', 'B25002_003E',
            'B25003_001E', 'B25003_002E', 'B25003_003E',
            'B25004_002E', 'B25004_004E',
            'B25024_001E', 'B25024_002E',
            'B25034_002E', 'B25034_003E',
            'B25042_009E', 'B25042_011E', 'B25042_012E',
            'B25042_013E', 'B25042_014E', 'B25042_015E'
        )
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── POPULATION + MEDIAN HHI + AGE COHORTS (TRANSFORM.CENSUS.ACS5) ───────────
-- B01001_001E = total population (52 states, 2020-2024)
-- B19013_001E = median household income (~51 states)
-- Age cohorts from B01001:
--   millennial_pop   (25-39): M:_011+_012+_013  / F:_035+_036+_037
--   young_adult_pop  (18-34): M:_007-_012       / F:_031-_036
--   children_u5_pop  (<5):    M:_003             / F:_027
--   school_age_pop   (5-17):  M:_004+_005+_006  / F:_028+_029+_030
--   senior_65plus_pop(65+):   M:_020-_025        / F:_044-_049
pop_income_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B01001_001E'
                  AND VALUE > 0 THEN VALUE END)                                  AS total_population,
        MAX(CASE WHEN VARIABLE_ID = 'B19013_001E'
                  AND VALUE > 0 AND VALUE <> -666666666 THEN VALUE END)          AS median_hhi,

        -- Millennial (25-39): core renter cohort for GMF/MFR demand
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_011E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_012E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_013E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_035E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_036E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_037E' AND VALUE > 0 THEN VALUE END), 0)
                                                                                 AS millennial_pop,

        -- Young adult (18-34): broadest apartment-demand cohort
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_007E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_008E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_009E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_010E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_011E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_012E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_031E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_032E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_033E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_034E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_035E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_036E' AND VALUE > 0 THEN VALUE END), 0)
                                                                                 AS young_adult_pop,

        -- Children under 5 (young-family renter signal → garden/low-rise)
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_003E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_027E' AND VALUE > 0 THEN VALUE END), 0)
                                                                                 AS children_under_5_pop,

        -- School-age children 5–17 (family household signal → garden)
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_004E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_005E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_006E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_028E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_029E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_030E' AND VALUE > 0 THEN VALUE END), 0)
                                                                                 AS school_age_pop,

        -- Seniors 65+
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_020E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_021E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_022E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_023E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_024E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_025E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_044E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_045E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_046E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_047E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_048E' AND VALUE > 0 THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B01001_049E' AND VALUE > 0 THEN VALUE END), 0)
                                                                                 AS senior_65plus_pop

    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND VARIABLE_ID IN (
              'B01001_001E', 'B19013_001E',
              -- Millennial (25-39): M + F
              'B01001_011E','B01001_012E','B01001_013E',
              'B01001_035E','B01001_036E','B01001_037E',
              -- Young adult (18-34): M + F
              'B01001_007E','B01001_008E','B01001_009E','B01001_010E',
              'B01001_031E','B01001_032E','B01001_033E','B01001_034E',
              -- Children under 5: M + F
              'B01001_003E','B01001_027E',
              -- School-age (5-17): M + F
              'B01001_004E','B01001_005E','B01001_006E',
              'B01001_028E','B01001_029E','B01001_030E',
              -- Seniors 65+: M + F
              'B01001_020E','B01001_021E','B01001_022E','B01001_023E','B01001_024E','B01001_025E',
              'B01001_044E','B01001_045E','B01001_046E','B01001_047E','B01001_048E','B01001_049E'
          )
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── RENTER / OWNER INCOME (TRANSFORM.CENSUS.ACS5 B25119, 52 states) ─────────
-- KNOWN INGESTION GAP (confirmed 2026-04-08): B25119 rows exist at block_group
-- level but VALUE is NULL throughout for YEAR=2024. median_renter_income_wavg
-- and median_owner_income_wavg will output 0 (not NULL — COALESCE absorbs the
-- miss) until DE re-ingests with VALUE populated.
-- Ticket: DE to re-ingest TRANSFORM.CENSUS.ACS5 GROUP_ID='B25119' block_group.
tenure_b25119 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B25119_002E'
                  AND VALUE > 0 AND VALUE <> -666666666 THEN VALUE END)          AS median_owner_income,
        MAX(CASE WHEN VARIABLE_ID = 'B25119_003E'
                  AND VALUE > 0 AND VALUE <> -666666666 THEN VALUE END)          AS median_renter_income
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B25119'
          AND VARIABLE_ID IN ('B25119_002E', 'B25119_003E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── RACE / ETHNICITY (TRANSFORM.CENSUS.ACS5 B02001 + B03003) ─────────────────
race_ethnicity AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B02001_001E' AND VALUE > 0 THEN VALUE END)  AS race_total,
        MAX(CASE WHEN VARIABLE_ID = 'B02001_002E' THEN VALUE END)                AS pop_white,
        MAX(CASE WHEN VARIABLE_ID = 'B02001_003E' THEN VALUE END)                AS pop_black,
        MAX(CASE WHEN VARIABLE_ID = 'B02001_005E' THEN VALUE END)                AS pop_asian,
        MAX(CASE WHEN VARIABLE_ID = 'B03003_001E' AND VALUE > 0 THEN VALUE END)  AS hispanic_total,
        MAX(CASE WHEN VARIABLE_ID = 'B03003_003E' THEN VALUE END)                AS pop_hispanic
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   IN ('B02001', 'B03003')
          AND VARIABLE_ID IN ('B02001_001E','B02001_002E','B02001_003E','B02001_005E',
                               'B03003_001E','B03003_003E')
          AND YEAR = 2024
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── GEOGRAPHIC MOBILITY (TRANSFORM.CENSUS.ACS5 B07001) ───────────────────────
-- KNOWN INGESTION GAP (confirmed 2026-04-08): B07001 rows exist at block_group
-- level (234K GEO_IDs, YEAR=2024) but VALUE is NULL for every row across all
-- variables in this group. Output metrics in_migration_share, total_movers_share,
-- and intrastate_mover_share will be NULL until DE re-ingests with VALUE populated.
-- Ticket: DE to re-ingest TRANSFORM.CENSUS.ACS5 GROUP_ID='B07001' block_group.
mobility_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B07001_001E' AND VALUE > 0 THEN VALUE END)  AS mobility_total,
        MAX(CASE WHEN VARIABLE_ID = 'B07001_017E' THEN VALUE END)                AS same_house,
        MAX(CASE WHEN VARIABLE_ID = 'B07001_033E' THEN VALUE END)                AS moved_same_county,
        MAX(CASE WHEN VARIABLE_ID = 'B07001_049E' THEN VALUE END)                AS moved_diff_county_same_state,
        MAX(CASE WHEN VARIABLE_ID = 'B07001_065E' THEN VALUE END)                AS moved_diff_state
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B07001'
          AND VARIABLE_ID IN ('B07001_001E','B07001_017E','B07001_033E',
                               'B07001_049E','B07001_065E')
          AND YEAR = 2024
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── COMMUTE MODE (TRANSFORM.CENSUS.ACS5 B08101) ──────────────────────────────
-- KNOWN INGESTION GAP (confirmed 2026-04-08): B08101 rows exist at block_group
-- level (12M rows, YEAR=2024) but VALUE is NULL throughout. Output metrics
-- transit_commuter_share, wfh_share, and car_dependent_share will be NULL until
-- DE re-ingests. NOTE: B08301 (commute detail) IS populated and preferred for
-- new feature models — use drove_alone_share / transit_share / wfh_det_share.
-- Ticket: DE to re-ingest TRANSFORM.CENSUS.ACS5 GROUP_ID='B08101' block_group.
commute_mode_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B08101_001E' AND VALUE > 0 THEN VALUE END)  AS commute_total,
        MAX(CASE WHEN VARIABLE_ID = 'B08101_009E' THEN VALUE END)                AS drove_alone,
        MAX(CASE WHEN VARIABLE_ID = 'B08101_025E' THEN VALUE END)                AS public_transit,
        MAX(CASE WHEN VARIABLE_ID = 'B08101_033E' THEN VALUE END)                AS walked,
        MAX(CASE WHEN VARIABLE_ID = 'B08101_049E' THEN VALUE END)                AS worked_from_home
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B08101'
          AND VARIABLE_ID IN ('B08101_001E','B08101_009E','B08101_025E',
                               'B08101_033E','B08101_049E')
          AND YEAR = 2024
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── COMMUTE DETAIL (TRANSFORM.CENSUS.ACS5 B08301) ────────────────────────────
-- Higher fidelity than B08101: bicycle and carpool separately; transit as total.
commute_detail_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_001E' AND VALUE > 0 THEN VALUE END)  AS commute_det_total,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_003E' THEN VALUE END)                AS drove_alone_det,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_004E' THEN VALUE END)                AS carpool_det,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_010E' THEN VALUE END)                AS transit_det,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_018E' THEN VALUE END)                AS bicycle_det,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_019E' THEN VALUE END)                AS walked_det,
        MAX(CASE WHEN VARIABLE_ID = 'B08301_021E' THEN VALUE END)                AS wfh_det
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B08301'
          AND VARIABLE_ID IN ('B08301_001E','B08301_003E','B08301_004E',
                               'B08301_010E','B08301_018E','B08301_019E','B08301_021E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── COMMUTE TIME (TRANSFORM.CENSUS.ACS5 B08303) ──────────────────────────────
commute_time_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B08303_001E' AND VALUE > 0 THEN VALUE END)  AS commute_time_total,
        -- < 30 minutes = urban proximity / TOD signal
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_002E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_003E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_004E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_005E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_006E' THEN VALUE END), 0)
                                                                                 AS commute_under_30,
        -- 60+ minutes = extreme long-haul commuters (BTR fringe-market signal)
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_012E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B08303_013E' THEN VALUE END), 0)
                                                                                 AS commute_60plus
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B08303'
          AND VARIABLE_ID IN ('B08303_001E','B08303_002E','B08303_003E','B08303_004E',
                               'B08303_005E','B08303_006E','B08303_012E','B08303_013E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── HOUSEHOLD TYPE (TRANSFORM.CENSUS.ACS5 B11001) ────────────────────────────
hh_type_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B11001_001E' AND VALUE > 0 THEN VALUE END)  AS hh_type_total,
        MAX(CASE WHEN VARIABLE_ID = 'B11001_002E' THEN VALUE END)                AS hh_family,
        MAX(CASE WHEN VARIABLE_ID = 'B11001_003E' THEN VALUE END)                AS hh_married_couple,
        MAX(CASE WHEN VARIABLE_ID = 'B11001_007E' THEN VALUE END)                AS hh_nonfamily,
        MAX(CASE WHEN VARIABLE_ID = 'B11001_008E' THEN VALUE END)                AS hh_single_person
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B11001'
          AND VARIABLE_ID IN ('B11001_001E','B11001_002E','B11001_003E',
                               'B11001_007E','B11001_008E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── HOUSEHOLD SIZE (TRANSFORM.CENSUS.ACS5 B11016) ────────────────────────────
-- family_3plus_hh = family HHs with 3+ persons (family total minus 2-person family)
hh_size_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B11016_001E' AND VALUE > 0 THEN VALUE END)  AS hh_size_total,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B11016_002E' THEN VALUE END), 0)
        - COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B11016_003E' THEN VALUE END), 0)
                                                                                 AS family_3plus_hh,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B11016_010E' THEN VALUE END), 0)  AS nonfamily_1person_hh
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B11016'
          AND VARIABLE_ID IN ('B11016_001E','B11016_002E','B11016_003E','B11016_010E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── EDUCATION ATTAINMENT (TRANSFORM.CENSUS.ACS5 B15003) ──────────────────────
-- All-state. _001E = total 25+; _022E = bachelor's; _023E = master's;
-- _024E = professional; _025E = doctorate.
education_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B15003_001E' AND VALUE > 0 THEN VALUE END)  AS pop_25_plus_edu,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_022E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_023E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_024E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_025E' THEN VALUE END), 0)
                                                                                 AS bachelors_plus_pop,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_023E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_024E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B15003_025E' THEN VALUE END), 0)
                                                                                 AS graduate_degree_pop
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B15003'
          AND VARIABLE_ID IN ('B15003_001E','B15003_022E','B15003_023E',
                               'B15003_024E','B15003_025E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── HOUSEHOLD INCOME DISTRIBUTION (TRANSFORM.CENSUS.ACS5 B19001) ─────────────
-- All-state. Income bracket signal map:
--   hh_75_150k_share  → SF BTR sweet spot
--   hh_100k_plus_share→ MF High-Rise+ demand
--   hh_150k_plus_share→ MF Tower+ demand
--   hh_200k_plus_share→ MF Skyscraper demand
income_dist_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B19001_001E' AND VALUE > 0 THEN VALUE END)  AS income_hh_total,
        -- Under $45K: low-income / poverty-adjacent pool
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_002E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_003E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_004E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_005E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_006E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_007E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_008E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_009E' THEN VALUE END), 0)
                                                                                 AS hh_under_45k,
        -- $45K–$100K: working/middle-income renter pool
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_010E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_011E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_012E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_013E' THEN VALUE END), 0)
                                                                                 AS hh_45_90k,
        -- $60K–$100K: MFR target income band (B19001_012 + B19001_013)
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_012E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_013E' THEN VALUE END), 0)
                                                                                 AS hh_60_100k,
        -- $75K–$150K: BTR sweet spot
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_013E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_014E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_015E' THEN VALUE END), 0)
                                                                                 AS hh_75_150k,
        -- $100K+: High-Rise+ demand bracket
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_014E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_015E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_016E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_017E' THEN VALUE END), 0)
                                                                                 AS hh_100k_plus,
        -- $150K+: Tower/Skyscraper demand bracket
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_016E' THEN VALUE END), 0)
        + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_017E' THEN VALUE END), 0)
                                                                                 AS hh_150k_plus,
        -- $200K+: Skyscraper luxury demand
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B19001_017E' THEN VALUE END), 0)  AS hh_200k_plus
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B19001'
          AND VARIABLE_ID IN (
              'B19001_001E','B19001_002E','B19001_003E','B19001_004E',
              'B19001_005E','B19001_006E','B19001_007E','B19001_008E',
              'B19001_009E','B19001_010E','B19001_011E','B19001_012E',
              'B19001_013E','B19001_014E','B19001_015E','B19001_016E',
              'B19001_017E'
          )
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── EMPLOYMENT STATUS (TRANSFORM.CENSUS.ACS5 B23025) ─────────────────────────
-- All-state. _001E = civilian pop 16+; _002E = in labor force;
-- _004E = employed; _005E = unemployed.
employment_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                              AS block_group_id,
        MAX(CASE WHEN VARIABLE_ID = 'B23025_001E' AND VALUE > 0 THEN VALUE END)  AS emp_pop_16plus,
        MAX(CASE WHEN VARIABLE_ID = 'B23025_002E' AND VALUE > 0 THEN VALUE END)  AS emp_in_lf,
        MAX(CASE WHEN VARIABLE_ID = 'B23025_004E' THEN VALUE END)                AS emp_employed,
        MAX(CASE WHEN VARIABLE_ID = 'B23025_005E' THEN VALUE END)                AS emp_unemployed
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL      = 'block_group'
          AND GROUP_ID   = 'B23025'
          AND VARIABLE_ID IN ('B23025_001E','B23025_002E','B23025_004E','B23025_005E')
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── SUPPLEMENTAL: rent burden, cost ratios, home value, gross rent (ACS5 BG) ──
-- Pivoted from EAV where DE has populated block_group rows (national when present).
demo_supplemental_acs5 AS (
    SELECT
        TRIM(GEO_ID)                                                               AS block_group_id,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25070_001E' THEN VALUE END), 0)      AS rent_burden_universe,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25070_007E' THEN VALUE END), 0)
            + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25070_008E' THEN VALUE END), 0)
            + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25070_009E' THEN VALUE END), 0)
            + COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25070_010E' THEN VALUE END), 0) AS rent_burden_30plus,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25070_010E' THEN VALUE END), 0)      AS rent_burden_50plus,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25071_001E' THEN VALUE END), 0)      AS gross_rent_pct_income,
        COALESCE(MAX(CASE WHEN VARIABLE_ID = 'B25106_001E' THEN VALUE END), 0)      AS owner_cost_pct_income,
        COALESCE(MAX(CASE
            WHEN VARIABLE_ID = 'B25077_001E' AND VALUE > 0 AND VALUE <> -666666666 THEN VALUE END), 0) AS median_home_value,
        COALESCE(MAX(CASE
            WHEN VARIABLE_ID = 'B25064_001E' AND VALUE > 0 AND VALUE <> -666666666 THEN VALUE END), 0) AS median_gross_rent
    FROM (
        SELECT GEO_ID, VARIABLE_ID, VALUE
        FROM {{ source('transform_census', 'acs5') }}
        WHERE LEVEL = 'block_group'
          AND VARIABLE_ID IN (
              'B25070_001E', 'B25070_007E', 'B25070_008E', 'B25070_009E', 'B25070_010E',
              'B25071_001E', 'B25106_001E', 'B25077_001E', 'B25064_001E'
          )
          AND GEO_ID IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (
            PARTITION BY GEO_ID, VARIABLE_ID ORDER BY YEAR DESC
        ) = 1
    ) AS latest
    GROUP BY TRIM(GEO_ID)
),

-- ── JOIN: block group → all sources ──────────────────────────────────────────
-- INNER JOIN housing_base (51-52 states) is the anchor.
-- All supplemental sources are LEFT JOIN; columns null-safe via COALESCE.
joined AS (
    SELECT
        xw.cbsa_id,
        xw.h3_r8_hex,
        xw.w,
        -- Housing structure (51-52 states)
        COALESCE(h.total_housing_units, 0)                                        AS total_housing_units,
        COALESCE(h.occupied_units, h.total_households, 0)                         AS occupied_units,
        COALESCE(h.total_households, h.occupied_units, 0)                         AS total_households,
        COALESCE(h.owner_occ_units, 0)                                            AS owner_occ_units,
        COALESCE(h.renter_occ_units, 0)                                           AS renter_occ_units,
        COALESCE(h.total_vacant_units, 0)                                         AS total_vacant_units,
        COALESCE(h.vacant_for_rent, 0)                                            AS vacant_for_rent,
        COALESCE(h.vacant_for_sale, 0)                                            AS vacant_for_sale,
        COALESCE(h.sfr_detached_units, 0)                                         AS sfr_detached_units,
        COALESCE(h.total_structure_units, 0)                                      AS total_structure_units,
        COALESCE(h.built_2010_plus, 0)                                            AS built_2010_plus,
        COALESCE(h.renter_units_total, 0)                                         AS renter_units_total,
        COALESCE(h.renter_units_3br_plus, 0)                                      AS renter_units_3br_plus,
        -- Population + age cohorts (52 states from ACS5 B01001)
        COALESCE(p.total_population, 0)                                           AS total_population,
        COALESCE(p.millennial_pop, 0)                                             AS millennial_pop,
        COALESCE(p.young_adult_pop, 0)                                            AS young_adult_pop,
        COALESCE(p.children_under_5_pop, 0)                                       AS children_under_5_pop,
        COALESCE(p.school_age_pop, 0)                                             AS school_age_pop,
        COALESCE(p.senior_65plus_pop, 0)                                          AS senior_65plus_pop,
        -- Median HHI (ACS5 B19013, ~51 states)
        COALESCE(NULLIF(p.median_hhi, 0), 0)                                      AS median_hhi,
        -- Renter / owner income (52 states from B25119)
        COALESCE(t.median_renter_income, 0)                                       AS median_renter_income,
        COALESCE(t.median_owner_income, 0)                                        AS median_owner_income,
        -- Race / ethnicity (B02001 + B03003, 2024, all states)
        COALESCE(re.race_total, 0)                                                AS race_total,
        COALESCE(re.pop_white, 0)                                                 AS pop_white,
        COALESCE(re.pop_black, 0)                                                 AS pop_black,
        COALESCE(re.pop_asian, 0)                                                 AS pop_asian,
        COALESCE(re.hispanic_total, 0)                                            AS hispanic_total,
        COALESCE(re.pop_hispanic, 0)                                              AS pop_hispanic,
        -- Geographic mobility (B07001, ~234K BGs)
        COALESCE(mo.mobility_total, 0)                                            AS mobility_total,
        COALESCE(mo.same_house, 0)                                                AS same_house,
        COALESCE(mo.moved_same_county, 0)                                         AS moved_same_county,
        COALESCE(mo.moved_diff_county_same_state, 0)                              AS moved_diff_county_same_state,
        COALESCE(mo.moved_diff_state, 0)                                          AS moved_diff_state,
        -- Commute mode (B08101, ~219K BGs — workers 16+ only)
        COALESCE(cm.commute_total, 0)                                             AS commute_total,
        COALESCE(cm.drove_alone, 0)                                               AS drove_alone,
        COALESCE(cm.public_transit, 0)                                            AS public_transit,
        COALESCE(cm.walked, 0)                                                    AS walked,
        COALESCE(cm.worked_from_home, 0)                                          AS worked_from_home,
        -- Commute detail (B08301, all-state; higher fidelity than B08101)
        COALESCE(cd.commute_det_total, 0)                                         AS commute_det_total,
        COALESCE(cd.drove_alone_det, 0)                                           AS drove_alone_det,
        COALESCE(cd.carpool_det, 0)                                               AS carpool_det,
        COALESCE(cd.transit_det, 0)                                               AS transit_det,
        COALESCE(cd.bicycle_det, 0)                                               AS bicycle_det,
        COALESCE(cd.walked_det, 0)                                                AS walked_det,
        COALESCE(cd.wfh_det, 0)                                                   AS wfh_det,
        -- Commute time (B08303, all-state)
        COALESCE(ct.commute_time_total, 0)                                        AS commute_time_total,
        COALESCE(ct.commute_under_30, 0)                                          AS commute_under_30,
        COALESCE(ct.commute_60plus, 0)                                            AS commute_60plus,
        -- HH type (B11001, all-state)
        COALESCE(ht.hh_type_total, 0)                                             AS hh_type_total,
        COALESCE(ht.hh_family, 0)                                                 AS hh_family,
        COALESCE(ht.hh_married_couple, 0)                                         AS hh_married_couple,
        COALESCE(ht.hh_nonfamily, 0)                                              AS hh_nonfamily,
        COALESCE(ht.hh_single_person, 0)                                          AS hh_single_person,
        -- HH size (B11016, all-state)
        COALESCE(hs.hh_size_total, 0)                                             AS hh_size_total,
        COALESCE(hs.family_3plus_hh, 0)                                           AS family_3plus_hh,
        COALESCE(hs.nonfamily_1person_hh, 0)                                      AS nonfamily_1person_hh,
        -- Education (B15003, all-state)
        COALESCE(ed.pop_25_plus_edu, 0)                                           AS pop_25_plus_edu,
        COALESCE(ed.bachelors_plus_pop, 0)                                        AS bachelors_plus_pop,
        COALESCE(ed.graduate_degree_pop, 0)                                       AS graduate_degree_pop,
        -- Income distribution (B19001, all-state)
        COALESCE(inc.income_hh_total, 0)                                          AS income_hh_total,
        COALESCE(inc.hh_under_45k, 0)                                             AS hh_under_45k,
        COALESCE(inc.hh_45_90k, 0)                                                AS hh_45_90k,
        COALESCE(inc.hh_60_100k, 0)                                               AS hh_60_100k,
        COALESCE(inc.hh_75_150k, 0)                                               AS hh_75_150k,
        COALESCE(inc.hh_100k_plus, 0)                                             AS hh_100k_plus,
        COALESCE(inc.hh_150k_plus, 0)                                             AS hh_150k_plus,
        COALESCE(inc.hh_200k_plus, 0)                                             AS hh_200k_plus,
        -- Employment (B23025, all-state)
        COALESCE(em.emp_pop_16plus, 0)                                            AS emp_pop_16plus,
        COALESCE(em.emp_in_lf, 0)                                                 AS emp_in_lf,
        COALESCE(em.emp_employed, 0)                                              AS emp_employed,
        COALESCE(em.emp_unemployed, 0)                                            AS emp_unemployed,
        -- Supplemental rent / value (ACS5 BG pivot)
        COALESCE(az.rent_burden_universe, 0)                                      AS rent_burden_universe,
        COALESCE(az.rent_burden_30plus, 0)                                        AS rent_burden_30plus,
        COALESCE(az.rent_burden_50plus, 0)                                        AS rent_burden_50plus,
        COALESCE(az.gross_rent_pct_income, 0)                                     AS gross_rent_pct_income,
        COALESCE(az.owner_cost_pct_income, 0)                                     AS owner_cost_pct_income,
        COALESCE(az.median_home_value, 0)                                         AS median_home_value,
        COALESCE(az.median_gross_rent, 0)                                         AS median_gross_rent
    FROM xw
    INNER JOIN housing_base          AS h   ON xw.block_group_id = h.block_group_id
    LEFT  JOIN pop_income_acs5       AS p   ON h.block_group_id  = p.block_group_id
    LEFT  JOIN tenure_b25119         AS t   ON h.block_group_id  = t.block_group_id
    LEFT  JOIN race_ethnicity        AS re  ON h.block_group_id  = re.block_group_id
    LEFT  JOIN mobility_acs5         AS mo  ON h.block_group_id  = mo.block_group_id
    LEFT  JOIN commute_mode_acs5     AS cm  ON h.block_group_id  = cm.block_group_id
    LEFT  JOIN commute_detail_acs5   AS cd  ON h.block_group_id  = cd.block_group_id
    LEFT  JOIN commute_time_acs5     AS ct  ON h.block_group_id  = ct.block_group_id
    LEFT  JOIN hh_type_acs5          AS ht  ON h.block_group_id  = ht.block_group_id
    LEFT  JOIN hh_size_acs5          AS hs  ON h.block_group_id  = hs.block_group_id
    LEFT  JOIN education_acs5        AS ed  ON h.block_group_id  = ed.block_group_id
    LEFT  JOIN income_dist_acs5      AS inc ON h.block_group_id  = inc.block_group_id
    LEFT  JOIN employment_acs5       AS em  ON h.block_group_id  = em.block_group_id
    LEFT  JOIN demo_supplemental_acs5 AS az  ON h.block_group_id  = az.block_group_id
)

SELECT
    j.cbsa_id,
    j.h3_r8_hex,

    -- ── Renter profile ─────────────────────────────────────────────────────
    SUM(j.renter_occ_units * j.w)
        / NULLIF(SUM(j.occupied_units * j.w), 0)            AS renter_share,
    SUM(j.renter_occ_units * j.w)
        / NULLIF(SUM(j.w), 0)                               AS renter_hh_count_wavg,
    SUM(j.total_households * j.w)
        / NULLIF(SUM(j.w), 0)                               AS total_hh_wavg,
    SUM(j.total_population * j.w)
        / NULLIF(SUM(j.w), 0)                               AS total_population_wavg,

    -- ── Income signals ─────────────────────────────────────────────────────
    SUM(j.median_hhi * j.w)
        / NULLIF(SUM(j.w), 0)                               AS median_hhi_wavg,
    SUM(j.median_renter_income * j.w)
        / NULLIF(SUM(j.w), 0)                               AS median_renter_income_wavg,
    SUM(j.median_owner_income * j.w)
        / NULLIF(SUM(j.w), 0)                               AS median_owner_income_wavg,
    -- Income distribution (B19001, all-state)
    SUM(j.hh_under_45k * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hh_under_45k_share,
    SUM(j.hh_45_90k * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hh_45_90k_share,
    SUM(j.hh_75_150k * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hh_75_150k_share,
    SUM(j.hh_100k_plus * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hh_100k_plus_share,
    SUM(j.hh_150k_plus * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hh_150k_plus_share,
    SUM(j.hh_200k_plus * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hh_200k_plus_share,
    -- hhi_ prefixed aliases for feature model compatibility
    SUM(j.hh_60_100k * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hhi_60_100k_share,
    SUM(j.hh_100k_plus * j.w)
        / NULLIF(SUM(j.income_hh_total * j.w), 0)           AS hhi_100k_plus_share,

    -- ── Education ──────────────────────────────────────────────────────────
    SUM(j.bachelors_plus_pop * j.w)
        / NULLIF(SUM(j.pop_25_plus_edu * j.w), 0)           AS bachelors_plus_share,
    SUM(j.graduate_degree_pop * j.w)
        / NULLIF(SUM(j.pop_25_plus_edu * j.w), 0)           AS graduate_degree_share,

    -- ── Housing type and bedroom demand ────────────────────────────────────
    SUM(j.sfr_detached_units * j.w)
        / NULLIF(SUM(j.total_structure_units * j.w), 0)     AS sfr_share,
    SUM(j.renter_units_3br_plus * j.w)
        / NULLIF(SUM(j.renter_units_total * j.w), 0)        AS renter_3br_plus_share,

    -- ── Vacancy ────────────────────────────────────────────────────────────
    SUM(j.total_vacant_units * j.w)
        / NULLIF(SUM(j.total_housing_units * j.w), 0)       AS total_vacant_share,
    SUM(j.vacant_for_rent * j.w)
        / NULLIF(SUM(j.total_housing_units * j.w), 0)       AS vacant_for_rent_share,
    SUM(j.vacant_for_sale * j.w)
        / NULLIF(SUM(j.total_housing_units * j.w), 0)       AS for_sale_vacant_share,

    -- ── Housing vintage (new supply competition) ───────────────────────────
    SUM(j.built_2010_plus * j.w)
        / NULLIF(SUM(j.total_housing_units * j.w), 0)       AS built_2010_plus_share,

    -- ── Employment (B23025, all-state) ─────────────────────────────────────
    SUM(j.emp_in_lf * j.w)
        / NULLIF(SUM(j.emp_pop_16plus * j.w), 0)            AS labor_force_participation_rate,
    SUM(j.emp_employed * j.w)
        / NULLIF(SUM(j.emp_in_lf * j.w), 0)                 AS employment_rate,
    SUM(j.emp_unemployed * j.w)
        / NULLIF(SUM(j.emp_in_lf * j.w), 0)                 AS unemployment_rate,

    -- ── Age cohorts (B01001, all states) ───────────────────────────────────
    SUM(j.millennial_pop * j.w)
        / NULLIF(SUM(j.total_population * j.w), 0)          AS millennial_share,
    SUM(j.young_adult_pop * j.w)
        / NULLIF(SUM(j.total_population * j.w), 0)          AS young_adult_share,
    SUM(j.children_under_5_pop * j.w)
        / NULLIF(SUM(j.total_population * j.w), 0)          AS children_under_5_share,
    SUM(j.school_age_pop * j.w)
        / NULLIF(SUM(j.total_population * j.w), 0)          AS school_age_share,
    (SUM(j.children_under_5_pop * j.w) + SUM(j.school_age_pop * j.w))
        / NULLIF(SUM(j.total_population * j.w), 0)          AS children_under_18_share,
    SUM(j.senior_65plus_pop * j.w)
        / NULLIF(SUM(j.total_population * j.w), 0)          AS senior_65plus_share,

    -- ── Race / ethnicity (B02001 + B03003, 2024, all states) ──────────────
    SUM(j.pop_white * j.w)
        / NULLIF(SUM(j.race_total * j.w), 0)                AS pct_white,
    SUM(j.pop_black * j.w)
        / NULLIF(SUM(j.race_total * j.w), 0)                AS pct_black,
    SUM(j.pop_asian * j.w)
        / NULLIF(SUM(j.race_total * j.w), 0)                AS pct_asian,
    SUM(j.pop_hispanic * j.w)
        / NULLIF(SUM(j.hispanic_total * j.w), 0)            AS pct_hispanic,

    -- ── Geographic mobility (B07001, ~234K BGs) ────────────────────────────
    SUM(j.moved_diff_state * j.w)
        / NULLIF(SUM(j.mobility_total * j.w), 0)            AS in_migration_share,
    (SUM(j.mobility_total * j.w) - SUM(j.same_house * j.w))
        / NULLIF(SUM(j.mobility_total * j.w), 0)            AS total_movers_share,
    SUM(j.moved_diff_county_same_state * j.w)
        / NULLIF(SUM(j.mobility_total * j.w), 0)            AS intrastate_mover_share,

    -- ── Commute mode: B08101 coarse (retained for backward compatibility) ──
    SUM(j.public_transit * j.w)
        / NULLIF(SUM(j.commute_total * j.w), 0)             AS transit_commuter_share,
    SUM(j.worked_from_home * j.w)
        / NULLIF(SUM(j.commute_total * j.w), 0)             AS wfh_share,
    SUM(j.drove_alone * j.w)
        / NULLIF(SUM(j.commute_total * j.w), 0)             AS car_dependent_share,

    -- ── Commute detail: B08301 (all-state; use for new feature models) ─────
    SUM(j.drove_alone_det * j.w)
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS drove_alone_share,
    SUM(j.carpool_det * j.w)
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS carpool_share,
    SUM(j.transit_det * j.w)
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS transit_share,
    SUM(j.bicycle_det * j.w)
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS bike_share,
    SUM(j.walked_det * j.w)
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS walk_share,
    (SUM(j.bicycle_det * j.w) + SUM(j.walked_det * j.w))
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS active_commute_share,
    SUM(j.wfh_det * j.w)
        / NULLIF(SUM(j.commute_det_total * j.w), 0)         AS wfh_det_share,

    -- ── Commute time: B08303 (all-state) ───────────────────────────────────
    SUM(j.commute_under_30 * j.w)
        / NULLIF(SUM(j.commute_time_total * j.w), 0)        AS commute_under_30_share,
    (SUM(j.commute_time_total * j.w) - SUM(j.commute_under_30 * j.w))
        / NULLIF(SUM(j.commute_time_total * j.w), 0)        AS commute_30plus_share,
    SUM(j.commute_60plus * j.w)
        / NULLIF(SUM(j.commute_time_total * j.w), 0)        AS commute_60plus_share,

    -- ── Household type: B11001 (all-state) ─────────────────────────────────
    SUM(j.hh_married_couple * j.w)
        / NULLIF(SUM(j.hh_type_total * j.w), 0)             AS married_couple_share,
    SUM(j.hh_family * j.w)
        / NULLIF(SUM(j.hh_type_total * j.w), 0)             AS family_hh_share,
    SUM(j.hh_nonfamily * j.w)
        / NULLIF(SUM(j.hh_type_total * j.w), 0)             AS nonfamily_hh_share,
    SUM(j.hh_single_person * j.w)
        / NULLIF(SUM(j.hh_type_total * j.w), 0)             AS single_person_hh_share,

    -- ── Household size: B11016 (all-state) ─────────────────────────────────
    SUM(j.family_3plus_hh * j.w)
        / NULLIF(SUM(j.hh_size_total * j.w), 0)             AS hh_family_3plus_share,
    SUM(j.nonfamily_1person_hh * j.w)
        / NULLIF(SUM(j.hh_size_total * j.w), 0)             AS hh_1person_share,

    -- ── Rent burden (B25070 — 0 where ACS5 BG rows absent) ───────────────────
    SUM(j.rent_burden_30plus * j.w)
        / NULLIF(SUM(j.rent_burden_universe * j.w), 0)      AS rent_burden_30plus_share,
    SUM(j.rent_burden_50plus * j.w)
        / NULLIF(SUM(j.rent_burden_universe * j.w), 0)      AS rent_burden_50plus_share,
    SUM(j.gross_rent_pct_income * j.w)
        / NULLIF(SUM(j.w), 0)                               AS gross_rent_pct_income_wavg,
    SUM(j.owner_cost_pct_income * j.w)
        / NULLIF(SUM(j.w), 0)                               AS owner_cost_pct_income_wavg,

    -- ── Home value / gross rent (B25077/B25064) ─────────────────────────────
    SUM(j.median_home_value * j.w)
        / NULLIF(SUM(j.w), 0)                               AS median_home_value_wavg,
    SUM(j.median_gross_rent * j.w)
        / NULLIF(SUM(j.w), 0)                               AS median_gross_rent_wavg,

    -- ── Derived: buy-barrier index (home value / renter income) ───────────
    -- When median_home_value is 0 (missing B25077 BG), ratio is 0.
    SUM(j.median_home_value * j.w) / NULLIF(SUM(j.w), 0)
        / NULLIF(SUM(j.median_renter_income * j.w) / NULLIF(SUM(j.w), 0), 0)
                                                             AS home_value_to_renter_income_ratio,

    CURRENT_TIMESTAMP()                                      AS dbt_updated_at

FROM joined AS j
GROUP BY j.cbsa_id, j.h3_r8_hex
