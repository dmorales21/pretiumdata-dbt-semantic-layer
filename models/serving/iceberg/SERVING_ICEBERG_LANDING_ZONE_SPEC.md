# Snowflake Iceberg landing zone — column specification

**Auto-generated:** `2026-04-22 18:44:13Z`  
**Connection (`snowsql -c`):** `pretium`  
**Target:** `SERVING.ICEBERG` (from `INFORMATION_SCHEMA` / `SHOW TABLES`)  

**dbt contract (model stubs):** `/Users/aposes/dev/pretium/pretiumdata-dbt-semantic-layer/pretiumdata-dbt-semantic-layer/models/serving/iceberg`  

**Table allowlist (9):** `ACS5_CBSA, ACS5_COUNTY, CHERRE_TAX_ASSESSOR_V2, CHERRE_USA_AVM_V2_PROPERTY, CONCEPT_RENT_MARKET_MONTHLY, MART_OPCO_PROPERTY_PRESENCE, PROGRESS_PROPERTIES, PROGRESS_VALUATIONS, PROGRESS_WORK_ORDERS`  

> Regenerate: `./scripts/serving/run_generate_serving_iceberg_landing_zone_spec.sh`

## Table inventory

| Table | Type | Row count | Bytes | Iceberg | Table comment |
|---|:---|---:|---:|---|:---|:---|
| ACS5_CBSA | TABLE | 3186706 | 12773888 | Y |  |
| ACS5_COUNTY | TABLE | 5130934 | 23487488 | Y |  |
| CHERRE_TAX_ASSESSOR_V2 | TABLE | 162290365 | 32802391040 | Y |  |
| CHERRE_USA_AVM_V2_PROPERTY | TABLE | 6694884663 | 220112519168 | Y |  |
| CONCEPT_RENT_MARKET_MONTHLY | TABLE | 610623 | 14354432 | Y |  |
| MART_OPCO_PROPERTY_PRESENCE | TABLE | 234993 | 9496576 | Y |  |
| PROGRESS_PROPERTIES | TABLE | 89307 | 42947072 | Y |  |
| PROGRESS_VALUATIONS | TABLE | 5174582 | 72610816 | Y |  |
| PROGRESS_WORK_ORDERS | TABLE | 3033520 | 236911104 | Y |  |

## Column type mix (per table)

| Table | # columns | By data type |
|---|---:|---|
| ACS5_CBSA | 16 | TEXT: 9, NUMBER: 7 |
| ACS5_COUNTY | 16 | TEXT: 9, NUMBER: 7 |
| CHERRE_TAX_ASSESSOR_V2 | 209 | TEXT: 82, NUMBER: 66, BOOLEAN: 52, DATE: 8, TIMESTAMP_NTZ: 1 |
| CHERRE_USA_AVM_V2_PROPERTY | 9 | NUMBER: 6, DATE: 1, TEXT: 1, TIMESTAMP_NTZ: 1 |
| CONCEPT_RENT_MARKET_MONTHLY | 17 | TEXT: 10, FLOAT: 3, DATE: 2, BOOLEAN: 1, TIMESTAMP_NTZ: 1 |
| MART_OPCO_PROPERTY_PRESENCE | 30 | TEXT: 18, NUMBER: 8, BOOLEAN: 1, DATE: 1, FLOAT: 1, TIMESTAMP_NTZ: 1 |
| PROGRESS_PROPERTIES | 213 | TEXT: 136, FLOAT: 67, NUMBER: 10 |
| PROGRESS_VALUATIONS | 5 | NUMBER: 2, TEXT: 2, FLOAT: 1 |
| PROGRESS_WORK_ORDERS | 7 | TEXT: 6, FLOAT: 1 |

## Column catalog

All columns are listed in physical order (`ordinal_position`).

### `SERVING.ICEBERG.ACS5_CBSA`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `YEAR` | NUMBER | YES |   |  |
| 2 | `LEVEL` | TEXT | YES |   |  |
| 3 | `VARIABLE_ID` | TEXT | YES |   |  |
| 4 | `GROUP_ID` | TEXT | YES |   |  |
| 5 | `STATE_ID` | NUMBER | YES |   |  |
| 6 | `PLACE_ID` | NUMBER | YES |   |  |
| 7 | `COUNTY_ID` | NUMBER | YES |   |  |
| 8 | `URBAN_AREA_ID` | NUMBER | YES |   |  |
| 9 | `TRACT_ID` | NUMBER | YES |   |  |
| 10 | `BLOCK_GROUP_ID` | NUMBER | YES |   |  |
| 11 | `ZIPCODE` | TEXT | YES |   |  |
| 12 | `VALUE` | TEXT | YES |   |  |
| 13 | `MARGIN_OF_ERROR` | TEXT | YES |   |  |
| 14 | `CONCEPT` | TEXT | YES |   |  |
| 15 | `LABEL` | TEXT | YES |   |  |
| 16 | `GEO_ID` | TEXT | YES |   |  |

### `SERVING.ICEBERG.ACS5_COUNTY`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `YEAR` | NUMBER | YES |   |  |
| 2 | `LEVEL` | TEXT | YES |   |  |
| 3 | `VARIABLE_ID` | TEXT | YES |   |  |
| 4 | `GROUP_ID` | TEXT | YES |   |  |
| 5 | `STATE_ID` | NUMBER | YES |   |  |
| 6 | `PLACE_ID` | NUMBER | YES |   |  |
| 7 | `COUNTY_ID` | NUMBER | YES |   |  |
| 8 | `URBAN_AREA_ID` | NUMBER | YES |   |  |
| 9 | `TRACT_ID` | NUMBER | YES |   |  |
| 10 | `BLOCK_GROUP_ID` | NUMBER | YES |   |  |
| 11 | `ZIPCODE` | TEXT | YES |   |  |
| 12 | `VALUE` | TEXT | YES |   |  |
| 13 | `MARGIN_OF_ERROR` | TEXT | YES |   |  |
| 14 | `CONCEPT` | TEXT | YES |   |  |
| 15 | `LABEL` | TEXT | YES |   |  |
| 16 | `GEO_ID` | TEXT | YES |   |  |

### `SERVING.ICEBERG.CHERRE_TAX_ASSESSOR_V2`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `ACCOUNT_NUMBER` | TEXT | YES |   |  |
| 2 | `ADDRESS` | TEXT | YES |   |  |
| 3 | `ALTERNATE_ASSESSOR_PARCEL_NUMBER` | TEXT | YES |   |  |
| 4 | `ASSESSED_IMPROVEMENTS_PERCENT` | NUMBER | YES |   |  |
| 5 | `ASSESSED_TAX_YEAR` | NUMBER | YES |   |  |
| 6 | `ASSESSED_VALUE_IMPROVEMENTS` | NUMBER | YES |   |  |
| 7 | `ASSESSED_VALUE_LAND` | NUMBER | YES |   |  |
| 8 | `ASSESSED_VALUE_TOTAL` | NUMBER | YES |   |  |
| 9 | `ASSESSOR_PARCEL_NUMBER_RAW` | TEXT | YES |   |  |
| 10 | `ATTIC_SQ_FT` | NUMBER | YES |   |  |
| 11 | `BASEMENT_FINISHED_SQ_FT` | NUMBER | YES |   |  |
| 12 | `BASEMENT_SQ_FT` | NUMBER | YES |   |  |
| 13 | `BASEMENT_UNFINISHED_SQ_FT` | NUMBER | YES |   |  |
| 14 | `BATH_COUNT` | NUMBER | YES |   |  |
| 15 | `BED_COUNT` | NUMBER | YES |   |  |
| 16 | `BUILDING_SQ_FT` | NUMBER | YES |   |  |
| 17 | `BUILDING_SQ_FT_CODE` | TEXT | YES |   |  |
| 18 | `BUILDINGS_COUNT` | NUMBER | YES |   |  |
| 19 | `CBSA_CODE` | TEXT | YES |   |  |
| 20 | `CBSA_NAME` | TEXT | YES |   |  |
| 21 | `CENSUS_BLOCK` | NUMBER | YES |   |  |
| 22 | `CENSUS_BLOCK_GROUP` | NUMBER | YES |   |  |
| 23 | `CENSUS_TRACT` | NUMBER | YES |   |  |
| 24 | `CHERRE_ASSESSOR_PARCEL_NUMBER_FORMATTED` | TEXT | YES |   |  |
| 25 | `CHERRE_DELETED_AT` | DATE | YES |   |  |
| 26 | `CHERRE_IS_DELETED` | BOOLEAN | YES |   |  |
| 27 | `CHERRE_PARCEL_ID` | TEXT | YES |   |  |
| 28 | `CITY` | TEXT | YES |   |  |
| 29 | `CONSTRUCTION_CODE` | NUMBER | YES |   |  |
| 30 | `CRRT` | TEXT | YES |   |  |
| 31 | `DATA_PUBLISH_DATE` | DATE | YES |   |  |
| 32 | `DEED_LAST_SALE_DOCUMENT_BOOK` | TEXT | YES |   |  |
| 33 | `DEED_LAST_SALE_DOCUMENT_NUMBER` | TEXT | YES |   |  |
| 34 | `DEED_LAST_SALE_DOCUMENT_PAGE` | TEXT | YES |   |  |
| 35 | `DESCRIPTION` | TEXT | YES |   |  |
| 36 | `DRIVEWAY_MATERIAL_CODE` | NUMBER | YES |   |  |
| 37 | `EFFECTIVE_YEAR_BUILT` | NUMBER | YES |   |  |
| 38 | `EXTERIOR_CODE` | NUMBER | YES |   |  |
| 39 | `FIPS_CODE` | TEXT | YES |   |  |
| 40 | `FIREPLACE_COUNT` | NUMBER | YES |   |  |
| 41 | `FISCAL_YEAR` | NUMBER | YES |   |  |
| 42 | `FL_COMMUNITY_NAME` | TEXT | YES |   |  |
| 43 | `FL_COMMUNITY_NBR` | TEXT | YES |   |  |
| 44 | `FL_FEMA_FLOOD_ZONE` | TEXT | YES |   |  |
| 45 | `FL_FEMA_MAP_DATE` | DATE | YES |   |  |
| 46 | `FL_FEMA_MAP_NBR` | TEXT | YES |   |  |
| 47 | `FL_FIRM_ID` | TEXT | YES |   |  |
| 48 | `FL_INSIDE_SFHA` | TEXT | YES |   |  |
| 49 | `FL_PANEL_NBR` | TEXT | YES |   |  |
| 50 | `FLOOR_1_SQ_FT` | NUMBER | YES |   |  |
| 51 | `FLOORING_MATERIAL_CODE` | NUMBER | YES |   |  |
| 52 | `FOUNDATION_CODE` | TEXT | YES |   |  |
| 53 | `GEOCODE_QUALITY_CODE` | TEXT | YES |   |  |
| 54 | `GROSS_SQ_FT` | NUMBER | YES |   |  |
| 55 | `HAS_ALARM_SYSTEM` | BOOLEAN | YES |   |  |
| 56 | `HAS_ARBOR_PERGOLA` | BOOLEAN | YES |   |  |
| 57 | `HAS_ATTIC` | BOOLEAN | YES |   |  |
| 58 | `HAS_BOAT_ACCESS` | BOOLEAN | YES |   |  |
| 59 | `HAS_BOAT_LIFT` | BOOLEAN | YES |   |  |
| 60 | `HAS_BONUS_ROOM` | BOOLEAN | YES |   |  |
| 61 | `HAS_BREAKFAST_NOOK` | BOOLEAN | YES |   |  |
| 62 | `HAS_CELLAR` | BOOLEAN | YES |   |  |
| 63 | `HAS_CENTRAL_VACUUM_SYSTEM` | BOOLEAN | YES |   |  |
| 64 | `HAS_DECK` | BOOLEAN | YES |   |  |
| 65 | `HAS_ELEVATOR` | BOOLEAN | YES |   |  |
| 66 | `HAS_EXERCISE_ROOM` | BOOLEAN | YES |   |  |
| 67 | `HAS_FAMILY_ROOM` | BOOLEAN | YES |   |  |
| 68 | `HAS_FIRE_SPRINKERS` | BOOLEAN | YES |   |  |
| 69 | `HAS_GAME_ROOM` | BOOLEAN | YES |   |  |
| 70 | `HAS_GOLF_COURSE_GREEN` | BOOLEAN | YES |   |  |
| 71 | `HAS_GREAT_ROOM` | BOOLEAN | YES |   |  |
| 72 | `HAS_HOBBY_ROOM` | BOOLEAN | YES |   |  |
| 73 | `HAS_HOME_OFFICE` | BOOLEAN | YES |   |  |
| 74 | `HAS_INSTALLED_SOUND_SYSTEM` | BOOLEAN | YES |   |  |
| 75 | `HAS_INTERCOM` | BOOLEAN | YES |   |  |
| 76 | `HAS_LAUNDRY_ROOM` | BOOLEAN | YES |   |  |
| 77 | `HAS_MEDIA_ROOM` | BOOLEAN | YES |   |  |
| 78 | `HAS_MOBILE_HOME_HOOKUP` | BOOLEAN | YES |   |  |
| 79 | `HAS_MUD_ROOM` | BOOLEAN | YES |   |  |
| 80 | `HAS_OTHER_SPORT_COURT` | BOOLEAN | YES |   |  |
| 81 | `HAS_OUTDOOR_KITCHEN_FIREPLACE` | BOOLEAN | YES |   |  |
| 82 | `HAS_OVERHEAD_DOOR` | BOOLEAN | YES |   |  |
| 83 | `HAS_PARKING_CARPORT` | BOOLEAN | YES |   |  |
| 84 | `HAS_RV_PARKING` | BOOLEAN | YES |   |  |
| 85 | `HAS_SAFE_ROOM` | BOOLEAN | YES |   |  |
| 86 | `HAS_SAUNA` | BOOLEAN | YES |   |  |
| 87 | `HAS_SITTING_ROOM` | BOOLEAN | YES |   |  |
| 88 | `HAS_SPRINKLERS` | BOOLEAN | YES |   |  |
| 89 | `HAS_STORM_SHELTER` | BOOLEAN | YES |   |  |
| 90 | `HAS_STORM_SHUTTER` | BOOLEAN | YES |   |  |
| 91 | `HAS_STUDY` | BOOLEAN | YES |   |  |
| 92 | `HAS_SUNROOM` | BOOLEAN | YES |   |  |
| 93 | `HAS_TENNIS_COURT` | BOOLEAN | YES |   |  |
| 94 | `HAS_UTILITY_ROOM` | BOOLEAN | YES |   |  |
| 95 | `HAS_WATER_FEATURE` | BOOLEAN | YES |   |  |
| 96 | `HAS_WET_BAR` | BOOLEAN | YES |   |  |
| 97 | `HAS_WINE_CELLAR` | BOOLEAN | YES |   |  |
| 98 | `HOA_1_FEE_FREQUENCY` | TEXT | YES |   |  |
| 99 | `HOA_1_FEE_VALUE` | NUMBER | YES |   |  |
| 100 | `HOA_1_NAME` | TEXT | YES |   |  |
| 101 | `HOA_1_TYPE` | TEXT | YES |   |  |
| 102 | `HOA_2_FEE_FREQUENCY` | TEXT | YES |   |  |
| 103 | `HOA_2_FEE_VALUE` | NUMBER | YES |   |  |
| 104 | `HOA_2_NAME` | TEXT | YES |   |  |
| 105 | `HOA_2_TYPE` | TEXT | YES |   |  |
| 106 | `HOUSE_NUMBER` | TEXT | YES |   |  |
| 107 | `HVACC_COOLING_CODE` | NUMBER | YES |   |  |
| 108 | `HVACC_HEATING_CODE` | NUMBER | YES |   |  |
| 109 | `HVACC_HEATING_FUEL_CODE` | NUMBER | YES |   |  |
| 110 | `INTERIOR_STRUCTURE_CODE` | NUMBER | YES |   |  |
| 111 | `IS_ADDITIONAL_EXEMPTION` | BOOLEAN | YES |   |  |
| 112 | `IS_DISABLED_EXEMPTION` | BOOLEAN | YES |   |  |
| 113 | `IS_HANDICAP_ACCESSIBLE` | BOOLEAN | YES |   |  |
| 114 | `IS_HOMEOWNER_EXEMPTION` | BOOLEAN | YES |   |  |
| 115 | `IS_OWNER_OCCUPIED` | BOOLEAN | YES |   |  |
| 116 | `IS_SENIOR_EXEMPTION` | BOOLEAN | YES |   |  |
| 117 | `IS_VETERAN_EXEMPTION` | BOOLEAN | YES |   |  |
| 118 | `IS_WIDOW_EXEMPTION` | BOOLEAN | YES |   |  |
| 119 | `JURISDICTION` | TEXT | YES |   |  |
| 120 | `LAST_SALE_AMOUNT` | NUMBER | YES |   |  |
| 121 | `LAST_SALE_DATE` | DATE | YES |   |  |
| 122 | `LAST_SALE_DOCUMENT_TYPE` | TEXT | YES |   |  |
| 123 | `LAST_UPDATE_DATE` | DATE | YES |   |  |
| 124 | `LATITUDE` | NUMBER | YES |   |  |
| 125 | `LEGAL_UNIT_NUMBER` | TEXT | YES |   |  |
| 126 | `LONGITUDE` | NUMBER | YES |   |  |
| 127 | `LOT_DEPTH_FT` | NUMBER | YES |   |  |
| 128 | `LOT_SIZE_ACRE` | NUMBER | YES |   |  |
| 129 | `LOT_SIZE_SQ_FT` | NUMBER | YES |   |  |
| 130 | `LOT_WIDTH` | NUMBER | YES |   |  |
| 131 | `MAILING_ADDRESS` | TEXT | YES |   |  |
| 132 | `MAILING_CITY` | TEXT | YES |   |  |
| 133 | `MAILING_COUNTY` | TEXT | YES |   |  |
| 134 | `MAILING_CRRT` | TEXT | YES |   |  |
| 135 | `MAILING_FIPS_CODE` | TEXT | YES |   |  |
| 136 | `MAILING_HOUSE_NUMBER` | TEXT | YES |   |  |
| 137 | `MAILING_STATE` | TEXT | YES |   |  |
| 138 | `MAILING_STREET_DIRECTION` | TEXT | YES |   |  |
| 139 | `MAILING_STREET_NAME` | TEXT | YES |   |  |
| 140 | `MAILING_STREET_POST_DIRECTION` | TEXT | YES |   |  |
| 141 | `MAILING_STREET_SUFFIX` | TEXT | YES |   |  |
| 142 | `MAILING_UNIT_NUMBER` | TEXT | YES |   |  |
| 143 | `MAILING_UNIT_PREFIX` | TEXT | YES |   |  |
| 144 | `MAILING_ZIP` | TEXT | YES |   |  |
| 145 | `MAILING_ZIP_4` | TEXT | YES |   |  |
| 146 | `MARKET_IMPROVEMENTS_PERCENT` | NUMBER | YES |   |  |
| 147 | `MARKET_VALUE_IMPROVEMENTS` | NUMBER | YES |   |  |
| 148 | `MARKET_VALUE_TOTAL` | NUMBER | YES |   |  |
| 149 | `MARKET_VALUE_YEAR` | NUMBER | YES |   |  |
| 150 | `METRO_DIVISION` | TEXT | YES |   |  |
| 151 | `MSA_CODE` | TEXT | YES |   |  |
| 152 | `MSA_NAME` | TEXT | YES |   |  |
| 153 | `NEIGHBORHOOD_CODE` | TEXT | YES |   |  |
| 154 | `PARKING_GARAGE_CODE` | NUMBER | YES |   |  |
| 155 | `PARKING_SPACE_COUNT` | NUMBER | YES |   |  |
| 156 | `PARKING_SQ_FT` | NUMBER | YES |   |  |
| 157 | `PARTIAL_BATH_COUNT` | NUMBER | YES |   |  |
| 158 | `PFC_DOCUMENT_TYPE` | TEXT | YES |   |  |
| 159 | `PFC_FLAG` | TEXT | YES |   |  |
| 160 | `PFC_INDICATOR` | NUMBER | YES |   |  |
| 161 | `PFC_RECORDING_DATE` | DATE | YES |   |  |
| 162 | `PFC_RELEASE_REASON` | TEXT | YES |   |  |
| 163 | `PFC_TRANSACTION_ID` | NUMBER | YES |   |  |
| 164 | `PHASE` | TEXT | YES |   |  |
| 165 | `PLUMBING_FEATURE_COUNT` | NUMBER | YES |   |  |
| 166 | `POOL_CODE` | NUMBER | YES |   |  |
| 167 | `PORCH_CODE` | NUMBER | YES |   |  |
| 168 | `PRIOR_SALE_AMOUNT` | NUMBER | YES |   |  |
| 169 | `PRIOR_SALE_DATE` | DATE | YES |   |  |
| 170 | `PROPERTY_GROUP_TYPE` | TEXT | YES |   |  |
| 171 | `PROPERTY_USE_CODE_MAPPED` | NUMBER | YES |   |  |
| 172 | `PROPERTY_USE_STANDARDIZED_CODE` | TEXT | YES |   |  |
| 173 | `QUARTER` | TEXT | YES |   |  |
| 174 | `QUARTER_QUARTER` | TEXT | YES |   |  |
| 175 | `RANGE` | TEXT | YES |   |  |
| 176 | `ROOF_CONSTRUCTION_CODE` | NUMBER | YES |   |  |
| 177 | `ROOF_MATERIAL_CODE` | NUMBER | YES |   |  |
| 178 | `ROOM_COUNT` | NUMBER | YES |   |  |
| 179 | `SECTION` | TEXT | YES |   |  |
| 180 | `SEWER_USAGE_CODE` | NUMBER | YES |   |  |
| 181 | `SITUS_COUNTY` | TEXT | YES |   |  |
| 182 | `SITUS_STATE` | TEXT | YES |   |  |
| 183 | `STATE` | TEXT | YES |   |  |
| 184 | `STORIES_COUNT` | NUMBER | YES |   |  |
| 185 | `STREET_DIRECTION` | TEXT | YES |   |  |
| 186 | `STREET_NAME` | TEXT | YES |   |  |
| 187 | `STREET_POST_DIRECTION` | TEXT | YES |   |  |
| 188 | `STREET_SUFFIX` | TEXT | YES |   |  |
| 189 | `STRUCTURE_STYLE_CODE` | NUMBER | YES |   |  |
| 190 | `SUBDIVISION` | TEXT | YES |   |  |
| 191 | `TAX_ASSESSOR_ID` | NUMBER | YES |   |  |
| 192 | `TAX_BILL_AMOUNT` | NUMBER | YES |   |  |
| 193 | `TAX_DELINQUENT_YEAR` | NUMBER | YES |   |  |
| 194 | `THE_VALUE_LAND` | NUMBER | YES |   |  |
| 195 | `TOPOGRAPHY_CODE` | TEXT | YES |   |  |
| 196 | `TOWNSHIP` | TEXT | YES |   |  |
| 197 | `TRACT` | TEXT | YES |   |  |
| 198 | `UNIT_NUMBER` | TEXT | YES |   |  |
| 199 | `UNIT_PREFIX` | TEXT | YES |   |  |
| 200 | `UNITS_COUNT` | NUMBER | YES |   |  |
| 201 | `VACANT_FLAG` | TEXT | YES |   |  |
| 202 | `VACANT_FLAG_DATE` | DATE | YES |   |  |
| 203 | `VIEW_CODE` | TEXT | YES |   |  |
| 204 | `WATER_SOURCE_CODE` | NUMBER | YES |   |  |
| 205 | `YEAR_BUILT` | NUMBER | YES |   |  |
| 206 | `ZIP` | TEXT | YES |   |  |
| 207 | `ZIP_4` | TEXT | YES |   |  |
| 208 | `ZONE_CODE` | TEXT | YES |   |  |
| 209 | `CHERRE_INGEST_DATETIME` | TIMESTAMP_NTZ | YES |   |  |

### `SERVING.ICEBERG.CHERRE_USA_AVM_V2_PROPERTY`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `CHERRE_INGEST_DATETIME` | TIMESTAMP_NTZ | YES |   |  |
| 2 | `CHERRE_USA_AVM_PK` | TEXT | YES |   |  |
| 3 | `CONFIDENCE_SCORE` | NUMBER | YES |   |  |
| 4 | `ESTIMATED_MAX_VALUE_AMOUNT` | NUMBER | YES |   |  |
| 5 | `ESTIMATED_MIN_VALUE_AMOUNT` | NUMBER | YES |   |  |
| 6 | `ESTIMATED_VALUE_AMOUNT` | NUMBER | YES |   |  |
| 7 | `STANDARD_DEVIATION` | NUMBER | YES |   |  |
| 8 | `TAX_ASSESSOR_ID` | NUMBER | YES |   |  |
| 9 | `VALUATION_DATE` | DATE | YES |   |  |

### `SERVING.ICEBERG.CONCEPT_RENT_MARKET_MONTHLY`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `CONCEPT_CODE` | TEXT | YES |   |  |
| 2 | `VENDOR_CODE` | TEXT | YES |   |  |
| 3 | `MONTH_START` | DATE | YES |   |  |
| 4 | `GEO_LEVEL_CODE` | TEXT | YES |   |  |
| 5 | `GEO_ID` | TEXT | YES |   |  |
| 6 | `CBSA_ID` | TEXT | YES |   |  |
| 7 | `COUNTY_FIPS` | TEXT | YES |   |  |
| 8 | `STATE_FIPS` | TEXT | YES |   |  |
| 9 | `HAS_CENSUS_GEO` | BOOLEAN | YES |   |  |
| 10 | `CENSUS_GEO_SOURCE` | TEXT | YES |   |  |
| 11 | `METRIC_ID_OBSERVE` | TEXT | YES |   |  |
| 12 | `RENT_CURRENT` | FLOAT | YES |   |  |
| 13 | `RENT_HISTORICAL` | FLOAT | YES |   |  |
| 14 | `RENT_FORECAST` | FLOAT | YES |   |  |
| 15 | `METRIC_ID_FORECAST` | TEXT | YES |   |  |
| 16 | `FORECAST_MONTH_START` | DATE | YES |   |  |
| 17 | `DBT_UPDATED_AT` | TIMESTAMP_NTZ | YES |   |  |

### `SERVING.ICEBERG.MART_OPCO_PROPERTY_PRESENCE`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `PROPERTY_ID` | TEXT | YES |   |  |
| 2 | `OPCO_ID` | TEXT | YES |   |  |
| 3 | `SOURCE_TABLE` | TEXT | YES |   |  |
| 4 | `SOURCE_PROPERTY_ID` | TEXT | YES |   |  |
| 5 | `ZIP_CODE` | TEXT | YES |   |  |
| 6 | `CITY` | TEXT | YES |   |  |
| 7 | `CBSA_CODE` | TEXT | YES |   |  |
| 8 | `CBSA_TITLE` | TEXT | YES |   |  |
| 9 | `COUNTY_FIPS` | TEXT | YES |   |  |
| 10 | `COUNTY_NAME` | TEXT | YES |   |  |
| 11 | `STATE` | TEXT | YES |   |  |
| 12 | `STATE_NAME` | TEXT | YES |   |  |
| 13 | `PROPERTY_TYPE` | TEXT | YES |   |  |
| 14 | `BEDROOMS` | NUMBER | YES |   |  |
| 15 | `BATHROOMS` | FLOAT | YES |   |  |
| 16 | `SQUARE_FEET` | NUMBER | YES |   |  |
| 17 | `YEAR_BUILT` | NUMBER | YES |   |  |
| 18 | `LOT_SIZE_SQFT` | NUMBER | YES |   |  |
| 19 | `PURCHASE_PRICE` | NUMBER | YES |   |  |
| 20 | `CURRENT_VALUE` | NUMBER | YES |   |  |
| 21 | `RENT_AMOUNT` | NUMBER | YES |   |  |
| 22 | `LOAN_AMOUNT` | NUMBER | YES |   |  |
| 23 | `IS_ACTIVE` | BOOLEAN | YES |   |  |
| 24 | `STATUS` | TEXT | YES |   |  |
| 25 | `LOAD_TIMESTAMP` | TIMESTAMP_NTZ | YES |   |  |
| 26 | `DATA_AS_OF_DATE` | DATE | YES |   |  |
| 27 | `GEOGRAPHY_POINT_WKT` | TEXT | YES |   |  |
| 28 | `OFFERING_ID` | TEXT | YES |   |  |
| 29 | `FUND_ID` | TEXT | YES |   |  |
| 30 | `FUND_NAME` | TEXT | YES |   |  |

### `SERVING.ICEBERG.PROGRESS_PROPERTIES`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `TRIBECA_ID` | NUMBER | YES |   |  |
| 2 | `UNIT_ID` | NUMBER | YES |   |  |
| 3 | `ADDRESS` | TEXT | YES |   |  |
| 4 | `CITY` | TEXT | YES |   |  |
| 5 | `COUNTY` | TEXT | YES |   |  |
| 6 | `ZIPCODE` | NUMBER | YES |   |  |
| 7 | `STATE` | TEXT | YES |   |  |
| 8 | `SUBMARKET` | TEXT | YES |   |  |
| 9 | `SUBDIVISION` | TEXT | YES |   |  |
| 10 | `MARKET` | TEXT | YES |   |  |
| 11 | `MARKET_BUCKET` | TEXT | YES |   |  |
| 12 | `AXIO_SUBMARKET` | TEXT | YES |   |  |
| 13 | `MSA` | TEXT | YES |   |  |
| 14 | `FUND` | TEXT | YES |   |  |
| 15 | `OWNER_ENTITY` | TEXT | YES |   |  |
| 16 | `PROPERTY_MANAGER` | TEXT | YES |   |  |
| 17 | `PROPERTY_TYPE` | TEXT | YES |   |  |
| 18 | `PURCHASE_PRICE` | FLOAT | YES |   |  |
| 19 | `PROGRESS_PURCHASE_DATE` | TEXT | YES |   |  |
| 20 | `PURCHASE_DATE` | TEXT | YES |   |  |
| 21 | `MANAGEMENT_DATE` | TEXT | YES |   |  |
| 22 | `MANAGEMENT_END_DATE` | TEXT | YES |   |  |
| 23 | `ACQUISITION_VINTAGE` | TEXT | YES |   |  |
| 24 | `BATHS` | FLOAT | YES |   |  |
| 25 | `BEDS` | FLOAT | YES |   |  |
| 26 | `STORIES` | FLOAT | YES |   |  |
| 27 | `SQFT` | FLOAT | YES |   |  |
| 28 | `LAND_SQFT` | FLOAT | YES |   |  |
| 29 | `YEAR_BUILT` | FLOAT | YES |   |  |
| 30 | `LATITUDE` | FLOAT | YES |   |  |
| 31 | `LONGITUDE` | FLOAT | YES |   |  |
| 32 | `OWNED_FLAG` | TEXT | YES |   |  |
| 33 | `ORIGINAL_MARKETING_RENT` | FLOAT | YES |   |  |
| 34 | `UNDERWRITTEN_RENT` | FLOAT | YES |   |  |
| 35 | `MARKED_FOR_SALE_DATE` | TEXT | YES |   |  |
| 36 | `PROPOSED_FOR_DISPOSITION` | TEXT | YES |   |  |
| 37 | `DISPOSITION_REJECTED_DATE` | TEXT | YES |   |  |
| 38 | `SOLD_DATE` | TEXT | YES |   |  |
| 39 | `SECTION_8_FLAG` | TEXT | YES |   |  |
| 40 | `UNIT_STATUS` | TEXT | YES |   |  |
| 41 | `POOL_FLAG` | TEXT | YES |   |  |
| 42 | `STABILIZATION_DATE` | TEXT | YES |   |  |
| 43 | `BOND_MSA` | TEXT | YES |   |  |
| 44 | `MIDDLE_SCHOOL` | FLOAT | YES |   |  |
| 45 | `HIGH_SCHOOL` | FLOAT | YES |   |  |
| 46 | `AVERAGE_SCHOOL` | FLOAT | YES |   |  |
| 47 | `GARAGES` | TEXT | YES |   |  |
| 48 | `REINVESTMENT` | TEXT | YES |   |  |
| 49 | `REINVESTMENT_DATE` | TEXT | YES |   |  |
| 50 | `GATE_CODE` | TEXT | YES |   |  |
| 51 | `CAP_RATE` | FLOAT | YES |   |  |
| 52 | `TAX_CITY` | TEXT | YES |   |  |
| 53 | `TAX_COUNTY` | TEXT | YES |   |  |
| 54 | `TAX_ADDRESS` | TEXT | YES |   |  |
| 55 | `CRIME_SCORE` | FLOAT | YES |   |  |
| 56 | `FLOOD_ZONE` | TEXT | YES |   |  |
| 57 | `ACTIVE_SMART_DEVICES` | NUMBER | YES |   |  |
| 58 | `SMART_HOME_FLAG` | TEXT | YES |   |  |
| 59 | `RESIDENT_IN_PLACE_FLAG` | TEXT | YES |   |  |
| 60 | `FIRST_READY_DATE` | TEXT | YES |   |  |
| 61 | `FIRST_MOVEIN_DATE` | TEXT | YES |   |  |
| 62 | `WAREHOUSE_DRAW_DATE` | TEXT | YES |   |  |
| 63 | `REO_START_DATE` | TEXT | YES |   |  |
| 64 | `COMMUNITY` | TEXT | YES |   |  |
| 65 | `FLOOR_PLAN` | TEXT | YES |   |  |
| 66 | `MSA_MANAGEMENT` | TEXT | YES |   |  |
| 67 | `PR3_OWNER` | TEXT | YES |   |  |
| 68 | `NEW_CONSTRUCTION` | TEXT | YES |   |  |
| 69 | `CENSUS_BLOCK` | FLOAT | YES |   |  |
| 70 | `CENSUS_BLOCK_GROUP` | NUMBER | YES |   |  |
| 71 | `CENSUS_TRACT` | NUMBER | YES |   |  |
| 72 | `ACTUAL_CBSA` | TEXT | YES |   |  |
| 73 | `COUNTY_FIPS_CODE` | TEXT | YES |   |  |
| 74 | `REPORTING_MSA` | TEXT | YES |   |  |
| 75 | `SID` | TEXT | YES |   |  |
| 76 | `SID2` | TEXT | YES |   |  |
| 77 | `TRIBECA_CLUSTER` | FLOAT | YES |   |  |
| 78 | `CLUSTER_NODE_ID` | FLOAT | YES |   |  |
| 79 | `CLUSTER_ID` | FLOAT | YES |   |  |
| 80 | `CLUSTERNAME` | TEXT | YES |   |  |
| 81 | `ACTUAL_CONSTRUCTION_DELIVERY_DATE` | FLOAT | YES |   |  |
| 82 | `RECENT_READY_DATE` | TEXT | YES |   |  |
| 83 | `ACQ_FEE_FLAG` | TEXT | YES |   |  |
| 84 | `DAYS_VACANT` | FLOAT | YES |   |  |
| 85 | `PROPERTY_SUB_TYPE` | TEXT | YES |   |  |
| 86 | `HOLDOVER_TENANT` | NUMBER | YES |   |  |
| 87 | `IN_HOA` | TEXT | YES |   |  |
| 88 | `INITIAL_REHAB_START_DATE` | TEXT | YES |   |  |
| 89 | `INITIAL_REHAB_END_DATE` | TEXT | YES |   |  |
| 90 | `PORTFOLIO_NAME` | TEXT | YES |   |  |
| 91 | `PROPERTY_MANAGEMENT_DATE` | TEXT | YES |   |  |
| 92 | `STAGE` | TEXT | YES |   |  |
| 93 | `REMODEL_COSTS` | FLOAT | YES |   |  |
| 94 | `MISC_COSTS` | FLOAT | YES |   |  |
| 95 | `ACQUISITION_COSTS` | FLOAT | YES |   |  |
| 96 | `INSPECTION_TERMITE_SEPTIC_COSTS` | FLOAT | YES |   |  |
| 97 | `DOWN_RESPONSIBLE` | TEXT | YES |   |  |
| 98 | `REPORTING_ENTITY` | TEXT | YES |   |  |
| 99 | `UNDER_MANAGEMENT` | TEXT | YES |   |  |
| 100 | `TYPE_OF_SALE` | TEXT | YES |   |  |
| 101 | `FIRST_SYNDICATED_DATE` | TEXT | YES |   |  |
| 102 | `EXTERNAL_PROPERTY_ID` | FLOAT | YES |   |  |
| 103 | `ESTIMATED_CONSTRUCTION_DELIVERY_DATE` | FLOAT | YES |   |  |
| 104 | `ESCROW_CLOSING_COSTS` | FLOAT | YES |   |  |
| 105 | `RESPONSIBLE_PARTY` | TEXT | YES |   |  |
| 106 | `RESPONSIBLE_PARTY_2` | TEXT | YES |   |  |
| 107 | `RESPONSIBLE_PARTY_3` | TEXT | YES |   |  |
| 108 | `PROP_YARDI_ID` | NUMBER | YES |   |  |
| 109 | `PROP_SFDC_ID` | TEXT | YES |   |  |
| 110 | `CLOSE_MONTH` | TEXT | YES |   |  |
| 111 | `SOLAR_HOME_FLAG` | TEXT | YES |   |  |
| 112 | `PROPERTY_STATUS` | TEXT | YES |   |  |
| 113 | `DISPOSITION_NOTES` | TEXT | YES |   |  |
| 114 | `DISTRICT` | TEXT | YES |   |  |
| 115 | `OPERATION_MARKET` | TEXT | YES |   |  |
| 116 | `AFFORDABLE_FLAG` | TEXT | YES |   |  |
| 117 | `SECURITIZATION_TARGET` | TEXT | YES |   |  |
| 118 | `PROJECTED_MAKE_READY_DATE` | TEXT | YES |   |  |
| 119 | `FINISH_QUALITY_NOTES` | TEXT | YES |   |  |
| 120 | `AFFORDABLE_UW_RENT` | FLOAT | YES |   |  |
| 121 | `EXECUTIVE_REGION` | TEXT | YES |   |  |
| 122 | `MAINTENANCE_SERVICE_REGION` | TEXT | YES |   |  |
| 123 | `CENSUS_PLACE_NAME` | TEXT | YES |   |  |
| 124 | `CENSUS_PLACE_NAME_DESC` | TEXT | YES |   |  |
| 125 | `RECENT_SYNDICATION_START_DATE` | TEXT | YES |   |  |
| 126 | `RECENT_SYNDICATION_END_DATE` | TEXT | YES |   |  |
| 127 | `PROP_NET_YIELD` | FLOAT | YES |   |  |
| 128 | `ACQ_AFFORDABLE_FLAG` | TEXT | YES |   |  |
| 129 | `PRE_CLOSED_MARKETING` | TEXT | YES |   |  |
| 130 | `FREEDOM_FIGHTING_MISSIONARIES` | NUMBER | YES |   |  |
| 131 | `MARKET_OPS_AREA` | TEXT | YES |   |  |
| 132 | `BUDGETED_2023` | TEXT | YES |   |  |
| 133 | `BUDGETED_2024` | TEXT | YES |   |  |
| 134 | `BUDGETED_2025` | TEXT | YES |   |  |
| 135 | `BUDGETED_2026` | TEXT | YES |   |  |
| 136 | `FINANCING_FACILITY` | TEXT | YES |   |  |
| 137 | `ALLOCATED_LOAN_AMOUNT` | FLOAT | YES |   |  |
| 138 | `DETAILED_REASON_NOT_RENTED` | TEXT | YES |   |  |
| 139 | `DETAILED_REASON_NOT_RENTED_UPDATED_DATE` | TEXT | YES |   |  |
| 140 | `PHOTOS_TRANSFERRED_DATE` | TEXT | YES |   |  |
| 141 | `HERO_PHOTO_TRANSFERRED_DATE` | TEXT | YES |   |  |
| 142 | `INITIAL_LEASE_KEY` | TEXT | YES |   |  |
| 143 | `DAYS_ON_HOLD_PRIOR_FIRST_READY` | FLOAT | YES |   |  |
| 144 | `SECURITIZATION` | TEXT | YES |   |  |
| 145 | `PROPERTY_FLAG` | TEXT | YES |   |  |
| 146 | `NUMBER` | FLOAT | YES |   |  |
| 147 | `PERCENT_OF_INITIAL_LOAN_AMOUNT` | TEXT | YES |   |  |
| 148 | `SECURITIZATION_PURCHASE_PRICE` | FLOAT | YES |   |  |
| 149 | `CLOSING_COSTS` | FLOAT | YES |   |  |
| 150 | `ACQUISITION_BASIS_PRE_REHAB` | FLOAT | YES |   |  |
| 151 | `TOTAL_UPFRONT_RENOVATION_COST` | FLOAT | YES |   |  |
| 152 | `TOTAL_COST_BASIS_POST_REHAB` | FLOAT | YES |   |  |
| 153 | `TOTAL_INVESTMENT_BASIS` | FLOAT | YES |   |  |
| 154 | `ACQUISITION_MONTH_YEAR` | TEXT | YES |   |  |
| 155 | `BPO_VALUE` | FLOAT | YES |   |  |
| 156 | `BPO_VALUE_AS_OF_DATE` | TEXT | YES |   |  |
| 157 | `SECURITIZATION_CITY` | TEXT | YES |   |  |
| 158 | `SECURITIZATION_STATE` | TEXT | YES |   |  |
| 159 | `SECURITIZATION_ZIP` | FLOAT | YES |   |  |
| 160 | `CLOSEST_MSA` | TEXT | YES |   |  |
| 161 | `SECURITIZATION_SWIMMING_POOL_FLAG` | TEXT | YES |   |  |
| 162 | `ORIGINAL_UNDERWRITTEN_GROSS_POTENTIAL_RENT_MONTH` | FLOAT | YES |   |  |
| 163 | `ORIGINAL_UNDERWRITTEN_GROSS_POTENTIAL_RENT_ANNUAL` | FLOAT | YES |   |  |
| 164 | `ORIGINAL_UNDERWRITTEN_ANNUAL_OTHER_INCOME` | FLOAT | YES |   |  |
| 165 | `ORIGINAL_TOTAL_ANNUAL_UNDERWRITTEN_GROSS_INCOME` | FLOAT | YES |   |  |
| 166 | `ORIGINAL_UNDERWRITTEN_ANNUAL_VACANCY` | FLOAT | YES |   |  |
| 167 | `ORIGINAL_UNDERWRITTEN_REAL_ESTATE_TAXES` | FLOAT | YES |   |  |
| 168 | `ORIGINAL_UNDERWRITTEN_ANNUAL_PROPERTY_MANAGEMENT_FEE` | FLOAT | YES |   |  |
| 169 | `ORIGINAL_UNDERWRITTEN_ANNUAL_HOA_FEES` | FLOAT | YES |   |  |
| 170 | `ORIGINAL_ANNUAL_ACTUAL_INSURANCE` | FLOAT | YES |   |  |
| 171 | `ORIGINAL_UNDERWRITTEN_ACTUAL_REPAIRS_MAINTENANCE` | FLOAT | YES |   |  |
| 172 | `ORIGINAL_UNDERWRITTEN_ANNUAL_TURNOVER_COSTS` | FLOAT | YES |   |  |
| 173 | `ORIGINAL_UNDERWRITTEN_ANNUAL_MARKETING_LEASING_COSTS` | FLOAT | YES |   |  |
| 174 | `ORIGINAL_UNDERWRITTEN_ANNUAL_OTHER_EXPENSES` | FLOAT | YES |   |  |
| 175 | `ORIGINAL_TOTAL_UNDERWRITTEN_EXPENSES` | FLOAT | YES |   |  |
| 176 | `ORIGINAL_UNDERWRITTEN_NET_OPERATING_INCOME` | FLOAT | YES |   |  |
| 177 | `ORIGINAL_UNDERWRITTEN_CAPEX_RESERVE` | FLOAT | YES |   |  |
| 178 | `ORIGINAL_UNDERWRITTEN_NET_CASH_FLOW` | FLOAT | YES |   |  |
| 179 | `ACTIVE_SMARTBOX_FLAG` | TEXT | YES |   |  |
| 180 | `PROPERTY_ACTIVITY_STATUS` | TEXT | YES |   |  |
| 181 | `INITIAL_LEASE_CAPTURE_DATE` | TEXT | YES |   |  |
| 182 | `INITIAL_LEASE_START_DATE` | TEXT | YES |   |  |
| 183 | `INITIAL_LEASE_END_CONTRACT_DATE` | TEXT | YES |   |  |
| 184 | `DPS_LAST_RENT` | FLOAT | YES |   |  |
| 185 | `DPS_RENT_FLOOR_TEMP_USED_IN_RENT` | FLOAT | YES |   |  |
| 186 | `DPS_RENT_FLOOR_FIXED_USED_IN_RENT` | FLOAT | YES |   |  |
| 187 | `DPS_RECOMMENDED_RENT_UNCONSTRAINED` | FLOAT | YES |   |  |
| 188 | `DPS_CURRENT_RENT_FLOOR_TEMP` | FLOAT | YES |   |  |
| 189 | `DPS_CURRENT_RENT_FLOOR_FIXED` | FLOAT | YES |   |  |
| 190 | `DPS_NODE_NAME` | FLOAT | YES |   |  |
| 191 | `HOME_TIER_LEVEL_NEW` | TEXT | YES |   |  |
| 192 | `SEWER_SEPTIC_SERVICE` | TEXT | YES |   |  |
| 193 | `ADDRESS_RECENCY` | NUMBER | YES |   |  |
| 194 | `LOCAL_TIMEZONE` | TEXT | YES |   |  |
| 195 | `ACQUISITION_CHANNEL` | TEXT | YES |   |  |
| 196 | `PROPERTY_KEY` | TEXT | YES |   |  |
| 197 | `HOME_QUALITY_SCORE` | FLOAT | YES |   |  |
| 198 | `PROPERTY_MANAGER_GROUP` | TEXT | YES |   |  |
| 199 | `SAME_STORE_2020` | TEXT | YES |   |  |
| 200 | `SAME_STORE_2021` | TEXT | YES |   |  |
| 201 | `SAME_STORE_2022` | TEXT | YES |   |  |
| 202 | `SAME_STORE_2023` | TEXT | YES |   |  |
| 203 | `SAME_STORE_2024` | TEXT | YES |   |  |
| 204 | `SAME_STORE_2025` | TEXT | YES |   |  |
| 205 | `SAME_STORE_2026` | TEXT | YES |   |  |
| 206 | `PORTFOLIO_OPERATIONS_DIRECTOR` | TEXT | YES |   |  |
| 207 | `REGIONAL_OPERATIONS_DIRECTOR` | TEXT | YES |   |  |
| 208 | `DIVISIONAL_VICE_PRESIDENT` | TEXT | YES |   |  |
| 209 | `SERVICE_DIRECTOR` | TEXT | YES |   |  |
| 210 | `REGION` | TEXT | YES |   |  |
| 211 | `LATEST_DPS_PRICING_NODE` | TEXT | YES |   |  |
| 212 | `STAFF_MARKET_TYPE` | TEXT | YES |   |  |
| 213 | `BROADBAND_CONTROL_FLAG` | TEXT | YES |   |  |

### `SERVING.ICEBERG.PROGRESS_VALUATIONS`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `ASOF` | TEXT | YES |   |  |
| 2 | `TRIBECA_ID` | NUMBER | YES |   |  |
| 3 | `VALUATION` | FLOAT | YES |   |  |
| 4 | `CURRENT_BPO` | NUMBER | YES |   |  |
| 5 | `CURRENT_BPO_DATE` | TEXT | YES |   |  |

### `SERVING.ICEBERG.PROGRESS_WORK_ORDERS`

| # | Column | Logical type | Nullable | Default | Column comment |
|---:|---|---|---|---|---|
| 1 | `TRIBECA_ID` | FLOAT | YES |   |  |
| 2 | `CREATE_DATE` | TEXT | YES |   |  |
| 3 | `CATEGORY` | TEXT | YES |   |  |
| 4 | `SUB_CATEGORY` | TEXT | YES |   |  |
| 5 | `SUB_CATEGORY2` | TEXT | YES |   |  |
| 6 | `WORK_DESCRIPTION` | TEXT | YES |   |  |
| 7 | `FULL_DESCRIPTION` | TEXT | YES |   |  |

## Stub / warehouse drift

When **not** using `--full-schema`, tables are the intersection of dbt `models/serving/iceberg/*.sql` stems and relations present in Snowflake. Add or remove `*.sql` stubs to align the contract.
