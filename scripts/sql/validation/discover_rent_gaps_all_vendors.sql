-- One-shot rent-gap discovery for snowsql -c pretium (see docs/migration/RENT_FACT_SOURCES_AND_BACKLOG.md).

SHOW TABLES LIKE '%RENT%' IN SCHEMA TRANSFORM.MARKERR;

SELECT 'TRANSFORM.DEV' AS layer, table_name, table_type
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE UPPER(table_schema) = 'DEV'
  AND (
      UPPER(table_name) LIKE '%MARKERR%RENT%'
      OR UPPER(table_name) LIKE 'FACT_MARKERR%'
      OR UPPER(table_name) LIKE 'FACT_%RENT%'
  )
ORDER BY table_name;

SHOW TABLES LIKE 'FACT_MARKERR%' IN SCHEMA TRANSFORM.DEV;
SHOW TABLES LIKE 'FACT_%RENT%' IN SCHEMA TRANSFORM.DEV;

-- Zillow RAW is SOURCE_PROD.ZILLOW (not TRANSFORM.ZILLOW)
SHOW TABLES IN SCHEMA SOURCE_PROD.ZILLOW LIMIT 200;
SHOW TABLES IN SCHEMA TRANSFORM.COSTAR LIMIT 200;

-- Rent-named tables in priority vendor schemas (no error if schema empty / invisible)
SELECT table_schema, table_name, table_type
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE UPPER(table_name) LIKE '%RENT%'
  AND UPPER(table_schema) IN (
      'MARKERR', 'DEV', 'ZILLOW', 'COSTAR',
      'APARTMENT_LIST', 'JBREC', 'GREEN_STREET', 'REALTOR', 'PARCLLABS', 'PARCL'
  )
ORDER BY table_schema, table_name;
