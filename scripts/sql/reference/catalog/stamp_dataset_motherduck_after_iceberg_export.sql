-- Stamp MotherDuck / lakehouse readiness on REFERENCE.CATALOG.DATASET after a successful
-- Iceberg (or other lake) export for the listed dataset_code values.
--
-- Wire this UPDATE into the same Snowflake Task / orchestration step that completes export
-- so Presley sees **is_motherduck_served** and **last_refresh_date** without ad hoc edits.
--
-- Adjust the IN list to match your export bundle; prefer parameterized Task variables over
-- hard-coding in production.

begin;

update reference.catalog.dataset
set
  is_motherduck_served = true,
  last_refresh_date = current_date()
where dataset_code in (
  'acs_demographics_cbsa',
  'bps_cbsa_monthly',
  'bps_county_monthly'
  -- add additional exported dataset_code values here
);

commit;
