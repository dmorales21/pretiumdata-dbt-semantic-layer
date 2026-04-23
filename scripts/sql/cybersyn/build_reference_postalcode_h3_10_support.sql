-- Cybersyn US_ADDRESSES → REFERENCE.GEOGRAPHY postal-code ↔ H3-10 support layer
-- Connection: snowsql -c pretium -f scripts/sql/cybersyn/build_reference_postalcode_h3_10_support.sql
--
-- Vet summary (ACCOUNTADMIN / pretium account, 2026-04):
--   US_REAL_ESTATE.CYBERSYN.US_ADDRESSES — VIEW, ~172M rows; columns match pipeline (ZIP, LAT/LONG, ADDRESS_ID, …).
--   US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS — secure VIEW; POI_ID, ADDRESS_ID, RELATIONSHIP_*.
--   h3_latlng_to_cell(lat, lng, 10) — available.
--
-- Fixes vs naive pipeline:
--   1) LPAD(TRIM(postal_code), 5, '0') so ZIPs align to census-style 5-digit where possible.
--   2) POI join: one row per ADDRESS_ID (QUALIFY rn=1) so H3 counts are not inflated by multi-POI duplicates.
--
-- Cost: full rebuild scans ~172M addresses + aggregations — use a large warehouse (e.g. LOAD_WH / XL).
-- Next: `build_reference_postalcode_h3_10_qa.sql` — dominance / ZIP / invalid-postal QA tables (do not merge into census spine docs).
-- Optional: `build_reference_postalcode_h3_10_production_smoothed.sql` — rule-based islet merge → `POSTALCODE_H3_10_PRODUCTION_SMOOTHED` (after QA).

USE DATABASE REFERENCE;
USE SCHEMA GEOGRAPHY;

CREATE SCHEMA IF NOT EXISTS REFERENCE.GEOGRAPHY;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_ADDRESS_CURRENT AS
WITH base AS (
    SELECT
        CURRENT_DATE() AS snapshot_date,
        address_id,
        LPAD(TRIM(TO_VARCHAR(zip)), 5, '0') AS postal_code,
        city,
        state,
        id_zip,
        id_city,
        id_state,
        id_country,
        number,
        street_directional_prefix,
        street,
        street_type,
        street_directional_suffix,
        unit,
        latitude,
        longitude,
        UPPER(TRIM(
            CONCAT_WS(
                ' ',
                NULLIF(TRIM(TO_VARCHAR(number)), ''),
                NULLIF(TRIM(TO_VARCHAR(street_directional_prefix)), ''),
                NULLIF(TRIM(TO_VARCHAR(street)), ''),
                NULLIF(TRIM(TO_VARCHAR(street_type)), ''),
                NULLIF(TRIM(TO_VARCHAR(street_directional_suffix)), ''),
                NULLIF(TRIM(TO_VARCHAR(unit)), '')
            )
        )) AS normalized_address
    FROM US_REAL_ESTATE.CYBERSYN.US_ADDRESSES
    WHERE latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND zip IS NOT NULL
      AND TRIM(TO_VARCHAR(zip)) <> ''
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY postal_code, latitude, longitude, normalized_address
            ORDER BY address_id
        ) AS rn
    FROM base
)
SELECT
    snapshot_date,
    address_id,
    postal_code,
    city,
    state,
    id_zip,
    id_city,
    id_state,
    id_country,
    number,
    street_directional_prefix,
    street,
    street_type,
    street_directional_suffix,
    unit,
    latitude,
    longitude,
    normalized_address
FROM ranked
WHERE rn = 1;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_POI_ADDRESS_CURRENT AS
SELECT
    poi_id,
    address_id,
    relationship_type,
    relationship_start_date,
    relationship_end_date
FROM US_REAL_ESTATE.CYBERSYN.POINT_OF_INTEREST_ADDRESSES_RELATIONSHIPS
WHERE relationship_end_date IS NULL
   OR relationship_end_date >= CURRENT_DATE();

-- One POI row per address (deterministic tie-break) so downstream counts stay address-grain.
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_POI_ADDRESS_ONE_PER_ADDRESS AS
SELECT
    poi_id,
    address_id,
    relationship_type,
    relationship_start_date,
    relationship_end_date
FROM REFERENCE.GEOGRAPHY.POSTALCODE_POI_ADDRESS_CURRENT
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY address_id
    ORDER BY relationship_start_date DESC NULLS LAST, poi_id
) = 1;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_ADDRESS_CURRENT_ENRICHED AS
SELECT
    a.*,
    CASE WHEN p.address_id IS NOT NULL THEN 1 ELSE 0 END AS is_poi_linked,
    p.poi_id,
    p.relationship_type,
    p.relationship_start_date,
    p.relationship_end_date
FROM REFERENCE.GEOGRAPHY.POSTALCODE_ADDRESS_CURRENT a
LEFT JOIN REFERENCE.GEOGRAPHY.POSTALCODE_POI_ADDRESS_ONE_PER_ADDRESS p
    ON a.address_id = p.address_id;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_COUNT AS
SELECT
    H3_LATLNG_TO_CELL(latitude::FLOAT, longitude::FLOAT, 10) AS h3_10,
    postal_code,
    COUNT(*) AS address_count,
    COUNT_IF(is_poi_linked = 1) AS poi_address_count
FROM REFERENCE.GEOGRAPHY.POSTALCODE_ADDRESS_CURRENT_ENRICHED
GROUP BY 1, 2;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT AS
WITH ranked AS (
    SELECT
        h3_10,
        postal_code,
        address_count,
        SUM(address_count) OVER (PARTITION BY h3_10) AS total_cell_addresses,
        ROW_NUMBER() OVER (
            PARTITION BY h3_10
            ORDER BY address_count DESC, postal_code
        ) AS rn
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_COUNT
)
SELECT
    h3_10,
    postal_code,
    address_count AS dominant_postal_code_count,
    total_cell_addresses,
    address_count / NULLIF(total_cell_addresses, 0) AS dominance_ratio
FROM ranked
WHERE rn = 1;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_CONFIDENT AS
SELECT *
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT
WHERE total_cell_addresses >= 3
  AND dominance_ratio >= 0.60;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SUMMARY AS
SELECT
    postal_code,
    COUNT(*) AS h3_cell_count,
    SUM(dominant_postal_code_count) AS supporting_address_count,
    AVG(dominance_ratio) AS avg_dominance_ratio,
    MIN(dominance_ratio) AS min_dominance_ratio,
    MAX(dominance_ratio) AS max_dominance_ratio
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT
GROUP BY 1;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SUMMARY_CONFIDENT AS
SELECT
    postal_code,
    COUNT(*) AS confident_h3_cell_count,
    SUM(dominant_postal_code_count) AS confident_supporting_address_count,
    AVG(dominance_ratio) AS avg_confident_dominance_ratio
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_CONFIDENT
GROUP BY 1;
