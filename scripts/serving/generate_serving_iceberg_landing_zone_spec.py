#!/usr/bin/env python3
"""
Generate SERVING_ICEBERG_LANDING_ZONE_SPEC.md from Snowflake INFORMATION_SCHEMA
plus dbt stub inventory under models/serving/iceberg/*.sql.

Requires ``snowsql`` on PATH and a working ``-c <connection>`` profile (default: pretium).
"""
import argparse
import csv
import io
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


def _repo_root() -> Path:
    env = os.environ.get("PRETIUMDATA_DBT_SEMANTIC_LAYER_ROOT", "").strip()
    if env:
        return Path(env).resolve()
    # scripts/serving/ -> repo root
    return Path(__file__).resolve().parents[2]


def _stub_tables(repo: Path) -> list[str]:
    d = repo / "models" / "serving" / "iceberg"
    names: list[str] = []
    for p in sorted(d.glob("*.sql")):
        stem = p.stem
        if stem.startswith("_") or stem.upper() in {"README"}:
            continue
        names.append(stem.upper())
    return names


def _snowsql_tsv(connection: str, sql: str) -> list[list[str]]:
    cmd = [
        "snowsql",
        "-c",
        connection,
        "-o",
        "friendly=false",
        "-o",
        "header=true",
        "-o",
        "output_format=tsv",
        "-q",
        sql,
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(
            f"snowsql failed (exit {proc.returncode}):\n{proc.stderr or proc.stdout}"
        )
    raw = proc.stdout.strip("\n")
    if not raw:
        return []
    reader = csv.reader(io.StringIO(raw), delimiter="\t")
    return list(reader)


def _header_index(header_upper: list[str], *candidates: str) -> Optional[int]:
    for c in candidates:
        if c in header_upper:
            return header_upper.index(c)
    return None


def _parse_show_tables_tsv(rows: list[list[str]]) -> dict[str, dict[str, str]]:
    """Map table_name upper -> metadata from SHOW TABLES TSV (column labels vary by snowsql version)."""
    if not rows:
        return {}
    header_raw = [h.strip() for h in rows[0]]
    header_upper = [h.upper() for h in header_raw]
    out: dict[str, dict[str, str]] = {}

    name_i = _header_index(header_upper, "NAME")
    if name_i is None and len(header_raw) >= 2:
        # Snowflake SHOW TABLES: created_on, name, database_name, ...
        name_i = 1
    if name_i is None:
        return {}

    kind_i = _header_index(header_upper, "KIND", "TABLE_TYPE")
    rows_i = _header_index(header_upper, "ROWS", "ROW_COUNT")
    bytes_i = _header_index(header_upper, "BYTES")
    ice_i = _header_index(header_upper, "IS_ICEBERG", "ICEBERG")

    for parts in rows[1:]:
        if len(parts) <= name_i:
            continue
        name = parts[name_i].strip().strip('"').upper()
        if not name:
            continue
        meta = {
            "kind": parts[kind_i].strip() if kind_i is not None and len(parts) > kind_i else "",
            "rows": parts[rows_i].strip() if rows_i is not None and len(parts) > rows_i else "",
            "bytes": parts[bytes_i].strip() if bytes_i is not None and len(parts) > bytes_i else "",
            "is_iceberg": parts[ice_i].strip() if ice_i is not None and len(parts) > ice_i else "",
        }
        out[name] = meta
    return out


ColRow = tuple[int, str, str, str, str, str]


def _fetch_columns_bulk(
    connection: str, database: str, schema: str, tables: list[str]
) -> dict[str, list[ColRow]]:
    """One round-trip: all columns for listed tables, keyed by UPPER(table_name)."""
    if not tables:
        return {}
    literals = ", ".join("'" + t.replace("'", "''") + "'" for t in tables)
    sql = f"""
SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    is_nullable,
    COALESCE(column_default, '') AS column_default,
    COALESCE(comment, '') AS comment
FROM {database}.INFORMATION_SCHEMA.COLUMNS
WHERE LOWER(table_catalog) = LOWER('{database}')
  AND LOWER(table_schema) = LOWER('{schema}')
  AND UPPER(table_name) IN ({literals})
ORDER BY table_name, ordinal_position;
"""
    rows = _snowsql_tsv(connection, sql)
    if len(rows) < 2:
        return {}
    hdr = [h.upper() for h in rows[0]]
    ci = {h: i for i, h in enumerate(hdr)}
    need = [
        "TABLE_NAME",
        "ORDINAL_POSITION",
        "COLUMN_NAME",
        "DATA_TYPE",
        "IS_NULLABLE",
        "COLUMN_DEFAULT",
        "COMMENT",
    ]
    if not all(k in ci for k in need):
        return {}
    by_table: dict[str, list[ColRow]] = {}
    for r in rows[1:]:
        if len(r) <= max(ci.values()):
            continue
        tname = r[ci["TABLE_NAME"]].strip().upper()
        by_table.setdefault(tname, []).append(
            (
                int(float(r[ci["ORDINAL_POSITION"]])),
                r[ci["COLUMN_NAME"]].strip(),
                r[ci["DATA_TYPE"]].strip(),
                r[ci["IS_NULLABLE"]].strip(),
                r[ci["COLUMN_DEFAULT"]].strip(),
                r[ci["COMMENT"]].strip(),
            )
        )
    return by_table


def _type_mix(columns: list[ColRow]) -> str:
    counts: dict[str, int] = {}
    for _, _, dt, _, _, _ in columns:
        base = dt.split("(")[0].strip().upper()
        counts[base] = counts.get(base, 0) + 1
    parts = [f"{k}: {v}" for k, v in sorted(counts.items(), key=lambda x: (-x[1], x[0]))]
    return ", ".join(parts) if parts else "—"


def _markdown(
    repo: Path,
    connection: str,
    database: str,
    schema: str,
    tables: list[str],
    show_meta: dict[str, dict[str, str]],
    columns_by_table: dict[str, list[ColRow]],
    full_schema: bool,
) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%SZ")
    stub_dir = repo / "models" / "serving" / "iceberg"
    lines: list[str] = [
        "# Snowflake Iceberg landing zone — column specification",
        "",
        f"**Auto-generated:** `{now}`  ",
        f"**Connection (`snowsql -c`):** `{connection}`  ",
        f"**Target:** `{database}.{schema}` (from `INFORMATION_SCHEMA` / `SHOW TABLES`)  ",
        "",
        f"**dbt contract (model stubs):** `{stub_dir}`  ",
        "",
        f"**Table allowlist ({len(tables)}):** `{', '.join(tables)}`  ",
        "",
        "> Regenerate: `./scripts/serving/run_generate_serving_iceberg_landing_zone_spec.sh`",
        "",
        "## Table inventory",
        "",
        "| Table | Type | Row count | Bytes | Iceberg | Table comment |",
        "|---|:---|---:|---:|---|:---|:---|",
    ]
    for t in tables:
        m = show_meta.get(t, {})
        rows = m.get("rows", "—")
        bts = m.get("bytes", "—")
        kind = m.get("kind", "BASE TABLE") or "BASE TABLE"
        ice = m.get("is_iceberg", "—")
        lines.append(f"| {t} | {kind} | {rows} | {bts} | {ice} |  |")
    lines.extend(["", "## Column type mix (per table)", "", "| Table | # columns | By data type |", "|---|---:|---|"])
    for t in tables:
        cols = columns_by_table.get(t, [])
        lines.append(f"| {t} | {len(cols)} | {_type_mix(cols)} |")
    lines.extend(["", "## Column catalog", "", "All columns are listed in physical order (`ordinal_position`)."])
    for t in tables:
        cols = columns_by_table.get(t, [])
        lines.extend(["", f"### `{database}.{schema}.{t}`", "", "| # | Column | Logical type | Nullable | Default | Column comment |", "|---:|---|---|---|---|---|"])
        if not cols:
            lines.append("| — | *no columns returned* | — | — | — | — |")
            continue
        for ordn, cname, dt, nul, dflt, cmt in cols:
            esc = cmt.replace("|", "\\|")
            lines.append(
                f"| {ordn} | `{cname}` | {dt} | {nul} | {dflt or ' '} | {esc} |"
            )
    if not full_schema:
        lines.extend(
            [
                "",
                "## Stub / warehouse drift",
                "",
                "When **not** using `--full-schema`, tables are the intersection of dbt `models/serving/iceberg/*.sql` stems "
                "and relations present in Snowflake. Add or remove `*.sql` stubs to align the contract.",
            ]
        )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Markdown output path (default: models/serving/iceberg/SERVING_ICEBERG_LANDING_ZONE_SPEC.md)",
    )
    parser.add_argument("--connection", default=os.environ.get("SNOWSQL_CONNECTION", "pretium"))
    parser.add_argument("--database", default=os.environ.get("SERVING_ICEBERG_DATABASE", "SERVING"))
    parser.add_argument("--schema", default=os.environ.get("SERVING_ICEBERG_SCHEMA", "ICEBERG"))
    parser.add_argument(
        "--full-schema",
        action="store_true",
        help="Document every BASE TABLE in the schema (not only dbt stubs).",
    )
    args = parser.parse_args()
    repo = _repo_root()
    out = args.output or (repo / "models" / "serving" / "iceberg" / "SERVING_ICEBERG_LANDING_ZONE_SPEC.md")

    db, sch = args.database, args.schema
    # Snowflake: ``SHOW TABLES IN <database>.<schema>`` (not ``IN SCHEMA ... IN DATABASE ...``).
    show_sql = f"SHOW TABLES IN {db}.{sch};"
    try:
        show_rows = _snowsql_tsv(args.connection, show_sql)
    except FileNotFoundError:
        print("snowsql not found on PATH.", file=sys.stderr)
        return 127
    except RuntimeError as e:
        print(str(e), file=sys.stderr)
        return 1
    show_meta = _parse_show_tables_tsv(show_rows)
    snowflake_tables = set(show_meta.keys())

    if args.full_schema:
        tables = sorted(snowflake_tables)
    else:
        want = set(_stub_tables(repo))
        tables = sorted(want & snowflake_tables)
        missing_sf = sorted(want - snowflake_tables)
        if missing_sf:
            print("WARN: dbt stubs with no Snowflake table:", ", ".join(missing_sf), file=sys.stderr)

    if not tables:
        print("No tables to document (check database/schema and stubs).", file=sys.stderr)
        return 2

    columns_by_table = _fetch_columns_bulk(args.connection, db, sch, tables)
    md = _markdown(
        repo,
        args.connection,
        db,
        sch,
        tables,
        show_meta,
        columns_by_table,
        args.full_schema,
    )
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(md, encoding="utf-8")
    print(f"Wrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
