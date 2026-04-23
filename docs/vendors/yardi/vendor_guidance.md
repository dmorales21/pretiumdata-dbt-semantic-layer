# Yardi Systems — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/yardi/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/yardi/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_030` |
| **vendor_code** | `yardi` |
| **vendor_label** | Yardi Systems |
| **definition** | Yardi property management operational data covering unit occupancy lease rent payments and work orders for Progress and BH portfolios |
| **data_type** | operational |
| **refresh_cadence** | daily |
| **contract_status** | active |
| **source_schema** | `SOURCE_ENTITY.PROGRESS` |
| **data_share_type** | snowflake_share |
| **vertical_codes** | resi |

**Primary migration doc (inventory):** [migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md](../migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md)

---

## Vendor methodology (full text from `docs/vendor/yardi/yardi.md`)

**Catalog row:** `vendor_id` = `VND_030` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

Yardi property management operational data covering unit occupancy lease rent payments and work orders for Progress and BH portfolios

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

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`yardi`** × concept × dataset gaps and stretch mappings.

## 5. Field dictionary (machine-readable)

| File | Description |
|------|-------------|
| `dictionary.csv` | Column/metric-level rows (extend per inventory). |
| `dictionary.yaml` | Vendor-level metadata + empty `fields` list until filled. |

## 6. Migration and QA

Primary task / vet doc: [`migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md`](../migration/MIGRATION_TASKS_YARDI_BH_PROGRESS.md)

## 7. Related rules

- [OPERATING_MODEL.md](../OPERATING_MODEL.md)
- [rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md](../rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md)

---

## Physical metrics summary (`vendor_metrics.csv`)

| Metric | Value |
|--------|-------|
| **Unique physical columns** | 1463 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 1463 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 1463 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| MET_034 | spine | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` | `yardi_propattr__PROPERTY_STATUS` |
| MET_033 | spine | capital | neutral | `TRANSFORM.DEV.CONCEPT_PROGRESS_PROPERTY` | `yardi_propattr__TIER` |
| YARDI_BH_LEDGER_AMOUNT_PAID | noi | capital | positive | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` | `TRANS_AMOUNT_PAID` |
| YARDI_BH_LEDGER_CREDIT_FLAG | noi | capital | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` | `TRANS_CREDIT_FLAG` |
| YARDI_BH_LEDGER_OPEN_FLAG | delinquency | capital | negative | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` | `TRANS_OPEN_FLAG` |
| YARDI_BH_LEDGER_TOTAL_AMOUNT | noi | capital | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` | `TRANS_TOTAL_AMOUNT` |
| YARDI_BH_LEDGER_VOID_FLAG | noi | capital | negative | `TRANSFORM.DEV.FACT_BH_YARDI_LEDGER` | `TRANS_VOID_FLAG` |
| YARDI_BH_PROPERTY_ROW_COUNT | spine | capital | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_PROPERTY` | `YARDI_PROPERTY_HKEY` |
| YARDI_BH_UNIT_BEDROOM_COUNT | spine | capital | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_UNIT` | `BEDROOM_COUNT` |
| YARDI_BH_UNIT_CONTRACT_RENT | rent | housing | positive | `TRANSFORM.DEV.FACT_BH_YARDI_UNIT` | `CONTRACT_RENT` |
| YARDI_BH_UNIT_SQFT | spine | capital | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_UNIT` | `SQFT` |
| YARDI_MAN_2CEC2421FE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_UNIT` | `YARDI_PROPERTY_HKEY` |
| YARDI_MAN_EC44E4B0A9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_BH_YARDI_UNIT` | `YARDI_UNIT_HKEY` |
| YARDI_MAN_D9A9658887 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_ACCTTREE` | `HCHART` |
| YARDI_MAN_C8ECEC88BB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_ACCTTREE` | `HDIVISOR` |
| YARDI_MAN_CF2E3067D4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_ACCTTREE` | `HFOREIGNDB` |
| YARDI_MAN_49521B7070 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_ACCTTREE` | `HMY` |
| YARDI_MAN_5468C72E09 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_ACCTTREE` | `ITYPE` |
| YARDI_MAN_F5607EF6F2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `AGI1_APPROVEDPER` |
| YARDI_MAN_5B8AF55FF9 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `AGI2_APPROVEDPER` |
| YARDI_MAN_84084FD7F8 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `APR` |
| YARDI_MAN_14A6C420CA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `AUG` |
| YARDI_MAN_02FAECE63F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BACH` |
| YARDI_MAN_F5ABEAD752 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BANCHORDEDUCTION` |
| YARDI_MAN_DBDB3EC676 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BASERULE` |
| YARDI_MAN_F80393D8C2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BBASEAMOUNTCREDIT` |
| YARDI_MAN_97FE211D34 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BCALCESTIMATE` |
| YARDI_MAN_B25D2133BE | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BCC` |
| YARDI_MAN_96D521790E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BCHARGELFONUNPAID` |
| YARDI_MAN_B4978B4966 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BCHECKANNUALLY` |
| YARDI_MAN_5FE4F73A3F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BCUMULATIVE` |
| YARDI_MAN_93744DE57B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BDAILYAMOUNT` |
| YARDI_MAN_F6FD4BD708 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BENDCAMRULE` |
| YARDI_MAN_31AD63D43C | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BEXCLUDERECOVERY` |
| YARDI_MAN_7AE9EF77BA | rent | housing | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BGROSSRENTTAXINCLUSIVE` |
| YARDI_MAN_11AFE1F40E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BHOLD` |
| YARDI_MAN_8A4CF6C953 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BINCREASEASPOINTS` |
| YARDI_MAN_760665F611 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BLASTDAYOFPERIOD` |
| YARDI_MAN_1F046D172A | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BLOCKED` |
| YARDI_MAN_CA0FE28F6D | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BNATURALBREAKPOINT` |
| YARDI_MAN_84C7813AD2 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BNINETYDAYDUEDATE` |
| YARDI_MAN_F05F0E59BD | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BOFFSETMULTIPLIER` |
| YARDI_MAN_982D009CE3 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BPAYMENTSCHEDULE` |
| YARDI_MAN_BDFF0D71D5 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BREVISEDBILLING` |
| YARDI_MAN_BCC314E498 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BROUNDTOONEDECIMAL` |
| YARDI_MAN_E737AE20FC | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BROUNDTOWHOLENUMBERS` |
| YARDI_MAN_052AEA1AC4 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BSCANDINAVIANINDEXATION` |
| YARDI_MAN_AD13039B02 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BSTEPINDEXATION` |
| YARDI_MAN_68082E4F9B | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BSWEDENINDEXATION` |
| YARDI_MAN_B63FF1B6FB | pipeline | place | neutral | `TRANSFORM.DEV.FACT_ENTITY_YARDI_CAMRULE` | `BTIERBREAKPOINT` |

*(1413 additional rows in `vendor_metrics.csv`.)*


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
