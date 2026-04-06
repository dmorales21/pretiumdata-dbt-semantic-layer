# pretiumdata-dbt-semantic-layer

Governed dbt repository for building, testing, documenting, versioning, and promoting Pretium's semantic catalog from **dev → staging → prod**.

This repo is the Git-based control plane for `mart.semantic`. It is intended to house:

- semantic entities, dimensions, bridges, and registries
- semantic contracts and governance rules
- CI/CD deployment workflows
- environment-aware dbt configuration
- future MetricFlow / dbt Semantic Layer assets

## Architectural intent

This repo supports a semantic operating model where:

- **Dev** is used for model development, local validation, and sandbox testing
- **Staging** is used for integrated validation, conformance checks, and release certification
- **Prod** is the only consumer-safe semantic layer for Prism, BI, IC materials, and Iceberg publishing

The repository is designed around stable semantic object families:

- `entity_*`
- `dim_*`
- `bridge_*`
- `registry_*`

No `_v2`, `_final`, `_new`, or unstable production object names should be published from this repo.

---

## Expected Snowflake environments

This starter package assumes the following database mapping:

| dbt target | Database | Schema |
|---|---|---|
| `dev` | `MART_DEV` | `SEMANTIC` |
| `staging` | `MART_STAGING` | `SEMANTIC` |
| `prod` | `MART_PROD` | `SEMANTIC` |

Recommended warehouse mapping:

| dbt target | Warehouse |
|---|---|
| `dev` | `DBT_DEV_WH` |
| `staging` | `DBT_STAGING_WH` |
| `prod` | `DBT_PROD_WH` |

---

## Repository layout

```text
pretiumdata-dbt-semantic-layer/
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── deploy-staging.yml
│       └── deploy-prod.yml
├── docs/
│   └── standards/
│       └── branching-release-standards.md
├── macros/
│   ├── environment/
│   ├── governance/
│   ├── semantic/
│   └── tests/
├── models/
│   ├── intermediate/
│   │   └── semantic_prep/
│   ├── mart/
│   │   └── semantic/
│   │       ├── bridge/
│   │       ├── dim/
│   │       ├── entity/
│   │       ├── explain/
│   │       ├── glossary/
│   │       ├── registry/
│   │       └── retrieval/
│   └── sources/
├── seeds/
│   └── semantic/
├── semantic_models/
│   ├── metrics/
│   ├── saved_queries/
│   └── semantic_models/
├── snapshots/
│   └── semantic/
├── tests/
│   ├── generic/
│   └── singular/
└── dbt_project.yml
```

---

## Bootstrap steps

### 1. Create the Python environment

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install dbt-snowflake sqlfluff
```

### 2. Install dbt packages

```bash
dbt deps
```

### 3. Create your local `profiles.yml`

Add a local profile in `~/.dbt/profiles.yml` that matches the project name below:

```yaml
pretiumdata_dbt_semantic_layer:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      password: <password>
      role: DBT_DEV_ROLE
      database: MART_DEV
      warehouse: DBT_DEV_WH
      schema: SEMANTIC
      threads: 8
      client_session_keep_alive: false
    staging:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      password: <password>
      role: DBT_STAGING_ROLE
      database: MART_STAGING
      warehouse: DBT_STAGING_WH
      schema: SEMANTIC
      threads: 8
      client_session_keep_alive: false
    prod:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      password: <password>
      role: DBT_PROD_ROLE
      database: MART_PROD
      warehouse: DBT_PROD_WH
      schema: SEMANTIC
      threads: 8
      client_session_keep_alive: false
```

### 4. Validate the project

```bash
dbt debug --target dev
dbt parse
dbt build --target dev
```

---

## Development workflow

1. Create a feature branch from `main`
2. Build and test only in `dev`
3. Open a pull request
4. CI must pass before merge
5. Merge to `main`
6. GitHub Actions deploys to `staging`
7. Validate release readiness in `staging`
8. Manually approve production deployment
9. Deploy same code to `prod`

---

## First semantic object rollout order

Recommended initial build sequence:

1. `entity_vertical`
2. `registry_signal`
3. `entity_offering`
4. `exposure_policy_registry`
5. `lineage_semantic_object`
6. `template_registry`
7. `template_section`
8. `retrieval_context_registry`
9. `glossary_term`
10. `glossary_alias`
11. `explain_signal`
12. `explain_metric`
13. `registry_conformance`
14. `registry_semantic_object`
15. `registry_entity`
16. `registry_dimension`
17. `registry_key_policy`
18. `registry_semantic_version`

---

## Guardrails

- Do not publish unstable object names
- Do not bypass PR review into `main`
- Do not allow semantic-breaking changes without changelog and version treatment
- Do not expose non-conformed semantic objects to production consumers
- Do not place dev or experimental artifacts in `mart.semantic`

---

## Suggested next files to add

After this bootstrap, the next recommended additions are:

- `packages.yml`
- `models/mart/semantic/_semantic.yml`
- first seed files for `entity_vertical`, `dim_taxon`, and `dim_org_role`
- reusable macros for environment/database resolution
- generic tests for semantic conformance and registry coverage
- `semantic_models/` YAML for first MetricFlow pilot
