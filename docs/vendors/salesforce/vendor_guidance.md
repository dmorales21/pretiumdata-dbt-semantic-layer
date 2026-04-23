# Salesforce — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/salesforce/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/salesforce/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_031` |
| **vendor_code** | `salesforce` |
| **vendor_label** | Salesforce |
| **definition** | Salesforce CRM data covering opportunities accounts and property records for Progress pipeline |
| **data_type** | operational |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.PROGRESS` |
| **data_share_type** | snowflake_share |
| **vertical_codes** | resi |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/salesforce/salesforce.md`)

**Catalog row:** `vendor_id` = `VND_031` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Salesforce CRM data covering opportunities accounts and property records for Progress pipeline

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | operational |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.PROGRESS` |
| **is_active** | TRUE |
| **data_share_type** | snowflake_share |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | resi |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`salesforce`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 515 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 515 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 515 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_036 | underwriting | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` | `acquisition__CAP_RATE__C` |
| MET_037 | underwriting | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` | `acquisition__NET_YIELD__C` |
| MET_035 | underwriting | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` | `acquisition__PURCHASE_PRICE__C` |
| MET_039 | underwriting | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` | `fdd__CLOSING_DATE__C` |
| MET_038 | underwriting | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` | `fdd__PURCHASE_PRICE__C` |
| MET_040 | underwriting | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_ACQUISITION_UW` | `fdd__STABILIZED__C` |
| MET_030 | spine | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` | `sf_properties__CAP_RATE__C` |
| MET_031 | spine | capital | positive | `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` | `sf_properties__GROSS_YIELD__C` |
| MET_032 | spine | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` | `sf_properties__HOME_CONDITION_SCORE__C` |
| MET_029 | spine | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` | `sf_properties__PROPERTYNUMBER__C` |
| SALESFORCE_MAN_ED9F839680 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ACQUISITION_COSTS__C` |
| SALESFORCE_MAN_480C8A0590 | pipeline | place | negative | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ACTIVE_DAYS_ON_MARKET__C` |
| SALESFORCE_MAN_89A97CF473 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ADDENDUM_GENERATED__C` |
| SALESFORCE_MAN_0EB71651DE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `AFFORDABLE_NET_YIELD_PERCENT__C` |
| SALESFORCE_MAN_A2A2043449 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `AFFORDABLE_NET_YIELD__C` |
| SALESFORCE_MAN_1BB93AA7CF | rent | housing | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `AFFORDABLE_UNDERWRITTEN_RENT__C` |
| SALESFORCE_MAN_994451C26C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ANNUAL_HOA__C` |
| SALESFORCE_MAN_45BE9CBE69 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ANNUAL_INSURANCE__C` |
| SALESFORCE_MAN_16F27E47FA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ANNUAL_TAXES__C` |
| SALESFORCE_MAN_C397552B16 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `AVAILABLE_ON_OPEN_DOOR__C` |
| SALESFORCE_MAN_8EA5395958 | education | household | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `AVERAGE_SCHOOL_SCORE__C` |
| SALESFORCE_MAN_B54698703F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BASIS_POINTS_ABOVE_MIN__C` |
| SALESFORCE_MAN_D227642E76 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BATHROOMS__C` |
| SALESFORCE_MAN_FE4EF06237 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BEDROOMS__C` |
| SALESFORCE_MAN_38A728A4EA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BID_AMOUNT__C` |
| SALESFORCE_MAN_79A2E70C44 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BROKER_COMMISSION__C` |
| SALESFORCE_MAN_8E28B7A489 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BROKER_CREDIT__C` |
| SALESFORCE_MAN_23142B54CA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `BUILDING_SQ_FT__C` |
| SALESFORCE_MAN_894985635B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CAPEX__C` |
| SALESFORCE_MAN_E2CFA82EF5 | cap_rate | capital | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CAP_RATE_PERCENT__C` |
| SALESFORCE_MAN_3AD56FA0AE | cap_rate | capital | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CAP_RATE__C` |
| SALESFORCE_MAN_153BB76691 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CASH_TO_BUYER__C` |
| SALESFORCE_MAN_FF2ABADA33 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CLOSING_DURATION__C` |
| SALESFORCE_MAN_4EAB2CC3EB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CLOSING_FUNDS__C` |
| SALESFORCE_MAN_5590BB4559 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CLOSING_PACKAGE__C` |
| SALESFORCE_MAN_AB9DFA0D60 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CONTRACT_BALANCE__C` |
| SALESFORCE_MAN_B7A3F8A726 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CONTRACT_GENERATED__C` |
| SALESFORCE_MAN_7D93E45E34 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CONVERTED__C` |
| SALESFORCE_MAN_448BEBA12E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `COUNTER_DD_DURATION__C` |
| SALESFORCE_MAN_A23C378CC8 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `COUNTER_EMD__C` |
| SALESFORCE_MAN_22A5C1126E | homeprice | housing | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `COUNTER_PRICE__C` |
| SALESFORCE_MAN_38D1551138 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `CREDIT_LOSS__C` |
| SALESFORCE_MAN_C28C4820CC | pipeline | place | negative | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `DAYS_ON_MARKET__C` |
| SALESFORCE_MAN_800D9C3E79 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `DD_ANNUAL_HOA__C` |
| SALESFORCE_MAN_7A7689F113 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `DD_DURATION__C` |
| SALESFORCE_MAN_B978FF9D8E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `DD_ESTIMATED_REHAB_COST__C` |
| SALESFORCE_MAN_AAEAFA8CBB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `DUE_DILLIGENCE_FEE__C` |
| SALESFORCE_MAN_BD241779EC | education | household | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ELEMENTARY_SCHOOL_SCORE__C` |
| SALESFORCE_MAN_0591864D40 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `EMD__C` |
| SALESFORCE_MAN_E537901EC7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_SFDC_ACQUISITION_C` | `ESCROW_CLOSING_COSTS__C` |

*(465 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
