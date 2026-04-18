# Profiles Template
# Copy this into ~/.dbt/profiles.yml and fill in your Snowflake credentials
# DO NOT commit credentials to git

pretiumdata_dbt_semantic_layer:
  target: dev
  outputs:

    # -------------------------------------------------------
    # DEV — ANALYTICS.DBT_DEV (Alex's primary target)
    # Used for: FEATURE_ MODEL_ ESTIMATE_ BI_ AI_ objects
    # -------------------------------------------------------
    dev:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      authenticator: externalbrowser   # SSO — no passwords in profiles
      role: DBT_DEV_ROLE
      database: ANALYTICS
      schema: DBT_DEV
      warehouse: DBT_DEV_WH
      threads: 8
      client_session_keep_alive: false

    # -------------------------------------------------------
    # STAGING — ANALYTICS.DBT_STAGE
    # -------------------------------------------------------
    staging:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      authenticator: externalbrowser
      role: DBT_STAGING_ROLE
      database: ANALYTICS
      schema: DBT_STAGE
      warehouse: DBT_STAGING_WH
      threads: 8
      client_session_keep_alive: false

    # -------------------------------------------------------
    # PROD — ANALYTICS.DBT_PROD
    # Requires QA gate pass — do not run manually
    # -------------------------------------------------------
    prod:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      authenticator: externalbrowser
      role: DBT_PROD_ROLE
      database: ANALYTICS
      schema: DBT_PROD
      warehouse: DBT_PROD_WH
      threads: 8
      client_session_keep_alive: false

    # -------------------------------------------------------
    # SEMANTIC DEV — MART_DEV.SEMANTIC (Spencer + Alex)
    # Used for semantic mart models only
    # -------------------------------------------------------
    semantic_dev:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      authenticator: externalbrowser
      role: DBT_DEV_ROLE
      database: MART_DEV
      schema: SEMANTIC
      warehouse: DBT_DEV_WH
      threads: 8
      client_session_keep_alive: false

    # -------------------------------------------------------
    # REFERENCE — for seeding REFERENCE.CATALOG only
    # dbt seed --target reference --select reference.catalog.*
    # -------------------------------------------------------
    reference:
      type: snowflake
      account: <snowflake_account>
      user: <username>
      authenticator: externalbrowser
      role: DBT_DEV_ROLE
      database: REFERENCE
      schema: CATALOG
      warehouse: DBT_DEV_WH
      threads: 4
      client_session_keep_alive: false
