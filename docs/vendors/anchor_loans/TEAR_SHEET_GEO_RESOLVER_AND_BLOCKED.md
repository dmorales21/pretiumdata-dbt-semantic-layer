# Tear Sheet Geography Resolution and BLOCKED Artifacts

**Purpose:** When a deal has lat/lon but no ZIP/CBSA (or canon join misses), the tear sheet must not be produced as “complete.” The correct output is a **BLOCKED** artifact with missing fields, debug geo, coverage, and next actions.  
**Audience:** Data engineering, pipeline owners, underwriting.

---

## 1. Why geography is required

The tear sheet content stack depends on **stable geography keys**:

- **ZIP** — ZIP-level facts (pricing, inventory, DOM, place/school/crime).
- **CBSA** — CBSA-level facts (labor, starts/closings, market metrics).
- **H3 ladder** — Optional for property-level and choropleths.

If **cbsa_code** or **zip_code** (and joinable keys) are missing:

- ZIP-level facts cannot join → pricing, inventory, DOM, school, crime show as — or empty.
- CBSA-level facts cannot join → labor, starts/closings, market score undefined.
- Choropleths and maps cannot render.
- The artifact is **not decision-grade** and must not be presented as a tear sheet.

---

## 2. Stop-ship is joinability-based and non-bypassable in production

Stop-ship is based on **joinability keys**, not “nice-to-have” context. For Anchor deal-level tear sheets:

- **Must have:** `deal_id`.
- **Must have at least one geo resolution ladder:**
  - **H3 ladder:** `h3_10` or `h3_8` (with consistent parents), OR
  - **ZIP ladder:** `zip_code` **and** `cbsa_code` (both).
- CBSA-only is **not** sufficient for deal-level; it is acceptable only for market-level tear sheets.
- **School/crime** are **not** stop-ship criteria; they are coverage (LIVE/STUB/MISSING_SOURCE) only.

**No patching:** Do not infer or patch CBSA/ZIP/H3 to make stop_ship pass. If no ladder is joinable, the output must be BLOCKED.

**Production:** When `stop_ship.pass` is false, the renderer only writes a BLOCKED report. No PDF and no complete-looking HTML tear sheet.

**Dev only:** `--dev-ignore-stop-ship` allows the renderer to continue; output is explicitly not decision-grade. Do not use in production or CI.

---

## 3. BLOCKED artifact content (human + machine-actionable)

When stop_ship fails, the renderer writes a single HTML artifact that includes:

- **Title:** “BLOCKED — Missing required geography resolution”
- **Structured (machine-actionable):** JSON block with `blocked_reason_code`, `blocked_reason_detail`, `resolver_stage_failed`, `missing_critical`, `deal_id` for orchestration and dashboards.
- **Missing required (joinability gate):** List from `stop_ship.missing_critical`
- **Reason code and resolver stage:** e.g. `GEO_CANON_MISS`, `MISSING_LATLON`, `MISSING_ZIP_CBSA`, `NO_JOINABLE_LADDER`; resolver stage e.g. `canon_join`, `geocode_missing`, `zip_cbsa_missing`.
- **Debug — geography:** lat, lon, cbsa_code, zip_code, resolver_stage_failed
- **Coverage:** Section status table (LIVE / STUB / MISSING_SOURCE) from payload
- **Next actions:** Fix canon, enrich at ingest, add polygon fallback

**Blocked reason codes (enum):** `MISSING_DEAL_ID`, `MISSING_LATLON`, `GEO_CANON_MISS`, `MISSING_ZIP_CBSA`, `H3_LADDER_INVALID`, `NO_JOINABLE_LADDER`.  
**Resolver stage failed:** `canon_join`, `polygon_fallback`, `geocode_missing`, `zip_cbsa_missing`.  
Persisted in `ANCHOR_TEAR_SHEET_BLOCKED_RUNS` (columns: `blocked_reason_code`, `blocked_reason_detail`, `resolver_stage_failed`) for querying and burn-down.

---

## 4. Root cause: canon miss

The **H3_XWALK_6810_CANON** (or equivalent) table maps H3 cells to ZIP/CBSA. If a deal’s (lat, lon) → H3-8 (or H3-10) does **not** appear in the canon, then:

- No ZIP or CBSA can be assigned from the canon.
- Downstream joins fail; coverage is effectively 0% for geography-dependent sections.

**LIBERTY_HILLS** (as of this doc): lat ≈ 33.376, lon ≈ -96.609. H3-8 lookup against `TRANSFORM_PROD.REF.H3_XWALK_6810_CANON` returned **0 rows**. So:

- That point is outside current canon coverage, or the point/canon grain is wrong.
- Until resolution is fixed, the correct output for LIBERTY_HILLS is a **BLOCKED** artifact, not a tear sheet.

---

## 5. What to fix next (order)

1. **Geo resolver fallback** — When canon misses, resolve lat/lon → CBSA/ZIP via polygon containment (e.g. Census ZCTA + CBSA shapes). Implement as fallback path in geography resolution (ref_anchor_deal_geography_resolved or equivalent).
2. **Stop-ship non-bypassable in prod** — Confirmed: only BLOCKED artifact when stop_ship fails; `--dev-ignore-stop-ship` for dev only.
3. **Coverage in artifact** — BLOCKED report includes section LIVE/STUB/MISSING_SOURCE and missing required fields.
4. **Production pipeline shape** — Payload from resolver + delivery views → ANCHOR_TEAR_SHEET_PAYLOAD (schema version, coverage, stop_ship) → renderer reads payload only. No ad hoc CSV → patch → JSON; no bypassing the contract.

---

## 6. Coverage contract (LIVE / STUB / MISSING_SOURCE)

Coverage classification must be **deterministic** and tied to the spec (required, allow_stub, zero_rows_behavior, source/join success):

| Status | Meaning |
|--------|--------|
| **LIVE** | Has value (scalar) or has rows (dataset); join succeeded. |
| **STUB** | Missing but `allow_stub=true`, OR dataset has zero rows where `zero_rows_behavior=stub`. |
| **MISSING_SOURCE** | Source object missing, OR join key missing, OR dataset required but zero rows where `zero_rows_behavior=stop_ship`. |

Persist coverage at **metric level** where possible: `(deal_id, run_ts, section_id, item_id, status)` so stubs can be burned down by item. Section-level status (as in payload today) is the minimum; metric-level is preferred for operational dashboards.

---

## 7. Appendix / provenance (for real tear sheets)

When stop_ship passes and a tear sheet is produced, it must include:

- **Source:** Exact table/view used per metric (per TEAR_SHEET_CONTENT_BY_OFFERING and data map).
- **As-of:** Timestamp/date for each metric where applicable.
- **Definition:** Metric definition and interpretation (e.g. from metric dictionary / DIM_TEMPLATE).

The BLOCKED artifact does not substitute for a tear sheet; it explains why a tear sheet was not generated and what to fix upstream.

---

## 8. Resolver implementation (fix order)

1. **Resolver model/step:** lat/lon → H3-10; H3-10 → ZIP/CBSA via canon; **if canon miss** → polygon containment (ZCTA + CBSA shapes).
2. **Persist:** Write result to `ref_anchor_deal_geography_resolved` (or equivalent).
3. **Payload builder:** Use resolver output only (no ad hoc joins). Screener view must expose `h3_8`/`h3_10` and/or `zip_code`+`cbsa_code` from the resolver.
