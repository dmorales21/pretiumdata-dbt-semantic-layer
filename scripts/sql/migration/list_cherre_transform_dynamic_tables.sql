-- Cherre — list Snowflake Dynamic Tables in TRANSFORM.CHERRE
-- Run: snowsql -c pretium -f scripts/sql/migration/list_cherre_transform_dynamic_tables.sql
--
-- Note: TRANSFORM.INFORMATION_SCHEMA.TABLES shows every object as BASE TABLE here; it does not
-- flag Dynamic Tables separately on this account build. Use SHOW + RESULT_SCAN (below) or
-- Snowsight → Dynamic Tables filtered by database/schema.

-- All relations in schema (type from INFORMATION_SCHEMA — may all read BASE TABLE)
SELECT table_catalog,
       table_schema,
       table_name,
       table_type,
       row_count,
       bytes,
       last_altered
FROM TRANSFORM.INFORMATION_SCHEMA.TABLES
WHERE table_schema = 'CHERRE'
ORDER BY table_name;

-- Dynamic tables only (compact): run SHOW first, then scan its result set
SHOW DYNAMIC TABLES IN SCHEMA TRANSFORM.CHERRE;

SELECT "name"              AS dynamic_table_name,
       "database_name"    AS database_name,
       "schema_name"       AS schema_name,
       "target_lag"        AS target_lag,
       "refresh_mode"      AS refresh_mode,
       "scheduling_state"  AS scheduling_state,
       "rows"              AS row_count,
       "data_timestamp"    AS data_timestamp
FROM TABLE (RESULT_SCAN (LAST_QUERY_ID ()))
ORDER BY 1;
