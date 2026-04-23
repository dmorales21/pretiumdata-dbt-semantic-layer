#!/usr/bin/env python3
"""Keep **product_type.csv** `bedroom_type_codes` aligned with **bridge_product_type_bedroom_type**.

**Authoring source:** `seeds/reference/catalog/bridge_product_type_bedroom_type.csv` only (not the comma
column). Rows are ordered by bridge **sort_order**, then **bedroom_type.sort_order** as tiebreak.

  python3 scripts/reference/catalog/sync_product_type_bedroom_codes_from_bridge.py
"""
from __future__ import annotations

import csv
import sys
from collections import defaultdict
from pathlib import Path


def _bedroom_sort_keys(cat: Path) -> dict[str, tuple[int, str]]:
    p = cat / "bedroom_type.csv"
    out: dict[str, tuple[int, str]] = {}
    with p.open(newline="") as f:
        for r in csv.DictReader(f):
            code = str(r.get("bedroom_type_code", "")).strip()
            if not code:
                continue
            try:
                so = int(str(r.get("sort_order", "999")).strip() or "999")
            except ValueError:
                so = 999
            out[code] = (so, code)
    return out


def main() -> None:
    root = Path(__file__).resolve().parents[3]
    cat = root / "seeds" / "reference" / "catalog"
    pt_path = cat / "product_type.csv"
    bridge_path = cat / "bridge_product_type_bedroom_type.csv"
    bedroom_keys = _bedroom_sort_keys(cat)

    if not bridge_path.exists():
        print(f"error: missing {bridge_path}", file=sys.stderr)
        raise SystemExit(1)

    rows_by_pt: dict[str, list[tuple[int, int, str]]] = defaultdict(list)
    with bridge_path.open(newline="") as f:
        for r in csv.DictReader(f):
            pc = str(r.get("product_type_code", "")).strip()
            bc = str(r.get("bedroom_type_code", "")).strip()
            if not pc or not bc:
                continue
            if str(r.get("is_active", "TRUE")).strip().upper() not in ("TRUE", "1", "T"):
                continue
            try:
                bridge_so = int(str(r.get("sort_order", "999")).strip() or "999")
            except ValueError:
                bridge_so = 999
            bk = bedroom_keys.get(bc, (999, bc))
            rows_by_pt[pc].append((bridge_so, bk[0], bc))

    by_pt: dict[str, list[str]] = {}
    for pc, triples in rows_by_pt.items():
        seen: set[str] = set()
        ordered: list[str] = []
        for _, __, bc in sorted(triples):
            if bc in seen:
                continue
            seen.add(bc)
            ordered.append(bc)
        unknown = [c for c in ordered if c not in bedroom_keys]
        if unknown:
            print(
                f"error: unknown bedroom_type_code in bridge for product_type {pc!r}: {unknown}",
                file=sys.stderr,
            )
            raise SystemExit(1)
        by_pt[pc] = ordered

    with pt_path.open(newline="") as f:
        rows = list(csv.DictReader(f))

    if not rows or "bedroom_type_codes" not in rows[0]:
        print("error: product_type.csv missing bedroom_type_codes", file=sys.stderr)
        raise SystemExit(1)

    pt_codes = {str(r.get("product_type_code", "")).strip() for r in rows if str(r.get("product_type_code", "")).strip()}
    orphan = sorted(set(by_pt) - pt_codes)
    if orphan:
        print(
            "error: bridge references unknown product_type_code: " + ", ".join(orphan),
            file=sys.stderr,
        )
        raise SystemExit(1)

    changed = 0
    for r in rows:
        pc = str(r.get("product_type_code", "")).strip()
        new_val = ",".join(by_pt.get(pc, []))
        old_val = str(r.get("bedroom_type_codes", "") or "").strip()
        if old_val != new_val:
            changed += 1
        r["bedroom_type_codes"] = new_val

    with pt_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    print(f"Updated bedroom_type_codes on {len(rows)} rows ({changed} changed) from {bridge_path.name}")


if __name__ == "__main__":
    main()
