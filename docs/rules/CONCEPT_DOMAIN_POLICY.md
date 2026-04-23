# Concept domain policy (`REFERENCE.CATALOG.CONCEPT.domain`)

**Owner:** Alex  
**Purpose:** Govern how each `concept_code` is assigned one of five **`domain_code`** values. Domains are **navigation and coarse IC filters**, not assertions of **metric comparability** (that remains **`metric_code`** and **`concept_code`** per catalog rules).

**Cross-ref (analytics-engine alignment):** [`../reference/concepts_by_domain.csv`](../reference/concepts_by_domain.csv) lists current `concept_code` → `domain_code` rows for this repo’s catalog seeds.

**Registry:** `seeds/reference/catalog/domain.csv` → **`REFERENCE.CATALOG.DOMAIN`**. **`concept.domain`** must equal a **`domain_code`** in that seed.

---

## What a concept is (and is not)

### A concept **is**

- A **stable semantic object** that groups comparable measures of the same economic meaning across vendors/time.
- A contract that can support **canonical concept unions** (`CONCEPT_*`) and consistent metric assignment in `REFERENCE.CATALOG.METRIC`.
- Examples: `ltv`, `rent`, `absorption`, `income`, `transactions`.

### A concept **is not**

- A workflow namespace, package label, or pipeline artifact (`spine`, `underwriting`, fund-process objects).
- A multi-source app bundle / panel shorthand (for example ranker bundles on `FEATURE_*` surfaces).
- A vendor table name, report title, or temporary project grouping.

### Non-overlap rule

- If a term overlaps a canonical measure concept and a workflow/bundle meaning, **it must not be an active `concept_code`**.
- Workflow/bundle aliases may exist only as **inactive legacy rows** (for backward compatibility), and must not carry active `MET_*` registrations.

---

## Decision tests (use these, not intuition)

| `domain_code` | Assign here when the concept is primarily about… |
|---------------|---------------------------------------------------|
| **`housing`** | **Housing stock and housing-market outcomes:** rent and price *levels for housing*, vacancy/occupancy of housing units, permits/pipeline/absorption as **housing supply**, concessions as a **lease-market** object tied to housing units, residential sales turnover when framed as the **housing market**. |
| **`household`** | **People and households** as units of analysis: population, migration, household income distribution, demographic structure. Not “rent USD” as a market clearing price—that stays **housing** via **`metric_code`**. |
| **`place`** | **Location quality / jurisdiction / environment** at a geography: crime, schools, amenities, regulatory climate as **place attributes**; **local labor market rates** (employment level, unemployment rate, labor-force participation) when used as **place-conditioned** screening signals. |
| **`capital`** | **Financing, cashflows, leverage, securities, and institutional capital-markets inputs:** NOI, DSCR, LTV, cap rate, delinquency, arbitrage, ownership structure; **benchmark rates and inflation indices** used as discount or macro-finance curves (not housing unit counts). |
| **`portfolio`** | **Owned-asset performance and operations** for assets already on the balance sheet: exit/disposition economics, realized yield and cashflow marks, valuation refresh cadence, turns, capex execution, credit loss experience, and **operational** occupancy (collections / revenue-generating unit state) when the read is **portfolio reporting**, not public housing-market vacancy. |

---

## Pretium default mapping (replaces legacy `demand` / `supply` / `macro` / ambiguous `portfolio` market vs org)

| `concept_code` | `domain_code` | Rationale |
|----------------|----------------|-----------|
| rent, occupancy, vacancy, permits, absorption, supply_pipeline, concession, homeprice, listings, housing_stock, transactions, multifamily_market | **housing** | Stock, flows, and prices in the **housing market** (including asset price for housing). |
| population, migration, income, wages, education | **household** | Stocks/flows of people and **household money** / demographics (earnings, attainment). |
| employment, unemployment, labor, crime, school_quality, automation, pipeline (O*NET / workforce bundle) | **place** | **Local labor market** and **location-quality** proxies at geo grain; **`pipeline`** here is **workforce / O*NET** indicators—not **`supply_pipeline`** (housing). |
| noi, dscr, ltv, cap_rate, delinquency, rates, inflation, spine, underwriting | **capital** | **Deal / curve / underwriting** objects and capital-markets series. |
| disposition | **portfolio** | **Exit economics and IC disposition** for owned assets (hold/sell/fix), distinct from public market housing mechanics. |

**Labor rule:** `employment`, `unemployment`, and **`labor`** share **`place`** so filters do not split one labor narrative across domains. If Pretium later splits concepts (e.g. national payroll vs county LAUS), revisit domain per **new** `concept_code` rows only.

**Occupancy fork:** **`occupancy`** in the catalog is **housing-market physical/economic occupancy of units** → **`housing`**. **Operational** occupancy for owned-asset reporting belongs on **`portfolio`** only if introduced as a **separate** `concept_code` (do not overload one code with two domains).

---

## Edge cases (explicit rulings)

1. **Rent burden / renter share vs market rent USD** — Wrong split is **`domain`** only. Use **`concept_code`** and **`metric_code`** (e.g. ACS burden under affordability/household economics vs `rent` market metrics).  
2. **Climate / hazard / insurance exposure at ZIP** — **`place`** (location-conditioned risk/amenity); structured **credit** products → **`capital`**.  
3. **ZHVI vs FHFA HPI** — Both **housing** domain; **never** mix index vs USD in one **`metric_code`** (separate catalog rule).  
4. **MF ranker panel** — not a canonical **`concept_code`**; treat as **feature/model bundle vocabulary** on `ANALYTICS` surfaces and map each metric to canonical concepts where possible.  
5. **Progress workflow objects** (`spine`, `underwriting`) — not canonical concepts; treat as workflow namespaces on FACT/CONCEPT_PROGRESS/FEATURE surfaces and avoid registering active `MET_*` on those pseudo-concepts.  
5. **Property transactions volume** — **`housing`** when the concept is **residential market turnover**; pure deed counts used only for non-residential analytics would need a different **`concept_code`**, not an extra **`domain_code`**.  
6. **Census “macro”** — There is **no** `macro` domain. Assign with the table above (e.g. population → **household**, unemployment → **place**).  
7. **Rates vs cap rates** — Both **capital**; comparability is still **`metric_code`**.  
8. **Inflation (CPI/PCE)** — **`capital`** (macro index for curves and real cuts).  
9. **Workforce automation (county exposure)** — **`place`** (geo-conditioned labor/task risk); if repurposed as **household welfare** only, document in **`definition`** but keep one domain per `concept_code`.  
10. **Anything that “does not fit”** — Prefer **splitting or retagging `concept_code`**, or using **`portfolio`** for owned-asset execution reads, before inventing ad hoc domain-like labels outside the five **`domain_code`** values.

---

## What not to do

- Do **not** use **`domain`** to encode **ask vs effective rent**, **index vs USD**, or **LAUS vs QCEW program** semantics—those live on **`metric_code`**, **`dataset_code`**, and vendor docs.  
- Do **not** add shadow domains (e.g. “macro”) via **`domain`**; fix **`concept`** definitions instead.

---

## Internal glossary — `concept.domain` as coarse partition

**Treat `domain` as a coarse, human-facing partition** for navigation, governance, and permissions—not as a substitute for **`concept_code`** (semantic meaning) or **`metric_code`** (comparable measure identity).

### 1. `housing` — the housing stock and housing-services market

#### What this domain is meant to capture

**`housing`** is the domain of **physical housing** and the **markets that price, allocate, and produce housing units** as housing: how much housing exists, how it is used (occupied vs vacant), how it is transacted (rented vs owned), how new housing is authorized and delivered, and how **housing cash flows and housing collateral** behave *as housing market outcomes*.

Think: **the housing product** and **the housing market mechanism** (even when measured at CBSA/ZIP/county).

#### Typical concepts/metrics that belong here

- **Rent and lease-market outcomes** when they are measures of **housing service prices** (market rent levels, effective vs asking where defined as rent, rent growth for housing units).
- **Occupancy / vacancy** of **housing units** (not employment occupancy).
- **Supply and market clearing for housing units**: permits, under construction, pipeline, **net absorption of housing inventory**, months’ supply when defined from housing inventory and housing demand flows.
- **Housing asset prices** when you treat them as **housing market pricing** (e.g., home price indices/medians used to describe the housing market, not the bond market).
- **Housing operations tied to units** (e.g., concessions expressed as leasing economics on housing units—still “housing market,” though it borders operations).

#### What `housing` is *not*

- It is **not** “everything that affects housing.” Macro rates, wage growth, and demographics *affect* housing but are not automatically **`housing`** unless your policy explicitly says “domain follows primary consumer” (usually a bad idea—blurs governance).
- It is **not** a dumping ground for **household financial stress** measures that are not housing-market prices (e.g., rent-to-income belongs in a careful split: the *ratio* is often **`household` economics**; the *rent component* is **`housing`**—see cross-domain note below).

#### How `housing` interacts with other domains

- **`housing` describes the housing-side object**. A household affordability constraint often combines **`housing` + `household`** inputs at the **`metric_derived`** layer rather than forcing one domain to “own” the whole story.

#### Practical governance value

Use **`housing`** to scope:

- market-selection screens focused on **rent/occupancy/supply/absorption**,
- underwriting narratives about **lease-up and stabilization**,
- product teams building **BTR / MF / SFR housing** analytics packs.

---

### 2. `household` — people, households, and household-level economic state

#### What this domain is meant to capture

**`household`** is the domain of **human populations organized as households** and the **economic and demographic states** of those populations: how many people/households there are, how they move, how they earn, how they form demand, and how they experience **economic pressure or opportunity** *as households*.

This is the natural home for **who lives here / who can pay / who is arriving or leaving** and for **demand fundamentals** that are not strictly “a housing unit market price.”

#### Typical concepts/metrics that belong here

- **Population** stocks and components.
- **Migration** (household/person flows) as demographic/economic relocation.
- **Income** (median household income, income distribution moments) as **household economic capacity**.
- **Household composition** measures: renter share *as a demographic structure*, age cohort dependency, household formation—when interpreted as **population structure**, not “rent USD.”
- **Workforce / labor participation** *if you classify it as household economic opportunity* (see tension with `place` below—pick a policy).

#### What `household` is *not*

- It is **not** the housing unit inventory system (`housing`).
- It is **not** “public goods / local amenities” (`place`).
- It is **not** securities, leverage, or loan performance (`capital`)—even though household income influences debt capacity.

#### Edge case: rent-to-income and “burden” metrics

These are inherently **cross-domain** in meaning:

- **Rent level** belongs in **`housing`**.
- **Income** belongs in **`household`**.
- **A ratio like rent-to-income** is best treated as either:
  - a **`metric_derived`** output with explicit inputs, and/or
  - a dedicated **`concept_code`** (e.g., affordability) with its own domain choice.

**Do not** use `domain=housing` alone to imply “affordability is fully described.”

#### Practical governance value

Use **`household`** to scope:

- demographic demand modeling,
- migration-driven rent *drivers* (not the rent print itself),
- affordability analytics that are fundamentally **income/population** led.

---

### 3. `place` — location quality, local public goods, and “site” competitiveness

#### What this domain is meant to capture

**`place`** is the domain of **geography as a bundle of attributes** that make a location more or less attractive **beyond the housing market clearing price**: safety, schools, amenities, access, regulatory environment, environmental exposure, and sometimes **local labor market conditions** *as a feature of place competitiveness*.

This is closest to: **why this ZIP/CBSA** is desirable or risky *as a location*.

#### Typical concepts/metrics that belong here

- **Crime** indices/rates (location public safety).
- **School quality** (location education services).
- **Amenity access** / connectivity measures that are explicitly about **place infrastructure** (walkability proxies, transit access—depending on your definitions).
- **Local unemployment / employment** *if your policy treats them as “labor market tightness / place quality”* for site selection (common in real estate). This is the main fork with `household`.

#### What `place` is *not*

- It is **not** “anything geo-referenced.” Almost everything in real estate is geo-referenced; domain is about **meaning**, not presence of `geo_id`.
- It is **not** a replacement for **`housing`** supply/demand mechanics (pipeline/absorption are housing market mechanisms, not “school quality”).

#### The key fork: `employment` / `unemployment` in `place` vs `household`

You should pick **one consistent story**:

- **`place` interpretation (common in site selection):** unemployment/employment are **local market conditions** that influence **location competitiveness** and operating risk (hiring, wage pressure, local recession risk).
- **`household` interpretation:** unemployment/employment are **household economic outcomes/opportunities** (jobs access as welfare of residents).

Either can be valid—**but split by `concept_code` policy**, not arbitrary row-by-row mood. If you cannot split concepts, keep **both** labor metrics in the **same** domain.

#### Practical governance value

Use **`place`** to scope:

- “micro-location” and **ESG / climate exposure** when framed as location risk,
- education/crime screens,
- location premia discussions that are not strictly “rent level.”

---

### 4. `capital` — financing, leverage, cashflows, and capital-markets primitives

#### What this domain is meant to capture

**`capital`** is the domain of **money and claims on cash flows** as finance: loans, leverage, coverage, returns, market rates, securitization performance, and **institutional underwriting objects**. It is where **balance sheet logic** lives.

#### Typical concepts/metrics that belong here

- **NOI, DSCR, LTV, cap rate** (as financing/investment metrics—often property grain).
- **Delinquency / default / loss severity** (credit performance).
- **Fund / deal spine objects** (acquisition underwriting packages, entity linkage) when treated as **capital workflow artifacts**.
- **Market rates** used as discounting/benchmark curves: Treasuries, mortgage rate indices, swap/spread primitives—**as finance series**, not as “local place quality.”

#### What `capital` is *not*

- It is **not** “anything numeric with dollars.” Rent is dollars but is usually **`housing`** because it is **housing service pricing**, not a financing claim.
- It is **not** household income (`household`) even though it is measured in dollars.

#### Edge case: cap rate straddles `housing` and `capital`

Cap rate uses **NOI (capital/operations)** and **value (often housing market pricing)**. Domain tagging should follow **primary consumer**:

- If the metric is used primarily as a **financing / investment screening metric**, **`capital`** is reasonable.
- If it is used primarily as a **market pricing / valuation summary** for housing assets, some teams prefer **`housing`**. The key is **consistency** and documentation—not pretending one tag resolves economic duality.

#### Practical governance value

Use **`capital`** to scope:

- lender + securities workflows,
- capital-structure and securities analytics,
- stress testing and rate shocks,
- anything that should never be mixed into “public demographic place” packs without explicit bridging.

---

### 5. `portfolio` — owned-asset performance and operations

#### What this domain is meant to capture

**`portfolio`** is the domain of **financial and operational outcomes for assets already owned or under active IC management**: disposition and exit economics, realized yield, cashflow and valuation marks, turns, capex programs, credit loss experience, and operational reporting that answers **“how is this book performing?”** rather than **“what is the public market doing?”**

#### Typical concepts/metrics that belong here

- **Disposition / exit economics** when framed as **owned-asset exit** (`disposition`).
- **Operational performance** metrics that are explicitly **fund or OpCo reporting** objects (not public market housing supply/demand).

#### What `portfolio` is *not*

- It is **not** a substitute for **`housing`** market concepts (rent level, market vacancy, listings, permits).
- It is **not** **`capital`** curves (rates, inflation) unless the series is used **only** as a discount input bundled elsewhere—prefer **`capital`** for rate level series.

#### Practical governance value

Use **`portfolio`** to scope IC reporting, hold/sell/fix decisions, and internal marks—so Presley and tearsheet surfaces can separate **public market** (`housing` / `place`) from **book** performance.

---

### Cross-cutting: how to use the five domains without breaking semantics

1. **`domain` is not a replacement for `concept_code` or `metric_code`.** It organizes catalogs and UI; it does not define comparability.
2. **If a concept is inherently cross-domain**, prefer **`metric_derived`** with explicit inputs, or **split `concept_code`**, rather than forcing a single `domain` to carry the whole meaning.
3. **This document plus the decision table above** is the arbiter for future rows; extend with numbered examples (rent, home price, unemployment, migration, crime, NOI, rates, rent-to-income) as new edge cases appear.

---

## Related

- Architecture and catalog layers: [`ARCHITECTURE_RULES.md`](./ARCHITECTURE_RULES.md)  
- Seed order: [`../CATALOG_SEED_ORDER.md`](../CATALOG_SEED_ORDER.md)  
- Domain dimension seed: [`../../seeds/reference/catalog/domain.csv`](../../seeds/reference/catalog/domain.csv)
