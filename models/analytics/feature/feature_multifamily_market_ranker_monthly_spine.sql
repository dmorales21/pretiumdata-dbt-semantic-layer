{#-
  **Multifamily market ranker** — county × month **FEATURE_** panel (ANALYTICS).

  **FACT_** in **TRANSFORM.DEV** stays vendor-native (clean/rename/roll-up only). This model **assembles**
  multiple corridor **FACT_** / sources plus **ref('fact_bls_laus_county')** at Markerr county-month grain.

  **Driver grain:** ``FACT_MARKERR_RENT_COUNTY_MONTHLY``.

  **Joins:** Cherre stock county, Cherre MF county snapshot, RCA MF construction county monthly,
  ACS demographics county (2024 vintage), BLS LAUS county (unemployment).

  **Light feature work here:** ``rent_mom_pct_change``, ``avg_concession_mom_pct_change`` from Markerr medians / concession rate.

  **Catalog:** ``concept_code = 'multifamily_market'`` is **REFERENCE.CATALOG** bundle vocabulary for metrics/UI — not a physical **`CONCEPT_*`** union table.

  **Placeholders (NULL until MODEL_* / app contracts):** ``market_phase``, ``pretium_score``, ``custom_score``, ``rent_trend_flag``.

  **Note:** ``avg_asking_rent`` aliases Markerr **median** asking rent (UI label vs column name documented on metric rows).
-#}

{{ config(
    materialized='table',
    alias='feature_multifamily_market_ranker_monthly',
    tags=['analytics', 'feature', 'multifamily_market', 'mfr_ranker', 'markerr', 'cherre', 'rca', 'census', 'bls'],
) }}

WITH mr_base AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(m.county_fips)), 5, '0') AS county_fips,
        LPAD(TRIM(TO_VARCHAR(m.cbsa_id)), 5, '0') AS cbsa_id,
        DATE_TRUNC(
            'month',
            COALESCE(
                TRY_TO_DATE(TO_VARCHAR(m.as_of_month)),
                TRY_TO_DATE(TO_VARCHAR(m.AS_OF_MONTH))
            )
        )::DATE AS month_start,
        COALESCE(
            TRY_TO_DOUBLE(TO_VARCHAR(m.median_rent_asking)),
            TRY_TO_DOUBLE(TO_VARCHAR(m.MEDIAN_RENT_ASKING))
        ) AS median_rent_asking,
        COALESCE(
            TRY_TO_DOUBLE(TO_VARCHAR(m.concession_rate)),
            TRY_TO_DOUBLE(TO_VARCHAR(m.CONCESSION_RATE))
        ) AS concession_rate
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_markerr_rent_county_monthly') }} AS m
    WHERE COALESCE(
            TRIM(TO_VARCHAR(m.county_fips)),
            TRIM(TO_VARCHAR(m.COUNTY_FIPS))
        ) IS NOT NULL
      AND TRIM(COALESCE(TO_VARCHAR(m.county_fips), TO_VARCHAR(m.COUNTY_FIPS))) != ''
      AND COALESCE(
            TRY_TO_DATE(TO_VARCHAR(m.as_of_month)),
            TRY_TO_DATE(TO_VARCHAR(m.AS_OF_MONTH))
        ) IS NOT NULL
),

mr_lagged AS (
    SELECT
        b.*,
        LAG(b.median_rent_asking) OVER (
            PARTITION BY b.county_fips
            ORDER BY b.month_start
        ) AS prev_median_rent_asking,
        LAG(b.concession_rate) OVER (
            PARTITION BY b.county_fips
            ORDER BY b.month_start
        ) AS prev_concession_rate
    FROM mr_base AS b
),

mr AS (
    SELECT
        county_fips,
        cbsa_id,
        month_start,
        median_rent_asking,
        DIV0(median_rent_asking - prev_median_rent_asking, prev_median_rent_asking) * 100.0::DOUBLE
            AS rent_mom_pct_change,
        median_rent_asking AS avg_asking_rent,
        DIV0(concession_rate - prev_concession_rate, NULLIF(prev_concession_rate, 0)) * 100.0::DOUBLE
            AS avg_concession_mom_pct_change
    FROM mr_lagged
),

stock AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(s.county_fips)), 5, '0') AS county_fips,
        COALESCE(
            TRY_TO_DOUBLE(TO_VARCHAR(s.median_market_ppsf)),
            TRY_TO_DOUBLE(TO_VARCHAR(s.MEDIAN_MARKET_PPSF))
        ) AS median_market_ppsf
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_cherre_stock_county') }} AS s
    WHERE COALESCE(
            TRIM(TO_VARCHAR(s.county_fips)),
            TRIM(TO_VARCHAR(s.COUNTY_FIPS))
        ) IS NOT NULL
),

mf_snap AS (
    SELECT
        county_fips,
        units_garden,
        pct_pre_1980
    FROM (
        SELECT
            LPAD(TRIM(TO_VARCHAR(f.county_fips)), 5, '0') AS county_fips,
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(f.units_garden)),
                TRY_TO_DOUBLE(TO_VARCHAR(f.UNITS_GARDEN))
            ) AS units_garden,
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(f.pct_pre_1980)),
                TRY_TO_DOUBLE(TO_VARCHAR(f.PCT_PRE_1980))
            ) AS pct_pre_1980,
            ROW_NUMBER() OVER (
                PARTITION BY LPAD(TRIM(TO_VARCHAR(f.county_fips)), 5, '0')
                ORDER BY LPAD(TRIM(TO_VARCHAR(f.cbsa_id)), 5, '0')
            ) AS rn
        FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_cherre_mf_county_snapshot') }} AS f
        WHERE COALESCE(
                TRIM(TO_VARCHAR(f.county_fips)),
                TRIM(TO_VARCHAR(f.COUNTY_FIPS))
            ) IS NOT NULL
    ) AS x
    WHERE rn = 1
),

rca AS (
    SELECT
        LPAD(TRIM(TO_VARCHAR(c.county_fips)), 5, '0') AS county_fips,
        DATE_TRUNC(
            'month',
            COALESCE(
                TRY_TO_DATE(TO_VARCHAR(c.as_of_month)),
                TRY_TO_DATE(TO_VARCHAR(c.AS_OF_MONTH))
            )
        )::DATE AS month_start,
        MAX(
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(c.median_months_to_completion)),
                TRY_TO_DOUBLE(TO_VARCHAR(c.MEDIAN_MONTHS_TO_COMPLETION))
            )
        ) AS median_months_to_completion,
        SUM(
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(c.units_under_construction)),
                TRY_TO_DOUBLE(TO_VARCHAR(c.UNITS_UNDER_CONSTRUCTION)),
                0::DOUBLE
            )
        )::DOUBLE AS units_under_construction
    FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_rca_mf_construction_county_monthly') }} AS c
    WHERE COALESCE(
            TRIM(TO_VARCHAR(c.county_fips)),
            TRIM(TO_VARCHAR(c.COUNTY_FIPS))
        ) IS NOT NULL
      AND COALESCE(
            TRY_TO_DATE(TO_VARCHAR(c.as_of_month)),
            TRY_TO_DATE(TO_VARCHAR(c.AS_OF_MONTH))
        ) IS NOT NULL
    GROUP BY 1, 2
),

acs AS (
    SELECT
        county_fips,
        total_households,
        pct_25_44,
        renter_share,
        rent_burden_30_plus_share
    FROM (
        SELECT
            LPAD(TRIM(TO_VARCHAR(a.county_fips)), 5, '0') AS county_fips,
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(a.total_households)),
                TRY_TO_DOUBLE(TO_VARCHAR(a.TOTAL_HOUSEHOLDS))
            )::DOUBLE AS total_households,
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(a.pct_25_44)),
                TRY_TO_DOUBLE(TO_VARCHAR(a.PCT_25_44))
            )::DOUBLE AS pct_25_44,
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(a.renter_share)),
                TRY_TO_DOUBLE(TO_VARCHAR(a.RENTER_SHARE))
            )::DOUBLE AS renter_share,
            COALESCE(
                TRY_TO_DOUBLE(TO_VARCHAR(a.rent_burden_30_plus_share)),
                TRY_TO_DOUBLE(TO_VARCHAR(a.RENT_BURDEN_30_PLUS_SHARE))
            )::DOUBLE AS rent_burden_30_plus_share,
            ROW_NUMBER() OVER (
                PARTITION BY LPAD(TRIM(TO_VARCHAR(a.county_fips)), 5, '0')
                ORDER BY LPAD(TRIM(TO_VARCHAR(a.cbsa_id)), 5, '0')
            ) AS rn
        FROM {{ source('transform_dev_corridor_transaction_facts', 'fact_acs_demographics_county') }} AS a
        WHERE COALESCE(
                TRY_TO_NUMBER(TO_VARCHAR(a.acs_year)),
                TRY_TO_NUMBER(TO_VARCHAR(a.ACS_YEAR))
            ) = 2024
          AND COALESCE(
                TRIM(TO_VARCHAR(a.county_fips)),
                TRIM(TO_VARCHAR(a.COUNTY_FIPS))
            ) IS NOT NULL
    ) AS z
    WHERE rn = 1
),

laus AS (
    SELECT
        DATE_TRUNC('month', TRY_TO_DATE(TO_VARCHAR(l.date_reference)))::DATE AS month_start,
        LPAD(TRIM(TO_VARCHAR(l.county_fips)), 5, '0') AS county_fips,
        TRY_TO_DOUBLE(TO_VARCHAR(l.value))::DOUBLE AS unemployment_rate
    FROM {{ ref('fact_bls_laus_county') }} AS l
    WHERE l.date_reference IS NOT NULL
      AND l.county_fips IS NOT NULL
      AND TRY_TO_NUMBER(TO_VARCHAR(l.measure_code)) = 3
      AND l.value IS NOT NULL
)

SELECT
    'multifamily_market' AS concept_code,
    'MF_RANKER_BUNDLE' AS vendor_code,
    mr.month_start,
    'county' AS geo_level_code,
    mr.county_fips AS geo_id,
    mr.cbsa_id,
    SUBSTRING(mr.county_fips, 1, 2) AS state_fips,
    mr.rent_mom_pct_change,
    mr.avg_asking_rent,
    mr.avg_concession_mom_pct_change,
    s.median_market_ppsf,
    CAST(NULL AS VARCHAR(64)) AS market_phase,
    r.median_months_to_completion,
    m.units_garden,
    r.units_under_construction,
    ac.total_households,
    m.pct_pre_1980,
    ac.renter_share,
    ac.pct_25_44,
    ac.rent_burden_30_plus_share,
    u.unemployment_rate,
    CAST(NULL AS DOUBLE) AS pretium_score,
    CAST(NULL AS DOUBLE) AS custom_score,
    CAST(NULL AS VARCHAR(32)) AS rent_trend_flag,
    CURRENT_TIMESTAMP() AS dbt_updated_at
FROM mr
LEFT JOIN stock AS s
    ON mr.county_fips = s.county_fips
LEFT JOIN mf_snap AS m
    ON mr.county_fips = m.county_fips
LEFT JOIN rca AS r
    ON mr.county_fips = r.county_fips
   AND mr.month_start = r.month_start
LEFT JOIN acs AS ac
    ON mr.county_fips = ac.county_fips
LEFT JOIN laus AS u
    ON mr.county_fips = u.county_fips
   AND mr.month_start = u.month_start
