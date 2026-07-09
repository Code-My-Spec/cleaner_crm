# Swoosh.Adapters.Gmail

An adapter that sends email using Gmail api

For reference: [Gmail API docs](https://developers.google.com/gmail/api)

**This adapter requires an API Client.** Swoosh comes with Hackney, Finch and Req out of the box.
See the [installation section](https://hexdocs.pm/swoosh/Swoosh.html#module-installation)
for details.

> ### Dependency {: .info}
>
> Gmail adapter requires `Mail` dependency to format message as RFC 2822 message.
>
>     {:mail, ">= 0.0.0"}

Because `Mail` library removes Bcc headers, they are being added after email is
rendered, in adapter code.

## Example

    # config/config.exs
    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.Gmail,
      access_token: {:system, "GMAIL_API_ACCESS_TOKEN"}

    # To deal with token refresh, it could be a better idea to pass the access token
    # in via deliver config explicitly, if you don't update the environment variable
    # periodically. e.g.
    MyMailer.deliver(my_email, access_token: my_access_token)

    # lib/sample/mailer.ex
    defmodule Sample.Mailer do
      use Swoosh.Mailer, otp_app: :sample
    end

## Required config parameters
  - `:access_token` valid OAuth2 access token
      Required scopes:
      - gmail.compose
    See https://developers.google.com/oauthplayground when developing