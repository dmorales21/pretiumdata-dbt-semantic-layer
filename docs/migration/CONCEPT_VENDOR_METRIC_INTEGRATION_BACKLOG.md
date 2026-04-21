# Concept Vendor Metric Integration Backlog

**Owner:** Alex  
**Purpose:** Track which active `REFERENCE.CATALOG.METRIC` vendor feeds are wired into `models/transform/dev/concept/` and what to add next.

**Ranked MET / derived / mart queue (concept → slug → path):** [`METRIC_BUILD_BACKLOG_BY_CONCEPT.md`](./METRIC_BUILD_BACKLOG_BY_CONCEPT.md).

**Active MET inventory by `concept_code`:** [`CATALOG_METRICS_BY_CONCEPT_INVENTORY.md`](./CATALOG_METRICS_BY_CONCEPT_INVENTORY.md) — regenerate with `python scripts/ci/print_catalog_metrics_by_concept_inventory.py` after bulk `metric.csv` changes.

**Corridor concept observe metrics (catalog):** `MET_127`–`MET_130` (`transactions` on `TRANSFORM.DEV.CONCEPT_TRANSACTIONS_MARKET_MONTHLY`), `MET_131`–`MET_132` (`supply_pipeline` on `TRANSFORM.DEV.CONCEPT_SUPPLY_PIPELINE_MARKET_MONTHLY`), `MET_144` / `MET_145` (Zonda SFR branches on those marts), `MET_133`–`MET_138` (`crime` on `CONCEPT_CRIME_MARKET_ANNUAL`), `MET_139`–`MET_142` (`school_quality` on `CONCEPT_SCHOOL_QUALITY_MARKET_ANNUAL`), `MET_143` (`rates` on `CONCEPT_RATES_NATIONAL_MONTHLY`) — align `metric_id_observe` + `vendor_code` filters when joining.

---

## Coverage snapshot (current)

### Well-covered concepts

- `rent`: Zillow, CoStar, Markerr, Yardi, HUD are wired in `concept_rent_market_monthly`.
- `homeprice`: Zillow + FHFA (CBSA monthly compatibility models) wired in `concept_home_price_market_monthly`.
- `listings`: Realtor + Zillow DOM + Zillow for-sale listings wired in `concept_listings_market_monthly` (CBSA monthly wide slots).
- `absorption`: CoStar MF absorption units/pct and similar **demand-clearing** measures; do not conflate with on-market **listings** inventory.
- `transactions`: Zillow sales plus **Cherre** recorder SFR/MF, **RCA** MF H3, and **Zonda** deeds (CBSA rollups) in `concept_transactions_market_monthly` when ``vars.concept_transactions_include_cherre_rca_zonda`` is true (default). Catalog: **MET_127–MET_130**; ``metric_id_observe`` on the concept equals each row’s **metric_code** (e.g. ``concept_transactions_cherre_recorder_sfr_sale_count_cbsa_monthly``).
- `employment`: BLS LAUS CBSA wired in `concept_employment_market_monthly`.
- `unemployment`: BLS LAUS CBSA wired in `concept_unemployment_market_monthly`.
- `occupancy`: HUD CBSA monthly wired in `concept_occupancy_market_monthly`.
- `migration`: IRS county + CBSA wired in `concept_migration_market_annual`.
- `delinquency`: FHFA mortgage performance county + CBSA wired in `concept_delinquency_market_monthly`.

### Remaining active metric families with concept gaps

- `crime` (Markerr amenity vs crime snapshot): **CBSA annual mart** `concept_crime_market_annual` + catalog `MET_133`–`MET_138` (join on `metric_id_observe`).
- `employment` (BLS QCEW / county SOC):
  - `FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY`
  - `FACT_COUNTY_SOC_EMPLOYMENT`
- `unemployment` (county path not represented):
  - `FACT_BLS_LAUS_COUNTY`
- `permits`:
  - `FACT_BPS_PERMITS_COUNTY`
- `pipeline`:
  - `FACT_CHERRE_VACANT_*` — **not** in monthly supply concept (snapshot lacks observation month); use `concept_vacancy_market_monthly` / future dated vacant FACT
- `automation`:
  - `FACT_DOL_ONET_SOC_*`, `FACT_COUNTY_AI_REPLACEMENT_RISK`, `REF_EPOCH_TO_GWA_CROSSWALK`

---

## Next concept additions (execution order)

1. **`concept_permits_market_monthly`**
   - Vendor: Census BPS.
   - Metric slots: `permits_current`, `permits_historical`.
2. **`concept_supply_pipeline_market_monthly`** *(shipped — Realtor + Zillow NC + Markerr listings + RCA MF construction CBSA rollups; Cherre vacant still snapshot-only)*
   - Vendors: **Realtor** CBSA; **Zillow** new construction CBSA; **Markerr** ``FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY``; **RCA** ``FACT_RCA_MF_CONSTRUCTION_COUNTY_MONTHLY`` (``source('transform_dev_corridor_transaction_facts', …)``).
   - Metric slots: ``supply_pipeline_current`` / ``supply_pipeline_historical`` (``concept_metric_slot('supply_pipeline', …)``).
3. **`concept_workforce_task_automation_annual`**
   - Vendors: O*NET, Epoch, BLS county risk.
   - Metric slots: `automation_current`, `automation_historical`.

---

## Build queue (active)

- [x] `concept_migration_market_annual` (IRS county/cbsa)
- [x] `concept_delinquency_market_monthly` (FHFA mortgage performance county/cbsa)
- [x] `concept_permits_market_monthly` (BPS permits)
- [x] `concept_supply_pipeline_market_monthly` (Realtor + Zillow NC + **Markerr** listings + **RCA** MF construction UC; Cherre vacant TBD dated FACT)
- [x] `concept_workforce_task_automation_annual` (BLS / O*NET / Epoch county AI replacement risk + CBSA / national rollups; catalog `automation`)

---

## Rules for adding vendor metrics to concept objects

- Use active `metric.csv` rows as source-of-truth for `concept_code`, `vendor_code`, and `table_path`.
- Prefer `_monthly` compatibility fact objects where catalog `table_path` uses that naming.
- Keep one row per `(vendor_code, month_start, geo_id, metric_id_observe)` after metric ranking/picking.
- Add lightweight model tests in `models/transform/dev/concept/schema.yml`:
  - `not_null`: `concept_code`, `vendor_code`, `month_start`, `geo_level_code`, `geo_id`
  - `accepted_values`: `concept_code`, `geo_level_code`
- Update `SERVING_DEMO_METRICS_CATALOG_MAP.md` status when a concept closes a gap.
