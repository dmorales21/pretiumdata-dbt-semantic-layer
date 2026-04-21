# QA §0 — Concept preflight checklist (geography + vendors)

**Owner:** Alex (primary) · **DE** (grants, env parity)  
**Source:** [`QA_METRIC_LAYER_VALIDATION.md`](./QA_METRIC_LAYER_VALIDATION.md) §0–§0.1  
**Why:** `CONCEPT_*` failures are usually **missing xwalks**, **no SELECT on REFERENCE.GEOGRAPHY**, or **vendor grants** — not SQL in the concept model.

**Stats + ACF for `FEATURE_*`:** [`CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md`](../reference/CONCEPT_FEATURE_STATISTICAL_METADATA_AND_AUTOCORRELATION.md).

**How to use:** In Snowflake (worksheet or `snowsql`), run each **§0 global** check once per quarter per account. Then, for each `CONCEPT_*` you depend on this quarter, tick **Vendor / FACT** rows after `dbt run` proves parents build.

---

## A. Global §0 checks (once per environment / quarter)

| # | Check | SQL or action | Done |
|---|--------|---------------|------|
| A1 | ZIP ↔ H3 R8 polyfill | `SELECT COUNT(*) FROM REFERENCE.GEOGRAPHY.BRIDGE_ZIP_H3_R8_POLYFILL` (or mirror under `ANALYTICS.REFERENCE`) | [ ] |
| A2 | BG ↔ H3 R8 polyfill | `SELECT COUNT(*) FROM REFERENCE.GEOGRAPHY` — identifier per `h3_polyfill_bg_bridge_identifier` / compat table | [ ] |
| A3 | H3 bridge override (if needed) | If xwalks live only under `ANALYTICS.REFERENCE`, set vars per QA §0 and re-run corridor / hex facts | [ ] |
| A4 | `reference_geography.county` | `source('reference_geography','county')` resolves; `SELECT 1` smoke | [ ] |
| A5 | `reference_geography.cbsa` | same | [ ] |
| A6 | `zip_county_xwalk` | same | [ ] |
| A7 | `postal_county_xwalk` | same | [ ] |
| A8 | `county_cbsa_xwalk` | same | [ ] |
| A9 | `zcta_cbsa_xwalk` | same | [ ] |
| A10 | CBSA ↔ H3 (corridor) | `CBSA_H3_R8_POLYFILL` if LODES / hex panels in scope | [ ] |
| A11 | Inventory script | `scripts/sql/migration/inventory_corridor_pipeline_critical.sql` archived / reviewed | [ ] |

---

## B. Per-`CONCEPT_*` — vendors & geo this quarter

Legend: **Zip spine** = macro `reference_geo_zip_to_cbsa_ctes()` (uses `reference_geography` ZIP/ZCTA → county/CBSA). **CBSA** = LPAD 5-digit / `reference_geography` CBSA spine.

| Concept model | Zip spine | CBSA / county spine | Key vendors / FACTs (grants) | Done |
|---------------|-----------|---------------------|------------------------------|------|
| `concept_rent_market_monthly` | [ ] Yardi ZIP, Markerr SFR, ApartmentIQ→CBSA | [ ] Zillow, CoStar, Markerr MF, HUD CBSA | Zillow rentals/forecasts; ApartmentIQ; Yardi Matrix; CoStar `SCENARIOS`; Markerr; `fact_hud_housing_series`; `transform_dev.fact_costar_cbsa_monthly` (MF wide); Cherre stub (0 rows OK) | [ ] |
| `concept_rent_property_monthly` | [ ] ApartmentIQ PROPERTY→ZIP | [ ] `zip_enriched` → CBSA | `transform_apartmentiq.*`; Cherre / Yardi stubs (0 rows OK) | [ ] |
| `concept_avm_market_monthly` | — | [ ] Cherre MA/CBSA | `cherre_avm_geo_stats` / `TRANSFORM.CHERRE`; Redfin stub (0 rows OK) | [ ] |
| `concept_valuation_market_monthly` | [ ] Zillow ZIP if branch uses | [ ] Cherre, FHFA CBSA, Zillow CBSA | Cherre; `fact_zillow_home_values`; FHFA facts | [ ] |
| `concept_listings_market_monthly` | — | [ ] Realtor CBSA; Zillow CBSA | `fact_realtor_inventory_cbsa`; Zillow DOM + for-sale listings | [ ] |
| `concept_transactions_market_monthly` | [ ] if ZIP branch | [ ] CBSA | `fact_zillow_sales` | [ ] |
| `concept_home_price_market_monthly` | [ ] Zillow ZIP paths | [ ] CBSA / county | Zillow; FHFA; affordability; listings aux | [ ] |
| `concept_employment_market_monthly` | — | [ ] BLS LAUS CBSA (AREA_CODE) | `fact_bls_laus_cbsa_monthly` — **not** guaranteed OMB CBSA | [ ] |
| `concept_unemployment_market_monthly` | — | [ ] same | same | [ ] |
| `concept_occupancy_market_monthly` | — | [ ] HUD CBSA | `fact_hud_housing_series_cbsa_monthly` | [ ] |
| `concept_migration_market_annual` | [ ] county rollup | [ ] CBSA | IRS SOI facts / Cybersyn | [ ] |
| `concept_delinquency_market_monthly` | [ ] county rollup | [ ] CBSA | FHFA mortgage performance | [ ] |

---

## C. `FEATURE_*` → upstream alignment (Phase B)

**Target pattern:** `FEATURE_*` reads **`ref('concept_*')`** for market unions; **`ref('fact_*')`** only when the FEATURE is **narrow transform math** on one fact grain (documented exception).

| FEATURE model | Upstream today | Preferred parent | Status |
|---------------|----------------|------------------|--------|
| `feature_rent_market_monthly_spine` | `ref('concept_rent_market_monthly')` | Concept | **Aligned** |
| `feature_listings_velocity_monthly_spine` | `fact_zillow_days_on_market_and_price_cuts`, `fact_zillow_for_sale_listings` | `concept_listings_market_monthly` (reshape to preserve `MET_042`/`MET_043` contract) | **Exception** — see model header |
| `feature_employment_delta_cbsa_monthly` | `ref('fact_bls_laus_county')` + `source('reference_geography','county_cbsa_xwalk')` | Could consume `concept_employment_*` later; today **county LAUS roll** | **Exception** — county YoY not stored on concept |
| `feature_home_price_delta_zip_monthly` | `ref('fact_zillow_home_values')` | ZIP YoY math; concept is multi-vendor CBSA-heavy | **Exception** — ZIP-only FEATURE |
| `feature_supply_pressure_cbsa_monthly` | `ref('fact_realtor_inventory_cbsa')` | Filter `concept_listings_market_monthly` vendor `REALTOR` | **Exception** — optional enable var |
| `feature_ai_replacement_risk_*` / `feature_ai_risk_county_bivariate` | FACT / FEATURE chain | Not driven by market `CONCEPT_*` | **N/A** (labor stack) |
| `feature_structural_unemployment_risk_county` | `ref('feature_ai_replacement_risk_county')` | FEATURE chain | **N/A** |

---

## D. Changelog

| Ver | Date | Notes |
|-----|------|--------|
| 0.1 | 2026-04-20 | Initial checklist: §0 global ticks, per-concept vendor/geo matrix, FEATURE alignment table. |
