defmodule CleanerCrm.Notifications.ReminderNotifier do
  @moduledoc """
  Builds and delivers the appointment reminder email via
  `CleanerCrm.Mailer` (Swoosh/Resend). Every reminder — whether sent
  on the client's preferred channel or as the SMS-undeliverable
  fallback — carries both the confirm and reschedule links.
  """

  import Swoosh.Email

  alias CleanerCrm.Mailer
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Scheduling.Job

  def deliver_reminder(%Client{} = client, %Job{} = job, confirm_url, reschedule_url) do
    client.email
    |> reminder_email(job, confirm_url, reschedule_url)
    |> Mailer.deliver()
  end

  defp reminder_email(to, job, confirm_url, reschedule_url) do
    new()
    |> to(to)
    |> from(Application.fetch_env!(:cleaner_crm, :mailer_from))
    |> subject("Reminder: your cleaning appointment on #{job.scheduled_date}")
    |> html_body("""
    <p>This is a reminder about your cleaning appointment on \
    #{job.scheduled_date} at #{job.start_time}.</p>
    <p><a href="#{confirm_url}">Confirm this appointment</a></p>
    <p><a href="#{reschedule_url}">Request a reschedule</a></p>
    """)
    |> text_body("""
    Reminder: your cleaning appointment is on #{job.scheduled_date} at #{job.start_time}.

    Confirm: #{confirm_url}
    Reschedule: #{reschedule_url}
    """)
  end
end
