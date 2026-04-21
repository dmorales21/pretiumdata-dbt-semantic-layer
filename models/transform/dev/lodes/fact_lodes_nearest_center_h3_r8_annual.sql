-- TRANSFORM.DEV.FACT_LODES_NEAREST_CENTER_H3_R8_ANNUAL — nearest employment-center distance by H3 R8 hex (annual).
-- Lineage: `ref_corridor_employment_centers` + BG→H3 bridge (`source('h3_polyfill_bridges','bridge_bg_h3_r8_polyfill')` → BLOCKGROUP_H3_R8_POLYFILL; vars `h3_polyfill_bridge_*`) — no ANALYTICS.FACTS.
{{ config(
    materialized='table',
    alias='fact_lodes_nearest_center_h3_r8_annual',
    tags=['transform', 'transform_dev', 'h3', 'corridor', 'corridor_h3_transform_dev', 'lodes', 'employment_centers'],
    cluster_by=['vintage_year', 'cbsa_id'],
) }}

WITH cbsa_hexes AS (
    SELECT DISTINCT
        cbsa_id,
        h3_r8_hex
    FROM {{ source('h3_polyfill_bridges', 'bridge_bg_h3_r8_polyfill') }}
    WHERE h3_r8_hex IS NOT NULL
      AND cbsa_id   IS NOT NULL
),

centers AS (
    SELECT
        vintage_year,
        cbsa_id,
        h3_r8_hex                   AS center_hex,
        center_type,
        center_strength_score
    FROM {{ ref('ref_corridor_employment_centers') }}
    WHERE is_center = TRUE
),

hex_center_pairs AS (
    SELECT
        c.vintage_year,
        h.cbsa_id,
        h.h3_r8_hex,
        c.center_hex,
        c.center_type,
        c.center_strength_score,
        H3_GRID_DISTANCE(h.h3_r8_hex::VARCHAR, c.center_hex::VARCHAR) AS grid_dist
    FROM cbsa_hexes AS h
    INNER JOIN centers AS c
        ON h.cbsa_id = c.cbsa_id
    WHERE h.h3_r8_hex <> c.center_hex
),

nearest_dist AS (
    SELECT
        vintage_year,
        cbsa_id,
        h3_r8_hex,
        MIN(grid_dist)                                                          AS dist_nearest_any_center,
        MIN(CASE WHEN center_type = 'HIGH_WAGE_OFFICE'    THEN grid_dist END)  AS dist_nearest_high_wage_office,
        MIN(CASE WHEN center_type = 'SUBURBAN_COMMERCIAL' THEN grid_dist END)  AS dist_nearest_suburban_commercial,
        MIN(CASE WHEN center_type = 'MIXED_URBAN'         THEN grid_dist END)  AS dist_nearest_mixed_urban,
        MIN(CASE WHEN center_type = 'GOODS_PRODUCING'     THEN grid_dist END)  AS dist_nearest_goods_producing
    FROM hex_center_pairs
    GROUP BY 1, 2, 3
),

nearest_strength AS (
    SELECT
        p.vintage_year,
        p.cbsa_id,
        p.h3_r8_hex,
        MAX(CASE WHEN p.center_type = 'HIGH_WAGE_OFFICE'
                  AND p.grid_dist = nd.dist_nearest_high_wage_office
                 THEN p.center_strength_score END)      AS strength_nearest_high_wage_office,
        MAX(CASE WHEN p.center_type = 'SUBURBAN_COMMERCIAL'
                  AND p.grid_dist = nd.dist_nearest_suburban_commercial
                 THEN p.center_strength_score END)      AS strength_nearest_suburban_commercial,
        MAX(CASE WHEN p.center_type = 'MIXED_URBAN'
                  AND p.grid_dist = nd.dist_nearest_mixed_urban
                 THEN p.center_strength_score END)      AS strength_nearest_mixed_urban,
        MAX(CASE WHEN p.grid_dist = nd.dist_nearest_any_center
                 THEN p.center_strength_score END)      AS strength_nearest_any_center
    FROM hex_center_pairs AS p
    INNER JOIN nearest_dist AS nd
        ON  p.vintage_year = nd.vintage_year
        AND p.cbsa_id      = nd.cbsa_id
        AND p.h3_r8_hex    = nd.h3_r8_hex
    GROUP BY 1, 2, 3
)

SELECT
    nd.vintage_year,
    nd.cbsa_id,
    nd.h3_r8_hex,

    nd.dist_nearest_any_center,
    nd.dist_nearest_high_wage_office,
    nd.dist_nearest_suburban_commercial,
    nd.dist_nearest_mixed_urban,
    nd.dist_nearest_goods_producing,

    CASE
        WHEN nd.dist_nearest_high_wage_office IS NULL THEN nd.dist_nearest_mixed_urban
        WHEN nd.dist_nearest_mixed_urban IS NULL      THEN nd.dist_nearest_high_wage_office
        ELSE LEAST(nd.dist_nearest_high_wage_office, nd.dist_nearest_mixed_urban)
    END                                                     AS dist_nearest_urban_center,

    CASE
        WHEN nd.dist_nearest_high_wage_office IS NULL     THEN nd.dist_nearest_suburban_commercial
        WHEN nd.dist_nearest_suburban_commercial IS NULL  THEN nd.dist_nearest_high_wage_office
        ELSE LEAST(nd.dist_nearest_high_wage_office, nd.dist_nearest_suburban_commercial)
    END                                                     AS dist_nearest_professional_center,

    ns.strength_nearest_any_center,
    ns.strength_nearest_high_wage_office,
    ns.strength_nearest_suburban_commercial,
    ns.strength_nearest_mixed_urban,

    CASE
        WHEN nd.dist_nearest_high_wage_office IS NULL THEN ns.strength_nearest_mixed_urban
        WHEN nd.dist_nearest_mixed_urban IS NULL      THEN ns.strength_nearest_high_wage_office
        WHEN nd.dist_nearest_high_wage_office <= nd.dist_nearest_mixed_urban
            THEN ns.strength_nearest_high_wage_office
        ELSE ns.strength_nearest_mixed_urban
    END                                                     AS strength_nearest_urban_center,

    CURRENT_TIMESTAMP()                                     AS dbt_updated_at

FROM nearest_dist AS nd
INNER JOIN nearest_strength AS ns
    ON  nd.vintage_year = ns.vintage_year
    AND nd.cbsa_id      = ns.cbsa_id
    AND nd.h3_r8_hex    = ns.h3_r8_hex
