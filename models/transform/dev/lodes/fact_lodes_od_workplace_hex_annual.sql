-- TRANSFORM.DEV.FACT_LODES_OD_WORKPLACE_HEX_ANNUAL — workplace H3 R8 hex inbound job-flow summary (annual).
-- Lineage: `fact_lodes_od_h3_r8_annual` (TRANSFORM.LODES.OD_H3_R8) only — no ANALYTICS.FACTS.
{{ config(
    materialized='table',
    alias='fact_lodes_od_workplace_hex_annual',
    tags=['transform', 'transform_dev', 'h3', 'corridor', 'corridor_h3_transform_dev', 'lodes', 'lehd'],
    cluster_by=['vintage_year', 'cbsa_id'],
) }}

WITH od AS (
    SELECT
        vintage_year,
        h3_r8_workplace,
        h3_r8_residence,
        cbsa_id_workplace                                   AS cbsa_id,
        jobs_total,
        jobs_earnings_se01,
        jobs_earnings_se02,
        jobs_earnings_se03,
        jobs_industry_si01,
        jobs_industry_si02,
        jobs_industry_si03
    FROM {{ ref('fact_lodes_od_h3_r8_annual') }}
    WHERE jobs_total > 0
      AND h3_r8_workplace IS NOT NULL
      AND cbsa_id_workplace IS NOT NULL
),

workplace_totals AS (
    SELECT
        vintage_year,
        h3_r8_workplace,
        cbsa_id,
        SUM(jobs_total)             AS job_inflow_total,
        SUM(jobs_earnings_se01)     AS jobs_earnings_se01,
        SUM(jobs_earnings_se02)     AS jobs_earnings_se02,
        SUM(jobs_earnings_se03)     AS jobs_earnings_se03,
        SUM(jobs_industry_si01)     AS jobs_industry_si01,
        SUM(jobs_industry_si02)     AS jobs_industry_si02,
        SUM(jobs_industry_si03)     AS jobs_industry_si03,
        COUNT(DISTINCT h3_r8_residence) AS commuter_hex_count
    FROM od
    GROUP BY 1, 2, 3
),

commuter_entropy AS (
    SELECT
        od.vintage_year,
        od.h3_r8_workplace,
        -SUM(
            (od.jobs_total::FLOAT / NULLIF(wt.job_inflow_total, 0))
            * LN(NULLIF(od.jobs_total::FLOAT / NULLIF(wt.job_inflow_total, 0), 0))
        )                           AS commuter_shed_diversity
    FROM od
    INNER JOIN workplace_totals AS wt
        ON od.vintage_year     = wt.vintage_year
        AND od.h3_r8_workplace  = wt.h3_r8_workplace
    GROUP BY 1, 2
),

cbsa_baseline AS (
    SELECT
        vintage_year,
        cbsa_id,
        AVG(job_inflow_total)       AS cbsa_avg_job_inflow,
        MEDIAN(job_inflow_total)    AS cbsa_median_job_inflow,
        COUNT(*)                    AS cbsa_occupied_hex_count
    FROM workplace_totals
    WHERE job_inflow_total > 0
    GROUP BY 1, 2
)

SELECT
    wt.vintage_year,
    wt.h3_r8_workplace,
    wt.cbsa_id,

    wt.job_inflow_total,
    wt.commuter_hex_count,

    DIV0(wt.jobs_earnings_se03::FLOAT, NULLIF(wt.job_inflow_total, 0))  AS se03_share,
    DIV0(wt.jobs_earnings_se02::FLOAT, NULLIF(wt.job_inflow_total, 0))  AS se02_share,
    DIV0(wt.jobs_earnings_se01::FLOAT, NULLIF(wt.job_inflow_total, 0))  AS se01_share,

    DIV0(wt.jobs_industry_si01::FLOAT, NULLIF(wt.job_inflow_total, 0))  AS si01_share,
    DIV0(wt.jobs_industry_si02::FLOAT, NULLIF(wt.job_inflow_total, 0))  AS si02_share,
    DIV0(wt.jobs_industry_si03::FLOAT, NULLIF(wt.job_inflow_total, 0))  AS si03_share,

    ce.commuter_shed_diversity,

    cb.cbsa_avg_job_inflow,
    cb.cbsa_median_job_inflow,
    cb.cbsa_occupied_hex_count,
    DIV0(wt.job_inflow_total::FLOAT, NULLIF(cb.cbsa_avg_job_inflow, 0)) AS concentration_ratio,

    wt.jobs_earnings_se01,
    wt.jobs_earnings_se02,
    wt.jobs_earnings_se03,
    wt.jobs_industry_si01,
    wt.jobs_industry_si02,
    wt.jobs_industry_si03,

    CURRENT_TIMESTAMP()                                                  AS dbt_updated_at

FROM workplace_totals AS wt
INNER JOIN commuter_entropy AS ce
    ON wt.vintage_year    = ce.vintage_year
    AND wt.h3_r8_workplace = ce.h3_r8_workplace
INNER JOIN cbsa_baseline AS cb
    ON wt.vintage_year = cb.vintage_year
    AND wt.cbsa_id     = cb.cbsa_id
