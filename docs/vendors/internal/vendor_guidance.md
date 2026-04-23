# Pretium Internal — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/internal/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/internal/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_040` |
| **vendor_code** | `internal` |
| **vendor_label** | Pretium Internal |
| **definition** | Pretium-generated derived datasets including governance audit tables portfolio footprint and news intelligence |
| **data_type** | operational |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `TRANSFORM.FACT` |
| **data_share_type** | manual |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/internal/internal.md`)

**Catalog row:** `vendor_id` = `VND_040` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Pretium-generated derived datasets including governance audit tables portfolio footprint and news intelligence

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | operational |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `TRANSFORM.FACT` |
| **is_active** | TRUE |
| **data_share_type** | manual |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`internal`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

No vendor-specific migration file is mapped in `generate_vendor_context_from_seed.py` yet. Use [`migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md`](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) and [`migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md`](../migration/MIGRATION_REGISTRY_VENDORS_DATASETS_METRICS.md).

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 589 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 589 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 598 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_161 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `CUSTOM_SCORE` |
| MET_150 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `MARKET_PHASE` |
| MET_151 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `MEDIAN_MONTHS_TO_COMPLETION` |
| MET_160 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `PRETIUM_SCORE` |
| MET_146 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `RENT_MOM_PCT_CHANGE` |
| MET_162 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `RENT_TREND_FLAG` |
| MET_153 | multifamily_market | housing | neutral | `ANALYTICS.DBT_DEV.FEATURE_MULTIFAMILY_MARKET_RANKER_MONTHLY` | `UNITS_UNDER_CONSTRUCTION` |
| MET_132 | supply_pipeline | housing | neutral | `TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY` | `supply_pipeline_current` |
| MET_129 | transactions | housing | positive | `TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY` | `transactions_current` |
| MET_121 | employment | place | neutral | `TRANSFORM.DEV.FACT_AIGE_COUNTIES` | `MULTI_COLUMN` |
| INTERNAL_MAN_D0435CAD26 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `ACTIVE_LEASES` |
| INTERNAL_MAN_494DA154DE | rent | housing | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `AVG_RENT_ACTIVE` |
| INTERNAL_MAN_A0AE4B34EB | rent | housing | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `AVG_RENT_NEW_LEASES` |
| INTERNAL_MAN_32DC9A455C | pipeline | place | positive | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `COLLECTION_RATE_PCT` |
| INTERNAL_MAN_3629426417 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `LEASE_RATE_PCT` |
| INTERNAL_MAN_FDAF6A39CE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `MOVE_INS` |
| INTERNAL_MAN_E4E298C42D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `MOVE_OUTS` |
| INTERNAL_MAN_2CBE2BFA47 | pipeline | place | positive | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `NET_ABSORPTION` |
| INTERNAL_MAN_7B9D4DDA85 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `N_CREDIT_TXNS` |
| INTERNAL_MAN_9548036BA3 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `N_OPEN_TXNS` |
| INTERNAL_MAN_B5F9D125A0 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `N_PROPERTIES` |
| INTERNAL_MAN_5A8DE971B0 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `N_TRANSACTIONS` |
| INTERNAL_MAN_569014B3A4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `TOTAL_CHARGED` |
| INTERNAL_MAN_137A0DFF2C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `TOTAL_COLLECTED` |
| INTERNAL_MAN_AFD2E69265 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `TOTAL_OUTSTANDING` |
| INTERNAL_MAN_A13959903C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `TOTAL_UNITS` |
| INTERNAL_MAN_9F1C74239D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `UNITS_DOWN_EOM` |
| INTERNAL_MAN_CCE30B6369 | occupancy | housing | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `UNITS_OCCUPIED_EOM` |
| INTERNAL_MAN_7219342465 | vacancy | housing | neutral | `TRANSFORM.DEV.FACT_BH_COUNTY_MONTHLY` | `UNITS_VACANT_EOM` |
| INTERNAL_MAN_B26BFD74EC | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `N_CHARGES_31_60` |
| INTERNAL_MAN_665CDCB827 | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `N_CHARGES_61_90` |
| INTERNAL_MAN_24675C58D6 | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `N_CHARGES_91_PLUS` |
| INTERNAL_MAN_3E8B3A5A84 | rent | housing | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `N_CHARGES_CURRENT` |
| INTERNAL_MAN_8950743D63 | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `N_CHARGES_TOTAL` |
| INTERNAL_MAN_2CC0A2577D | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `OUTSTANDING_31_60` |
| INTERNAL_MAN_AEBDF197F2 | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `OUTSTANDING_61_90` |
| INTERNAL_MAN_3EC8B8D20A | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `OUTSTANDING_91_PLUS` |
| INTERNAL_MAN_F31CE0A476 | rent | housing | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `OUTSTANDING_CURRENT` |
| INTERNAL_MAN_1518EFC56E | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `OUTSTANDING_TOTAL` |
| INTERNAL_MAN_2F67ED5286 | delinquency | capital | neutral | `TRANSFORM.DEV.FACT_BH_DELINQUENCY_MONTHLY` | `PCT_SERIOUSLY_DELINQUENT` |
| INTERNAL_MAN_18A1D047CB | pipeline | place | positive | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `COLLECTION_RATE_PCT` |
| INTERNAL_MAN_F8AE59253D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `N_CREDIT_TXNS` |
| INTERNAL_MAN_048B05DFD3 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `N_OPEN_TXNS` |
| INTERNAL_MAN_0AA858E0C7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `N_TRANSACTIONS` |
| INTERNAL_MAN_DBACE1A717 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `TOTAL_CHARGED` |
| INTERNAL_MAN_DBAD5638D7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `TOTAL_COLLECTED` |
| INTERNAL_MAN_0FF9B41E3B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_FINANCIALS_MONTHLY` | `TOTAL_OUTSTANDING` |
| INTERNAL_MAN_229696D7EC | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_LEASE_DETAIL` | `BEDROOMS` |
| INTERNAL_MAN_863510097C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_LEASE_DETAIL` | `LEASE_TERM_MONTHS` |
| INTERNAL_MAN_C42EA16BA0 | rent | housing | neutral | `TRANSFORM.DEV.FACT_BH_LEASE_DETAIL` | `RENT_AMOUNT` |

*(539 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
