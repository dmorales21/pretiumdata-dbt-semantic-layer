# Concept Vendor Metric Integration Backlog

**Owner:** Alex  
**Purpose:** Track which active `REFERENCE.CATALOG.METRIC` vendor feeds are wired into `models/transform/dev/concept/` and what to add next.

**Ranked MET / derived / mart queue (concept → slug → path):** [`METRIC_BUILD_BACKLOG_BY_CONCEPT.md`](./METRIC_BUILD_BACKLOG_BY_CONCEPT.md).

**Active MET inventory by `concept_code`:** [`CATALOG_METRICS_BY_CONCEPT_INVENTORY.md`](./CATALOG_METRICS_BY_CONCEPT_INVENTORY.md) — regenerate with `python scripts/ci/print_catalog_metrics_by_concept_inventory.py` after bulk `metric.csv` changes.

---

## Coverage snapshot (current)

### Well-covered concepts

- `rent`: Zillow, CoStar, Markerr, Yardi, HUD are wired in `concept_rent_market_monthly`.
- `homeprice`: Zillow + FHFA (CBSA monthly compatibility models) wired in `concept_home_price_market_monthly`.
- `listings`: Realtor + Zillow DOM + Zillow for-sale listings wired in `concept_listings_market_monthly` (CBSA monthly wide slots).
- `absorption`: CoStar MF absorption units/pct and similar **demand-clearing** measures; do not conflate with on-market **listings** inventory.
- `transactions`: Zillow sales wired in `concept_transactions_market_monthly`.
- `employment`: BLS LAUS CBSA wired in `concept_employment_market_monthly`.
- `unemployment`: BLS LAUS CBSA wired in `concept_unemployment_market_monthly`.
- `occupancy`: HUD CBSA monthly wired in `concept_occupancy_market_monthly`.
- `migration`: IRS county + CBSA wired in `concept_migration_market_annual`.
- `delinquency`: FHFA mortgage performance county + CBSA wired in `concept_delinquency_market_monthly`.

### Remaining active metric families with concept gaps

- `employment` (BLS QCEW / county SOC):
  - `FACT_BLS_QCEW_COUNTY_NAICS_QUARTERLY`
  - `FACT_COUNTY_SOC_EMPLOYMENT`
- `unemployment` (county path not represented):
  - `FACT_BLS_LAUS_COUNTY`
- `permits`:
  - `FACT_BPS_PERMITS_COUNTY`
- `pipeline`:
  - `FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY`
  - `FACT_CHERRE_VACANT_H3_R8_SNAPSHOT`
- `automation`:
  - `FACT_DOL_ONET_SOC_*`, `FACT_COUNTY_AI_REPLACEMENT_RISK`, `REF_EPOCH_TO_GWA_CROSSWALK`

---

## Next concept additions (execution order)

1. **`concept_permits_market_monthly`**
   - Vendor: Census BPS.
   - Metric slots: `permits_current`, `permits_historical`.
2. **`concept_supply_pipeline_market_monthly`**
   - Vendor: Markerr listings county (+ Cherre vacant when CBSA-compatible policy is set).
   - Metric slots: `pipeline_current`, `pipeline_historical`.
3. **`concept_workforce_task_automation_annual`**
   - Vendors: O*NET, Epoch, BLS county risk.
   - Metric slots: `automation_current`, `automation_historical`.

---

## Build queue (active)

- [x] `concept_migration_market_annual` (IRS county/cbsa)
- [x] `concept_delinquency_market_monthly` (FHFA mortgage performance county/cbsa)
- [ ] `concept_permits_market_monthly` (BPS permits)
- [ ] `concept_supply_pipeline_market_monthly` (Markerr listings + Cherre vacant; catalog `pipeline`)
- [ ] `concept_workforce_task_automation_annual` (O*NET / Epoch / county AI risk; catalog `automation`)

---

## Rules for adding vendor metrics to concept objects

- Use active `metric.csv` rows as source-of-truth for `concept_code`, `vendor_code`, and `table_path`.
- Prefer `_monthly` compatibility fact objects where catalog `table_path` uses that naming.
- Keep one row per `(vendor_code, month_start, geo_id, metric_id_observe)` after metric ranking/picking.
- Add lightweight model tests in `models/transform/dev/concept/schema.yml`:
  - `not_null`: `concept_code`, `vendor_code`, `month_start`, `geo_level_code`, `geo_id`
  - `accepted_values`: `concept_code`, `geo_level_code`
- Update `SERVING_DEMO_METRICS_CATALOG_MAP.md` status when a concept closes a gap.
