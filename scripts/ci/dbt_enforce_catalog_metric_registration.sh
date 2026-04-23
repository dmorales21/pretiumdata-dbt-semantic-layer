#!/usr/bin/env bash
# Enforce **REFERENCE.CATALOG.metric** registrations for **TRANSFORM.DEV** (Snowflake):
#   **dbt build** — catalog seeds (including seed tests) + **qa_catalog_metric_transform_dev_lineage**
#   + singular **tag:metric_transform_dev_lineage** (active MET_* must be OK in the QA table), in DAG order.
#
# Usage (repo root, profile with SELECT on TRANSFORM.INFORMATION_SCHEMA):
#   bash scripts/ci/dbt_enforce_catalog_metric_registration.sh
#   bash scripts/ci/dbt_enforce_catalog_metric_registration.sh --target dev
#
# Optional — **metric_derived** FEATURE rows vs **ANALYTICS.DBT_DEV** (requires feature tables built):
#   ENFORCE_CATALOG_METRIC_DERIVED_FEATURE=1 bash scripts/ci/dbt_enforce_catalog_metric_registration.sh --target dev
#
# Equivalent one-liner: ``dbt build --selector catalog_metric_transform_dev_registration_enforcement``
# (then optional block below). Wired into ``.github/workflows/semantic_layer_catalog_and_quality.yml`` when
# Snowflake CI is enabled.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "== Catalog seeds + QA lineage + metric_transform_dev_lineage singular (selector: catalog_metric_transform_dev_registration_enforcement) =="
dbt build "$@" --selector catalog_metric_transform_dev_registration_enforcement

if [[ "${ENFORCE_CATALOG_METRIC_DERIVED_FEATURE:-0}" == "1" ]]; then
  echo "== Optional: metric_derived FEATURE lineage (ANALYTICS.DBT_DEV) =="
  dbt run "$@" --select qa_catalog_metric_derived_feature_lineage
  dbt test "$@" --select path:tests/catalog_registration/assert_catalog_metric_derived_feature_registration_lineage.sql
fi

echo "== Catalog metric TRANSFORM.DEV registration enforced OK =="
