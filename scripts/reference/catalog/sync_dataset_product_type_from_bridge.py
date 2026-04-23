#!/usr/bin/env python3
"""Reads from **dataset_product_type** bridge CSV — not from dataset.product_type_codes**.

Keeps **dataset.csv** `product_type_codes` machine-aligned with
**seeds/reference/catalog/dataset_product_type.csv** (authoring source). Do **not** hand-edit the comma
column; it is frozen until a follow-up PR drops it.

  python3 scripts/reference/catalog/sync_dataset_product_type_from_bridge.py

See **seeds/reference/catalog/DATASET_PRODUCT_TYPE_CODES_FROZEN.txt** for governance note.
"""
from __future__ import annotations

import csv
import sys
from collections import defaultdict
from pathlib import Path


def _product_type_sort_keys(cat: Path) -> dict[str, tuple[int, str]]:
    p = cat / "product_type.csv"
    out: dict[str, tuple[int, str]] = {}
    with p.open(newline="") as f:
        for r in csv.DictReader(f):
            code = str(r.get("product_type_code", "")).strip()
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
    dataset_path = cat / "dataset.csv"
    bridge_path = cat / "dataset_product_type.csv"
    sort_keys = _product_type_sort_keys(cat)

    if not bridge_path.exists():
        print(f"error: missing bridge file {bridge_path}", file=sys.stderr)
        raise SystemExit(1)

    by_dataset: dict[str, list[str]] = defaultdict(list)
    with bridge_path.open(newline="") as f:
        for r in csv.DictReader(f):
            dc = str(r.get("dataset_code", "")).strip()
            pt = str(r.get("product_type_code", "")).strip()
            if not dc or not pt:
                continue
            by_dataset[dc].append(pt)

    for dc in by_dataset:
        codes = sorted(set(by_dataset[dc]), key=lambda c: sort_keys.get(c, (999, c)))
        unknown = [c for c in codes if c not in sort_keys]
        if unknown:
            print(
                f"error: unknown product_type_code in bridge for dataset {dc!r}: {unknown}",
                file=sys.stderr,
            )
            raise SystemExit(1)
        by_dataset[dc] = codes

    with dataset_path.open(newline="") as f:
        drows = list(csv.DictReader(f))

    if not drows or "product_type_codes" not in drows[0]:
        print("error: dataset.csv missing product_type_codes", file=sys.stderr)
        raise SystemExit(1)

    dataset_codes = {str(r.get("dataset_code", "")).strip() for r in drows if str(r.get("dataset_code", "")).strip()}
    orphan = sorted(set(by_dataset) - dataset_codes)
    if orphan:
        print(
            "error: bridge references unknown dataset_code: " + ", ".join(orphan[:20]),
            file=sys.stderr,
        )
        raise SystemExit(1)

    changed = 0
    for r in drows:
        dc = str(r.get("dataset_code", "")).strip()
        new_val = ",".join(by_dataset.get(dc, []))
        old_val = str(r.get("product_type_codes", "") or "").strip()
        if old_val != new_val:
            changed += 1
        r["product_type_codes"] = new_val

    with dataset_path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(drows[0].keys()))
        w.writeheader()
        w.writerows(drows)

    print(
        f"Updated product_type_codes on {len(drows)} dataset rows ({changed} changed) from {bridge_path.name}"
    )


if __name__ == "__main__":
    main()
