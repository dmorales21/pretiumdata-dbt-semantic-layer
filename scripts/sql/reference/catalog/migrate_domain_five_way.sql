-- Domain vocabulary + concept.domain remap — five-way model (capital, housing, household, place, portfolio).
-- Run in Snowflake after dbt seeds (or equivalent) load REFERENCE.CATALOG.DOMAIN and REFERENCE.CATALOG.CONCEPT.
-- Review CONCEPT rows before applying bulk UPDATEs; FK add at end may fail if orphan domains exist.

begin;

-- 1) Replace DOMAIN dimension (matches seeds/reference/catalog/domain.csv)
truncate table reference.catalog.domain;

insert into reference.catalog.domain (
  domain_code,
  domain,
  description,
  description_ai,
  description_long
)
values
  ('capital', 'Capital', 'Capital markets and financial structure',
   'Rates, cap rates, NOI, DSCR, LTV, delinquency, arbitrage, ownership structure',
   'Capital market signals governing cost of money, asset pricing, leverage, credit quality, and structural ownership. Drives acquisition underwriting, exit timing, and capital stack decisions.'),
  ('housing', 'Housing', 'Housing market mechanics and supply/demand balance',
   'Rent, home price, AVM, absorption, vacancy, permits, supply pipeline, transactions',
   'The mechanics of the housing market including price formation, tightness, supply constraints, and transaction velocity. Core to rental pricing, value estimation, and market cycle positioning.'),
  ('household', 'Household', 'People, income, and demand drivers',
   'Population, migration, income, wages, household formation, demographics, affordability',
   'Demand-side fundamentals: who lives where, what they earn, how households form, and where the affordability ceiling sits. Structural driver of long-term rental demand.'),
  ('place', 'Place', 'Location quality, economy, and risk context',
   'Employment, labor, schools, crime, climate hazard, commute, automation risk',
   'The economic and environmental context of a location. Determines tenant demand quality, retention, and long-run neighborhood trajectory.'),
  ('portfolio', 'Portfolio', 'Owned asset performance and operations',
   'Yield, cashflow, valuation marks, turns, capex, credit loss, occupancy operations',
   'Internal performance layer covering financial outcomes and operational execution for owned assets. Feeds hold/sell/fix decisions and IC reporting.');

-- 2) Legacy macro / demand / supply remaps (adjust lists to match your warehouse before running)
update reference.catalog.concept
set domain = 'capital'
where domain in ('macro')
  and concept_code in ('cap_rate', 'noi', 'dscr', 'ltv', 'delinquency', 'rates', 'inflation');

update reference.catalog.concept
set domain = 'housing'
where domain in ('supply', 'demand')
  and concept_code in (
    'rent', 'homeprice', 'vacancy', 'occupancy', 'absorption', 'supply_pipeline',
    'permits', 'transactions', 'concession', 'multifamily_market', 'listings', 'housing_stock'
  );

update reference.catalog.concept
set domain = 'household'
where domain in ('demand', 'macro')
  and concept_code in ('population', 'migration', 'income', 'wages', 'education');

update reference.catalog.concept
set domain = 'place'
where concept_code in ('employment', 'unemployment', 'labor', 'school_quality', 'crime', 'automation', 'pipeline');

-- 3) Explicit portfolio + place splits aligned to pretiumdata-dbt-semantic-layer seeds
update reference.catalog.concept set domain = 'portfolio' where concept_code = 'disposition';
update reference.catalog.concept set domain = 'place' where concept_code = 'pipeline';

-- 4) Optional FK (skip if constraint already exists or if Snowflake role lacks rights)
-- alter table reference.catalog.concept
--   add constraint fk_concept_domain
--   foreign key (domain) references reference.catalog.domain (domain_code);

commit;
