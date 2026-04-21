-- TRANSFORM.DEV.FACT_LODES_H3R8_WORKPLACE_GRAVITY — BG OD area-weighted to H3 R8 workplace hex (annual).
-- Lineage: TRANSFORM.LODES.OD_BG + H3 polyfill bridge (default REFERENCE.GEOGRAPHY; vars `h3_polyfill_bridge_*`) — no ANALYTICS.FACTS.
{{ config(
    materialized='table',
    alias='fact_lodes_h3r8_workplace_gravity',
    tags=['transform', 'transform_dev', 'h3', 'corridor', 'corridor_h3_transform_dev', 'lodes', 'lehd'],
    cluster_by=['vintage_year', 'cbsa_id'],
) }}

WITH lodes AS (
    SELECT
        vintage_year,
        geo_id_workplace_block_group,
        geo_id_residence_block_group,
        jobs_total,
        jobs_earnings_se01,
        jobs_earnings_se02,
        jobs_earnings_se03,
        jobs_industry_si01,
        jobs_industry_si02,
        jobs_industry_si03
    FROM {{ source('transform_lodes', 'od_bg') }}
),

bridge AS (
    SELECT
        bg_geoid,
        cbsa_id,
        h3_r8_hex,
        weight
    FROM {{ source('h3_polyfill_bridges', 'bridge_bg_h3_r8_polyfill') }}
    WHERE cbsa_id IS NOT NULL
      AND weight  > 0
),

weighted AS (
    SELECT
        l.vintage_year,
        b.cbsa_id,
        b.h3_r8_hex,

        SUM(l.jobs_total          * b.weight)  AS job_inflow_total,
        SUM(l.jobs_earnings_se01  * b.weight)  AS jobs_se01,
        SUM(l.jobs_earnings_se02  * b.weight)  AS jobs_se02,
        SUM(l.jobs_earnings_se03  * b.weight)  AS jobs_se03,
        SUM(l.jobs_industry_si01  * b.weight)  AS jobs_goods,
        SUM(l.jobs_industry_si02  * b.weight)  AS jobs_trade_transport,
        SUM(l.jobs_industry_si03  * b.weight)  AS jobs_services,

        COUNT(DISTINCT l.geo_id_residence_block_group) AS commuter_bg_count

    FROM lodes AS l
    INNER JOIN bridge AS b ON l.geo_id_workplace_block_group = b.bg_geoid
    GROUP BY l.vintage_year, b.cbsa_id, b.h3_r8_hex
)

SELECT
    vintage_year,
    cbsa_id,
    h3_r8_hex,

    GREATEST(job_inflow_total, 0)  AS job_inflow_total,
    GREATEST(jobs_se01, 0)         AS jobs_se01,
    GREATEST(jobs_se02, 0)         AS jobs_se02,
    GREATEST(jobs_se03, 0)         AS jobs_se03,
    GREATEST(jobs_goods, 0)        AS jobs_goods,
    GREATEST(jobs_trade_transport, 0) AS jobs_trade_transport,
    GREATEST(jobs_services, 0)     AS jobs_services,
    commuter_bg_count,

    LN(GREATEST(job_inflow_total, 0) + 1.0)              AS log_job_inflow,

    COALESCE(
        GREATEST(jobs_se03, 0) / NULLIF(GREATEST(job_inflow_total, 0), 0),
        0.0
    )                                                     AS se03_share,

    COALESCE(
        GREATEST(jobs_services, 0) / NULLIF(GREATEST(job_inflow_total, 0), 0),
        0.0
    )                                                     AS si03_share,

    COALESCE(
        GREATEST(jobs_goods, 0) / NULLIF(GREATEST(job_inflow_total, 0), 0),
        0.0
    )                                                     AS si01_share,

    CURRENT_TIMESTAMP()                                   AS dbt_updated_at

FROM weighted
