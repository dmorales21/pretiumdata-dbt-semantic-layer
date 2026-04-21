#!/usr/bin/env python3
"""Generate CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md from catalog table list."""
from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
ART = ROOT / "docs/migration/artifacts/cybersyn_global_government_catalog_table_names.tsv"
OUT = ROOT / "docs/reference/CYBERSYN_GLOBAL_GOVERNMENT_BRING_IN_MATRIX.md"


def pit_note(name: str) -> str:
    if name.endswith("_pit"):
        return (
            "Source object name ends with `_pit`: treat as **latest / as-of / snapshot-history** support in "
            "SOURCE_SNOW; do not name REFERENCE outputs “PIT”."
        )
    return ""


def deprioritized(name: str) -> bool:
    n = name.lower()
    if n.startswith(("openalex_", "github_")):
        return True
    if n.startswith("world_bank_") or n.startswith("oecd_"):
        return True
    if n.startswith("sec_"):
        return True
    if n.startswith("xbrl_"):
        return True
    if n.startswith("stock_price_"):
        return True
    if n.startswith("permid_") or n.startswith("openfigi_"):
        return True
    if n.startswith("company_"):
        return True
    return False


def classify(name: str) -> tuple[int, str, str, str, str, list[str]]:
    """Returns tier, purpose, grain, geo_levels, target_layer, notes list."""
    n = name.lower()
    notes: list[str] = []
    pn = pit_note(name)
    if pn:
        notes.append(pn)

    if deprioritized(name):
        notes.append("De-prioritized for first-order geography + housing real-estate intelligence.")

    # default
    tier = 99
    purpose = "Cybersyn GLOBAL_GOVERNMENT share object (see catalog DESCRIPTION / DESCRIBE)."
    grain = "varies"
    geo = "varies / non-geo-native unless domain-specific"
    target = "SOURCE_SNOW"

    # Tier 1 — geography backbone
    if n.startswith("geography_"):
        tier = 1
        target = "SOURCE_SNOW"
        geo = "all Cybersyn LEVEL strings on index; cross-level on relationships/hierarchy/overlaps"
        if n.startswith("geography_index"):
            purpose = "Master geography registry (GEO_ID, GEO_NAME, LEVEL, …)."
            grain = "1 row per GEO_ID" if not n.endswith("_pit") else "1 row per GEO_ID × as-of snapshot grain (when populated)"
        elif n.startswith("geography_characteristics"):
            purpose = "Codes, labels, and geometry payloads keyed by GEO_ID (RELATIONSHIP_TYPE + VALUE)."
            grain = "1 row per GEO_ID × characteristic type (per snapshot table)"
        elif n.startswith("geography_relationships"):
            purpose = "Flexible geo↔geo edges (Contains, Overlaps, …) for rollups and allocation logic."
            grain = "1 row per geo pair × relationship type"
        elif n.startswith("geography_hierarchy"):
            purpose = "Stricter parent→child hierarchy when you need a single canonical parent path."
            grain = "1 row per child GEO_ID × parent GEO_ID (when populated)"
        elif n.startswith("geography_overlaps"):
            purpose = "Overlap / allocation relationships (e.g. tract↔ZCTA) distinct from strict hierarchy."
            grain = "1 row per overlap pair × relationship"
        notes.append(
            "Before joins to REFERENCE.CATALOG or TRANSFORM facts, map raw LEVEL → `geo_level_code` "
            "(e.g. CensusCoreBasedStatisticalArea→cbsa, CensusZipCodeTabulationArea→zcta, CensusTract→tract, "
            "CensusBlockGroup→block_group, County→county, State→state, City→city) using "
            "REFERENCE.GEOGRAPHY.GEOGRAPHY_LEVEL_DICTIONARY."
        )
        return tier, purpose, grain, geo, target, notes

    # Tier 2 — housing, demographics, migration core
    t2_prefixes = (
        "us_real_estate_",
        "housing_urban_development_",
        "american_community_survey_",
        "irs_origin_destination_migration_",
        "irs_migration_by_characteristic_",
        "usps_address_change_",
    )
    if any(n.startswith(p) for p in t2_prefixes):
        tier = 2
        target = "SOURCE_SNOW"
        geo = "county, tract, ZCTA/ZIP-like, CBSA, state (domain-dependent)"
        if "attributes" in n:
            purpose = "Variable / measure dictionary for the domain."
            grain = "1 row per variable (or attribute key)"
        elif "timeseries" in n:
            purpose = "Long-form metrics: geo × date × variable."
            grain = "1 row per GEO_ID × date × variable (wide→tall in TRANSFORM)"
        else:
            purpose = "Core housing / demographic / migration object."
            grain = "see DESCRIBE"
        return tier, purpose, grain, geo, target, notes

    # Tier 3 — housing finance
    t3_prefixes = ("fhfa_", "freddie_mac_housing_", "home_mortgage_disclosure_")
    if any(n.startswith(p) for p in t3_prefixes):
        tier = 3
        target = "SOURCE_SNOW"
        geo = "county, CBSA, state; tract/HMDA where applicable"
        if "attributes" in n:
            purpose = "Housing-finance variable metadata."
            grain = "1 row per variable"
        elif "timeseries" in n:
            purpose = "Housing-finance metrics time series."
            grain = "1 row per GEO_ID × date × variable"
        else:
            purpose = "Housing-finance catalog object."
            grain = "varies"
        return tier, purpose, grain, geo, target, notes

    # Tier 4 — institutions / lender footprint
    t4_prefixes = (
        "financial_institution_",
        "financial_branch_",
        "fdic_",
    )
    if any(n.startswith(p) for p in t4_prefixes):
        tier = 4
        target = "SOURCE_SNOW"
        geo = "institution entity; branch point/address; county/state for SOD aggregates"
        purpose = "Lender / branch / deposits universe (FDIC + institution models)."
        if "index" in n or n.endswith("_entities"):
            grain = "1 row per entity or branch registry row"
        elif "attributes" in n:
            grain = "1 row per variable / attribute"
        elif "timeseries" in n:
            grain = "1 row per entity × date × variable"
        elif "hierarchy" in n or "relationships" in n:
            grain = "1 row per relationship edge"
        else:
            grain = "varies"
        return tier, purpose, grain, geo, target, notes

    # Tier 5 — crime, weather, disaster
    t5_prefixes = (
        "fbi_crime_",
        "urban_crime_",
        "nws_weather_",
        "fema_",
        "noaa_",  # weather / water where relevant to property risk
    )
    if any(n.startswith(p) for p in t5_prefixes):
        tier = 5
        target = "SOURCE_SNOW"
        geo = "city, county, state, tract-ish, weather zone/station, declaration area"
        if "incident" in n:
            purpose = "Event-level crime or incident feed."
            grain = "1 row per incident"
        elif "attributes" in n:
            purpose = "Risk-overlay variable dictionary."
            grain = "1 row per variable"
        elif "timeseries" in n:
            purpose = "Risk-overlay metrics time series."
            grain = "1 row per geo × date × variable"
        else:
            purpose = "Risk / environment overlay index or relationship object."
            grain = "varies"
        return tier, purpose, grain, geo, target, notes

    # Tier 6 — address / POI
    t6_prefixes = ("us_addresses", "point_of_interest_", "airport_index")
    if any(n.startswith(p) for p in t6_prefixes):
        tier = 6
        target = "SOURCE_SNOW"
        geo = "point / address; join up to tract/county via TRANSFORM enrichment"
        purpose = "Address and POI spine for geo-anchoring and nearest-feature workflows."
        if "relationships" in n:
            grain = "1 row per POI × address edge"
        elif n.endswith("_index") or n == "us_addresses" or n.startswith("us_addresses"):
            grain = "1 row per address / POI / airport"
        else:
            grain = "varies"
        return tier, purpose, grain, geo, target, notes

    # BLS / Fed / intl macro — keep SOURCE_SNOW but not housing-first
    if n.startswith("bureau_of_labor_statistics") or n.startswith("federal_reserve"):
        tier = 88
        purpose = "Labor / price macro (supporting context for housing demand; not first-order home price series)."
        return tier, purpose, grain, geo, target, notes

    return tier, purpose, grain, geo, target, notes


def main() -> None:
    names = [ln.strip() for ln in ART.read_text().splitlines() if ln.strip()]
    rows: list[tuple[int, str, str, str, str, str, str, str]] = []
    for name in names:
        tier, purpose, grain, geo, target, notes = classify(name)
        rows.append((tier, name, purpose, grain, geo, target, " ".join(notes)))

    rows.sort(key=lambda r: (r[0], r[1]))

    lines: list[str] = []
    lines.append("# Cybersyn bring-in matrix — `SOURCE_SNOW.GLOBAL_GOVERNMENT.CYBERSYN_DATA_CATALOG`")
    lines.append("")
    lines.append("**Source of truth for `table_name`:** `SELECT DISTINCT TABLE_NAME` from ")
    lines.append("`SOURCE_SNOW.GLOBAL_GOVERNMENT.CYBERSYN_DATA_CATALOG` (353 rows on 2026-04-19 snapshot).")
    lines.append("")
    lines.append("**Full name list (machine-readable):** `docs/migration/artifacts/cybersyn_global_government_catalog_table_names.tsv`.")
    lines.append("")
    lines.append("## Validation — `REFERENCE.CATALOG` geography levels")
    lines.append("")
    lines.append("Canonical **`geo_level_code`** and the Snowflake Cybersyn crosswalk live in a single file: ")
    lines.append("`seeds/reference/catalog/geo_level.csv` (column **`source_snow_cybersyn_level`** = exact ")
    lines.append("`LEVEL` on `SOURCE_SNOW.GLOBAL_GOVERNMENT.CYBERSYN.GEOGRAPHY_INDEX`). **`REFERENCE.GEOGRAPHY.GEOGRAPHY_LEVEL_DICTIONARY`** ")
    lines.append("is a **table model** built from that seed (non-null `source_snow_cybersyn_level` rows only). Warehouse joins use ")
    lines.append("stable codes such as **`zcta`**, **`tract`**, **`block_group`**, **`city`** — not raw vendor strings.")
    lines.append("")
    lines.append("| Cybersyn `LEVEL` (examples) | Dictionary `canonical_geo_level_code` |")
    lines.append("|-----------------------------|----------------------------------------|")
    lines.append("| CensusCoreBasedStatisticalArea | cbsa |")
    lines.append("| CensusZipCodeTabulationArea | zcta |")
    lines.append("| CensusTract | tract |")
    lines.append("| CensusBlockGroup | block_group |")
    lines.append("| County | county |")
    lines.append("| State | state |")
    lines.append("| City | city |")
    lines.append("")
    lines.append(
        "**Product vs census postal:** `geo_level.csv` keeps **`zip`** for USPS-style product grain; census-spine facts "
        "should use **`zcta`** where the geography is ZCTA-backed (`source_snow_cybersyn_level` = CensusZipCodeTabulationArea). "
        "Register datasets with the correct `geo_level_code` so facts align with **`REFERENCE.CATALOG.geo_level`**."
    )
    lines.append("")
    lines.append("## Naming — latest vs source `_pit` tables")
    lines.append("")
    lines.append(
        "When a **source** `table_name` ends with `_pit`, treat it operationally as **latest / as-of / "
        "snapshot-history** support material in **SOURCE_SNOW**. Do not describe **REFERENCE** outputs using "
        "the word “PIT” unless you are quoting the underlying Snowflake table name."
    )
    lines.append("")
    lines.append("## REFERENCE.GEOGRAPHY — canonical utilities (dbt in this repo)")
    lines.append("")
    lines.append("| Snowflake object | purpose | target_layer |")
    lines.append("|------------------|---------|--------------|")
    lines.append("| `REFERENCE.GEOGRAPHY.GEOGRAPHY_LEVEL_DICTIONARY` | `LEVEL` → `geo_level_code` (from `REFERENCE.CATALOG.geo_level.source_snow_cybersyn_level`) | REFERENCE |")
    lines.append("| `REFERENCE.GEOGRAPHY.GEOGRAPHY_INDEX` | Normalized registry + canonical level | REFERENCE |")
    lines.append("| `REFERENCE.GEOGRAPHY.GEOGRAPHY_CODES` | Pivoted FIPS / state abbrev | REFERENCE |")
    lines.append("| `REFERENCE.GEOGRAPHY.GEOGRAPHY_SHAPES` | Pivoted WKT / GeoJSON / `GEOGRAPHY` | REFERENCE |")
    lines.append("| `REFERENCE.GEOGRAPHY.GEOGRAPHY_RELATIONSHIPS` | Canonicalized edges | REFERENCE |")
    lines.append(
        "| `REFERENCE.GEOGRAPHY.GEOGRAPHY_CURRENT` | **Architecture name** for flattened current-use join surface "
        "(index+codes+shapes+parents). **Physical dbt relation today:** `GEOGRAPHY_LATEST` — same role; rename "
        "warehouse object to `CURRENT` only when you intentionally align names. | REFERENCE |"
    )
    lines.append("")
    lines.append("## Placement rules")
    lines.append("")
    lines.append("- **REFERENCE** — canonical shared utilities and reusable spines (dictionary, index, codes, shapes, relationships, flattened current join).")
    lines.append("- **SOURCE_SNOW** — native share tables; read or thin-wrap; do not dump raw vendor copies into REFERENCE.")
    lines.append("- **TRANSFORM** — normalized tall `FACT_*` / `CONCEPT_*` built from SOURCE_SNOW + REFERENCE joins, QA, semantic-ready.")
    lines.append("")
    lines.append(
        "This catalog lists **SOURCE_SNOW** base `table_name` values only. **`TRANSFORM`** objects are your dbt "
        "models (not rows in `CYBERSYN_DATA_CATALOG`)."
    )
    lines.append("")
    lines.append("## Matrix — `tier` column (priority tiers)")
    lines.append("")
    lines.append("| tier | Meaning |")
    lines.append("|------|---------|")
    lines.append("| **1** | Tier 1 — geography backbone |")
    lines.append("| **2** | Tier 2 — housing, demographics, migration core |")
    lines.append("| **3** | Tier 3 — housing finance and mortgage performance |")
    lines.append("| **4** | Tier 4 — financial institutions and lender footprint |")
    lines.append("| **5** | Tier 5 — crime, weather, disaster, risk overlays |")
    lines.append("| **6** | Tier 6 — address and POI support layers |")
    lines.append("| **88** | Supporting macro (e.g. BLS, Fed) — not first-order housing price series |")
    lines.append("| **99** | Other catalog objects; includes **de-prioritized** domains per governance note |")
    lines.append("")
    lines.append("## Matrix (all catalog `table_name` values)")
    lines.append("")
    lines.append("| tier | table_name | purpose | likely_grain | likely_geo_levels | target_layer | notes |")
    lines.append("|------|------------|---------|--------------|-------------------|--------------|-------|")
    for tier, name, purpose, grain, geo, target, note in rows:
        esc = lambda s: s.replace("|", "\\|").replace("\n", " ")
        lines.append(
            f"| {tier} | `{name}` | {esc(purpose)} | {esc(grain)} | {esc(geo)} | {target} | {esc(note)} |"
        )
    lines.append("")
    lines.append("## Recommended first-cut shortlist (minimum viable geography + housing)")
    lines.append("")
    lines.append("| table_name | why |")
    lines.append("|------------|-----|")
    lines.append("| `geography_index` | Registry for every downstream geo join and LEVEL crosswalk. |")
    lines.append("| `geography_characteristics` | FIPS, WKT, GeoJSON payloads for codes + shapes. |")
    lines.append("| `geography_relationships` | CBSA/county/tract/ZCTA rollups and overlaps without bespoke SQL. |")
    lines.append("| `geography_hierarchy` | Single-parent paths when relationships are too permissive. |")
    lines.append("| `geography_overlaps` | Tract↔ZCTA-style allocation edges for housing market ZIP/ZCTA semantics. |")
    lines.append("| `geography_*` tables whose names end with `_pit` | As-of / snapshot-history companion reads when you must reproduce vendor vintage. |")
    lines.append("| `us_real_estate_attributes` + `us_real_estate_timeseries` | Core Cybersyn real-estate metrics spine. |")
    lines.append("| `housing_urban_development_attributes` + `housing_urban_development_timeseries` | HUD-aligned housing supply/demand context. |")
    lines.append("| `american_community_survey_attributes` + `american_community_survey_timeseries` | Demographic / tenure / rent burden controls at census geographies. |")
    lines.append("| `irs_migration_by_characteristic_timeseries` + `irs_origin_destination_migration_timeseries` | Migration demand-side narratives tied to counties/states. |")
    lines.append("| `usps_address_change_timeseries` | Mobility / churn proxy at postal-ish geographies. |")
    lines.append("")
    lines.append(
        "**Why this set:** you cannot build a governed **TRANSFORM** fact layer on Cybersyn housing series without "
        "the **geography backbone** (index + characteristics + relationships + hierarchy + overlaps) and the "
        "**variable + timeseries** pairs for real estate, HUD, ACS, and migration. Everything else in the catalog "
        "either supports overlays later (FHFA, HMDA, crime, weather, FEMA) or is intentionally de-prioritized for "
        "first-order real-estate intelligence."
    )
    lines.append("")
    OUT.write_text("\n".join(lines) + "\n")
    print("Wrote", OUT, "rows", len(rows))


if __name__ == "__main__":
    main()
