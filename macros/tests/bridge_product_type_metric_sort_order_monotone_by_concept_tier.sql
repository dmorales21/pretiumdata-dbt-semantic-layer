{#-
  Generic data test (seed-safe): `bridge_product_type_metric.sort_order` must not move to a
  **lower** `concept_definition_package.bridge_sort_tier` as `sort_order` increases, for the
  governed **active** bundle (`is_active = 1`).

  Inactive tail rows (`is_active = 0`) are excluded: they are parked after the active spine and
  may repeat earlier narrative tiers without implying a regression in the primary bundle order.

  Prerequisites: `dbt seed --select path:seeds/reference/catalog` (refs `metric`, `concept_definition_package`).
-#}
{% test bridge_product_type_metric_sort_order_monotone_by_concept_tier(model) %}

WITH enriched AS (
    SELECT
        b.bridge_product_type_metric_id,
        b.product_type_code,
        b.metric_code,
        b.sort_order,
        p.bridge_sort_tier
    FROM {{ model }} AS b
    INNER JOIN {{ ref('metric') }} AS m
        ON m.metric_code = b.metric_code
    INNER JOIN {{ ref('concept_definition_package') }} AS p
        ON p.concept_code = m.concept_code
    WHERE COALESCE(
            TRY_TO_NUMBER(TO_VARCHAR(b.is_active)),
            CASE
                WHEN UPPER(TRIM(TO_VARCHAR(b.is_active))) IN ('TRUE', 'T', 'Y', 'YES') THEN 1
                WHEN UPPER(TRIM(TO_VARCHAR(b.is_active))) IN ('FALSE', 'F', 'N', 'NO') THEN 0
                ELSE NULL
            END
        ) = 1
),

ordered AS (
    SELECT
        bridge_product_type_metric_id,
        product_type_code,
        metric_code,
        sort_order,
        bridge_sort_tier,
        LAG(bridge_sort_tier) OVER (
            PARTITION BY product_type_code
            ORDER BY sort_order, bridge_product_type_metric_id
        ) AS prev_bridge_sort_tier,
        LAG(metric_code) OVER (
            PARTITION BY product_type_code
            ORDER BY sort_order, bridge_product_type_metric_id
        ) AS prev_metric_code,
        LAG(sort_order) OVER (
            PARTITION BY product_type_code
            ORDER BY sort_order, bridge_product_type_metric_id
        ) AS prev_sort_order
    FROM enriched
)

SELECT
    product_type_code,
    prev_sort_order,
    sort_order,
    prev_metric_code,
    metric_code,
    prev_bridge_sort_tier,
    bridge_sort_tier
FROM ordered
WHERE prev_bridge_sort_tier IS NOT NULL
  AND bridge_sort_tier < prev_bridge_sort_tier

{% endtest %}
