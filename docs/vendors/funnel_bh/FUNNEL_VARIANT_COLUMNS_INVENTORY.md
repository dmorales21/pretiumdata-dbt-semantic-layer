# Funnel variant (OBJECT) columns – inventory and extraction

**Purpose:** Ensure every OBJECT (Variant/JSON) column in DS_FUNNEL_BH.STANDARD is either **extracted** in a fact or cleaned model or **documented** as intentional pass-through.

**Discovery:** Run from repo root (Snowflake connection `pretium`):

```bash
snowsql -c pretium -f scripts/discovery/funnel_object_columns.sql
```

Or Python: `.venv/bin/python scripts/discovery/list_funnel_object_columns.py`

Full snapshot: `docs/vendors/funnel_bh/discovery/OBJECT_COLUMNS_INVENTORY.txt` (65 OBJECT columns across 24 views, as of last run).

---

## Views used in the fact layer (extraction status)

| Source view | OBJECT columns | Extracted in | Notes |
|-------------|----------------|--------------|-------|
| **CLIENT_APPOINTMENTS** | APPOINTMENT_STATUS, TOUR_TYPE | fact_funnel_appointment_outcomes_daily | APPOINTMENT_STATUS → status_num (funnel_parse_appointment_status). TOUR_TYPE: pass-through; add funnel_variant_get if needed. |
| **LISTING_HISTORY_DAILY** | LAYOUT_TYPE, UNIT_STATUS | fact_funnel_listing_history | Both extracted → layout_type_id/name, unit_status_id/name (funnel_variant_get). |
| **CLIENT_FUNNEL** | CLIENT_LEAD_SOURCE, CLIENT_DISCOVERY_SOURCE, CLIENT_ORIGIN_SOURCE | — | housing_hou_demand_funnel_bh uses only scalars. Variants pass through cleaned; add extraction in fact if lead/source dimensions needed. |
| **LEASE_TRANSACTION_HISTORY** | *(none)* | — | No OBJECT columns; fact uses scalars only. |

---

## Full inventory (65 OBJECT columns, 24 views)

| View | OBJECT columns |
|------|----------------|
| ACCOUNT_GROUPS | TEAM_TYPE |
| ACTION_REQUIRED | HANDOFF_TYPE, RESPONSIBLE_TEAM, LEASE_TRANSACTION_STEP, LEASE_STEP |
| APPLICANTS | IDENTITY_VERIFICATION_INFO, EMERGENCY_CONTACT_RELATIONSHIP |
| CHATBOT_CONVERSATIONS | CONVERSATION_TYPE |
| CLIENTS | CLIENT_STATUS, CLIENT_HOUSEHOLD, LEASE_TERM, CLIENT_NEIGHBORHOOD, INTEREST_LEVEL |
| CLIENTS_PERSON | SMS_OPTED_IN, EMAIL_UPDATES_OPT_IN, COMMUNICATION_PREFERENCE, IDENTITY_VERIFICATION_STATUS |
| CLIENT_APPOINTMENTS | APPOINTMENT_STATUS ✓, TOUR_TYPE |
| CLIENT_FUNNEL | CLIENT_LEAD_SOURCE, CLIENT_DISCOVERY_SOURCE, CLIENT_ORIGIN_SOURCE |
| CLIENT_HISTORY | EVENT_NAME, CLIENT_LEAD_SOURCE, CLIENT_DISCOVERY_SOURCE, CLIENT_ORIGIN_SOURCE, LAYOUT_TYPE, LOSS_REASON |
| CLIENT_REMINDERS | CREATED_VIA |
| CLIENT_TOUCHES | SOURCE_TYPE, ORIGIN_SOURCE, MEDIUM, CATEGORY, LEAD_SOURCE, DISCOVERY_SOURCE, DEVICE |
| GROUP_ASSIGNMENTS | CLIENT_STATUS, LEASE_RENEWAL_STATUS, NOTICE_STATUS |
| LEADACQUISITION_COST, LEAD_ACQUISITION_COST | COST_TYPE, LEAD_SOURCE |
| LISTING_HISTORY_DAILY | LAYOUT_TYPE ✓, UNIT_STATUS ✓ |
| LISTING_HISTORY_PERIODS | LAYOUT_TYPE, UNIT_STATUS, LAST_STATUS |
| ONLINELEASING_* (7 views) | DENIAL_REASON, NEXT_STEP, PAYMENT_TIME, UNIT_CHANGES (see inventory file) |
| TWILIO_* (4 views) | CLIENT_STATUS_DESCRIPTION, *_LEAD_SOURCE (see inventory file) |

✓ = extracted in fact layer. **UNITS** and **STRIPE_*** views: no OBJECT columns.

---

## Other funnel views

- **UNITS** → funnel_units, funnel_property. Discovery: **no OBJECT columns**.
- All other STANDARD views with OBJECT columns (above) are cleaned pass-through only. Add extraction in the cleaned or fact model when a use case exists.

---

## Extraction patterns (canonical)

1. **Single key (e.g. status id):** Use `funnel_parse_appointment_status(column_name)` for numeric status; or `funnel_variant_get(column_name, 'id')` for string id.
2. **Object with id + name (or other keys):** Use `funnel_variant_get(column_name, 'id')`, `funnel_variant_get(column_name, 'name')` in the fact (or cleaned) model. Handles OBJECT and VARCHAR JSON; macro in `macros/funnel_variant_get.sql`.
3. **Custom keys:** Same macro: `funnel_variant_get(column_name, 'key_name')`. If the share uses different keys (e.g. `label` instead of `name`), pass that key.

---

## Checklist after running discovery

1. Run `snowsql -c pretium -f scripts/discovery/funnel_object_columns.sql` (or `list_funnel_object_columns.py`) and save the output to `OBJECT_COLUMNS_INVENTORY.txt`.
2. For each view that has OBJECT columns:
   - If the view feeds a **fact** model: ensure the fact (or its cleaned source) extracts those columns or explicitly documents pass-through.
   - If the view is **cleaned-only** and no fact uses it: document in this file or in DS_FUNNEL_BH_VIEWS_INVENTORY.md that OBJECT columns are pass-through; add extraction when a use case exists.
3. Update the table above if new OBJECT columns are found in CLIENT_FUNNEL, LEASE_TRANSACTION_HISTORY, or UNITS.
4. If a new view gets a fact consumer, re-run discovery for that view and add extraction if it has OBJECT columns.
