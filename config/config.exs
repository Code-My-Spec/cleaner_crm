# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :cleaner_crm, :scopes,
  user: [
    default: true,
    module: CleanerCrm.Users.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: CleanerCrm.UsersFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :cleaner_crm,
  ecto_repos: [CleanerCrm.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :cleaner_crm, CleanerCrmWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: CleanerCrmWeb.ErrorHTML, json: CleanerCrmWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: CleanerCrm.PubSub,
  live_view: [signing_salt: "v772GiZk"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :cleaner_crm, CleanerCrm.Mailer, adapter: Swoosh.Adapters.Local

# Sender identity for every outbound email (reminders, receipts, review
# requests, magic links, booking confirmations). Overridden at runtime
# in prod from MAILER_FROM_NAME / MAILER_FROM_EMAIL.
config :cleaner_crm, :mailer_from, {"Cleaner CRM", "contact@example.com"}

config :cleaner_crm, CleanerCrm.Billing.StripeGateway,
  adapter: CleanerCrm.Billing.StripeGateway.Live

# Background jobs (Oban) — queues per the background-jobs-oban ADR.
# The cron plugin drives periodic reminder scanning in every env except
# test, which runs Oban inline for deterministic specs (config/test.exs).
config :cleaner_crm, Oban,
  engine: Oban.Engines.Basic,
  repo: CleanerCrm.Repo,
  queues: [notifications: 10, scheduling: 10, billing: 10, exports: 5],
  plugins: [
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    {Oban.Plugins.Cron,
     crontab: [
       {"*/5 * * * *", CleanerCrm.Notifications.ReminderScheduler},
       {"*/15 * * * *", CleanerCrm.Reviews.ReviewRequestWorker}
     ]}
  ]

# SMS delivery — Twilio in every env except test, per the sms-delivery ADR.
config :cleaner_crm, :sms_delivery_adapter, CleanerCrm.Notifications.Delivery.Twilio

config :cleaner_crm, :integration_providers, [:codemyspec]

config :cleaner_crm, :codemyspec_url, "https://codemyspec.com"

config :cleaner_crm, :oauth_providers, %{
  codemyspec: CleanerCrm.Integrations.Providers.Codemyspec
}

# Cloak vault for encrypted OAuth token storage.
# Dev/test key only — production must override via CLOAK_KEY in runtime.exs.
config :cleaner_crm, CleanerCrm.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM,
       tag: "AES.GCM.V1", key: Base.decode64!("Uz5wK022DbLSaLm1yTLGm/0wGeiJpIxbp2rOFjgKJK8=")}
  ]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  cleaner_crm: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  cleaner_crm: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
