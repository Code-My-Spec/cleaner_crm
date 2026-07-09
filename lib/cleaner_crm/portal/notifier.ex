defmodule CleanerCrm.Portal.Notifier do
  @moduledoc """
  Emails a client a fresh magic-link to their client portal — the
  "request a login link" flow's own delivery, for an existing client
  who lost or never got the link a booking confirmation would
  otherwise have handed them (mirrors
  `CleanerCrm.Booking.Notifier.deliver_confirmation/2`'s portal-link
  styling).
  """

  import Swoosh.Email

  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Mailer

  def deliver_login_link(%Client{email: email} = client, portal_url)
      when is_binary(email) and is_binary(portal_url) do
    message =
      new()
      |> to(email)
      |> from(Application.fetch_env!(:cleaner_crm, :mailer_from))
      |> subject("Your client portal link")
      |> html_body("""
      <p>Hi#{name_suffix(client)},</p>
      <p>Here's the link you asked for: <a href="#{portal_url}">open your client portal</a>.</p>
      <p>If you didn't request this, you can safely ignore this email.</p>
      """)
      |> text_body("""
      Hi#{name_suffix(client)},

      Here's the link you asked for — open your client portal: #{portal_url}

      If you didn't request this, you can safely ignore this email.
      """)

    Mailer.deliver(message)
  end

  defp name_suffix(%Client{name: name}) when is_binary(name) and name != "", do: ", #{name}"
  defp name_suffix(_client), do: ""
end
