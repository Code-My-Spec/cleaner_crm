# Swoosh.Adapters.Mua

An adapter for sending emails using the SMTP protocol.

> ### Dependencies {: .info}
>
> This adapter relies on the [Mua](https://github.com/ruslandoga/mua) and
> [Mail](https://github.com/DockYard/elixir-mail) libraries.
> Ensure they are added to your mix.exs file:

    # mix.exs
    def deps do
      [
       {:swoosh, "~> 1.3"},
       {:mua, "~> 0.2.0"},
       {:mail, "~> 0.3.0"},
       # if on OTP version below 25
       # {:castore, "~> 1.0"}
      ]
    end

## Configuration

For direct email sending:

    # config/config.exs
    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.Mua

For sending emails via a relay:

    # config/config.exs
    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.Mua,
      relay: "smtp.matrix.com",
      port: 587,
      auth: [username: "neo", password: "one"]

Define your mailer module:

    # lib/sample/mailer.ex
    defmodule Sample.Mailer do
      use Swoosh.Mailer, otp_app: :sample
    end

For supported configuration options, please see [`option()`](#t:option/0)

## Sending Email Directly

When the relay option is omitted, the adapter sends emails directly to the recipients' mail servers.
All recipients must be on the same host; otherwise, a `Swoosh.Adapters.Mua.MultihostError` is raised.

Ensure your application can make outgoing connections to port 25 and
that your sender domain has appropriate DNS records (e.g. SPF, DKIM).

> #### Short-lived Connections {: .warning}
>
> Each `deliver/2` call results in a new connection to the recipient's email server.

## Sending Email via a Relay

When the relay option is set, emails are sent through the specified relay, typically requiring authentication.
For example, you can use your Gmail account with an app password.

> #### Short-lived Connections {: .warning}
>
> Each `deliver/2` call results in a new connection to the relay. This is less efficient than `gen_smtp` which reuses long-lived connections.
> Future versions of this adapter may address this issue.

## CA Certificates

Starting with OTP 25, [system cacerts](https://www.erlang.org/doc/apps/public_key/public_key.html#cacerts_get/0)
are used by default for the [cacerts](https://www.erlang.org/doc/apps/ssl/ssl.html#t:client_option_cert/0) option:

    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.Mua,
      # this happens by default
      ssl: [cacerts: :public_key.cacerts_get()]

For OTP versions below 25, [`CAStore.file_path/0`](https://hexdocs.pm/castore/CAStore.html#file_path/0) is used for the [cacertfile](https://www.erlang.org/doc/apps/ssl/ssl.html#t:client_option_cert/0) option:

    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.Mua,
      # this happens by default
      ssl: [cacertfile: CAStore.file_path()]

This means that for OTP versions below 25, you need to add [CAStore](https://hex.pm/packages/castore) to your project.

You can also use custom certificates:

    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.Mua,
      ssl: [cacertfile: System.fetch_env!("MY_OWN_SMTP_CACERTFILE")]


> #### CA Certfile Cache {: .warning}
>
> When using the `:cacertfile` option, certificates are decoded with each new connection.
> To cache the decoded certificates, set `:persistent_term` for `:mua` to true:
>
>     config :mua, persistent_term: true