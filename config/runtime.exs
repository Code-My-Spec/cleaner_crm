import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/cleaner_crm start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :cleaner_crm, CleanerCrmWeb.Endpoint, server: true
end

# === Secret loading ==========================================================
#
# Deployed containers (UAT + prod, both MIX_ENV=prod) carry only AWS
# bootstrap creds + APP_ENV; every app secret is fetched from SSM
# Parameter Store (/cleaner_crm/<APP_ENV>/*) into System env here,
# BEFORE any config below reads it. Local dev/test never set APP_ENV.
if config_env() == :prod do
  case System.get_env("APP_ENV") do
    nil -> :ok
    app_env -> CleanerCrm.Secrets.load!(app_env)
  end
end

config :cleaner_crm, CleanerCrmWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4100"))]

# CodeMySpec feedback widget / OAuth provider credentials.
# Generate the client ID/secret on the CodeMySpec project page and set them
# as env vars before deploying.
config :cleaner_crm,
  codemyspec_url: System.get_env("CODEMYSPEC_URL") || "https://codemyspec.com",
  codemyspec_client_id: System.get_env("CODEMYSPEC_CLIENT_ID"),
  codemyspec_client_secret: System.get_env("CODEMYSPEC_CLIENT_SECRET")

# Stripe credentials — see .code_my_spec/integrations/stripe.md. Only
# CleanerCrm.Billing.StripeGateway.Live (never the test adapter) reads these.
config :cleaner_crm, CleanerCrm.Billing.StripeGateway,
  secret_key: System.get_env("STRIPE_SECRET_KEY"),
  webhook_secret: System.get_env("STRIPE_WEBHOOK_SECRET")

# STRIPE_ADAPTER=test swaps in the no-network fake gateway — for UAT
# until real Stripe test keys are seeded. Anything else keeps the
# compile-time default (Live in prod, Test in dev — see config files).
if System.get_env("STRIPE_ADAPTER") == "test" do
  config :cleaner_crm, CleanerCrm.Billing.StripeGateway,
    adapter: CleanerCrm.Billing.StripeGateway.Test
end

# Stripe *publishable* key — safe to ship to the browser, unlike the
# secret/webhook config above. Only prod ever sets it (already seeded
# in SSM on UAT); dev/test leave it unconfigured (`nil`), which is how
# `CleanerCrmWeb.BookingLive.Accept` decides whether to mount real
# Stripe Elements or fall back to today's hidden test-card field.
if config_env() == :prod do
  config :cleaner_crm, :stripe_publishable_key, System.get_env("STRIPE_PUBLISHABLE_KEY")
end

# Twilio — SMS delivery per the sms-delivery ADR. Unconditional (like
# the Stripe block above), not `:prod`-only: `CleanerCrm.Notifications.
# Delivery.Twilio` must always have *some* config to read. Missing
# credentials in dev/CI aren't an error here — `Twilio.send_sms/2`
# returns `{:error, :not_configured}` and the caller falls back to
# email, it never reaches the network or raises.
twilio_host = System.get_env("PHX_HOST") || "localhost:4100"

config :cleaner_crm, CleanerCrm.Notifications.Delivery.Twilio,
  account_sid: System.get_env("TWILIO_ACCOUNT_SID"),
  auth_token: System.get_env("TWILIO_AUTH_TOKEN"),
  from_number: System.get_env("TWILIO_FROM_NUMBER"),
  status_callback_url: "https://#{twilio_host}/webhooks/twilio"

if config_env() == :prod do
  # Encrypted-token vault key — required in production.
  config :cleaner_crm, CleanerCrm.Vault,
    ciphers: [
      default:
        {Cloak.Ciphers.AES.GCM,
         tag: "AES.GCM.V1",
         key:
           Base.decode64!(
             System.get_env("CLOAK_KEY") ||
               raise("environment variable CLOAK_KEY is missing (base64 32-byte key)")
           )}
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :cleaner_crm, CleanerCrm.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :cleaner_crm, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :cleaner_crm, CleanerCrmWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://bandit.hexdocs.pm/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # Resend for real email delivery (fleet ADR). Only when the key is
  # present — a UAT/prod box without it keeps the Local adapter and
  # boots fine, emails just stay undelivered.
  if resend_api_key = System.get_env("RESEND_API_KEY") do
    config :cleaner_crm, CleanerCrm.Mailer,
      adapter: Swoosh.Adapters.Resend,
      api_key: resend_api_key

    config :cleaner_crm,
           :mailer_from,
           {System.get_env("MAILER_FROM_NAME") || "Desert First Cleaning",
            System.get_env("MAILER_FROM_EMAIL") || "no-reply@#{host}"}
  end

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :cleaner_crm, CleanerCrmWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://plug.hexdocs.pm/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :cleaner_crm, CleanerCrmWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Here is an example configuration for Mailgun:
  #
  #     config :cleaner_crm, CleanerCrm.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # Most non-SMTP adapters require an API client. Swoosh supports Req, Hackney,
  # and Finch out-of-the-box. This configuration is typically done at
  # compile-time in your config/prod.exs:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Req
  #
  # See https://swoosh.hexdocs.pm/Swoosh.html#module-installation for details.
end
