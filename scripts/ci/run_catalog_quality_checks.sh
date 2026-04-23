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
SNOWSQL_CONNECTION="${SNOWSQL_CONNECTION:-pretium}"

echo "==> dbt deps"
dbt deps

echo "==> assert_no_legacy_prod_snowflake_databases_in_dbt_graph"
bash "$ROOT/scripts/ci/assert_no_legacy_prod_snowflake_databases_in_dbt_graph.sh"

echo "==> dbt parse (ci/profiles.yml target: parse)"
dbt parse

echo "==> dbt ls — catalog seeds"
dbt ls --select path:seeds/reference/catalog --resource-type seed

echo "==> compile-time KPI block — catalog seed dbt test inventory"
bash "$ROOT/scripts/ci/print_catalog_seed_test_inventory.sh"

if [[ "${RUN_SNOWFLAKE_CHECKS:-0}" == "1" ]]; then
  TARGET="${DBT_TARGET:-dev}"
  echo "==> dbt build — catalog seeds + TRANSFORM.DEV metric registration QA (selector: catalog_metric_transform_dev_registration_enforcement) target=${TARGET}"
  # Single graph invocation: catalog seeds/tests, materialize QA lineage, singular **metric_transform_dev_lineage**.
  dbt build --target "${TARGET}" --selector catalog_metric_transform_dev_registration_enforcement
  echo "==> dbt compile — models/analytics/feature"
  dbt compile --target "${TARGET}" --select path:models/analytics/feature
  echo "==> Snowflake KPI block — concept assignment coverage"
  snowsql -c "${SNOWSQL_CONNECTION}" -f scripts/sql/validation/catalog_concept_metric_assignment_coverage.sql
fi
echo "Done. Snowflake dimensional SQL (0 hard FK failures):"
echo "  snowsql -c pretium -f scripts/sql/validation/dimensional_reference_catalog_and_geography.sql"
echo "TRANSFORM.DEV catalog registration QA (METRIC.table_path vs TRANSFORM.INFORMATION_SCHEMA):"
echo "  snowsql -c pretium -f scripts/sql/validation/qa_transform_dev_catalog_metric_table_paths.sql"
echo "Metric registration KPIs + FACT/CONCEPT/REF gaps vs MET rows:"
echo "  snowsql -c pretium -f scripts/sql/validation/catalog_metric_registration_coverage.sql"
echo "Concept assignment coverage KPIs (CONCEPT x METRIC):"
echo "  snowsql -c ${SNOWSQL_CONNECTION} -f scripts/sql/validation/catalog_concept_metric_assignment_coverage.sql"
echo "  (see docs/migration/QA_TRANSFORM_DEV_CATALOG_REGISTRATIONS.md; dbt surface: dbt run --selector catalog_metric_transform_dev_surface)"
echo "TRANSFORM.DEV materialized QA table (dbt run after catalog seed):"
echo "  dbt seed --select qa_tract_zcta_harmonized_parquet_manifest   # REFERENCE.DRAFT manifest"
echo "  dbt run --select qa_catalog_metric_transform_dev_lineage      # TRANSFORM.DEV.QA_CATALOG_METRIC_TRANSFORM_DEV_LINEAGE"
echo "Boundary parquet stage QA template:"
echo "  snowsql -c pretium -f scripts/sql/validation/qa_boundary_parquet_stage_list_template.sql"
