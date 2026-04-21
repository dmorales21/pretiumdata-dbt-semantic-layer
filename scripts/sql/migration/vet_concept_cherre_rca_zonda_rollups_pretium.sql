-- Post-build validation for **concept_transactions_market_monthly** / **concept_supply_pipeline_market_monthly**
-- rollups over **TRANSFORM.DEV** Cherre / RCA / Zonda / Markerr FACTs (same logic as dbt ``source()`` reads).
--
-- **Last Pretium run (2026-04-21):** Cherre SFR/MF and RCA MF transaction CBSA-month buckets with
-- sale_count>0: **~89k / ~57k / ~33k** rows respectively; Zonda deeds CBSA-month rollup **0** rows;
-- Markerr listings **~10k**; RCA MF construction UC **~2.5k** CBSA-month rows with units_uc>0.
--
-- Run:
--   snowsql -c pretium -f scripts/sql/migration/vet_concept_cherre_rca_zonda_rollups_pretium.sql

SELECT 'txn_cherre_sfr_cbsa_rows' AS check_id, COUNT(*) AS cnt
FROM (
    SELECT DATE_TRUNC('month', recorded_month)::DATE AS month_start,
           LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_id,
           SUM(sale_count) AS sale_count
    FROM TRANSFORM.DEV.FACT_CHERRE_RECORDER_SFR_H3_R8_MONTHLY
    WHERE cbsa_id IS NOT NULL AND recorded_month IS NOT NULL
    GROUP BY 1, 2
) s
WHERE s.sale_count > 0;

SELECT 'txn_cherre_mf_cbsa_rows' AS check_id, COUNT(*) AS cnt
FROM (
    SELECT DATE_TRUNC('month', recorded_month)::DATE AS month_start,
           LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_id,
           SUM(sale_count) AS sale_count
    FROM TRANSFORM.DEV.FACT_CHERRE_RECORDER_MF_H3_R8_MONTHLY
    WHERE cbsa_id IS NOT NULL AND recorded_month IS NOT NULL
    GROUP BY 1, 2
) s
WHERE s.sale_count > 0;

SELECT 'txn_rca_h3_cbsa_rows' AS check_id, COUNT(*) AS cnt
FROM (
    SELECT DATE_TRUNC('month', as_of_month)::DATE AS month_start,
           LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_id,
           SUM(sale_count) AS sale_count
    FROM TRANSFORM.DEV.FACT_RCA_MF_TRANSACTIONS_H3_R8_MONTHLY
    WHERE cbsa_id IS NOT NULL AND as_of_month IS NOT NULL
    GROUP BY 1, 2
) r
WHERE r.sale_count > 0;

SELECT 'txn_zonda_cbsa_rows' AS check_id, COUNT(*) AS cnt
FROM (
    SELECT DATE_TRUNC('month', as_of_month)::DATE AS month_start,
           LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_id,
           SUM(sale_count) AS sale_count
    FROM TRANSFORM.DEV.FACT_ZONDA_DEEDS_H3_R8_MONTHLY
    WHERE cbsa_id IS NOT NULL AND as_of_month IS NOT NULL
    GROUP BY 1, 2
) z;

SELECT 'pl_markerr_listings_cbsa_rows' AS check_id, COUNT(*) AS cnt
FROM (
    SELECT DATE_TRUNC('month', as_of_month)::DATE AS month_start,
           LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_id,
           SUM(listing_count) AS listing_count
    FROM TRANSFORM.DEV.FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY
    WHERE cbsa_id IS NOT NULL AND as_of_month IS NOT NULL
    GROUP BY 1, 2
) m
WHERE m.listing_count > 0;

SELECT 'pl_rca_construction_uc_cbsa_rows' AS check_id, COUNT(*) AS cnt
FROM (
    SELECT DATE_TRUNC('month', as_of_month)::DATE AS month_start,
           LPAD(TRIM(TO_VARCHAR(cbsa_id)), 5, '0') AS cbsa_id,
           SUM(units_under_construction) AS units_uc
    FROM TRANSFORM.DEV.FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY
    WHERE cbsa_id IS NOT NULL AND as_of_month IS NOT NULL
    GROUP BY 1, 2
) c
WHERE c.units_uc > 0;
