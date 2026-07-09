defmodule CleanerCrm.Booking.Notifier do
  @moduledoc """
  Emails the client their booking confirmation once a webhook confirms
  the card charge — with a magic-link to their client portal (story
  850's `CleanerCrm.Portal`), so confirming a booking is also how a
  first-time client gets portal access.
  """

  import Swoosh.Email

  alias CleanerCrm.Booking.Lead
  alias CleanerCrm.Mailer
  alias CleanerCrm.Money

  def deliver_confirmation(%Lead{client_email: email} = lead, portal_url)
      when is_binary(email) and is_binary(portal_url) do
    message =
      new()
      |> to(email)
      |> from(Application.fetch_env!(:cleaner_crm, :mailer_from))
      |> subject("Your cleaning is booked!")
      |> html_body("""
      <p>Thanks#{name_suffix(lead)}! Your cleaning is booked for #{format_visit(lead)}.</p>
      <p>Total: #{Money.format_cents(lead.total_cents)}, already on file — nothing due at your visit.</p>
      <p><a href="#{portal_url}">View your booking in your client portal</a></p>
      """)
      |> text_body("""
      Thanks#{name_suffix(lead)}! Your cleaning is booked for #{format_visit(lead)}.

      Total: #{Money.format_cents(lead.total_cents)}, already on file — nothing due at your visit.

      View your booking in your client portal: #{portal_url}
      """)

    Mailer.deliver(message)
  end

  defp name_suffix(%Lead{client_name: name}) when is_binary(name) and name != "", do: ", #{name}"
  defp name_suffix(_lead), do: ""

  defp format_visit(%Lead{scheduled_date: date, start_time: start_time}) do
    "#{Calendar.strftime(date, "%B %-d, %Y")} at #{Calendar.strftime(start_time, "%-I:%M %p")}"
  end
end
