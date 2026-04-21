#!/usr/bin/env bash
# Fail if the semantic-layer dbt graph (models / macros / tests) references legacy
# Snowflake databases TRANSFORM_PROD, ANALYTICS_PROD, or EDW_PROD.
#
# Scope: executable graph + source YAML — not docs/, scripts/sql/, or one-off land SQL
# (those may mention PROD FQNs only for human operators).
#
# Usage (from inner project root — directory containing dbt_project.yml):
#   ./scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

# Case-sensitive Snowflake FQNs + lowercase database slugs in YAML.
FQNS='TRANSFORM_PROD\.|ANALYTICS_PROD\.|EDW_PROD\.|transform_prod\.|analytics_prod\.|edw_prod\.'
SOURCE_RE="source\([[:space:]]*['\"]?(transform_prod|analytics_prod|edw_prod)['\"]?"
DATABASE_RE='^[[:space:]]*\+?database:[[:space:]].*\b(transform_prod|analytics_prod|edw_prod)\b'

violations=0

scan_sql() {
  local root="$1"
  [[ -d "$ROOT/$root" ]] || return 0
  while IFS= read -r -d '' f; do
    if grep -qE "$FQNS" "$f" 2>/dev/null; then
      echo "FORBIDDEN FQN (legacy *_PROD database) in $f:" >&2
      grep -nE "$FQNS" "$f" >&2 || true
      violations=$((violations + 1))
    fi
    if grep -qE "$SOURCE_RE" "$f" 2>/dev/null; then
      echo "FORBIDDEN source() name in $f:" >&2
      grep -nE "$SOURCE_RE" "$f" >&2 || true
      violations=$((violations + 1))
    fi
  done < <(find "$ROOT/$root" -type f \( -name '*.sql' \) -print0 2>/dev/null)
}

scan_yml() {
  local root="$1"
  [[ -d "$ROOT/$root" ]] || return 0
  while IFS= read -r -d '' f; do
    if grep -qiE "$DATABASE_RE" "$f" 2>/dev/null; then
      echo "FORBIDDEN database: key in $f:" >&2
      grep -niE "$DATABASE_RE" "$f" >&2 || true
      violations=$((violations + 1))
    fi
    # Do not grep bare FQNs in all YAML: schema descriptions may cite legacy object names.
    if grep -qE "$SOURCE_RE" "$f" 2>/dev/null; then
      echo "FORBIDDEN source() in YAML $f:" >&2
      grep -nE "$SOURCE_RE" "$f" >&2 || true
      violations=$((violations + 1))
    fi
  done < <(find "$ROOT/$root" -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 2>/dev/null)
}

echo "==> assert_no_legacy_prod_snowflake_databases_in_dbt_graph (models/, macros/, tests/, dbt_project.yml)"
for root in models macros tests; do
  scan_sql "$root"
  scan_yml "$root"
done

for proj in dbt_project.yml packages.yml; do
  f="$ROOT/$proj"
  [[ -f "$f" ]] || continue
  if grep -qiE "$DATABASE_RE" "$f" 2>/dev/null; then
    echo "FORBIDDEN database: key in $f:" >&2
    grep -niE "$DATABASE_RE" "$f" >&2 || true
    violations=$((violations + 1))
  fi
  if grep -qE "$FQNS" "$f" 2>/dev/null; then
    echo "FORBIDDEN FQN in $f:" >&2
    grep -nE "$FQNS" "$f" >&2 || true
    violations=$((violations + 1))
  fi
done

if [[ "$violations" -gt 0 ]]; then
  echo >&2
  echo "FAILED: legacy PROD Snowflake database reference(s) in dbt graph." >&2
  echo "Policy: no TRANSFORM_PROD, ANALYTICS_PROD, or EDW_PROD in models/, macros/, or tests/." >&2
  echo "See docs/migration/MIGRATION_RULES.md (PROD database ban)." >&2
  exit 1
fi

echo "OK: no TRANSFORM_PROD / ANALYTICS_PROD / EDW_PROD references in dbt graph paths."
