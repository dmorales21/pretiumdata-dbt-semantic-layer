-- Discovery: Markerr rent-related objects in Snowflake (run with snowsql -c pretium).
-- Use output to confirm identifiers before editing models/sources/sources_transform_markerr.yml.

SHOW TABLES LIKE '%RENT%' IN SCHEMA TRANSFORM.MARKERR;

SELECT 'TRANSFORM.DEV' AS layer, table_name, table_type
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE UPPER(table_schema) = 'DEV'
  AND (
      UPPER(table_name) LIKE '%MARKERR%RENT%'
      OR UPPER(table_name) LIKE 'FACT_MARKERR%'
  )
ORDER BY table_name;
