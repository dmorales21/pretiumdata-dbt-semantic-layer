-- Pass-through spine parity vs concept_rent_market_monthly:
-- (1) No duplicate natural keys on the concept grain.
-- (2) No concept rows missing from the feature spine on that grain (same join as QA_FEATURE_CONCEPT_PARITY_DIFF).
-- (3) No feature rows missing from concept on that grain.
--
-- Raw COUNT(*) parity can fail when the concept UNION emits duplicate keys; the spine is still a faithful
-- SELECT * pass-through if every distinct key row exists on both sides.
WITH grain AS (
    SELECT
        vendor_code,
        month_start,
        geo_level_code,
        geo_id,
        COALESCE(TO_VARCHAR(metric_id_observe), '') AS metric_id_observe
    FROM {{ ref('concept_rent_market_monthly') }}
),

dup_concept AS (
    SELECT
        vendor_code,
        month_start,
        geo_level_code,
        geo_id,
        metric_id_observe,
        COUNT(*)::BIGINT AS row_cnt
    FROM grain
    GROUP BY 1, 2, 3, 4, 5
    HAVING COUNT(*) > 1
),

missing_in_feature AS (
    SELECT
        'missing_in_feature' AS kind,
        c.vendor_code,
        c.month_start,
        c.geo_level_code,
        c.geo_id,
        COALESCE(TO_VARCHAR(c.metric_id_observe), '') AS metric_id_observe
    FROM {{ ref('concept_rent_market_monthly') }} AS c
    WHERE NOT EXISTS (
        SELECT 1
        FROM {{ ref('feature_rent_market_monthly_spine') }} AS f
        WHERE f.vendor_code = c.vendor_code
          AND f.month_start = c.month_start
          AND f.geo_level_code = c.geo_level_code
          AND f.geo_id = c.geo_id
          AND COALESCE(TO_VARCHAR(f.metric_id_observe), '') = COALESCE(TO_VARCHAR(c.metric_id_observe), '')
    )
),

extra_in_feature AS (
    SELECT
        'extra_in_feature' AS kind,
        f.vendor_code,
        f.month_start,
        f.geo_level_code,
        f.geo_id,
        COALESCE(TO_VARCHAR(f.metric_id_observe), '') AS metric_id_observe
    FROM {{ ref('feature_rent_market_monthly_spine') }} AS f
    WHERE NOT EXISTS (
        SELECT 1
        FROM {{ ref('concept_rent_market_monthly') }} AS c
        WHERE c.vendor_code = f.vendor_code
          AND c.month_start = f.month_start
          AND c.geo_level_code = f.geo_level_code
          AND c.geo_id = f.geo_id
          AND COALESCE(TO_VARCHAR(c.metric_id_observe), '') = COALESCE(TO_VARCHAR(f.metric_id_observe), '')
    )
)

SELECT
    'duplicate_grain_on_concept' AS kind,
    vendor_code,
    month_start,
    geo_level_code,
    geo_id,
    metric_id_observe,
    row_cnt AS detail_row_cnt
FROM dup_concept

UNION ALL

SELECT
    kind,
    vendor_code,
    month_start,
    geo_level_code,
    geo_id,
    metric_id_observe,
    NULL::BIGINT AS detail_row_cnt
FROM missing_in_feature

UNION ALL

SELECT
    kind,
    vendor_code,
    month_start,
    geo_level_code,
    geo_id,
    metric_id_observe,
    NULL::BIGINT AS detail_row_cnt
FROM extra_in_feature
