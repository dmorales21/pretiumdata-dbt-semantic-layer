# CATALOG UNBLOCK PROMPT
# Audience: Cursor operating in pretiumdata-dbt-semantic-layer
# Goal: Execute the 4 tasks that are blocking downstream metric registration,
#       dbt model promotion, and bridge table work.
# Read before starting:
#   - docs/migration/MIGRATION_RULES.md
#   - docs/rules/TRANSFORM_VENDOR_DESIGN_PRINCIPLES.md
#   - ddl/catalog_constraints.sql
#   - MIGRATION_LOG.md (append your batch row when done)

---

## CONTEXT

The catalog seed layer (REFERENCE.CATALOG) has been hardened with:
- Referential integrity tests (Q1–Q20 in scripts/sql/validation/catalog_health_inventory.sql)
- Hard-fail dbt tests on METRIC (active rows require table_path + snowflake_column)
- Promotion gate: METRIC_RAW active+active → METRIC
- MotherDuck ∧ active ⇒ last_refresh_date on DATASET
- unit accepted_values enforced in two YAML files

Four items are now blocking downstream work. Execute them in order.

---

## TASK 1 — Freeze dataset.product_type_codes and migrate the sync script

### What is blocked
The product_type_bedroom_type bridge table cannot be built while
dataset.product_type_codes is the authoring source.

### What to do

1. In seeds/reference/dataset.csv — add a comment row at the top:
   `# FROZEN: do not edit product_type_codes column — bridge table is authoring source`
   (or add a NOTES column if the seed schema allows it)

2. Open scripts/reference/ and find the script that reads dataset.product_type_codes
   (likely sync_dataset_product_type_from_dataset.py or similar).
   Identify the line(s) that read the comma column.

3. Create scripts/reference/sync_dataset_product_type_from_bridge.py:
   - Read from seeds/reference/bridge_dataset_product_type.csv (see Task 2)
   - Write the same output the old script produced
   - Add a header comment: "Reads from bridge CSV — not from dataset.product_type_codes"

4. Do NOT drop dataset.product_type_codes from dataset.csv yet.
   That is a second PR after the bridge CSV is the confirmed authoring source.

5. Log: append to MIGRATION_LOG.md under "Type Fixes Applied":
   dataset.product_type_codes | frozen pending bridge migration | data-eng

---

## TASK 2 — Create the product_type_bedroom_type bridge CSV

### What is blocked
Q5 referential integrity (ENUM), product_type bedroom_type_codes column removal,
and the unit seed work all depend on the bridge existing first.

### What to do

1. Create seeds/reference/bridge_product_type_bedroom_type.csv with columns:
   product_type_code, bedroom_type_code, sort_order, is_active

2. Populate from the existing bedroom_type_codes comma values in seeds/reference/product_type.csv.
   Expand each comma-separated value into one bridge row per pair.
   Example:
     product_type.csv row: product_type_code=SFR, bedroom_type_codes=3BR,4BR,5BR+
     → bridge rows: (SFR, 3BR, 1, true), (SFR, 4BR, 2, true), (SFR, 5BR+, 3, true)

3. Add to seeds/reference/schema_reference_seeds.yml:
   - not_null tests on product_type_code and bedroom_type_code
   - relationships test: product_type_code → product_type.product_type_code
   - relationships test: bedroom_type_code → bedroom_type.bedroom_type_code
   - unique test on (product_type_code, bedroom_type_code) composite

4. Do NOT drop bedroom_type_codes from product_type.csv yet. Freeze it the same way
   as dataset.product_type_codes (Task 1).

5. Run: dbt seed --select bridge_product_type_bedroom_type
   Confirm 0 relationship test failures.

---

## TASK 3 — Create the unit seed

### What is blocked
The two-YAML accepted_values lists will drift. This is a governance debt item
that gets harder to fix the longer it stays as duplicated hardcoded lists.

### What to do

1. Create seeds/reference/unit.csv with columns:
   unit_code, unit_label, is_active

   Populate with the 11 values currently in accepted_values in schema_metric.yml
   and schema_metric_raw.yml. Confirm the lists are identical before proceeding —
   if they differ, resolve the conflict and document the decision.

2. Add to seeds/reference/schema_reference_seeds.yml:
   - not_null + unique on unit_code
   - is_active boolean test

3. In seeds/reference/schema_metric.yml and schema_metric_raw.yml:
   Replace the accepted_values list for unit with a relationships test:
     - dbt_utils.relationships_where:
         to: ref('unit')
         field: unit_code
         from_condition: is_active = true

4. Run: dbt seed --select unit
   Then: dbt test --select metric metric_raw
   Confirm 0 unit-related test failures.

5. Add a comment in both YAML files pointing to seeds/reference/unit.csv
   so the single source is obvious:
   # unit vocabulary: seeds/reference/unit.csv — do not add values here

---

## TASK 4 — Convert Q6, Q7, Q11, Q19 to hard-fail dbt singular tests

### What is blocked
CI does not currently gate on the four highest-risk catalog violations.
Downstream metric registration and MotherDuck exports can fail silently
without these as blocking CI checks.

### What to do

For each query below, create a file in tests/catalog/ that returns rows
only when the violation exists. A non-empty result = test failure.

**Q6 — Active metric missing table_path or snowflake_column**
File: tests/catalog/assert_active_metric_has_table_path_and_column.sql
```sql
select metric_code, metric_label
from {{ ref('metric') }}
where is_active = true
  and (table_path is null or snowflake_column is null)
```

**Q7 — MotherDuck active dataset missing last_refresh_date**
File: tests/catalog/assert_motherduck_active_dataset_has_refresh_date.sql
```sql
select dataset_code
from {{ ref('dataset') }}
where is_active = true
  and is_motherduck_served = true
  and (last_refresh_date is null or last_refresh_date = '')
```

**Q11 — Active METRIC_RAW not promoted to METRIC**
File: tests/catalog/assert_active_metric_raw_promoted_to_metric.sql
(This already exists — verify it is tagged as a hard failure in selectors.yml
and that it runs in .github/workflows/semantic_layer_catalog_and_quality.yml)

**Q19 — Duplicate metric_code in METRIC**
File: tests/catalog/assert_no_duplicate_metric_code.sql
```sql
select metric_code, count(*) as ct
from {{ ref('metric') }}
group by metric_code
having ct > 1
```

After creating files:
1. Add these tests to selectors.yml under a 'catalog_hard_gates' selector
2. Confirm they are invoked in .github/workflows/semantic_layer_catalog_and_quality.yml
3. Run locally: dbt test --select catalog_hard_gates
4. All four must return 0 rows before the branch merges.

---

## EXECUTION ORDER

1 → 2 → 3 → 4

Tasks 1 and 2 are coupled (bridge replaces comma column).
Task 3 is independent but small — do it alongside Task 2.
Task 4 is independent and can run in parallel after Task 1.

---

## WHAT NOT TO DO

- Do NOT drop dataset.product_type_codes or product_type.bedroom_type_codes in this PR
- Do NOT add dbt source() entries pointing to TRANSFORM_PROD, ANALYTICS_PROD, or EDW_PROD
- Do NOT write to TRANSFORM.[VENDOR] schemas (Jon's space)
- Do NOT add post-hook DDL for NOT NULL — that belongs in ddl/catalog_constraints.sql only
- Do NOT modify the opco.pretium row — vertical_code stays nullable with documented exception

---

## LOGGING

After completing all tasks, append one batch row to MIGRATION_LOG.md:
  batch | today's date | tasks completed | Cursor | catalog unblock — bridge + unit seed + CI gates
