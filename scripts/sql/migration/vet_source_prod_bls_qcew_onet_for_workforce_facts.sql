-- =============================================================================
-- Vet SOURCE_PROD BLS QCEW + DOL O*NET for workforce FACT migration
--
-- Purpose: Row counts, column presence, geography sanity, duplicate-grain probes,
--   null-rate hints on key metrics — before/after `dbt run -s fact_bls_qcew_county_naics_quarterly`.
-- Note on **B**: QCEW raw includes non-county `area_fips` (e.g. CBSA codes like `C2662`, state totals);
--   a high **B** count in a random SAMPLE is **expected** — `fact_bls_qcew_county_naics_quarterly` applies the
--   same 5-digit numeric + not `***000` filters as pretium-ai-dbt `cleaned_qcew_county_naics`.
-- Note on **D**: Many county-shaped rows have null/zero employment (disclosure / suppressed); the FACT filters `employment > 0`.
--
-- Run from inner repo root:
--   snowsql -c pretium -f scripts/sql/migration/vet_source_prod_bls_qcew_onet_for_workforce_facts.sql
--
-- Pairing: pretium-ai-dbt docs/governance/AI_REPLACEMENT_AND_AIGE_DATA_DEPENDENCIES.md §0;
--   semantic-layer `models/sources/sources_source_prod_bls_onet.yml`,
--   `models/transform/dev/bls/fact_bls_qcew_county_naics_quarterly.sql`.
-- =============================================================================

-- Adjust if your session defaults differ; metadata reads use current database.
USE DATABASE SOURCE_PROD;

-- ---------------------------------------------------------------------------
-- A) BLS.QCEW_COUNTY_RAW — exists, rows, VARIANT path signal
-- ---------------------------------------------------------------------------
SELECT 'A_qcew_raw_rowcount' AS check_id, COUNT(*)::VARCHAR AS result
FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW;

SELECT 'A_qcew_rows_where_v_present' AS check_id,
       SUM(IFF(v IS NOT NULL, 1, 0))::VARCHAR AS result
FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW;

SELECT 'A_qcew_rows_where_area_fips_path' AS check_id,
       SUM(IFF(v:area_fips IS NOT NULL, 1, 0))::VARCHAR AS result
FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW;

-- Geography sanity on parsed county FIPS (sample — raw is VARIANT-only in prod)
WITH parsed AS (
    SELECT lpad(trim(v:area_fips::varchar), 5, '0') AS area_fips
    FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW
    SAMPLE (1000000 ROWS)
    WHERE v:area_fips IS NOT NULL
      AND trim(v:area_fips::varchar) != ''
)
SELECT 'B_geo_invalid_area_fips' AS check_id, COUNT(*)::VARCHAR AS result
FROM parsed
WHERE area_fips IS NULL
   OR LENGTH(TRIM(area_fips)) != 5
   OR NOT REGEXP_LIKE(TRIM(area_fips), '^[0-9]{5}$')
   OR RIGHT(TRIM(area_fips), 3) = '000';

-- Duplicate grain probe at raw (area + industry + year + qtr + own); high dup rate => investigate
WITH r AS (
    SELECT
        lpad(trim(v:area_fips::varchar), 5, '0') AS area_fips,
        TRIM(v:industry_code::varchar) AS industry_code,
        v:year::integer AS yr,
        TRIM(v:qtr::varchar) AS qtr,
        TRIM(v:own_code::varchar) AS own_code
    FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW
    SAMPLE (1000000 ROWS)
    WHERE v:area_fips IS NOT NULL
      AND trim(v:area_fips::varchar) != ''
)
SELECT 'C_raw_dup_grain_groups' AS check_id, TO_VARCHAR(COUNT(*)) AS result
FROM (
    SELECT 1
    FROM r
    GROUP BY area_fips, industry_code, yr, qtr, own_code
    HAVING COUNT(*) > 1
);

-- Null / nonpositive employment share (quality)
WITH r2 AS (
    SELECT v:month3_emplvl::float AS emp
    FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW
    SAMPLE (1000000 ROWS)
    WHERE v:area_fips IS NOT NULL
      AND trim(v:area_fips::varchar) != ''
)
SELECT 'D_null_or_nonpositive_employment_rows' AS check_id, COUNT(*)::VARCHAR AS result
FROM r2
WHERE emp IS NULL OR emp <= 0;

-- Year coverage (approximate from 5M-row sample)
SELECT 'E_year_distribution_sample' AS check_id, yr::VARCHAR || '=' || cnt::VARCHAR AS result
FROM (
    SELECT v:year::integer AS yr, COUNT(*) AS cnt
    FROM SOURCE_PROD.BLS.QCEW_COUNTY_RAW
    SAMPLE (1000000 ROWS)
    GROUP BY 1
) y
ORDER BY y.cnt DESC
LIMIT 8;

-- ---------------------------------------------------------------------------
-- F) O*NET — table presence + row counts (identifiers may be upper or lower case)
-- ---------------------------------------------------------------------------
SELECT 'F_onet_occupation_base_rows' AS check_id,
       TO_VARCHAR(COUNT(*)) AS result
FROM SOURCE_PROD.ONET.OCCUPATION_BASE;

SELECT 'F_onet_work_activities_general_rows' AS check_id,
       TO_VARCHAR(COUNT(*)) AS result
FROM SOURCE_PROD.ONET.WORK_ACTIVITIES_GENERAL;

SELECT 'F_onet_work_context_rows' AS check_id,
       TO_VARCHAR(COUNT(*)) AS result
FROM SOURCE_PROD.ONET.WORK_CONTEXT;
