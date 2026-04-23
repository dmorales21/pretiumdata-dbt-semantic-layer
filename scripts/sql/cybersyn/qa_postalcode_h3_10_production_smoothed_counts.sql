-- Quick QA after build_reference_postalcode_h3_10_production_smoothed.sql
USE DATABASE REFERENCE;
USE SCHEMA GEOGRAPHY;

SELECT smoothing_action, COUNT(*) AS cell_count
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_PRODUCTION_SMOOTHED
GROUP BY 1
ORDER BY 2 DESC;

SELECT
    COUNT_IF(postal_code_modeled <> postal_code_production) AS cells_reassigned,
    COUNT(*) AS total_cells,
    ROUND(100.0 * cells_reassigned / NULLIF(total_cells, 0), 4) AS pct_reassigned
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_PRODUCTION_SMOOTHED;
