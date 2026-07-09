import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :cleaner_crm, CleanerCrm.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cleaner_crm_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Wallaby feature tests (test/journeys/) drive a real browser against a
# real HTTP endpoint, so the server has to actually run in test — plain
# ConnCase tests are unaffected, they never issue real HTTP requests.
config :cleaner_crm, CleanerCrmWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "pKeS+s2UVTkO2arvvgQLttUR3McIVtITSdLygq0I9T9C5M+7mGuWBFFVOWsO/ZMR",
  server: true

# Lets the endpoint inject the Ecto sandbox metadata plug (see
# lib/cleaner_crm_web/endpoint.ex) so Wallaby's real HTTP requests share
# the test process's DB sandbox connection.
config :cleaner_crm, :sql_sandbox, true

config :wallaby,
  otp_app: :cleaner_crm,
  driver: Wallaby.Chrome,
  chromedriver: [headless: true]

# In test we don't send emails
config :cleaner_crm, CleanerCrm.Mailer, adapter: Swoosh.Adapters.Test

# Never reach the real Stripe API in test — see CleanerCrm.Billing.StripeGateway.Test
config :cleaner_crm, CleanerCrm.Billing.StripeGateway,
  adapter: CleanerCrm.Billing.StripeGateway.Test

# Oban runs inline in test — jobs execute synchronously in the calling
# process instead of a background queue, per the background-jobs-oban ADR.
# `plugins: false` also disables the Cron plugin specifically: config.exs's
# crontab merges into every env (Config deep-merges same-key keyword lists
# across files), so without this override the real Cron plugin would still
# fire ReminderScheduler/ReviewRequestWorker on a wall-clock timer during a
# long test run — racing test-owned DB sandbox connections it was never
# granted, from a process with no test ancestry, undermining the whole
# point of the injectable-`now` seam these scans are built around.
config :cleaner_crm, Oban, testing: :inline, plugins: false

# Never reach the real Twilio API in test — see CleanerCrm.Notifications.Delivery.Test
config :cleaner_crm, :sms_delivery_adapter, CleanerCrm.Notifications.Delivery.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
