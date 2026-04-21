{#-
  MET_044–MET_048 — Markerr CBSA rent, Yardi Matrix DATAVALUE, CoStar SCENARIOS rent columns.

  **Gated:** `semantic_layer_qa_transform_dev_bound_tests: true` in `dbt_project.yml` or `--vars`.
  Requires **`dbt run`** for the four WL_020 read-through views in `TRANSFORM.DEV` first.
-#}
{{ config(
    tags=['catalog_metric_statistical', 'qa'],
    enabled=var('semantic_layer_qa_transform_dev_bound_tests', false),
) }}

WITH
v_met_044 AS (
    SELECT 'MET_044' AS metric_id, 'markerr_avg_rent_effective_usd_window' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_markerr_rent_property_cbsa_monthly') }}
    WHERE avg_rent_effective IS NOT NULL
      AND (avg_rent_effective <= 0 OR avg_rent_effective > 100000 OR avg_rent_effective != avg_rent_effective)
),
v_met_045 AS (
    SELECT 'MET_045' AS metric_id, 'markerr_avg_rent_asking_usd_window' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_markerr_rent_property_cbsa_monthly') }}
    WHERE avg_rent_asking IS NOT NULL
      AND (avg_rent_asking <= 0 OR avg_rent_asking > 100000 OR avg_rent_asking != avg_rent_asking)
),
v_met_046 AS (
    SELECT 'MET_046' AS metric_id, 'yardi_matrix_datavalue_finite_when_numeric' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_yardi_matrix_marketperformance_bh') }}
    WHERE datavalue IS NOT NULL
      AND try_to_double(to_varchar(datavalue)) IS NOT NULL
      AND (abs(try_to_double(to_varchar(datavalue))) > 1e18
           OR try_to_double(to_varchar(datavalue)) != try_to_double(to_varchar(datavalue)))
),
v_met_047 AS (
    SELECT 'MET_047' AS metric_id, 'costar_market_effective_rent_per_unit_window' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_costar_scenarios') }}
    WHERE market_effective_rent_per_unit IS NOT NULL
      AND (market_effective_rent_per_unit < 0 OR market_effective_rent_per_unit > 50000
           OR market_effective_rent_per_unit != market_effective_rent_per_unit)
),
v_met_048 AS (
    SELECT 'MET_048' AS metric_id, 'costar_market_asking_rent_per_unit_window' AS check_name, COUNT(*) AS violation_rows
    FROM {{ ref('fact_costar_scenarios') }}
    WHERE market_asking_rent_per_unit IS NOT NULL
      AND (market_asking_rent_per_unit < 0 OR market_asking_rent_per_unit > 50000
           OR market_asking_rent_per_unit != market_asking_rent_per_unit)
),
combined AS (
    SELECT * FROM v_met_044
    UNION ALL SELECT * FROM v_met_045
    UNION ALL SELECT * FROM v_met_046
    UNION ALL SELECT * FROM v_met_047
    UNION ALL SELECT * FROM v_met_048
)

SELECT metric_id, check_name, violation_rows
FROM combined
WHERE violation_rows > 0
