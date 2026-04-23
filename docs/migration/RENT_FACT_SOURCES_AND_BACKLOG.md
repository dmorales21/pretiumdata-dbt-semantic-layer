# Rent data — `TRANSFORM.DEV.FACT_*` coverage, sources, and backlog

**Purpose:** Inventory **market-rent** vendors that appear (or should appear) in **pretiumdata-dbt-semantic-layer**, how they land in Snowflake today, and which need **new typed `FACT_*` read-throughs** from Jon silver or **new builds** from RAW. Use this with **`snowsql -c pretium`** discovery queries below.

**Conventions (this repo):**

- **`FACT_*` on `TRANSFORM.DEV`:** implement **rename / cast / parse / QC** from the **true vendor landing** (`source('transform_markerr', …)`, `source('jbrec', …)`, `source('parcllabs', …)`, `source('zillow', …)`, etc.). The SQL should mirror the **pretium-ai-dbt** `cleaned_*` contracts where they exist (same column semantics), not `SELECT *` from a migration **`*_CLEANED`** table that only copies RAW.
- **`TRANSFORM.DEV.*_CLEANED` tables** from **pretium-ai-dbt** `models/transform/dev/dev_*` are **landing / parity** objects — treat them as optional QA compares, not the semantic-layer lineage root. See **pretium-ai-dbt** [`docs/migration/DEV_CLEANED_TABLES_PARITY_POLICY.md`](../../../../pretium-ai-dbt/docs/migration/DEV_CLEANED_TABLES_PARITY_POLICY.md) for keep vs retire criteria.
- **`source('transform_dev_corridor_transaction_facts', …)`:** read-only corridor tables materialized outside this repo (often **pretium-ai-dbt** `analytics/facts` with `analytics_facts_to_transform_dev`). **Do not** add a dbt model whose **alias collides** with an object documented as “existing DEV table” in `sources_transform_dev_corridor_transaction_facts.yml` unless you are intentionally taking ownership of the build.
- **`concept_rent_market_monthly`:** union of vendor arms; **`vendor_code`** must match **`REFERENCE.CATALOG.vendor.vendor_code`** (e.g. **`markerr`**, not `MARKERR_MF`). Use **`metric_id_observe`** (and dbt vars) to separate MF vs SFR Markerr lines.

---

## 1. Snowflake discovery (`snowsql -c pretium`)

Run from a machine with the **pretium** connection configured.

```sql
-- Markerr Jon schema: tables matching rent
SHOW TABLES LIKE '%RENT%' IN SCHEMA TRANSFORM.MARKERR;

-- Dev corridor / analytics-promoted facts (read-only inventory)
SHOW TABLES LIKE 'FACT_MARKERR%' IN SCHEMA TRANSFORM.DEV;
SHOW TABLES LIKE 'FACT_%RENT%' IN SCHEMA TRANSFORM.DEV;

-- CoStar silver (TRANSFORM)
SHOW TABLES IN SCHEMA TRANSFORM.COSTAR LIMIT 200;

-- Zillow raw landings live under **SOURCE_PROD.ZILLOW**, not TRANSFORM.ZILLOW (see ``sources_transform.yml`` → ``zillow`` source).
SHOW TABLES IN SCHEMA SOURCE_PROD.ZILLOW LIMIT 200;
```

**Last discovery run (pretium account, 2026-04-20):**

| Area | Finding |
|------|---------|
| **TRANSFORM.MARKERR** | ``MARKERR_RENT_SFR``, ``RENT_LISTINGS``, ``RENT_PROPERTY``, ``RENT_PROPERTY_CBSA_MONTHLY``, ``RENT_PROPERTY_MONTHLY`` |
| **TRANSFORM.DEV** rent / Markerr | ``FACT_MARKERR_RENT_COUNTY_MONTHLY``, ``FACT_MARKERR_RENT_H3_R8_MONTHLY``, ``FACT_MARKERR_RENT_LISTINGS_COUNTY_MONTHLY``, ``FACT_MARKERR_SFR_RENT_H3_R8_MONTHLY`` (base tables); ``FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY``, ``FACT_MARKERR_RENT_SFR`` (views); cleaned ``MARKERR_*_CLEANED``; ``FACT_ZILLOW_RENTALS``, ``FACT_ZILLOW_RENTAL_FORECASTS``; ``JBREC_BTR_RENT_OCCUPANCY_CLEANED``, ``PARCLLABS_RENT_LISTINGS_CLEANED``, ``ZONDA_BTR_RENT_CBSA_MONTHLY_CLEANED`` |
| **TRANSFORM.COSTAR** | ``SCENARIOS`` (and other non-rent-named tables — use ``SHOW TABLES`` / contract for rent columns) |
| **Script** | Run ``scripts/sql/validation/discover_rent_gaps_all_vendors.sql`` (bundled ``SHOW`` + ``INFORMATION_SCHEMA`` filter). |

**Implemented `FACT_*` builds (source-first):** see ``models/transform/dev/markerr/`` (Jon silver + **TRANSFORM.REF** xwalk for listings), ``jbrec/``, ``parcllabs/``, ``zonda/`` — each ports the corresponding **pretium-ai-dbt** ``cleaned_*`` logic into this repo’s dbt graph.

Document the **exact** table name for any new `source()` entry, then add **`models/sources/*.yml`** + **`models/transform/dev/<vendor>/fact_*.sql`** with explicit transforms (not corridor ``SELECT *`` from ``*_CLEANED``).

---

## 2. Current rent-related `FACT_*` in this repo (semantic layer)

| dbt model | Snowflake alias (typical) | Upstream |
|-----------|---------------------------|----------|
| `fact_markerr_rent_property_cbsa_monthly` | `FACT_MARKERR_RENT_PROPERTY_CBSA_MONTHLY` | Typed projection from `source('transform_markerr', 'rent_property_cbsa_monthly')` |
| `fact_markerr_rent_sfr` | `FACT_MARKERR_RENT_SFR` | Typed projection from `source('transform_markerr', 'markerr_rent_sfr')` (ZIP SFR fields used by rent concept) |
| `fact_markerr_rent_property` / `_listings` / `_property_monthly` | `FACT_MARKERR_RENT_*` | Jon silver + **TRANSFORM.REF** (listings) — ports **pretium-ai-dbt** ``cleaned_markerr_*`` (see model headers) |
| `fact_jbrec_btr_rent_occupancy_cleaned` | `FACT_JBREC_BTR_RENT_OCCUPANCY_CLEANED` | `source('jbrec', 'btr_rent_and_occupancy')` — ports ``cleaned_jbrec_btr_rent_and_occupancy`` |
| `fact_parcllabs_rent_listings_cleaned` | `FACT_PARCLLABS_RENT_LISTINGS_CLEANED` | `source('parcllabs', 'rent_listings')` — ports ``cleaned_parcllabs_rent_listings`` |
| `fact_zonda_btr_rent_cbsa_monthly_cleaned` | `FACT_ZONDA_BTR_RENT_CBSA_MONTHLY_CLEANED` | `source('tpanalytics_share', …)` — ports ``cleaned_zonda_btr_rent_cbsa`` |
| `fact_zillow_rentals` | (see model) | Zillow long-form rentals |
| `fact_zillow_rental_forecasts` | (see model) | Zillow forecasts |
| `fact_yardi_matrix_marketperformance_bh` | (see model) | Yardi Matrix read-through |
| `fact_yardi_matrix_submarketmatch_zipzcta_bh` | (see model) | Yardi Matrix ZIP/ZCTA crosswalk |
| `fact_costar_scenarios` | (see model) | CoStar scenarios read-through |
| `fact_hud_housing_series` (+ county/CBSA slices) | (see model) | HUD / Cybersyn housing |

**County MF rent (`FACT_MARKERR_RENT_COUNTY_MONTHLY`):** not built in this repo. It is registered on the **corridor** source as an external **`TRANSFORM.DEV`** object (built upstream—see **pretium-ai-dbt** `fact_markerr_rent_county_monthly.sql`, which compiles from **Markerr `RENT_PROPERTY`** + geography bridge). **Backlog options:**

1. **Keep** corridor `source()` for county rent until Jon publishes a **`TRANSFORM.MARKERR`** county silver table; then add **`fact_markerr_rent_county_monthly.sql`** `SELECT * FROM source('transform_markerr', '<TABLE>')` and switch MF ranker / concepts to **`ref()`** for lineage tests.
2. **Or** move the pretium-ai-dbt build into this repo’s **`transform/dev/markerr/`** and retire the duplicate DEV object (coordinate with platform—avoid two writers).

---

## 3. `concept_rent_market_monthly` — vendor arms vs catalog

| `vendor_code` on concept | Catalog vendor | MF vs mixed | Typed `FACT_*` in this repo |
|---------------------------|----------------|--------------|------------------------------|
| `ZILLOW` | `zillow` | Mixed (filter `metric_id`) | `fact_zillow_rentals`, `fact_zillow_rental_forecasts` |
| `APARTMENTIQ` | `apartmentiq` | MF operator KPIs | ApartmentIQ property sources (see model) |
| `YARDI_MATRIX` | `yardi_matrix` | MF market research | `fact_yardi_matrix_*` |
| `COSTAR` | `costar` | MF filter via dbt var | `fact_costar_scenarios` |
| **`markerr`** | **`markerr`** | **MF line:** CBSA property table + vars; **SFR line:** ZIP rollup | `fact_markerr_rent_property_cbsa_monthly`, `fact_markerr_rent_sfr` |
| `HUD_CYBERSYN` | `hud` / `cybersyn` | Administrative / survey rent | `fact_hud_housing_series_*` |
| `CHERRE` | `cherre` | Stub | Zero-row stub |

---

## 4. Registered vendors **without** a rent `FACT_*` in this repo (backlog)

These appear in **`REFERENCE.CATALOG.vendor`** and are relevant to **rent / affordability** studies but are **not** wired into `concept_rent_market_monthly` today. **JBREC / Parcl / Zonda** now have **source-first** `FACT_*` models (§2); they still need **concept / catalog** wiring when product wants them on the rent union.

Next step for each remaining vendor: confirm **RAW or TRANSFORM** landing, then add **`sources_*.yml`** + **`fact_*`** with explicit transforms (or explicit stub + IC deferral).

| `vendor_code` | Typical use | Action |
|----------------|-------------|--------|
| `apartment_list` | CBSA / national rent index | Land table → `source` → `fact_apartment_list_*` → optional concept arm |
| `jbrec` | CBSA research | Same |
| `green_street` | Scenario / effective rent context | Same |
| `realtor` | Listings / rent-adjacent | Same if metric contract is rent |
| `parcllabs` | Institutional / listings rent | Same (align with pretium-ai-dbt facts if shared) |
| `acs` / `census` | Median gross rent, tenure | Often joined via **`FACT_ACS_DEMOGRAPHICS_COUNTY`** (not always “rent concept” union) |

---

## 5. Multifamily vs non-MF in modeling

| Mechanism | Notes |
|-----------|--------|
| **`product_type` / `bridge_product_type_metric`** | Catalog binds metrics to **`mf_*`** product types for UI. |
| **CoStar** | `concept_rent_market_costar_property_type_pattern` defaults to `%Multifamily%`. |
| **Markerr** | Single catalog vendor **`markerr`**; **MF vs SFR** = different **`metric_id_observe`** + MF **bedroom/class vars** on the MF arm. |

---

## 6. Related docs

- [`docs/reference/CONTRACT_RENT_AVM_VALUATION.md`](../reference/CONTRACT_RENT_AVM_VALUATION.md) — grain, slots, add-a-vendor checklist.
- [`models/sources/sources_transform_markerr.yml`](../../models/sources/sources_transform_markerr.yml) — Markerr silver sources.
- [`models/sources/sources_transform_dev_corridor_transaction_facts.yml`](../../models/sources/sources_transform_dev_corridor_transaction_facts.yml) — external DEV facts (county rent, ranker corridor inputs).
