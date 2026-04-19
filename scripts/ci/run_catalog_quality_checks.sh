#!/usr/bin/env bash
# Local / merge gate for catalog + Pilot A compile (METRIC_INTAKE_CHECKLIST §3.4,
# PLAYBOOK_ANALYTICS_FEATURES_FROM_CATALOG §D / §E).
#
# Usage (from inner dbt project root — folder containing dbt_project.yml):
#   ./scripts/ci/run_catalog_quality_checks.sh
# With Snowflake seed + test + compile (uses ~/.dbt/profiles or DBT_PROFILES_DIR):
#   RUN_SNOWFLAKE_CHECKS=1 dbt ...   # see below — expects `dev` or `ci` target with credentials
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
export DBT_PROFILES_DIR="${DBT_PROFILES_DIR:-$ROOT/ci}"

echo "==> dbt deps"
dbt deps

echo "==> dbt parse (ci/profiles.yml target: parse)"
dbt parse

echo "==> dbt ls — catalog seeds"
dbt ls --select path:seeds/reference/catalog --resource-type seed

if [[ "${RUN_SNOWFLAKE_CHECKS:-0}" == "1" ]]; then
  TARGET="${DBT_TARGET:-dev}"
  echo "==> dbt seed + test (path:seeds/reference/catalog) target=${TARGET}"
  dbt seed --target "${TARGET}" --select path:seeds/reference/catalog
  dbt test --target "${TARGET}" --select path:seeds/reference/catalog
  echo "==> dbt compile — models/analytics/feature"
  dbt compile --target "${TARGET}" --select path:models/analytics/feature
fi

echo "Done. Snowflake dimensional SQL (0 hard FK failures):"
echo "  snowsql -c pretium -f scripts/sql/validation/dimensional_reference_catalog_and_geography.sql"
