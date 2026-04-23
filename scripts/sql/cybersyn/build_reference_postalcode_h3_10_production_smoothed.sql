-- Production-smoothed H3-10 ↔ postal layer (cartographic / operational).
-- Does NOT modify POSTALCODE_H3_10_DOMINANT_CONFIDENT (raw modeled surface).
--
-- Prereqs: build_reference_postalcode_h3_10_support.sql + build_reference_postalcode_h3_10_qa.sql
-- Run: snowsql -c pretium -f scripts/sql/cybersyn/build_reference_postalcode_h3_10_production_smoothed.sql
--
-- Why multi-step: a single CTAS with 18× label-propagation branches can exceed Snowflake SQL *compilation*
-- timeout (~1h, error 000649). Staging tables compile and execute separately.
--
-- Staging objects (dropped at end): REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES, REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A, REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B.
--
-- Method: same-ZIP disk-1 components → min-label propagation → merge small non-primary components →
-- disk-1 + (disk2−disk1) weighted absorber score.

USE DATABASE REFERENCE;
USE SCHEMA GEOGRAPHY;

/* ---------- 1) Intra-ZIP disk-1 edges on confident cells ---------- */
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS
WITH conf AS (
    SELECT
        h3_10,
        postal_code,
        dominant_postal_code_count,
        total_cell_addresses,
        dominance_ratio
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_CONFIDENT
)
SELECT
    c1.h3_10 AS h_from,
    c2.h3_10 AS h_to,
    c1.postal_code
FROM conf AS c1
INNER JOIN LATERAL FLATTEN(INPUT => H3_GRID_DISK(c1.h3_10, 1)) AS n
INNER JOIN conf AS c2
    ON c2.h3_10 = TO_NUMBER(n.value)::BIGINT
   AND c2.postal_code = c1.postal_code
WHERE TO_NUMBER(n.value)::BIGINT <> c1.h3_10;

/* ---------- 2) Label propagation (18 rounds; A/B ping-pong) ---------- */
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    h3_10,
    postal_code,
    h3_10::BIGINT AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_CONFIDENT;


CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS
SELECT
    t.h3_10,
    t.postal_code,
    LEAST(t.comp_id, COALESCE(nb.min_nbr_comp, t.comp_id)) AS comp_id
FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS t
LEFT JOIN (
    SELECT
        e.h_from,
        e.postal_code,
        MIN(n.comp_id) AS min_nbr_comp
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES AS e
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B AS n
        ON e.h_to = n.h3_10
       AND e.postal_code = n.postal_code
    GROUP BY e.h_from, e.postal_code
) AS nb
    ON t.h3_10 = nb.h_from
   AND t.postal_code = nb.postal_code;

/* ---------- 3) Production table (reads final labels from LABEL_A) ---------- */
CREATE OR REPLACE TABLE REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_PRODUCTION_SMOOTHED AS
WITH conf AS (
    SELECT
        h3_10,
        postal_code,
        dominant_postal_code_count,
        total_cell_addresses,
        dominance_ratio
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT_CONFIDENT
),
dominant_global AS (
    SELECT
        h3_10,
        postal_code,
        dominant_postal_code_count,
        total_cell_addresses,
        dominance_ratio
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_DOMINANT
),
zip_profile_row AS (
    SELECT
        postal_code,
        supporting_addresses,
        avg_dominance_ratio,
        confident_h3_cells,
        confident_supporting_addresses,
        avg_confident_dominance_ratio
    FROM REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_ZIP_PROFILE
),
cell_labeled AS (
    SELECT
        c.h3_10,
        c.postal_code,
        c.dominant_postal_code_count,
        c.total_cell_addresses,
        c.dominance_ratio,
        lp.comp_id
    FROM conf AS c
    INNER JOIN REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A AS lp
        ON c.h3_10 = lp.h3_10
       AND c.postal_code = lp.postal_code
),
zip_conf_addr AS (
    SELECT
        postal_code,
        SUM(dominant_postal_code_count)::BIGINT AS zip_supporting_addresses
    FROM conf
    GROUP BY 1
),
comp_agg AS (
    SELECT
        postal_code,
        comp_id,
        COUNT(*)::BIGINT AS component_cells,
        SUM(dominant_postal_code_count)::BIGINT AS component_support
    FROM cell_labeled
    GROUP BY 1, 2
),
comp_ranked AS (
    SELECT
        ca.postal_code,
        ca.comp_id,
        ca.component_cells,
        ca.component_support,
        zc.zip_supporting_addresses,
        ROW_NUMBER() OVER (
            PARTITION BY ca.postal_code
            ORDER BY ca.component_cells DESC, ca.component_support DESC
        ) AS component_rank,
        ROW_NUMBER() OVER (
            PARTITION BY ca.postal_code
            ORDER BY ca.component_cells DESC, ca.component_support DESC
        ) = 1 AS is_primary_component
    FROM comp_agg AS ca
    INNER JOIN zip_conf_addr AS zc
        ON ca.postal_code = zc.postal_code
),
zip_morph AS (
    SELECT
        postal_code,
        COUNT(DISTINCT comp_id)::INTEGER AS component_count
    FROM cell_labeled
    GROUP BY 1
),
merge_thresholds AS (
    SELECT
        zm.postal_code,
        zm.component_count,
        CASE
            WHEN zm.component_count >= 12 THEN 10
            WHEN zm.component_count >= 6 THEN 18
            ELSE 25
        END AS max_nonprimary_cells,
        CASE
            WHEN zm.component_count >= 12 THEN 40
            WHEN zm.component_count >= 6 THEN 100
            ELSE 180
        END AS max_nonprimary_support,
        CASE
            WHEN zm.component_count >= 12 THEN 0.012
            ELSE 0.022
        END AS max_share_of_zip_support
    FROM zip_morph AS zm
),
merge_components AS (
    SELECT
        cr.postal_code,
        cr.comp_id,
        cr.component_cells,
        cr.component_support,
        cr.zip_supporting_addresses,
        cr.component_rank,
        mt.max_nonprimary_cells,
        mt.max_nonprimary_support,
        mt.max_share_of_zip_support,
        zm.component_count AS zip_component_count
    FROM comp_ranked AS cr
    INNER JOIN merge_thresholds AS mt
        ON cr.postal_code = mt.postal_code
    INNER JOIN zip_morph AS zm
        ON cr.postal_code = zm.postal_code
    WHERE cr.is_primary_component = FALSE
      AND cr.component_cells <= mt.max_nonprimary_cells
      AND cr.component_support <= mt.max_nonprimary_support
      AND (cr.component_support::FLOAT / NULLIF(cr.zip_supporting_addresses, 0)) < mt.max_share_of_zip_support
),
merge_comp_cells AS (
    SELECT
        mc.postal_code AS src_postal,
        mc.comp_id,
        cl.h3_10
    FROM merge_components AS mc
    INNER JOIN cell_labeled AS cl
        ON cl.postal_code = mc.postal_code
       AND cl.comp_id = mc.comp_id
),
alt_zip_fragmentation AS (
    SELECT
        postal_code,
        COUNT(DISTINCT comp_id)::INTEGER AS alt_zip_component_count
    FROM cell_labeled
    GROUP BY 1
),
perim_d1 AS (
    SELECT
        m.src_postal,
        m.comp_id,
        dg.postal_code AS alt_postal,
        COUNT(*)::BIGINT AS d1_touch_cells,
        SUM(dg.dominant_postal_code_count)::DOUBLE AS d1_touch_address_support
    FROM merge_comp_cells AS m
    INNER JOIN LATERAL FLATTEN(INPUT => H3_GRID_DISK(m.h3_10, 1)) AS f
    INNER JOIN dominant_global AS dg
        ON dg.h3_10 = TO_NUMBER(f.value)::BIGINT
    WHERE TO_NUMBER(f.value)::BIGINT <> m.h3_10
      AND dg.postal_code <> m.src_postal
    GROUP BY 1, 2, 3
),
perim_d2 AS (
    SELECT
        m.src_postal,
        m.comp_id,
        dg.postal_code AS alt_postal,
        COUNT(*)::BIGINT AS d2_touch_cells,
        SUM(dg.dominant_postal_code_count)::DOUBLE AS d2_touch_address_support
    FROM merge_comp_cells AS m
    INNER JOIN LATERAL FLATTEN(INPUT => H3_GRID_DISK(m.h3_10, 2)) AS f
    INNER JOIN dominant_global AS dg
        ON dg.h3_10 = TO_NUMBER(f.value)::BIGINT
    WHERE TO_NUMBER(f.value)::BIGINT <> m.h3_10
      AND dg.postal_code <> m.src_postal
    GROUP BY 1, 2, 3
),
alt_joined AS (
    SELECT
        COALESCE(d1.src_postal, d2.src_postal) AS src_postal,
        COALESCE(d1.comp_id, d2.comp_id) AS comp_id,
        COALESCE(d1.alt_postal, d2.alt_postal) AS alt_postal,
        COALESCE(d1.d1_touch_cells, 0)::BIGINT AS d1_touch_cells,
        COALESCE(d1.d1_touch_address_support, 0)::DOUBLE AS d1_touch_address_support,
        COALESCE(d2.d2_touch_cells, 0)::BIGINT AS d2_touch_cells,
        COALESCE(d2.d2_touch_address_support, 0)::DOUBLE AS d2_touch_address_support
    FROM perim_d1 AS d1
    FULL OUTER JOIN perim_d2 AS d2
        ON d1.src_postal = d2.src_postal
       AND d1.comp_id = d2.comp_id
       AND d1.alt_postal = d2.alt_postal
),
alt_scored AS (
    SELECT
        aj.src_postal,
        aj.comp_id,
        aj.alt_postal,
        aj.d1_touch_cells,
        aj.d1_touch_address_support,
        aj.d2_touch_cells,
        aj.d2_touch_address_support,
        zp_alt.avg_dominance_ratio AS alt_zip_avg_dom,
        azf.alt_zip_component_count,
        (
            (aj.d1_touch_cells::DOUBLE + 0.001 * aj.d1_touch_address_support)
            + 0.45 * (
                GREATEST(aj.d2_touch_cells - aj.d1_touch_cells, 0)::DOUBLE
                + 0.001 * GREATEST(aj.d2_touch_address_support - aj.d1_touch_address_support, 0)::DOUBLE
            )
            + 0.12 * COALESCE(zp_alt.avg_dominance_ratio, 0)::DOUBLE
            - CASE WHEN COALESCE(zp_alt.avg_dominance_ratio, 0) < 0.55 THEN 1.5 ELSE 0 END
            - CASE WHEN COALESCE(azf.alt_zip_component_count, 0) > 14 THEN 1.1 ELSE 0 END
            - CASE WHEN COALESCE(zp_alt.avg_dominance_ratio, 0) < 0.72 THEN 0.6 ELSE 0 END
        )::DOUBLE AS absorption_score
    FROM alt_joined AS aj
    LEFT JOIN zip_profile_row AS zp_alt
        ON zp_alt.postal_code = aj.alt_postal
    LEFT JOIN alt_zip_fragmentation AS azf
        ON azf.postal_code = aj.alt_postal
),
winner_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY src_postal, comp_id
            ORDER BY
                absorption_score DESC,
                (
                    d1_touch_address_support
                    + GREATEST(d2_touch_address_support - d1_touch_address_support, 0)
                ) DESC,
                alt_postal ASC
        ) AS win_rn
    FROM alt_scored
    WHERE alt_postal IS NOT NULL
),
winner_pick AS (
    SELECT *
    FROM winner_ranked
    WHERE win_rn = 1
      AND absorption_score >= 2.5
),
cell_out AS (
    SELECT
        cl.h3_10,
        cl.postal_code AS postal_code_modeled,
        COALESCE(wp.alt_postal, cl.postal_code) AS postal_code_production,
        cl.dominant_postal_code_count,
        cl.total_cell_addresses,
        cl.dominance_ratio,
        cl.postal_code || ':' || TO_VARCHAR(cl.comp_id) AS component_key,
        cr.component_cells,
        cr.component_support,
        cr.is_primary_component,
        cr.component_rank,
        zm.component_count AS zip_component_count,
        CASE
            WHEN wp.alt_postal IS NOT NULL THEN 'merged_nonprimary_component'
            WHEN mc.comp_id IS NOT NULL THEN 'merge_eligible_no_qualified_absorber'
            ELSE 'unchanged'
        END AS smoothing_action,
        wp.alt_postal AS merge_absorber_postal,
        wp.absorption_score AS merge_absorption_score,
        wp.d1_touch_cells AS merge_perimeter_d1_cells,
        wp.d2_touch_cells AS merge_perimeter_d2_cells,
        LEAST(
            1.0,
            GREATEST(
                0.0,
                0.34 * cl.dominance_ratio::DOUBLE
                + 0.20 * LEAST(
                    cl.dominant_postal_code_count::FLOAT / NULLIF(zc.zip_supporting_addresses, 0) * 18.0,
                    1.0
                )
                + 0.18 * CASE
                    WHEN wp.alt_postal IS NULL THEN 1.0
                    ELSE LEAST(COALESCE(wp.absorption_score, 0) / 14.0, 1.0)
                END
                + 0.16 * (1.0 - LEAST(zm.component_count::FLOAT / 28.0, 1.0))
                + 0.12 * LEAST(cl.dominant_postal_code_count::FLOAT / 120.0, 1.0)
            )
        )::DOUBLE AS production_confidence_score,
        CURRENT_TIMESTAMP() AS smoothed_built_at
    FROM cell_labeled AS cl
    INNER JOIN comp_ranked AS cr
        ON cl.postal_code = cr.postal_code
       AND cl.comp_id = cr.comp_id
    INNER JOIN zip_conf_addr AS zc
        ON cl.postal_code = zc.postal_code
    INNER JOIN zip_morph AS zm
        ON cl.postal_code = zm.postal_code
    LEFT JOIN merge_components AS mc
        ON mc.postal_code = cl.postal_code
       AND mc.comp_id = cl.comp_id
    LEFT JOIN winner_pick AS wp
        ON wp.src_postal = cl.postal_code
       AND wp.comp_id = cl.comp_id
)
SELECT * FROM cell_out;

/* ---------- 4) Drop staging (keeps GEOGRAPHY tidy; comment out to inspect labels/edges) ---------- */
DROP TABLE IF EXISTS REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_INTRAZIP_EDGES;
DROP TABLE IF EXISTS REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_A;
DROP TABLE IF EXISTS REFERENCE.GEOGRAPHY.POSTALCODE_H3_10_SMTH_LABEL_B;
