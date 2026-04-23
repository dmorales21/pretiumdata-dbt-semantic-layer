#!/usr/bin/env python3
"""Merge pretium-ai-dbt ``metric.csv`` into semantic-layer ``metric_raw.csv`` (bulk backlog).

Applies REFERENCE.CATALOG FK-safe **geo_level_code** remaps (e.g. Oxford ``varies`` → ``cbsa``/``national``) documented in
``docs/migration/MIGRATION_TASKS_VENDOR_METRIC_CATALOG_INTAKE.md``. Appends any
``metric_code`` rows required by ``bridge_product_type_metric.csv`` that are absent
from the source CSV (typically placeholder MET_* rows maintained only here).

Usage (from pretiumdata-dbt-semantic-layer repo root)::

    python3 scripts/sync_metric_csv_from_pretium_ai_dbt.py
    python3 scripts/sync_metric_csv_from_pretium_ai_dbt.py --source /path/to/pretium-ai-dbt/dbt/seeds/reference/catalog/metric.csv
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


def _remap_geo_level(row: dict[str, str]) -> str:
    g = (row.get("geo_level_code") or "").strip()
    if g == "varies":
        tp = (row.get("table_path") or "").upper()
        if "WDMARCO" in tp:
            return "national"
        if "AMREG" in tp:
            return "cbsa"
        return "cbsa"
    return g


def _norm_bool(val: str) -> str:
    v = (val or "").strip().upper()
    return "TRUE" if v in ("TRUE", "1", "T", "YES") else "FALSE"


def _transform_row(row: dict[str, str]) -> dict[str, str]:
    out = dict(row)
    out["geo_level_code"] = _remap_geo_level(out)
    out["is_derived"] = _norm_bool(out.get("is_derived", ""))
    out["is_active"] = _norm_bool(out.get("is_active", ""))
    out["is_opco_metric"] = _norm_bool(out.get("is_opco_metric", ""))
    return out


FIELDNAMES = [
    "metric_id",
    "metric_code",
    "metric_label",
    "definition",
    "concept_code",
    "vendor_code",
    "is_derived",
    "source_vendor_codes",
    "unit",
    "direction",
    "geo_level_code",
    "frequency_code",
    "is_active",
    "data_status_code",
    "snowflake_column",
    "table_path",
    "metric_category_code",
    "is_opco_metric",
]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        help="pretium-ai-dbt metric.csv path (default: sibling repo pretium-ai-dbt)",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parents[1]
    default_source = root.parent / "pretium-ai-dbt" / "dbt" / "seeds" / "reference" / "catalog" / "metric.csv"
    source: Path = args.source or default_source
    if not source.is_file():
        raise SystemExit(f"Source metric.csv not found: {source}")

    out_path = root / "seeds" / "reference" / "catalog" / "metric_raw.csv"
    bridge_path = root / "seeds" / "reference" / "catalog" / "bridge_product_type_metric.csv"

    with source.open(newline="", encoding="utf-8") as f:
        rows = [_transform_row(dict(r)) for r in csv.DictReader(f)]

    by_code: dict[str, dict[str, str]] = {}
    for r in rows:
        by_code[r["metric_code"]] = r

    bridge_codes = {r["metric_code"] for r in csv.DictReader(bridge_path.open(newline="", encoding="utf-8"))}
    missing_bridge = sorted(bridge_codes - set(by_code))
    if missing_bridge:
        extra_from = None
        for candidate in (
            out_path,
            root / "seeds" / "reference" / "catalog" / "metric.csv",
        ):
            if candidate.is_file():
                extra_from = candidate
                break
        if not extra_from:
            raise SystemExit(
                f"bridge requires metric_codes not in source and no existing metric_raw/metric: {missing_bridge}"
            )
        existing = {r["metric_code"]: r for r in csv.DictReader(extra_from.open(newline="", encoding="utf-8"))}
        for code in missing_bridge:
            if code not in existing:
                raise SystemExit(
                    f"metric_code in bridge but not in source or existing catalog metric files: {code}"
                )
            by_code[code] = _transform_row(dict(existing[code]))

    out_rows = list(by_code.values())
    out_rows.sort(key=lambda r: r["metric_code"])

    with out_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=FIELDNAMES, lineterminator="\n")
        w.writeheader()
        w.writerows(out_rows)

    print(f"wrote {len(out_rows)} rows to {out_path}")
    print(f"source {source}")
    print("next: python3 scripts/reference/catalog/build_metric_csv_from_metric_raw.py")


if __name__ == "__main__":
    main()
