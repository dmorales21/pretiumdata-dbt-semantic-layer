-- SERVING.DEMO — thin delivery surface; Iceberg / external tables can mirror this view.
SELECT *
FROM {{ ref('concept_rent_market_monthly') }}
