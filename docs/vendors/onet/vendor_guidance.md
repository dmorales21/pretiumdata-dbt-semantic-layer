# O*NET — Department of Labor — Data Guidance

⚠️ **INTERNAL — contract and operational context**

**Intake bundle:** `docs/vendors/onet/` (machine column inventory + this narrative).  
**Canonical vendor hub:** `docs/vendor/onet/` (dictionary + structured stubs).

---

## Catalog snapshot (seeds/reference/catalog/vendor.csv)

| Field | Value |
|-------|-------|
| **vendor_id** | `VND_007` |
| **vendor_code** | `onet` |
| **vendor_label** | O*NET — Department of Labor |
| **definition** | O*NET occupational data covering work activities skills tasks and automation exposure by SOC code |
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.ONET` |
| **data_share_type** | s3 |
| **vertical_codes** | — |

**Primary migration doc (inventory):** — (see `docs/vendor/0_inventory/vendors_inventory.csv`)

---

## Vendor methodology (full text from `docs/vendor/onet/onet.md`)

**Catalog row:** `vendor_id` = `VND_007` in `seeds/reference/catalog/vendor.csv`.

## 1. Identity

O*NET occupational data covering work activities skills tasks and automation exposure by SOC code

## 2. Contract (catalog)

| Attribute | Value |
|-----------|-------|
| **data_type** | administrative |
| **refresh_cadence** | annual |
| **contract_status** | active |
| **source_schema** | `RAW.ONET` |
| **is_active** | TRUE |
| **data_share_type** | s3 |
| **is_motherduck_served** | FALSE |
| **vertical_codes** | — |

## 3. Read path (methodology)

1. Prefer **Jon silver** on **TRANSFORM** (vendor schema, e.g. `TRANSFORM.ZILLOW`, `TRANSFORM.MARKERR`) or **`TRANSFORM.FACT`** when the object exists and is vetted (see [MIGRATION_RULES.md](../migration/MIGRATION_RULES.md)).
2. Otherwise use the catalog **`source_schema`** (`RAW.*`, `SOURCE_ENTITY.*`, `SOURCE_SNOW.*`, etc.) and declare reads in `models/sources/*.yml`.
3. **Alex dbt** implements **`TRANSFORM.DEV`** read-throughs and typed facts under `models/transform/dev/` where applicable.
4. **REFERENCE.CATALOG** (`metric`, `dataset`, `bridge_product_type_metric`) must align with real column names after `DESCRIBE` / lineage — see [METRIC_INTAKE_CHECKLIST.md](../migration/METRIC_INTAKE_CHECKLIST.md).

## 4. Grain and concepts

See [VENDOR_CONCEPT_COVERAGE_MATRIX.md](../migration/VENDOR_CONCEPT_COVERAGE_MATRIX.md) for **`onet`** × concept × dataset gaps and stretch mappings.

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
| **Unique physical columns** | 30 |
| **Rows pointing at TRANSFORM.DEV / DEV paths** | 30 |
| **Raw catalog metrics (metric.csv rows for this vendor)** | 30 |

Long-form facts collapse many catalog `metric_id` values onto one `snowflake_column` (for example `VALUE` / `METRIC_VALUE`); use **`seeds/reference/catalog/metric.csv`** (this repo) or pretium-ai-dbt merged `metric.csv` for the full metric registry.

---

## Concept mapping (physical rows, first 50)

| metric_id | concept_code | domain | direction | table_path | snowflake_column |
|-----------|--------------|--------|-----------|------------|------------------|
| ONET_MAN_C089CC5535 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `EPOCH_CAPABILITY_COVERAGE` |
| ONET_MAN_11AAA20FAD | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `EPOCH_COVERED_DIMENSIONS` |
| ONET_MAN_6B6C18C8CA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `FACE_TO_FACE_SCORE` |
| ONET_MAN_6352C86822 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `FRICTION_INDEX` |
| ONET_MAN_380071AF31 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `INFORMATION_INPUT_RISK` |
| ONET_MAN_701A1551A0 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `INTERACTING_RISK` |
| ONET_MAN_9C31EBE548 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `MENTAL_PROCESS_RISK` |
| ONET_MAN_313D944C0E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `OUTDOOR_ENVIRONMENT_SCORE` |
| ONET_MAN_C2967F2011 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `PHYSICAL_BODY_SCORE` |
| ONET_MAN_B06235B3A3 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `PHYSICAL_PROXIMITY_SCORE` |
| ONET_MAN_AF3CCB56DA | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `RAW_ACTIVITY_EXPOSURE` |
| ONET_MAN_1AEB9CE189 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `SCORED_ACTIVITY_COUNT` |
| ONET_MAN_1DEB810F9E | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `TIER_HIGH_FLOOR` |
| ONET_MAN_503DE55516 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `TIER_MEDIUM_FLOOR` |
| ONET_MAN_9B387DAFE1 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `TIER_VERY_HIGH_FLOOR` |
| ONET_MAN_20B69D67B2 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `WORK_OUTPUT_RISK` |
| MET_027 | automation | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_AI_EXPOSURE` | `friction_adjusted_exposure` |
| ONET_MAN_7FA531AACC | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `FACE_TO_FACE_SCORE` |
| ONET_MAN_59BF3F3E9F | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `HAZARD_SCORE` |
| ONET_MAN_2A70030546 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `OUTDOOR_ENVIRONMENT_SCORE` |
| ONET_MAN_F395A89691 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `PHYSICAL_BODY_SCORE` |
| ONET_MAN_6854A1D2A7 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `PHYSICAL_PROXIMITY_SCORE` |
| ONET_MAN_0B35499A67 | pipeline | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `PUBLIC_CONTACT_SCORE` |
| MET_026 | automation | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_CONTEXT_FRICTION` | `friction_index` |
| ONET_MAN_D995965E54 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | `INFORMATION_INPUT_RISK` |
| ONET_MAN_6ED90626F0 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | `INTERACTING_RISK` |
| ONET_MAN_5C9015F1F6 | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | `MENTAL_PROCESS_RISK` |
| ONET_MAN_C175DF0FFF | automation | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | `SCORED_ACTIVITY_COUNT` |
| ONET_MAN_7B7F9B9F4B | automation | place | negative | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | `WORK_OUTPUT_RISK` |
| MET_025 | automation | place | neutral | `TRANSFORM.DEV.FACT_DOL_ONET_SOC_GWA_ACTIVITY_RISK` | `gwa_activity_risk_score` |


---

## Join keys, refresh detection, limitations

**[UNKNOWN — needs profiling]** unless the embedded methodology above states otherwise. Align postal vs ZCTA, CBSA vintages, and agency attribution (especially Cybersyn-sourced agency tables) before production joins.

---

## Changelog

| Date | Commit | Notes |
|------|--------|-------|
| 2026-04-23 | `[auto]` | Full intake regeneration via `scripts/docs/generate_all_vendors_intake_full.py`. |
