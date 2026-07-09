# Swoosh.Adapters.ZeptoMail

An adapter that sends transactional email using the ZeptoMail API.

For reference: [ZeptoMail API docs](https://www.zoho.com/zeptomail/help/api/email-sending.html)

## Configuration options

* `:api_key` - the API key without the prefix `Zoho-enczapikey` used with ZeptoMail.
* `:type` - the type of email to send `:single` or `:batch`. Defaults to `:single`
* `:base_url` - the url to use as the API endpoint. For EU, use https://api.zeptomail.eu/v1.1

## Example

    # config/config.exs
    config :sample, Sample.Mailer,
      adapter: Swoosh.Adapters.ZeptoMail,
      api_key: "my-api-key"

    # lib/sample/mailer.ex
    defmodule Sample.Mailer do
      use Swoosh.Mailer, otp_app: :sample
    end

## Using with provider options

    import Swoosh.Email

    new()
    |> from({"T Stark", "tony.stark@example.com"})
    |> to({"Steve Rogers", "steve.rogers@example.com"})
    |> to("wasp.avengers@example.com")
    |> reply_to("office.avengers@example.com")
    |> cc({"Bruce Banner", "hulk.smash@example.com"})
    |> cc("thor.odinson@example.com")
    |> bcc({"Clinton Francis Barton", "hawk.eye@example.com"})
    |> bcc("beast.avengers@example.com")
    |> subject("Hello, Avengers!")
    |> html_body("<h1>Hello</h1><img src=\"cid:inline-attachment-from-cache\" />")
    |> text_body("Hello")
    |> put_provider_option(:bounce_address, "bounce@example.com")
    |> put_provider_option(:track_clicks, false)
    |> put_provider_option(:track_opens, true)
    |> put_provider_option(:inline_images, [%{cid: "inline-attachment-from-cache", file_cache_key: "cache-key"}])

## Batch Sending

`ZeptoMail` does not support sending multiple different emails, however it does support sending one email
to a list of recipients.

To allow the customization of the email per recipient, a field `:merge_info` may be provided for each recipient.

    import Swoosh.Email

    email =
      new()
      |> from({"T Stark", "tony.stark@example.com"})
      |> to({"Steve Rogers", "steve.rogers@example.com"})
      |> to("wasp.avengers@example.com")
      |> subject("Hello, Avengers!")
      |> html_body("<h1>Hello Avenger from {{ team }}</h1>")
      |> put_provider_option(:merge_info,
        %{
          "steve.rogers@example.com" => %{team: "Avengers"},
          "wasp.avengers@example.com" => %{team: "Avengers 2"}
        }
      )

    Swoosh.Adapters.ZeptoMail.deliver(email, type: :batch)

## Provider options
  * `:bounce_address` (string) - The email address to which bounced emails will be sent.

  * `:track_clicks` (boolean) - Enable or disable email click tracking.

  * `:track_opens` (boolean) - Enable or disable email open tracking.

  * `:client_reference` (string) - An identifier set by the user to track a particular transaction.

  * `:mime_headers` (map) - The additional headers to be sent in the email for your reference purposes.

  * `:attachments` (list) - A list of file cache keys to send as attachments.

  * `:inline_images` (list) - A list of map (`cid` and `file_cache_key`) to include as inline attachments.

  * `:template_key` (string) - Unique key identifier of your template.

  * `:template_alias` (string) - Alias name given to the template key, can be used instead of `template_key`.

  * `:merge_info` (map) - Use this values to replace the placeholders in the template.

    In case of batch email sending, this should be a map of email address to a map of key-value.