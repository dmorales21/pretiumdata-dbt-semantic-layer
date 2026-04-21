-- §A only — TRANSFORM.YARDI table list (batch 012 §1.5 minimum).
-- Export: see docs/migration/artifacts/batch012_yardi/RUNBOOK.md
USE DATABASE TRANSFORM;

SELECT table_catalog, table_schema, table_name, table_type
FROM INFORMATION_SCHEMA.TABLES
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'YARDI'
  AND table_type IN ('BASE TABLE', 'VIEW', 'EXTERNAL TABLE')
ORDER BY table_name;
