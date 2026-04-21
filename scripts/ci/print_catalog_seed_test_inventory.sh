#!/usr/bin/env bash
# Print compile-time KPIs for catalog seed QA: how many dbt tests are bound to
# path:seeds/reference/catalog (requires dbt_packages — run dbt deps first).
# Execution KPIs (PASS/FAIL per test) require a real Snowflake target + seed load:
#   RUN_SNOWFLAKE_CHECKS=1 ./scripts/ci/run_catalog_quality_checks.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
export DBT_PROFILES_DIR="${DBT_PROFILES_DIR:-$ROOT/ci}"
# Avoid corporate proxy breaking hub.getdbt.com when users run deps elsewhere
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy || true
if [[ ! -d dbt_packages/dbt_utils ]]; then
  echo "ERROR: dbt_packages missing. Run: unset HTTP_PROXY HTTPS_PROXY; dbt deps" >&2
  exit 1
fi
echo "==> dbt parse (target parse)"
dbt parse --quiet
N="$(dbt ls --resource-type test --select path:seeds/reference/catalog -q 2>/dev/null | wc -l | tr -d ' ')"
echo "KPI: catalog_seed_bound_dbt_tests=${N}"
echo "Run for PASS/FAIL: dbt build --select path:seeds/reference/catalog (Snowflake target; seeds before tests)"
