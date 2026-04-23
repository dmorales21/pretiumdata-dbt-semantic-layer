#!/usr/bin/env python3
"""Build canonical ``seeds/reference/catalog/metric.csv`` from ``metric_raw.csv``.

Hybrid **C** (see ``docs/reference/METRIC_CSV_BUILD_SPEC.md``):

1. **Core** — rows whose ``table_path`` registers a **TRANSFORM.DEV** warehouse object that is either
   a **FACT_*** surface (``FACT_`` in the path, case-insensitive) or a physical **CONCEPT_*** union
   (``CONCEPT_`` in the path) — the SoT for measures that ship in the transform corridor.
2. **FK closure** — any ``metric_code`` referenced from sibling catalog seeds so dbt relationship tests
   keep passing: ``bridge_product_type_metric``, ``metric_derived`` (``primary_metric_code``),
   ``metric_derived_input`` (``input_metric_code``), ``catalog_wishlist`` (``primary_catalog_metric_code``).

**Precedence:** raw row wins by ``metric_code``. Optional ``metric_overrides.csv`` (same directory)
with columns ``metric_code`` + ``force_include`` (``TRUE``/``FALSE``) may force-include or exclude
codes after the core+closure pass (exclude removes a code unless still required by closure).

**Authoring flow:** edit **metric_raw.csv** (or run ``scripts/sync_metric_csv_from_pretium_ai_dbt.py``),
then run this script, then commit both **metric_raw.csv** and generated **metric.csv**.

Usage (repo root)::

    python3 scripts/reference/catalog/build_metric_csv_from_metric_raw.py
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path


def _norm_upper(s: str | None) -> str:
    return (s or "").upper().replace('"', "")


def _is_core_registration(table_path: str | None) -> bool:
    u = _norm_upper(table_path)
    if "TRANSFORM.DEV" not in u:
        return False
    return "FACT_" in u or "CONCEPT_" in u


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="", encoding="utf-8") as f:
        r = csv.DictReader(f)
        fieldnames = list(r.fieldnames or [])
        rows = [dict(row) for row in r]
    return fieldnames, rows


def _collect_required_metric_codes(catalog_dir: Path) -> set[str]:
    req: set[str] = set()

    bridge = catalog_dir / "bridge_product_type_metric.csv"
    if bridge.is_file():
        for row in csv.DictReader(bridge.open(newline="", encoding="utf-8")):
            c = (row.get("metric_code") or "").strip()
            if c:
                req.add(c)

    md = catalog_dir / "metric_derived.csv"
    if md.is_file():
        for row in csv.DictReader(md.open(newline="", encoding="utf-8")):
            c = (row.get("primary_metric_code") or "").strip()
            if c:
                req.add(c)

    mdi = catalog_dir / "metric_derived_input.csv"
    if mdi.is_file():
        for row in csv.DictReader(mdi.open(newline="", encoding="utf-8")):
            c = (row.get("input_metric_code") or "").strip()
            if c:
                req.add(c)

    wl = catalog_dir / "catalog_wishlist.csv"
    if wl.is_file():
        for row in csv.DictReader(wl.open(newline="", encoding="utf-8")):
            c = (row.get("primary_catalog_metric_code") or "").strip()
            if c:
                req.add(c)

    return req


def _load_overrides(catalog_dir: Path) -> tuple[set[str], set[str]]:
    """Returns (force_include_codes, force_exclude_codes)."""
    path = catalog_dir / "metric_overrides.csv"
    if not path.is_file():
        return set(), set()
    inc: set[str] = set()
    exc: set[str] = set()
    for row in csv.DictReader(path.open(newline="", encoding="utf-8")):
        code = (row.get("metric_code") or "").strip()
        if not code:
            continue
        flag = (row.get("force_include") or "").strip().upper()
        if flag in ("TRUE", "1", "T", "YES"):
            inc.add(code)
        elif flag in ("FALSE", "0", "NO"):
            exc.add(code)
    return inc, exc


def main() -> int:
    # scripts/reference/catalog/<this>.py → repo root is parents[3]
    root = Path(__file__).resolve().parents[3]
    catalog_dir = root / "seeds" / "reference" / "catalog"
    raw_path = catalog_dir / "metric_raw.csv"
    out_path = catalog_dir / "metric.csv"

    if not raw_path.is_file():
        print(f"error: missing {raw_path}", file=sys.stderr)
        return 1

    fieldnames, raw_rows = _read_csv(raw_path)
    if not fieldnames or "metric_code" not in fieldnames:
        print("error: metric_raw.csv missing header or metric_code column", file=sys.stderr)
        return 1

    by_code: dict[str, dict[str, str]] = {}
    for row in raw_rows:
        code = (row.get("metric_code") or "").strip()
        if not code:
            continue
        by_code[code] = row

    core_codes = {code for code, row in by_code.items() if _is_core_registration(row.get("table_path"))}
    required = _collect_required_metric_codes(catalog_dir)
    force_inc, force_exc = _load_overrides(catalog_dir)

    missing_required = sorted(required - set(by_code))
    if missing_required:
        print(
            "error: metric_code referenced from catalog seeds but absent from metric_raw.csv:\n  "
            + "\n  ".join(missing_required[:50]),
            file=sys.stderr,
        )
        if len(missing_required) > 50:
            print(f"  ... and {len(missing_required) - 50} more", file=sys.stderr)
        return 1

    selected: set[str] = set(core_codes)
    selected |= required
    selected |= force_inc
    selected -= force_exc
    # closure must win over exclude
    selected |= required

    out_rows = [by_code[c] for c in sorted(selected) if c in by_code]

    # stable sort: metric_id then metric_code
    def sort_key(r: dict[str, str]) -> tuple[str, str]:
        return (r.get("metric_id") or "", r.get("metric_code") or "")

    out_rows.sort(key=sort_key)

    with out_path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, lineterminator="\n")
        w.writeheader()
        w.writerows(out_rows)

    print(
        f"wrote {len(out_rows)} rows to {out_path} "
        f"(raw={len(raw_rows)} core={len(core_codes)} required_refs={len(required)})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
