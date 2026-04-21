-- §B only — TRANSFORM.YARDI columns (large; batch 012 §1.5 minimum).
-- Export: see docs/migration/artifacts/batch012_yardi/RUNBOOK.md
USE DATABASE TRANSFORM;

SELECT table_schema, table_name, ordinal_position, column_name, data_type, is_nullable
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_catalog = 'TRANSFORM'
  AND UPPER(table_schema) = 'YARDI'
ORDER BY table_name, ordinal_position;
