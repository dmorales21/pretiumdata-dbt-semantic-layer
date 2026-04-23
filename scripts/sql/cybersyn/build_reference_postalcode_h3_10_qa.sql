-- QA layer for Cybersyn postal ↔ H3-10 support (run after build_reference_postalcode_h3_10_support.sql)
-- snowsql -c pretium -f scripts/sql/cybersyn/build_reference_postalcode_h3_10_qa.sql
--
-- Produces:
--   POSTALCODE_H3_10_DOMINANT_QA        — dominance + cell-volume bands, % of H3 cells
--   POSTALCODE_H3_10_ZIP_PROFILE        — per-ZIP support + low-support flags (thresholds below)
--   POSTALCODE_H3_10_INVALID_POSTAL_CODES — raw ZIP pattern audit + normalized failures in ADDRESS_CURRENT
--
-- Notes:
--   Raw ZIP audit scans US_ADDRESSES once with GROUP BY (distinct ZIP cardinality is manageable).
--   Polygon / connected-component fragmentation is out of scope here — when polygonizing, measure
--   connected components per ZIP (fragmentation vs sparsity) separately.
--
--   If POSTALCODE_H3_10_INVALID_POSTAL_CODES is empty: source rows used in ADDRESS_CURRENT may already
--   be strictly 5-digit numeric ZIPs (true for pretium vet on US_ADDRESSES); the table still enforces
--   the contract for other vintages/shares.

USE DATABASE REFERENCE;
USE SCHEMA GEOGRAPHY;

-- ---------------------------------------------------------------------------
-- 1) Dominance and cell-volume profiling on POSTALCODE_H3_10_DOMINANT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_QA AS
WITH dom AS (
    SELECT * FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT
),
tot AS (
    SELECT COUNT(*)::FLOAT AS total_cells FROM dom
),
dominance_bands AS (
    SELECT
        'dominance_ratio'::VARCHAR(64) AS qa_family,
        CASE
            WHEN dominance_ratio >= 0.90 THEN '0.90-1.00'
            WHEN dominance_ratio >= 0.75 THEN '0.75-0.89'
            WHEN dominance_ratio >= 0.60 THEN '0.60-0.74'
            ELSE '<0.60'
        END AS band_label,
        COUNT(*)::BIGINT AS cell_count
    FROM dom
    GROUP BY 1, 2
),
volume_bands AS (
    SELECT
        'total_cell_addresses'::VARCHAR(64) AS qa_family,
        CASE
            WHEN total_cell_addresses >= 20 THEN '20+'
            WHEN total_cell_addresses >= 11 THEN '11-19'
            WHEN total_cell_addresses >= 6 THEN '6-10'
            WHEN total_cell_addresses >= 3 THEN '3-5'
            ELSE '1-2'
        END AS band_label,
        COUNT(*)::BIGINT AS cell_count
    FROM dom
    GROUP BY 1, 2
),
unioned AS (
    SELECT * FROM dominance_bands
    UNION ALL
    SELECT * FROM volume_bands
)
SELECT
    u.qa_family,
    u.band_label,
    u.cell_count,
    u.cell_count / NULLIF(t.total_cells, 0) AS pct_of_all_h3_cells,
    CURRENT_TIMESTAMP() AS qa_built_at
FROM unioned AS u
CROSS JOIN tot AS t;

-- ---------------------------------------------------------------------------
-- 2) Per-ZIP profile (dominant layer + confident join + heuristic flags)
--    Thresholds (tune in one place):
--      FLAG_VERY_FEW_H3_CELLS:        h3_cells < 10
--      FLAG_VERY_FEW_ADDRESSES:      supporting_addresses < 50  (aligns with exploratory HAVING)
--      FLAG_LOW_AVG_DOMINANCE:       avg_dominance_ratio < 0.75
--      FLAG_SINGLE_H3_CELL:          h3_cells = 1
--      FLAG_POSSIBLE_ZIP_PLUS_4:     raw pattern not audited here — use INVALID table
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_ZIP_PROFILE AS
WITH dom_zip AS (
    SELECT
        postal_code,
        COUNT(*)::BIGINT AS h3_cells,
        SUM(dominant_postal_code_count)::BIGINT AS supporting_addresses,
        AVG(dominance_ratio)::FLOAT AS avg_dominance_ratio,
        MIN(dominance_ratio)::FLOAT AS min_dominance_ratio,
        MAX(dominance_ratio)::FLOAT AS max_dominance_ratio
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT
    GROUP BY 1
),
conf_zip AS (
    SELECT
        postal_code,
        COUNT(*)::BIGINT AS confident_h3_cells,
        SUM(dominant_postal_code_count)::BIGINT AS confident_supporting_addresses,
        AVG(dominance_ratio)::FLOAT AS avg_confident_dominance_ratio
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_CONFIDENT
    GROUP BY 1
)
SELECT
    d.postal_code,
    d.h3_cells,
    d.supporting_addresses,
    d.avg_dominance_ratio,
    d.min_dominance_ratio,
    d.max_dominance_ratio,
    COALESCE(c.confident_h3_cells, 0)::BIGINT AS confident_h3_cells,
    COALESCE(c.confident_supporting_addresses, 0)::BIGINT AS confident_supporting_addresses,
    c.avg_confident_dominance_ratio,
    CASE WHEN d.h3_cells < 10 THEN TRUE ELSE FALSE END AS flag_very_few_h3_cells,
    CASE WHEN d.supporting_addresses < 50 THEN TRUE ELSE FALSE END AS flag_very_few_supporting_addresses,
    CASE WHEN d.avg_dominance_ratio < 0.75 THEN TRUE ELSE FALSE END AS flag_low_avg_dominance,
    CASE WHEN d.h3_cells = 1 THEN TRUE ELSE FALSE END AS flag_single_h3_cell_zip,
    CURRENT_TIMESTAMP() AS qa_built_at
FROM dom_zip AS d
LEFT JOIN conf_zip AS c
    ON d.postal_code = c.postal_code;

-- ---------------------------------------------------------------------------
-- 3) Invalid / suspicious postal inputs
--    - raw_us_addresses: GROUP BY trimmed raw ZIP from source (non–5-digit-numeric patterns)
--    - address_current_normalized: rows in POSTALCODE_ADDRESS_CURRENT that still fail strict [0-9]{5}
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_INVALID_POSTAL_CODES AS
WITH raw_zip_agg AS (
    SELECT
        TRIM(TO_VARCHAR(zip)) AS raw_zip,
        COUNT(*)::BIGINT AS source_address_count
    FROM US_REAL_ESTATE.CYBERSYN.US_ADDRESSES
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND zip IS NOT NULL
    GROUP BY 1
),
raw_classified AS (
    SELECT
        'raw_us_addresses'::VARCHAR(48) AS qa_source,
        CASE
            WHEN raw_zip IS NULL OR raw_zip = '' THEN 'null_or_empty'
            WHEN REGEXP_LIKE(raw_zip, '^[0-9]{5}$') THEN 'ok_5_digit_numeric'
            WHEN REGEXP_LIKE(raw_zip, '^[0-9]{5}-[0-9]{4}$') THEN 'zip_plus_4'
            WHEN REGEXP_LIKE(raw_zip, '^[0-9]+$') AND LENGTH(raw_zip) < 5 THEN 'numeric_short_pad_candidate'
            WHEN REGEXP_LIKE(raw_zip, '^[0-9]+$') AND LENGTH(raw_zip) > 5 AND NOT REGEXP_LIKE(raw_zip, '^[0-9]{5}-[0-9]{4}$') THEN 'numeric_long_non_zip4'
            WHEN REGEXP_LIKE(raw_zip, '^[0-9]+$') THEN 'numeric_other_length'
            WHEN REGEXP_LIKE(raw_zip, '[A-Za-z]') THEN 'contains_alpha'
            WHEN CONTAINS(raw_zip, '-') THEN 'has_hyphen_non_zip4_pattern'
            ELSE 'other_pattern'
        END AS issue_bucket,
        raw_zip AS postal_key,
        source_address_count AS row_count
    FROM raw_zip_agg
),
raw_issues AS (
    SELECT qa_source, issue_bucket, postal_key, row_count
    FROM raw_classified
    WHERE issue_bucket <> 'ok_5_digit_numeric'
),
norm_issues AS (
    SELECT
        'address_current_normalized'::VARCHAR(48) AS qa_source,
        'fails_strict_5_digit_after_lpad'::VARCHAR(64) AS issue_bucket,
        postal_code AS postal_key,
        COUNT(*)::BIGINT AS row_count
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_ADDRESS_CURRENT
    WHERE postal_code IS NULL
       OR LENGTH(postal_code) <> 5
       OR NOT REGEXP_LIKE(postal_code, '^[0-9]{5}$')
    GROUP BY 1, 2, 3
)
SELECT
    qa_source,
    issue_bucket,
    postal_key,
    row_count,
    CURRENT_TIMESTAMP() AS qa_built_at
FROM raw_issues
UNION ALL
SELECT
    qa_source,
    issue_bucket,
    postal_key,
    row_count,
    CURRENT_TIMESTAMP()
FROM norm_issues;

-- ---------------------------------------------------------------------------
-- Ad hoc checks (run manually in a worksheet; not part of CTAS above)
-- ---------------------------------------------------------------------------
-- SELECT * FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_QA ORDER BY qa_family, band_label;
-- SELECT * FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_ZIP_PROFILE
--  WHERE flag_very_few_supporting_addresses OR flag_low_avg_dominance
--  ORDER BY supporting_addresses ASC, avg_dominance_ratio ASC
--  LIMIT 200;
-- SELECT * FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_INVALID_POSTAL_CODES ORDER BY row_count DESC LIMIT 500;
