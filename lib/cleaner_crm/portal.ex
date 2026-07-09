defmodule CleanerCrm.Portal do
  @moduledoc """
  Client-facing portal domain: magic-link session tokens for clients
  (no password accounts), the client's view of upcoming visits with
  assigned-cleaner identity, service history with proof-of-work, and
  self-service reschedule/cancel enforcement against the account's
  cancellation policy.

  Every function here takes a `CleanerCrm.Clients.Client` directly
  rather than a `CleanerCrm.Users.Scope` — a portal visitor is a
  client reached through a magic link, never a logged-in staff user.
  Internally, calls into `Scheduling`, `Quality`, `Billing`, and
  `Notifications` are scoped by deriving a `Scope` from the client's
  own `account_id`.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Billing
  alias CleanerCrm.Billing.Invoice
  alias CleanerCrm.Clients
  alias CleanerCrm.Clients.Client
  alias CleanerCrm.Notifications
  alias CleanerCrm.Portal.{CancellationPolicy, PortalSession, Tip}
  alias CleanerCrm.Quality
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Users.Scope

  ## Magic-link sessions

  @doc """
  Issues a fresh portal session for `client`, returning the record
  with its plaintext `:token` set — the only time that token is ever
  available, so the caller (booking confirmation, "email me a link")
  must send or redirect with it immediately.
  """
  def create_portal_session(%Client{} = client, attrs \\ %{}) do
    client
    |> PortalSession.build_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Exchanges a magic-link token for the client id it grants access to.
  Touches the session's `last_used_at` on success. Fails closed with
  `{:error, :invalid}` for a token that doesn't match any session, or
  one that's expired — a client offered the same "your link is
  invalid or expired" outcome either way, never told which.
  """
  def access_portal(token) when is_binary(token) do
    case Repo.get_by(PortalSession, token_hash: PortalSession.hash_token(token)) do
      nil -> {:error, :invalid}
      %PortalSession{} = session -> exchange(session)
    end
  end

  defp exchange(%PortalSession{} = session) do
    if PortalSession.expired?(session) do
      {:error, :invalid}
    else
      {:ok, _touched} = session |> PortalSession.touch_changeset() |> Repo.update()
      {:ok, session.client_id}
    end
  end

  @doc "Loads a client by id — the portal session carries only the id, never the whole struct."
  def get_client!(client_id), do: Repo.get!(Client, client_id)

  ## Visits

  @doc """
  The client's upcoming (today or later, not cancelled) visits,
  soonest first, cleaner preloaded for name/photo display.
  """
  def list_upcoming_visits(%Client{} = client) do
    client
    |> account_scope()
    |> Scheduling.list_jobs()
    |> Enum.filter(&(&1.client_id == client.id and &1.status in [:scheduled, :in_progress]))
    |> Enum.filter(&(Date.compare(&1.scheduled_date, Date.utc_today()) != :lt))
    |> Enum.sort_by(&{&1.scheduled_date, &1.start_time})
  end

  @doc """
  The client's completed visits, most recent first — each one's
  checklist and before/after photos are read separately via
  `visit_checklist/1`.
  """
  def list_visit_history(%Client{} = client) do
    client
    |> account_scope()
    |> Scheduling.list_jobs()
    |> Enum.filter(&(&1.client_id == client.id and &1.status == :completed))
    |> Enum.sort_by(& &1.scheduled_date, {:desc, Date})
  end

  @doc "A completed visit's checklist with items and photos preloaded, or `nil` if it has none."
  def visit_checklist(%Job{} = job) do
    Quality.get_checklist_for_job(system_scope(job.account_id), job)
  end

  @doc """
  Fetches a single visit for the portal's visit-detail page. Raises
  if `job_id` doesn't belong to `client` — the account-scoped lookup
  alone isn't enough, since other clients on the same account must
  never reach each other's visits by guessing an id.
  """
  def get_visit!(%Client{} = client, job_id) do
    job = Scheduling.get_job!(account_scope(client), job_id)

    case job.client_id do
      client_id when client_id == client.id -> job
      _other -> raise Ecto.NoResultsError, queryable: Job
    end
  end

  @doc """
  Reschedules a visit to a new date/start time, preserving its
  original duration, agreed price, and assigned cleaner. Notifies the
  assigned cleaner (and, through their unacknowledged status, the
  office) the same way a staff-driven reschedule does. Refused with
  `{:error, :not_modifiable}` for a completed or already-cancelled
  visit, or `{:error, :slot_in_past}` for a date/time no longer ahead
  of `now` — mirrors `CleanerCrm.Booking.Lead.slot_in_future?/2`,
  since without this a client could reschedule into a past date with
  zero validation. `now` defaults to the real clock but takes an
  override for tests.
  """
  def reschedule_visit(client, job, attrs, now \\ DateTime.utc_now())

  def reschedule_visit(
        %Client{} = client,
        %Job{} = job,
        %{"date" => date_input, "start_time" => start_time_input},
        now
      ) do
    scope = account_scope(client)

    with :ok <- ensure_modifiable(job),
         {:ok, date} <- parse_date(date_input),
         {:ok, start_time} <- parse_time(start_time_input),
         :ok <- ensure_slot_in_future(date, start_time, now),
         {:ok, updated} <-
           Scheduling.update_job(scope, job, %{
             scheduled_date: date,
             start_time: start_time,
             end_time: shift_end_time(job, start_time)
           }) do
      notify_schedule_change(
        scope,
        updated,
        "Visit rescheduled by the client from #{schedule_label(job)} to #{schedule_label(updated)}"
      )

      {:ok, updated}
    end
  end

  @doc """
  The fee a client would be charged for cancelling `job` right now:
  the account's same-day fee if the visit is scheduled for today, its
  late fee if cancelling inside the notice window, otherwise zero.
  """
  def cancellation_fee_cents(%Client{} = client, %Job{} = job) do
    policy = get_cancellation_policy(client.account_id)
    fee_for(policy, job)
  end

  defp fee_for(%CancellationPolicy{} = policy, %Job{} = job) do
    cond do
      Date.compare(job.scheduled_date, Date.utc_today()) == :eq -> policy.same_day_fee_cents
      hours_until_visit(job) < policy.notice_window_hours -> policy.late_fee_cents
      true -> 0
    end
  end

  @doc """
  Cancels a visit, refusing with `{:error, :not_modifiable}` for one
  already completed or cancelled. Returns the fee charged alongside
  the updated visit — computed against the moment cancellation was
  requested, not looked up again afterward — and notifies the
  assigned cleaner of the cancellation.
  """
  def cancel_visit(%Client{} = client, %Job{} = job) do
    with :ok <- ensure_modifiable(job) do
      scope = account_scope(client)
      fee_cents = cancellation_fee_cents(client, job)

      with {:ok, updated} <- Scheduling.cancel_job(scope, job) do
        notify_schedule_change(scope, updated, "Visit cancelled by the client")
        {:ok, updated, fee_cents}
      end
    end
  end

  ## Cancellation policy

  @doc "The account's cancellation policy, defaulting to a fresh, unsaved (all-zero-fee) one."
  def get_cancellation_policy(account_id) when not is_nil(account_id) do
    case Repo.get_by(CancellationPolicy, account_id: account_id) do
      nil -> %CancellationPolicy{account_id: account_id}
      policy -> policy
    end
  end

  @doc "Sets (creating or updating) the account's cancellation policy."
  def set_cancellation_policy(%Scope{active_account_id: account_id}, attrs)
      when not is_nil(account_id) do
    account_id
    |> get_cancellation_policy()
    |> CancellationPolicy.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  A changeset for editing the account's cancellation policy — the
  owner settings form's own basis, same shape whether the account has
  a saved policy yet or is still on the unsaved, all-zero-fee default.
  """
  def change_cancellation_policy(%Scope{}, %CancellationPolicy{} = policy, attrs \\ %{}) do
    CancellationPolicy.changeset(policy, attrs)
  end

  ## Invoices and payment

  @doc "Every invoice for `client`'s own jobs, most recent first."
  def list_invoices(%Client{} = client) do
    Invoice
    |> join(:inner, [i], j in Job, on: j.id == i.job_id)
    |> where([i, j], j.client_id == ^client.id)
    |> order_by([i], desc: i.inserted_at)
    |> preload(job: :client)
    |> Repo.all()
  end

  @doc """
  Pays an invoice from the portal: submits the charge (per the
  payments-stripe ADR, this only moves the invoice to
  `:charge_pending` — final `:paid` status is webhook-driven), then
  optionally saves the card on file and records a tip against the
  visit's assigned cleaner.

  `attrs` (string-keyed, straight off the payment form): `"card_token"`
  (required), `"save_card"` (`"true"`/`"on"` to save), `"tip_cents"`
  (blank or omitted to skip the tip).
  """
  def pay_invoice(%Client{} = client, %Invoice{} = invoice, attrs) do
    with {:ok, updated_invoice} <- Billing.pay_via_link(invoice, Map.get(attrs, "card_token")) do
      maybe_save_card(client, attrs)
      maybe_record_tip(updated_invoice, attrs)
      {:ok, updated_invoice}
    end
  end

  defp maybe_save_card(%Client{} = client, %{"save_card" => save_card})
       when save_card in ["true", "on"] do
    Clients.update_client(system_scope(client.account_id), client, %{card_on_file: true})
  end

  defp maybe_save_card(_client, _attrs), do: :ok

  defp maybe_record_tip(%Invoice{} = invoice, attrs) do
    case parse_tip_cents(Map.get(attrs, "tip_cents")) do
      cents when is_integer(cents) and cents > 0 -> record_tip(invoice, cents)
      _no_tip -> :ok
    end
  end

  defp record_tip(%Invoice{} = invoice, cents) do
    %Tip{
      account_id: invoice.account_id,
      invoice_id: invoice.id,
      cleaner_id: invoice.job.cleaner_id
    }
    |> Tip.changeset(%{
      amount_cents: cents,
      stripe_payment_intent_id: invoice.stripe_payment_intent_id
    })
    |> Repo.insert()
  end

  @doc """
  Cents a cleaner has been tipped through the portal within `period`
  (a `{start_date, end_date}` tuple, matching
  `CleanerCrm.TimeTracking.current_pay_period/1`'s own shape) — read
  by `CleanerCrmWeb.FieldLive.EarningsComponent` to fold tips into a
  cleaner's pay-period total alongside their time-tracked earnings.
  """
  def tip_cents_for_cleaner(
        %Scope{active_account_id: account_id},
        cleaner_id,
        {start_date, end_date}
      )
      when not is_nil(account_id) do
    start_at = DateTime.new!(start_date, ~T[00:00:00])
    end_at = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00])

    Tip
    |> where(
      [t],
      t.account_id == ^account_id and t.cleaner_id == ^cleaner_id and
        t.inserted_at >= ^start_at and t.inserted_at < ^end_at
    )
    |> select([t], sum(t.amount_cents))
    |> Repo.one()
    |> Kernel.||(0)
  end

  ## Shared helpers

  defp account_scope(%Client{account_id: account_id}), do: system_scope(account_id)

  defp system_scope(account_id), do: %Scope{active_account_id: account_id}

  defp ensure_modifiable(%Job{status: status}) when status in [:completed, :cancelled],
    do: {:error, :not_modifiable}

  defp ensure_modifiable(%Job{}), do: :ok

  defp ensure_slot_in_future(date, start_time, now) do
    if slot_in_future?(date, start_time, now), do: :ok, else: {:error, :slot_in_past}
  end

  # Mirrors `CleanerCrm.Booking.Lead.slot_in_future?/2`'s own
  # date/time-vs-`now` comparison — today only counts if `start_time`
  # hasn't passed yet.
  defp slot_in_future?(date, start_time, now) do
    case Date.compare(date, DateTime.to_date(now)) do
      :gt -> true
      :lt -> false
      :eq -> Time.compare(start_time, DateTime.to_time(now)) == :gt
    end
  end

  defp parse_date(%Date{} = date), do: {:ok, date}
  defp parse_date(string) when is_binary(string), do: Date.from_iso8601(string)

  defp parse_time(%Time{} = time), do: {:ok, time}

  defp parse_time(string) when is_binary(string) do
    case String.split(string, ":") do
      [_hour, _minute] -> Time.from_iso8601(string <> ":00")
      _other -> Time.from_iso8601(string)
    end
  end

  defp parse_tip_cents(value) when value in [nil, ""], do: nil

  defp parse_tip_cents(value) when is_binary(value) do
    case Integer.parse(value) do
      {cents, _rest} -> cents
      :error -> nil
    end
  end

  # Moves `start_time` in by the same amount the visit already runs,
  # clamping to end-of-day rather than wrapping past midnight into an
  # earlier clock time — mirrors
  # `CleanerCrmSpex.Fixtures`' own `default_end_time/1` safeguard.
  defp shift_end_time(%Job{} = job, %Time{} = start_time) do
    {start_seconds, _} = Time.to_seconds_after_midnight(job.start_time)
    {end_seconds, _} = Time.to_seconds_after_midnight(job.end_time)
    candidate = Time.add(start_time, end_seconds - start_seconds, :second)

    if Time.compare(candidate, start_time) == :gt, do: candidate, else: ~T[23:59:59]
  end

  defp hours_until_visit(%Job{scheduled_date: date, start_time: time}) do
    visit_at = DateTime.new!(date, time, "Etc/UTC")
    DateTime.diff(visit_at, DateTime.utc_now(), :hour)
  end

  defp notify_schedule_change(_scope, %Job{cleaner_id: nil}, _summary), do: :ok

  defp notify_schedule_change(scope, %Job{} = job, summary) do
    Notifications.create_notification(scope, %{
      cleaner_id: job.cleaner_id,
      job_id: job.id,
      kind: :schedule_change,
      channel: :push,
      status: :pending,
      change_summary: summary,
      pushed_at: DateTime.utc_now(),
      token: "portal_schedule_change_#{job.id}_#{System.unique_integer([:positive])}"
    })
  end

  defp schedule_label(%Job{} = job),
    do:
      "#{job.scheduled_date} #{format_time_12h(job.start_time)}-#{format_time_12h(job.end_time)}"

  defp format_time_12h(%Time{} = time) do
    {hour, period} = to_12_hour(time.hour)
    minute = time.minute |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{hour}:#{minute} #{period}"
  end

  defp to_12_hour(0), do: {12, "AM"}
  defp to_12_hour(hour) when hour < 12, do: {hour, "AM"}
  defp to_12_hour(12), do: {12, "PM"}
  defp to_12_hour(hour), do: {hour - 12, "PM"}
end
