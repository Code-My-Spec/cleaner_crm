defmodule CleanerCrm.Notifications do
  @moduledoc """
  Client appointment reminders with confirm/reschedule actions, and
  cleaner schedule-change alerts requiring explicit acknowledgment with
  office visibility into what's still unacknowledged. Email/SMS
  delivery is abstracted behind `CleanerCrm.Notifications.Delivery`.

  Most functions are scoped by the caller's `Scope`. The confirm,
  reschedule, and delivery-status webhook endpoints are reached by an
  unauthenticated client or provider, so they look a notification up by
  its opaque `token` (or the provider's message id) instead.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Repo
  alias CleanerCrm.Users.Scope

  alias CleanerCrm.Notifications.{
    Notification,
    ReminderNotifier,
    ReminderScheduler,
    ReminderSettings
  }

  ## Reminder settings

  @doc "The account's reminder settings, defaulting to a 24-hour lead time if never configured."
  def get_reminder_settings(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    case Repo.get_by(ReminderSettings, account_id: account_id) do
      nil -> %ReminderSettings{account_id: account_id}
      settings -> settings
    end
  end

  def change_reminder_settings(%Scope{} = scope, attrs \\ %{}) do
    scope |> get_reminder_settings() |> ReminderSettings.changeset(attrs)
  end

  def update_reminder_settings(%Scope{active_account_id: account_id} = scope, attrs)
      when not is_nil(account_id) do
    scope
    |> get_reminder_settings()
    |> ReminderSettings.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc "Runs the periodic reminder scan now — see `CleanerCrm.Notifications.ReminderScheduler`."
  defdelegate send_due_reminders(), to: ReminderScheduler, as: :scan_and_send

  ## Notifications

  def create_notification(%Scope{active_account_id: account_id}, attrs)
      when not is_nil(account_id) do
    %Notification{account_id: account_id}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  @doc "The office's delivery log: every notification for the account, most recent first."
  def list_notifications(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    Notification
    |> where([n], n.account_id == ^account_id)
    |> order_by([n], desc: n.inserted_at)
    |> preload([:client, :cleaner])
    |> Repo.all()
  end

  ## Public confirm/reschedule — reached by token, no scope available

  def get_notification_by_token(token) when is_binary(token) do
    Repo.get_by(Notification, token: token)
  end

  def confirm_reminder(token) when is_binary(token) do
    with %Notification{} = notification <- get_notification_by_token(token) do
      update_status(notification, status: :confirmed, confirmed_at: DateTime.utc_now())
    else
      nil -> {:error, :not_found}
    end
  end

  def request_reschedule(token) when is_binary(token) do
    with %Notification{} = notification <- get_notification_by_token(token) do
      update_status(notification,
        status: :reschedule_requested,
        reschedule_requested_at: DateTime.utc_now()
      )
    else
      nil -> {:error, :not_found}
    end
  end

  @doc "True once the client has confirmed the most recent reminder sent for this job."
  def job_confirmed?(job_id) do
    Notification
    |> where([n], n.job_id == ^job_id and n.kind == :reminder and n.status == :confirmed)
    |> Repo.exists?()
  end

  @doc "True once the client has asked to reschedule via the most recent reminder for this job."
  def reschedule_requested?(job_id) do
    Notification
    |> where(
      [n],
      n.job_id == ^job_id and n.kind == :reminder and n.status == :reschedule_requested
    )
    |> Repo.exists?()
  end

  @doc """
  The client's confirm/reschedule decision on their most recent
  reminder for this job, for `ScheduleLive.Index` to render on the
  board — `nil` (no decision yet), `:confirmed`, or
  `:reschedule_requested`.
  """
  def reminder_status_for_job(job_id) do
    Notification
    |> where([n], n.job_id == ^job_id and n.kind == :reminder)
    |> where([n], n.status in [:confirmed, :reschedule_requested])
    |> order_by([n], desc: n.inserted_at)
    |> limit(1)
    |> select([n], n.status)
    |> Repo.one()
  end

  ## Twilio delivery-status webhook

  @doc """
  Applies a Twilio status callback: marks the matching notification
  delivered or undelivered, and — for an undeliverable SMS reminder —
  falls back to emailing the client and flags it for office visibility.
  """
  def handle_delivery_status(%{"MessageSid" => sid, "MessageStatus" => status} = params)
      when is_binary(sid) do
    # Most-recent match: real SIDs are unique, but webhook retries racing
    # inserts (or duplicated test data) must not 500 the endpoint.
    notification =
      from(n in Notification,
        where: n.provider_message_id == ^sid,
        order_by: [desc: n.inserted_at],
        limit: 1
      )
      |> Repo.one()

    case notification do
      nil -> {:error, :not_found}
      notification -> apply_delivery_status(notification, status, params["ErrorCode"])
    end
  end

  def handle_delivery_status(_params), do: {:error, :invalid_payload}

  defp apply_delivery_status(notification, "delivered", _error_code) do
    update_status(notification, status: :delivered, delivered_at: DateTime.utc_now())
  end

  defp apply_delivery_status(notification, status, error_code)
       when status in ["failed", "undelivered"] do
    with {:ok, updated} <-
           update_status(notification, status: :undelivered, failure_reason: error_code || status) do
      maybe_fallback_to_email(updated)
      {:ok, updated}
    end
  end

  defp apply_delivery_status(notification, _status, _error_code), do: {:ok, notification}

  defp maybe_fallback_to_email(
         %Notification{kind: :reminder, channel: :sms, client_id: client_id} = notification
       )
       when not is_nil(client_id) do
    client = Repo.get!(CleanerCrm.Clients.Client, notification.client_id)
    job = Repo.get!(CleanerCrm.Scheduling.Job, notification.job_id)
    token = generate_token()

    confirm_url = reminder_url("/reminders/confirm/#{token}")
    reschedule_url = reminder_url("/reminders/reschedule/#{token}")

    {:ok, _email} = ReminderNotifier.deliver_reminder(client, job, confirm_url, reschedule_url)

    %Notification{account_id: notification.account_id}
    |> Notification.changeset(%{
      client_id: client.id,
      job_id: job.id,
      kind: :reminder,
      channel: :email,
      status: :sent,
      token: token,
      sent_at: DateTime.utc_now()
    })
    |> Repo.insert()
  end

  defp maybe_fallback_to_email(_notification), do: :ok

  ## Schedule-change alerts (story 843 groundwork)

  def acknowledge(token) when is_binary(token) do
    with %Notification{} = notification <- get_notification_by_token(token) do
      update_status(notification, status: :acknowledged, acknowledged_at: DateTime.utc_now())
    else
      nil -> {:error, :not_found}
    end
  end

  @doc "Pending schedule-change alerts a cleaner hasn't acknowledged yet, for office visibility."
  def list_unacknowledged(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    Notification
    |> where(
      [n],
      n.account_id == ^account_id and n.kind == :schedule_change and n.status == :pending
    )
    |> preload([:cleaner, :job])
    |> Repo.all()
  end

  @doc """
  Job ids whose most recent schedule-change notification hasn't been
  acknowledged (`:pending` or `:escalated`) — for `ScheduleLive.Index`
  to keep a cancelled job's row (and its ack-status/channel
  indicators) on the board until the office has visibility into it,
  per story 843's escalation path. A job with no schedule-change
  notification at all, or whose latest one is already `:acknowledged`,
  is left out.
  """
  def job_ids_with_unacknowledged_schedule_change(%Scope{active_account_id: account_id})
      when not is_nil(account_id) do
    Notification
    |> where([n], n.account_id == ^account_id and n.kind == :schedule_change)
    |> distinct([n], n.job_id)
    |> order_by([n], asc: n.job_id, desc: n.inserted_at)
    |> select([n], {n.job_id, n.status})
    |> Repo.all()
    |> Enum.filter(fn {_job_id, status} -> status != :acknowledged end)
    |> Enum.map(fn {job_id, _status} -> job_id end)
  end

  @doc """
  The most recent schedule-change alert pushed for this job — `nil`,
  or a `Notification` exposing `:status`
  (`:pending` | `:acknowledged` | `:escalated`) and `:channel`
  (`:push` | `:sms` | `:email`). This is the contract
  `CleanerCrmWeb.ScheduleLive.Index` reads defensively to show a job's
  ack status on the board.
  """
  def latest_schedule_change_for_job(%Scope{active_account_id: account_id}, job_id)
      when not is_nil(account_id) do
    Notification
    |> where(
      [n],
      n.account_id == ^account_id and n.job_id == ^job_id and n.kind == :schedule_change
    )
    |> order_by([n], desc: n.inserted_at)
    |> limit(1)
    |> Repo.one()
    |> maybe_escalate()
  end

  # A same-day change nobody has acknowledged within the escalation
  # window re-sends via the fallback channel (SMS) and flags as
  # escalated for office visibility. Computed on read rather than a
  # separate periodic pass — every read of a job's alert (the board,
  # `FieldLive.Today`) goes through here, so none of them can show a
  # stale "pending" past the window.
  @escalation_window_seconds 600

  defp maybe_escalate(%Notification{status: :pending} = notification) do
    if escalation_due?(notification) do
      {:ok, updated} =
        update_status(notification,
          status: :escalated,
          channel: :sms,
          escalated_at: DateTime.utc_now()
        )

      updated
    else
      notification
    end
  end

  defp maybe_escalate(notification), do: notification

  defp escalation_due?(%Notification{pushed_at: nil}), do: false

  defp escalation_due?(%Notification{pushed_at: pushed_at, job_id: job_id}) do
    job = Repo.get!(CleanerCrm.Scheduling.Job, job_id)

    Date.compare(job.scheduled_date, Date.utc_today()) != :gt and
      DateTime.diff(DateTime.utc_now(), pushed_at, :second) >= @escalation_window_seconds
  end

  ## Shared helpers

  @doc false
  def generate_token, do: Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)

  defp update_status(%Notification{} = notification, attrs) do
    notification
    |> Notification.changeset(Map.new(attrs))
    |> Repo.update()
  end

  # `CleanerCrmWeb.Endpoint.url()` is the standard phx.gen.auth-style
  # exception for building absolute links in outbound messages — see
  # the `dirty_xrefs` note on the `CleanerCrm` boundary.
  defp reminder_url(path), do: CleanerCrmWeb.Endpoint.url() <> path
end
