defmodule CleanerCrm.Notifications.ReminderScheduler do
  @moduledoc """
  Schedules reminder sends ahead of upcoming jobs.

  Driven by Oban's cron plugin in production (see the
  background-jobs-oban ADR): `perform/1` runs on a schedule and calls
  `scan_and_send/1`, the pure entry point, so the same check can also
  be run synchronously — deterministic, no clock-waiting — right after
  a job is created.

  Only accounts that have explicitly saved reminder settings
  (`CleanerCrmWeb.ReminderLive`) are scanned, so this never fires for
  an account that hasn't opted in.
  """

  use Oban.Worker, queue: :notifications

  import Ecto.Query
  require Logger

  alias CleanerCrm.Repo
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Notifications.{Delivery, Notification, ReminderNotifier, ReminderSettings}

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    scan_and_send()
    :ok
  end

  @doc "Sends every reminder that's due right now, across every account with reminder settings."
  def scan_and_send(now \\ DateTime.utc_now()) do
    ReminderSettings
    |> Repo.all()
    |> Enum.each(&send_for_account(&1, now))
  end

  defp send_for_account(
         %ReminderSettings{account_id: account_id, lead_time_hours: lead_time_hours},
         now
       ) do
    account_id
    |> due_jobs()
    |> Enum.filter(&due_now?(&1, lead_time_hours, now))
    |> Enum.each(&send_reminder_isolated/1)
  end

  # One job's send failing (a delivery-adapter bug, a bad email
  # address, whatever) must never stop the rest of the scan — each job
  # gets its own failure boundary rather than the whole `Enum.each`
  # aborting on the first raise.
  defp send_reminder_isolated(job) do
    send_reminder(job)
  rescue
    error ->
      Logger.error(
        "ReminderScheduler failed to send reminder for job #{job.id}: " <>
          Exception.format(:error, error, __STACKTRACE__)
      )
  end

  defp due_jobs(account_id) do
    already_reminded =
      from n in Notification, where: n.job_id == parent_as(:job).id and n.kind == :reminder

    from(j in Job,
      as: :job,
      where: j.account_id == ^account_id,
      where: j.status == :scheduled,
      where: not is_nil(j.client_id),
      where: not exists(already_reminded),
      preload: [:client]
    )
    |> Repo.all()
  end

  defp due_now?(%Job{scheduled_date: date, start_time: time}, lead_time_hours, now) do
    with {:ok, start_at} <- DateTime.new(date, time, "Etc/UTC") do
      due_at = DateTime.add(start_at, -lead_time_hours * 3600, :second)
      DateTime.compare(due_at, now) != :gt and DateTime.compare(start_at, now) == :gt
    else
      _ -> false
    end
  end

  defp send_reminder(%Job{client: %Client{preferred_channel: :sms, phone: phone}} = job)
       when is_binary(phone) do
    token = CleanerCrm.Notifications.generate_token()
    body = reminder_sms_body(job, token)

    case Delivery.send_sms(phone, body) do
      {:ok, %{provider_message_id: sid}} ->
        insert_notification!(job, job.client, :sms, token, sid, DateTime.utc_now())

      {:error, _reason} ->
        send_email_reminder(job, job.client)
    end
  end

  defp send_reminder(%Job{client: client} = job), do: send_email_reminder(job, client)

  defp send_email_reminder(job, client) do
    token = CleanerCrm.Notifications.generate_token()
    confirm_url = reminder_url("/reminders/confirm/#{token}")
    reschedule_url = reminder_url("/reminders/reschedule/#{token}")

    {:ok, _email} = ReminderNotifier.deliver_reminder(client, job, confirm_url, reschedule_url)

    insert_notification!(job, client, :email, token, nil, DateTime.utc_now())
  end

  defp reminder_sms_body(job, token) do
    "Cleaning appointment reminder for #{job.scheduled_date} at #{job.start_time}. " <>
      "Confirm: #{reminder_url("/reminders/confirm/#{token}")} " <>
      "Reschedule: #{reminder_url("/reminders/reschedule/#{token}")}"
  end

  defp insert_notification!(job, client, channel, token, provider_message_id, sent_at) do
    %Notification{account_id: job.account_id}
    |> Notification.changeset(%{
      client_id: client.id,
      job_id: job.id,
      kind: :reminder,
      channel: channel,
      status: :sent,
      token: token,
      provider_message_id: provider_message_id,
      sent_at: sent_at
    })
    |> Repo.insert!()
  end

  # `CleanerCrmWeb.Endpoint.url()` is the standard phx.gen.auth-style
  # exception for building absolute links in outbound messages — see
  # the `dirty_xrefs` note on the `CleanerCrm` boundary.
  defp reminder_url(path), do: CleanerCrmWeb.Endpoint.url() <> path
end
