-- =============================================================================
-- Spot-check TRANSFORM.DEV concept_progress_* columns registered in catalog seeds
-- (MET_029–MET_040): alias spelling, type, nullability before relying on lineage.
-- Run from pretiumdata-dbt-semantic-layer repo root (mirror in pretium-ai-dbt same path):
--   snowsql -c pretium -f scripts/sql/validation/describe_concept_progress_catalog_shortlist.sql
-- =============================================================================

DESCRIBE TABLE TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY;
DESCRIBE TABLE TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW;

-- Non-null counts for starter-metric aliases (snowflake_column in metric.csv)
SELECT
    'CONCEPT_PROGRESS_PROPERTY' AS table_name,
    COUNT(*) AS row_count,
    COUNT("sf_properties__PROPERTYNUMBER__C") AS sf_properties__PROPERTYNUMBER__C,
    COUNT("sf_properties__CAP_RATE__C") AS sf_properties__CAP_RATE__C,
    COUNT("sf_properties__GROSS_YIELD__C") AS sf_properties__GROSS_YIELD__C,
    COUNT("sf_properties__HOME_CONDITION_SCORE__C") AS sf_properties__HOME_CONDITION_SCORE__C,
    COUNT("yardi_propattr__TIER") AS yardi_propattr__TIER,
    COUNT("yardi_propattr__PROPERTY_STATUS") AS yardi_propattr__PROPERTY_STATUS
FROM TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY;

SELECT
    'CONCEPT_PROGRESS_ACQUISITION_UW' AS table_name,
    COUNT(*) AS row_count,
    COUNT("acquisition__PURCHASE_PRICE__C") AS acquisition__PURCHASE_PRICE__C,
    COUNT("acquisition__CAP_RATE__C") AS acquisition__CAP_RATE__C,
    COUNT("acquisition__NET_YIELD__C") AS acquisition__NET_YIELD__C,
    COUNT("fdd__PURCHASE_PRICE__C") AS fdd__PURCHASE_PRICE__C,
    COUNT("fdd__CLOSING_DATE__C") AS fdd__CLOSING_DATE__C,
    COUNT("fdd__STABILIZED__C") AS fdd__STABILIZED__C
FROM TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW;
