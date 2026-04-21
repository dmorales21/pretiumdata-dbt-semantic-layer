-- Dimensional integrity: REFERENCE.CATALOG seeds (Snowflake) + REFERENCE.GEOGRAPHY when present.
-- Run: snowsql -c pretium -f scripts/sql/validation/dimensional_reference_catalog_and_geography.sql
-- Expect failures = 0 for each check; non-zero rows list upstream seed or model fixes.

-- ---------------------------------------------------------------------------
-- 1) CATALOG — foreign-style keys (dataset → vendor / concept / geo / frequency)
-- ---------------------------------------------------------------------------
SELECT 'CATALOG:dataset.vendor_code missing in vendor' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.dataset d
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.vendor v WHERE v.vendor_code = d.vendor_code
);

SELECT 'CATALOG:dataset.concept_code missing in concept' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.dataset d
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.concept c WHERE c.concept_code = d.concept_code
);

SELECT 'CATALOG:dataset.geo_level_code missing in geo_level' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.dataset d
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.geo_level g WHERE g.geo_level_code = d.geo_level_code
);

SELECT 'CATALOG:dataset.frequency_code missing in frequency' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.dataset d
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.frequency f WHERE f.frequency_code = d.frequency_code
);

-- ---------------------------------------------------------------------------
-- 2) CATALOG — metric spine (when METRIC table matches seed columns)
-- ---------------------------------------------------------------------------
SELECT 'CATALOG:metric.concept_code missing in concept' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.metric m
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.concept c WHERE c.concept_code = m.concept_code
);

SELECT 'CATALOG:metric.vendor_code missing in vendor' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.metric m
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.vendor v WHERE v.vendor_code = m.vendor_code
);

SELECT 'CATALOG:metric.geo_level_code missing in geo_level' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.metric m
WHERE m.geo_level_code IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM reference.catalog.geo_level g WHERE g.geo_level_code = m.geo_level_code
);

SELECT 'CATALOG:metric.frequency_code missing in frequency' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.metric m
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.frequency f WHERE f.frequency_code = m.frequency_code
);

-- ---------------------------------------------------------------------------
-- 3) CATALOG — vendor refresh cadence must resolve to frequency
-- ---------------------------------------------------------------------------
SELECT 'CATALOG:vendor.refresh_cadence missing in frequency' AS check_name, COUNT(*) AS failure_rows
FROM reference.catalog.vendor v
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.frequency f WHERE f.frequency_code = v.refresh_cadence
);

-- ---------------------------------------------------------------------------
-- 4) GEOGRAPHY — dictionary ↔ geo_level (built model; may be empty until dbt run)
-- ---------------------------------------------------------------------------
SELECT 'GEOGRAPHY:level_dictionary.canonical_geo_level_code missing in geo_level' AS check_name, COUNT(*) AS failure_rows
FROM reference.geography.geography_level_dictionary d
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.geo_level g WHERE g.geo_level_code = d.canonical_geo_level_code
);

-- ---------------------------------------------------------------------------
-- 5) GEOGRAPHY — index rows stuck at unmapped (crosswalk gap signal)
-- ---------------------------------------------------------------------------
SELECT 'GEOGRAPHY:index rows with GEO_LEVEL_CODE = unmapped' AS check_name, COUNT(*) AS failure_rows
FROM reference.geography.geography_index i
WHERE UPPER(TRIM(i.geo_level_code)) = 'UNMAPPED';

-- ---------------------------------------------------------------------------
-- 6) GEOGRAPHY — index GEO_LEVEL_CODE must exist in catalog geo_level
-- ---------------------------------------------------------------------------
SELECT 'GEOGRAPHY:index.GEO_LEVEL_CODE missing in catalog geo_level' AS check_name, COUNT(*) AS failure_rows
FROM reference.geography.geography_index i
WHERE NOT EXISTS (
    SELECT 1 FROM reference.catalog.geo_level g WHERE g.geo_level_code = i.geo_level_code
);
