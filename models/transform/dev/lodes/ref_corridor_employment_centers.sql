-- TRANSFORM.DEV.REF_CORRIDOR_EMPLOYMENT_CENTERS — H3 R8 employment center classification (annual).
-- Lineage: `fact_lodes_od_workplace_hex_annual` only — no ANALYTICS.FACTS / analytics.reference.
{{ config(
    materialized='table',
    alias='ref_corridor_employment_centers',
    tags=['transform', 'transform_dev', 'h3', 'corridor', 'corridor_h3_transform_dev', 'lodes', 'lehd', 'employment_centers'],
    cluster_by=['vintage_year', 'cbsa_id'],
) }}

WITH workplace AS (
    SELECT
        vintage_year,
        h3_r8_workplace                     AS h3_r8_hex,
        cbsa_id,
        job_inflow_total,
        concentration_ratio,
        se03_share,
        se01_share,
        si01_share,
        si02_share,
        si03_share,
        commuter_shed_diversity,
        commuter_hex_count,
        cbsa_avg_job_inflow
    FROM {{ ref('fact_lodes_od_workplace_hex_annual') }}
    WHERE job_inflow_total > 0
),

kring_neighbors AS (
    SELECT
        w.vintage_year,
        w.h3_r8_hex                                         AS focal_hex,
        LOWER(TRIM(TO_VARCHAR(n.value)))                    AS neighbor_hex
    FROM workplace AS w,
    LATERAL FLATTEN(INPUT => H3_GRID_DISK(w.h3_r8_hex::VARCHAR, 2)) AS n
    WHERE LOWER(TRIM(TO_VARCHAR(n.value))) <> LOWER(TRIM(TO_VARCHAR(w.h3_r8_hex)))
),

neighbor_max AS (
    SELECT
        kn.vintage_year,
        kn.focal_hex,
        MAX(wn.job_inflow_total)            AS max_neighbor_inflow,
        COUNT(wn.h3_r8_hex)                 AS occupied_neighbor_count
    FROM kring_neighbors AS kn
    INNER JOIN workplace AS wn
        ON kn.vintage_year  = wn.vintage_year
        AND kn.neighbor_hex  = wn.h3_r8_hex
    GROUP BY 1, 2
),

classified AS (
    SELECT
        w.vintage_year,
        w.h3_r8_hex,
        w.cbsa_id,
        w.job_inflow_total,
        w.concentration_ratio,
        w.se03_share,
        w.se01_share,
        w.si01_share,
        w.si02_share,
        w.si03_share,
        w.commuter_shed_diversity,
        w.commuter_hex_count,
        nm.max_neighbor_inflow,
        nm.occupied_neighbor_count,

        COALESCE(w.job_inflow_total >= nm.max_neighbor_inflow, TRUE)    AS is_local_max,

        w.concentration_ratio >= 2.0                                    AS exceeds_ratio,

        COALESCE(w.job_inflow_total >= nm.max_neighbor_inflow, TRUE)
            AND w.concentration_ratio >= 2.0                            AS is_center,

        GREATEST(
            DIV0(w.job_inflow_total - COALESCE(nm.max_neighbor_inflow, 0),
                 NULLIF(COALESCE(nm.max_neighbor_inflow, w.job_inflow_total), 0)),
            0.0
        )                                                                AS excess_vs_local_max_pct,

        w.concentration_ratio
            * (1 + GREATEST(
                DIV0(w.job_inflow_total - COALESCE(nm.max_neighbor_inflow, 0),
                     NULLIF(COALESCE(nm.max_neighbor_inflow, w.job_inflow_total), 0)),
                0.0
            ))                                                           AS center_strength_score

    FROM workplace AS w
    LEFT JOIN neighbor_max AS nm
        ON w.vintage_year = nm.vintage_year
        AND w.h3_r8_hex   = nm.focal_hex
)

SELECT
    vintage_year,
    h3_r8_hex,
    cbsa_id,
    is_center,
    is_local_max,
    exceeds_ratio,

    CASE
        WHEN si01_share  > 0.40
             THEN 'GOODS_PRODUCING'
        WHEN se03_share  > 0.40 AND si03_share > 0.50
             THEN 'HIGH_WAGE_OFFICE'
        WHEN si02_share  > 0.30 AND se03_share < 0.35
             THEN 'SUBURBAN_COMMERCIAL'
        ELSE 'MIXED_URBAN'
    END                                                                  AS center_type,

    center_strength_score,
    concentration_ratio,
    excess_vs_local_max_pct,

    job_inflow_total,
    max_neighbor_inflow,
    occupied_neighbor_count,
    commuter_shed_diversity,
    commuter_hex_count,
    se03_share,
    si01_share,
    si02_share,
    si03_share,

    CURRENT_TIMESTAMP()                                                  AS dbt_updated_at

FROM classified
