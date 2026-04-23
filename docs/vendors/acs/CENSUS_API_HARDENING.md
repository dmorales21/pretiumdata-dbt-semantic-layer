# Census API Hardening Implementation

**Date**: 2026-01-12  
**Status**: ✅ Implemented

---

## Problem Statement

The Census Population Estimates (PEP) county endpoint returned HTTP 404 errors because county-level data requires a parent geography parameter (`in=state:*`) in the Census API's hierarchical geography model.

**Root Cause**: County geography is hierarchical; some PEP endpoints require specifying the parent geography (`in=state`) when requesting all counties. The Census API's geography model uses `for=` and `in=` clauses, and PEP examples show county requests scoped under state.

---

## Solution Implemented

### 1. Geography Hierarchy Map

Added a `GEOGRAPHY_HIERARCHY` dictionary that maps geography levels to their required parent geographies:

```python
GEOGRAPHY_HIERARCHY = {
    'county': {
        'required_parent': 'state',
        'parent_param': 'in',
        'parent_value': 'state:*',
    },
    'tract': {
        'required_parent': ['state', 'county'],
        'parent_param': 'in',
        'parent_value': 'state:*',
    },
    'place': {
        'required_parent': 'state',
        'parent_param': 'in',
        'parent_value': 'state:*',
    },
    'cbsa': None,  # No parent required
}
```

**Benefits**:
- Prevents 404 errors by automatically adding required parent parameters
- Centralized configuration for all Census datasets
- Easy to extend for new geographies

---

### 2. Automatic Query Builder

Created `build_census_query_params()` function that:
- Automatically enforces geography hierarchy
- Adds `in=state:*` for counties without manual intervention
- Can be reused across all Census API scripts

**Usage**:
```python
params = build_census_query_params('county', 'county:*')
# Automatically includes: {'in': 'state:*'}
```

---

### 3. Deterministic 404 Handling

**Key Change**: Treat 404 as deterministic failure, not transient error.

**Before**: 404 errors were retried 5 times (wasting time)

**After**:
- 404 errors are logged immediately with full URL and parameters
- No retries for 404 (saves time)
- Immediate fallback to state-by-state iteration for hierarchical geographies

**Code Pattern**:
```python
if response.status_code == 404:
    logger.error(f"404 Not Found - Invalid endpoint or geography clause")
    logger.error(f"URL: {full_url}")
    # No retry - try fallback immediately
    return None
```

---

### 4. State-by-State Fallback

Implemented `download_pep_data_by_state()` as a bulletproof fallback:

- Iterates over all state FIPS codes (01-56)
- Makes individual requests per state: `for=county:*&in=state:01`, etc.
- Combines results into single DataFrame
- Slower but operationally bulletproof

**When Used**:
- Primary request with `in=state:*` returns 404
- For hierarchical geographies (county, tract, place)

**Benefits**:
- Works even if `state:*` syntax fails for a dataset
- Provides granular error reporting per state
- Can resume from specific states if interrupted

---

### 5. Error Classification

**Transient Errors** (retry with backoff):
- HTTP 429 (Rate Limit) - retry with `Retry-After` header
- HTTP 5xx (Server Errors) - retry with exponential backoff
- Network errors - retry with exponential backoff

**Deterministic Errors** (no retry):
- HTTP 404 (Not Found) - invalid endpoint or geography clause
- HTTP 400 (Bad Request) - invalid parameters

---

### 6. Endpoint Validation (Smoke Tests)

Created `scripts/validate_census_endpoints.py` for CI/pre-flight checks:

**Features**:
- Lightweight test calls for each geography before bulk downloads
- Validates endpoint URLs and parameter combinations
- Fails fast if endpoints are invalid
- Can be run in CI/CD pipeline

**Usage**:
```bash
python3 scripts/validate_census_endpoints.py
```

**Tests**:
- PEP - CBSA (all CBSAs)
- PEP - County (all counties, with state parent)
- PEP - County (single state: CA)
- CBP - CBSA (all CBSAs)
- CBP - County (all counties, with state parent)

---

## Code Changes

### Files Modified

1. **`scripts/download_census_pep.py`**:
   - Added `GEOGRAPHY_HIERARCHY` map
   - Added `build_census_query_params()` function
   - Refactored `download_pep_data()` with deterministic 404 handling
   - Added `download_pep_data_by_state()` fallback
   - Split request logic into `download_pep_data_single_request()`

2. **`scripts/validate_census_endpoints.py`** (NEW):
   - Smoke test script for endpoint validation
   - Can be run before bulk downloads
   - Suitable for CI/CD integration

---

## Usage Examples

### Standard Download (Automatic Hierarchy)

```python
# County download - automatically adds in=state:*
df = download_pep_data('county', 'county:*')
```

### State-by-State Fallback (Automatic)

If primary request fails with 404, fallback is automatic:

```python
# Tries: for=county:*&in=state:*
# If 404, automatically falls back to state-by-state iteration
df = download_pep_data('county', 'county:*')
```

### Validation Before Bulk Download

```bash
# Run smoke tests
python3 scripts/validate_census_endpoints.py

# If all pass, proceed with bulk download
python3 scripts/download_census_pep.py
```

---

## Sanity Check URLs

These patterns are validated and work correctly:

1. **County PEP (all counties)**:
   ```
   .../pep/population?get=NAME,POP&for=county:*&in=state:*&key=...
   ```

2. **County PEP (single state: CA)**:
   ```
   .../pep/population?get=NAME,POP&for=county:*&in=state:06&key=...
   ```

3. **CBSA PEP (all CBSAs)**:
   ```
   .../pep/population?get=NAME,POP&for=metropolitan%20statistical%20area/micropolitan%20statistical%20area:*&key=...
   ```

---

## Prevention Measures

### 1. Query Builder Rule Enforcement

The `build_census_query_params()` function automatically enforces required parent geographies per level. No manual intervention needed.

### 2. CI Smoke Test Integration

Add to CI/CD pipeline:
```yaml
- name: Validate Census Endpoints
  run: python3 scripts/validate_census_endpoints.py
```

### 3. 404 as Deterministic Failure

404 errors are logged immediately with full context and don't waste time on retries.

### 4. State-by-State Fallback

If `state:*` ever behaves oddly, the fallback iterates states individually (slower but bulletproof).

---

## Benefits

✅ **Prevents 404 Errors**: Automatic hierarchy enforcement  
✅ **Faster Failure Detection**: 404 treated as deterministic (no wasted retries)  
✅ **Operationally Bulletproof**: State-by-state fallback for edge cases  
✅ **Reusable Pattern**: Can be applied to other Census datasets (CBP, ACS, etc.)  
✅ **CI/CD Ready**: Smoke test script for validation  
✅ **Better Debugging**: Full URL and parameter logging on failures  

---

## Next Steps

1. **Apply to Other Scripts**: Extend hierarchy map to `download_census_cbp.py` and other Census API scripts
2. **CI Integration**: Add `validate_census_endpoints.py` to CI/CD pipeline
3. **Documentation**: Update Census API integration docs with hierarchy patterns
4. **Monitoring**: Add alerts for 404 errors in production downloads

---

## References

- [Census Data API User Guide](https://www.census.gov/content/dam/Census/data/developers/api-user-guide/api-user-guide.pdf)
- [PEP API Examples](https://api.census.gov/data/2023/pep/population/examples.html)
- [Census Geography Hierarchy](https://www.census.gov/programs-surveys/geography/guidance/geo-identifiers.html)

---

**Last Updated**: 2026-01-12

