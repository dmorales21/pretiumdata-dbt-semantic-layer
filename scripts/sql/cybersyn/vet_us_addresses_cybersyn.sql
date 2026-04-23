-- Quick vet: source shape, null rates on geo/ZIP, row scale (snowsql -c pretium -f …)

USE DATABASE US_REAL_ESTATE;
USE SCHEMA CYBERSYN;

SELECT 'US_ADDRESSES row count (full)' AS metric, COUNT(*) AS value
FROM US_REAL_ESTATE.CYBERSYN.US_ADDRESSES
UNION ALL
SELECT 'rows with lat+long+zip', COUNT(*)
FROM US_REAL_ESTATE.CYBERSYN.US_ADDRESSES
WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND zip IS NOT NULL AND TRIM(TO_VARCHAR(zip)) <> ''
UNION ALL
SELECT 'POI_REL current-ish rows', COUNT(*)
FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS
WHERE relationship_end_date IS NULL OR relationship_end_date >= CURRENT_DATE();

SELECT
    COUNT(DISTINCT address_id) AS distinct_address_id,
    COUNT(*) AS row_cnt,
    COUNT(*) - COUNT(DISTINCT address_id) AS dup_rows_if_any
FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS
WHERE relationship_end_date IS NULL OR relationship_end_date >= CURRENT_DATE();

SELECT H3_LATLNG_TO_CELL(40.7128::FLOAT, -74.0060::FLOAT, 10) AS sample_h3_10;
