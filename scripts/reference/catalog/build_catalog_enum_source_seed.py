#!/usr/bin/env python3
"""
Build:
  1) seeds/reference/catalog/catalog_enum_source.csv — merged rows for small catalog enums
     (replaces ~55 per-enum CSVs in Snowflake / dbt).
  2) models/reference/catalog/enum_refs/erf__*.sql — ephemeral code lists for dbt `relationships` tests.

**Excluded** from the merge (remain standalone seeds; also unioned in `catalog_enum`):
  frequency, asset_type, tenant_type

Regenerate after editing any dropped per-enum CSV **before** deleting it, or edit **catalog_enum_source.csv**
directly once cutover is done.

Run from repo root:
  python3 scripts/reference/catalog/build_catalog_enum_source_seed.py
"""
from __future__ import annotations

import csv
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
CAT = ROOT / "seeds" / "reference" / "catalog"
ENUM_REFS = ROOT / "models" / "reference" / "catalog" / "enum_refs"

# Must match logical tables previously unioned in catalog_enum, minus dimension seeds kept on disk.
MERGED_ENUM_TABLES: tuple[str, ...] = (
    "absorption_tier",
    "amenity_tier",
    "bath_type",
    "bedroom_type",
    "cap_rate_tier",
    "class",
    "construction_status",
    "crime_tier",
    "data_status",
    "deal_status",
    "delinquency_bucket",
    "dscr_tier",
    "employment_sector",
    "estimate_type",
    "exit_strategy",
    "flood_zone",
    "function",
    "geography_status",
    "hoa_type",
    "hold_period",
    "income_band",
    "insurance_type",
    "investment_strategy",
    "lease_term",
    "loan_type",
    "ltv_tier",
    "market_cycle_phase",
    "market_status",
    "market_tier",
    "metric_category",
    "migration_type",
    "model_type",
    "natural_hazard_type",
    "noi_tier",
    "occupancy_status",
    "ownership_type",
    "parking_type",
    "permit_type",
    "population_segment",
    "portfolio_size_tier",
    "price_tier",
    "property_condition",
    "promotion_gate",
    "rate_type",
    "renovation_type",
    "rent_tier",
    "risk_rating",
    "school_rating_tier",
    "score_tier",
    "tenancy",
    "transit_score_tier",
    "units_in_structure",
    "utility_type",
    "vacancy_tier",
    "vintage",
    "walk_score_tier",
    "zoning_type",
)

SPECIAL = {
    "delinquency_bucket": ("bucket_code", "bucket_label"),
    "employment_sector": ("sector_code", "sector_label"),
    "geography_status": ("geo_status_code", "geo_status_label"),
    "investment_strategy": ("strategy_code", "strategy_label"),
    "market_cycle_phase": ("phase_code", "phase_label"),
    "metric_category": ("category_code", "category_label"),
    "natural_hazard_type": ("hazard_type_code", "hazard_type_label"),
    "population_segment": ("segment_code", "segment_label"),
    "property_condition": ("condition_code", "condition_label"),
    "promotion_gate": ("gate_code", "gate_label"),
    "units_in_structure": ("units_code", "units_label"),
}

RANGE_PAIRS = [
    ("rate_min", "rate_max"),
    ("index_min", "index_max"),
    ("noi_min", "noi_max"),
    ("rating_min", "rating_max"),
    ("score_min", "score_max"),
    ("year_min", "year_max"),
    ("ami_pct_min", "ami_pct_max"),
    ("unit_min", "unit_max"),
    ("price_min", "price_max"),
    ("rent_min", "rent_max"),
    ("bedroom_count_min", "bedroom_count_max"),
    ("days_min", "days_max"),
    ("range_min", "range_max"),
]


def default_code_label(table: str) -> tuple[str, str]:
    return f"{table}_code", f"{table}_label"


def sniff_header(table: str) -> list[str]:
    p = CAT / f"{table}.csv"
    if not p.exists():
        raise FileNotFoundError(f"Missing {p} — restore enum CSV or edit MERGED_ENUM_TABLES.")
    with p.open(newline="") as f:
        return next(csv.reader(f))


def pick_range(cols: set[str]) -> tuple[str | None, str | None]:
    for a, b in RANGE_PAIRS:
        if a in cols and b in cols:
            return a, b
    return None, None


def parse_bool(s: str) -> str:
    t = (s or "").strip().upper()
    if t in ("TRUE", "T", "1", "YES"):
        return "TRUE"
    return "FALSE"


def rows_for_table(table: str) -> list[dict[str, str]]:
    cols = set(sniff_header(table))
    if table in SPECIAL:
        code_c, label_c = SPECIAL[table]
    else:
        code_c, label_c = default_code_label(table)
    if code_c not in cols or label_c not in cols:
        raise ValueError(f"{table}: expected {code_c}, {label_c}; got {sorted(cols)}")
    sort_c = "sort_order" if "sort_order" in cols else None
    act_c = "is_active" if "is_active" in cols else None
    rmin, rmax = pick_range(cols)
    out: list[dict[str, str]] = []
    with (CAT / f"{table}.csv").open(newline="") as f:
        for row in csv.DictReader(f):
            code = (row.get(code_c) or "").strip()
            label = (row.get(label_c) or "").strip()
            if not code:
                continue
            so = (row.get(sort_c) or "").strip() if sort_c else ""
            rm = (row.get(rmin) or "").strip() if rmin else ""
            rx = (row.get(rmax) or "").strip() if rmax else ""
            ia = parse_bool(row.get(act_c, "TRUE")) if act_c else "TRUE"
            out.append(
                {
                    "enum_table": table,
                    "code": code,
                    "label": label,
                    "sort_order": so,
                    "range_min": rm,
                    "range_max": rx,
                    "is_active": ia,
                    "updated_at": "",
                }
            )
    return out


def relationship_field_for_table(table: str) -> str:
    if table in SPECIAL:
        code_c, _ = SPECIAL[table]
        return code_c
    return f"{table}_code"


def _write_erf_models(tables: tuple[str, ...]) -> None:
    ENUM_REFS.mkdir(parents=True, exist_ok=True)
    for old in ENUM_REFS.glob("erf__*.sql"):
        old.unlink()
    for t in tables:
        field = relationship_field_for_table(t)
        sql = f"""{{{{ config(materialized='ephemeral', tags=['reference', 'catalog', 'enum_ref']) }}}}

select distinct
    code as {field}
from {{{{ ref('catalog_enum_source') }}}}
where enum_table = '{t}'
  and trim(code) <> ''
"""
        (ENUM_REFS / f"erf__{t}.sql").write_text(sql + "\n")
    print(f"Wrote {len(tables)} ephemeral enum ref models under {ENUM_REFS}")


def main() -> None:
    today = date.today().isoformat()
    missing = [t for t in MERGED_ENUM_TABLES if not (CAT / f"{t}.csv").exists()]
    erf_only = len(missing) == len(MERGED_ENUM_TABLES)

    if erf_only:
        src = CAT / "catalog_enum_source.csv"
        if not src.exists():
            raise FileNotFoundError(
                f"No per-enum CSVs and no {src.name}; restore seeds from git or add catalog_enum_source.csv."
            )
        found: set[str] = set()
        with src.open(newline="") as f:
            for row in csv.DictReader(f):
                et = (row.get("enum_table") or "").strip()
                if et:
                    found.add(et)
        if found != set(MERGED_ENUM_TABLES):
            raise ValueError(
                f"catalog_enum_source enum_table set mismatch vs MERGED_ENUM_TABLES. "
                f"extra={found - set(MERGED_ENUM_TABLES)} missing={set(MERGED_ENUM_TABLES) - found}"
            )
        _write_erf_models(MERGED_ENUM_TABLES)
        print("erf-only mode: left catalog_enum_source.csv unchanged.")
        return

    if missing:
        raise FileNotFoundError(
            "Some per-enum CSVs are missing but not all — either restore "
            + ", ".join(missing[:5])
            + ("…" if len(missing) > 5 else "")
            + " or use a full git checkout of seeds/reference/catalog before rebuilding."
        )

    all_rows: list[dict[str, str]] = []
    for t in MERGED_ENUM_TABLES:
        for r in rows_for_table(t):
            r = dict(r)
            r["updated_at"] = today
            all_rows.append(r)

    out_csv = CAT / "catalog_enum_source.csv"
    with out_csv.open("w", newline="") as f:
        w = csv.DictWriter(
            f,
            fieldnames=["enum_table", "code", "label", "sort_order", "range_min", "range_max", "is_active", "updated_at"],
        )
        w.writeheader()
        w.writerows(all_rows)
    print(f"Wrote {len(all_rows)} rows to {out_csv} ({len(MERGED_ENUM_TABLES)} enum_table values)")

    _write_erf_models(MERGED_ENUM_TABLES)


if __name__ == "__main__":
    main()
