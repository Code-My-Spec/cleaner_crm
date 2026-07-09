defmodule CleanerCrm.TimeTracking do
  @moduledoc """
  Clock-in/out per job, hourly and piece-rate pay, transparent
  per-job and pay-period earnings, and payroll-ready CSV export.

  Every function is scoped to the caller's active account. Money is
  always integer cents; `CleanerCrm.Money` formats it for display and
  `CleanerCrm.TimeTracking.Earnings` does the cents math.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Accounts
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.TimeTracking.{Earnings, PayRate, PayrollExport, TimeEntry}
  alias CleanerCrm.Users.{Scope, User}

  ## Clocking in and out

  @doc """
  Clocks the scope's user in to `job`. Fails closed: `{:error,
  :not_assigned}` if the job isn't theirs, `{:error,
  {:already_clocked_in, other_job}}` if they're still on the clock
  somewhere else.
  """
  def clock_in(%Scope{active_account_id: account_id} = scope, %Job{} = job)
      when not is_nil(account_id) do
    with :ok <- ensure_assigned(job, scope.user),
         :ok <- ensure_not_already_clocked_in(scope, job) do
      create_time_entry(scope, %{job_id: job.id, clocked_in_at: DateTime.utc_now()})
    end
  end

  @doc "Clocks the scope's user out of their open entry on `job`."
  def clock_out(%Scope{active_account_id: account_id} = scope, %Job{} = job)
      when not is_nil(account_id) do
    case open_time_entry_for_job(scope, job) do
      nil ->
        {:error, :not_clocked_in}

      entry ->
        entry |> TimeEntry.changeset(%{clocked_out_at: DateTime.utc_now()}) |> Repo.update()
    end
  end

  defp ensure_assigned(%Job{cleaner_id: cleaner_id}, %User{id: cleaner_id}), do: :ok
  defp ensure_assigned(_job, _user), do: {:error, :not_assigned}

  defp ensure_not_already_clocked_in(%Scope{user: user} = scope, %Job{id: job_id}) do
    case open_time_entry_for_cleaner(scope, user.id) do
      nil -> :ok
      %TimeEntry{job_id: ^job_id} -> :ok
      %TimeEntry{} = entry -> {:error, {:already_clocked_in, Repo.preload(entry, :job).job}}
    end
  end

  @doc """
  Creates a resolved (or open, if `clocked_out_at` is omitted or
  `nil`) time entry directly. The sanctioned bypass
  `CleanerCrmSpex.Fixtures.time_entry_fixture` seeds through — real
  clock-in/out goes through `clock_in/2` and `clock_out/2` above.
  """
  def create_time_entry(%Scope{active_account_id: account_id} = scope, attrs)
      when not is_nil(account_id) do
    job = Scheduling.get_job!(scope, fetch!(attrs, :job_id))

    %TimeEntry{account_id: account_id, job_id: job.id, cleaner_id: job.cleaner_id}
    |> TimeEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets the clock-out time on an open entry to a specific time of day
  on its clock-in date — how the owner resolves a forgotten
  clock-out.
  """
  def resolve_clock_out(%Scope{active_account_id: account_id}, %TimeEntry{} = entry, attrs)
      when not is_nil(account_id) do
    with {:ok, time} <- parse_time(fetch!(attrs, :clock_out_time)),
         {:ok, clocked_out_at} <- combine(entry.clocked_in_at, time) do
      entry |> TimeEntry.changeset(%{clocked_out_at: clocked_out_at}) |> Repo.update()
    end
  end

  defp fetch!(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, value} -> value
      :error -> Map.fetch!(attrs, to_string(key))
    end
  end

  defp parse_time(%Time{} = time), do: {:ok, time}

  defp parse_time(string) when is_binary(string) do
    case String.split(string, ":") do
      [_hour, _minute] -> Time.from_iso8601(string <> ":00")
      _ -> Time.from_iso8601(string)
    end
  end

  # Combines the submitted time-of-day with the clock-in's date. A
  # resolution submitted for the same day is the common case, but a
  # cleaner who clocked in late at night and got resolved the next
  # morning would otherwise land before their own clock-in and fail
  # validation — so a candidate that doesn't come after clock-in rolls
  # forward to the next day instead.
  defp combine(%DateTime{time_zone: time_zone} = clocked_in_at, %Time{} = time) do
    date = DateTime.to_date(clocked_in_at)

    with {:ok, candidate} <- DateTime.new(date, time, time_zone) do
      if DateTime.compare(candidate, clocked_in_at) == :gt do
        {:ok, candidate}
      else
        DateTime.new(Date.add(date, 1), time, time_zone)
      end
    end
  end

  ## Reading time entries

  def open_time_entry_for_job(%Scope{active_account_id: account_id}, %Job{} = job)
      when not is_nil(account_id) do
    TimeEntry
    |> where(
      [t],
      t.account_id == ^account_id and t.job_id == ^job.id and is_nil(t.clocked_out_at)
    )
    |> order_by([t], desc: t.clocked_in_at)
    |> limit(1)
    |> Repo.one()
  end

  def open_time_entry_for_cleaner(%Scope{active_account_id: account_id}, cleaner_id)
      when not is_nil(account_id) do
    TimeEntry
    |> where(
      [t],
      t.account_id == ^account_id and t.cleaner_id == ^cleaner_id and is_nil(t.clocked_out_at)
    )
    |> order_by([t], desc: t.clocked_in_at)
    |> limit(1)
    |> Repo.one()
  end

  def list_time_entries_for_job(%Scope{active_account_id: account_id}, %Job{} = job)
      when not is_nil(account_id) do
    TimeEntry
    |> where([t], t.account_id == ^account_id and t.job_id == ^job.id)
    |> order_by([t], asc: t.clocked_in_at)
    |> Repo.all()
  end

  ## Earnings

  @doc """
  Cents earned on `job` so far — see `CleanerCrm.TimeTracking.Earnings.job_cents/2`
  for exactly what that means for each pay type.
  """
  def job_earnings_cents(%Scope{} = scope, %Job{} = job) do
    Earnings.job_cents(job, list_time_entries_for_job(scope, job))
  end

  @doc "Seconds elapsed on the cleaner's currently-open entry for `job`, or `nil` if not clocked in."
  def elapsed_seconds(%Scope{} = scope, %Job{} = job) do
    case open_time_entry_for_job(scope, job) do
      nil -> nil
      entry -> Earnings.elapsed_seconds(entry)
    end
  end

  ## Pay periods

  @doc "The Monday-Sunday week containing `date`."
  def pay_period_for(%Date{} = date) do
    monday = Date.add(date, -(Date.day_of_week(date) - 1))
    {monday, Date.add(monday, 6)}
  end

  @doc """
  The account's current pay period: the week containing its most
  recent time entry, falling back to this real-world week when the
  account has none yet. Anchoring on the latest activity rather than
  the wall clock means newly-seeded or backfilled data is visible the
  moment the owner opens the timesheet, with no period picker to
  navigate first.
  """
  def current_pay_period(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    TimeEntry
    |> where([t], t.account_id == ^account_id)
    |> select([t], max(t.clocked_in_at))
    |> Repo.one()
    |> case do
      nil -> Date.utc_today()
      clocked_in_at -> DateTime.to_date(clocked_in_at)
    end
    |> pay_period_for()
  end

  @doc """
  Every job with time recorded in `period` (a `{start_date, end_date}`
  tuple), with its cleaner, entries, earned cents (`nil` if
  unresolved), and resolved status — the timesheet's row-level data.
  """
  def list_job_time_summaries(%Scope{active_account_id: account_id} = scope, {_, _} = period)
      when not is_nil(account_id) do
    scope
    |> time_entries_in_period(period)
    |> Enum.group_by(& &1.job_id)
    |> Enum.map(fn {_job_id, entries} ->
      job = hd(entries).job
      cents = Earnings.job_cents(job, entries)
      open? = Enum.any?(entries, &(!TimeEntry.resolved?(&1)))

      %{
        job: job,
        cleaner: job.cleaner,
        entries: entries,
        cents: cents,
        # `open?` is genuinely missing a clock-out — the only state a
        # clock-out resolution can fix. `unresolved?` is broader: it
        # also covers a job whose entries are all closed but whose pay
        # can't be computed yet (missing pay type/rate), which must
        # block payroll the same way an open entry does rather than
        # silently price at $0 — but has no open entry for a
        # clock-out resolution to act on, so the two are tracked
        # separately rather than folded into one flag.
        open?: open?,
        unresolved?: is_nil(cents) or open?
      }
    end)
    |> Enum.sort_by(& &1.job.scheduled_date, Date)
  end

  @doc """
  Per-cleaner totals for `period`, excluding unresolved jobs. A
  cleaner whose only job is unresolved still appears, at zero — the
  amount isn't missing, it's withheld pending resolution.
  """
  def cleaner_pay_totals(%Scope{} = scope, period) do
    scope
    |> list_job_time_summaries(period)
    |> Enum.group_by(& &1.cleaner.id)
    |> Map.new(fn {cleaner_id, summaries} ->
      total = summaries |> Enum.reject(& &1.unresolved?) |> Enum.map(& &1.cents) |> Enum.sum()
      {cleaner_id, total}
    end)
  end

  defp time_entries_in_period(%Scope{active_account_id: account_id}, {start_date, end_date}) do
    start_at = DateTime.new!(start_date, ~T[00:00:00])
    end_at = DateTime.new!(Date.add(end_date, 1), ~T[00:00:00])

    TimeEntry
    |> where(
      [t],
      t.account_id == ^account_id and t.clocked_in_at >= ^start_at and t.clocked_in_at < ^end_at
    )
    |> preload(job: :cleaner)
    |> Repo.all()
  end

  ## Payroll export

  @doc """
  Exports `period`'s earnings to CSV, one row per cleaner. Refuses
  with `{:error, :unresolved_entries}` while any job in the period is
  still missing a clock-out — payroll never goes out on an estimate.
  """
  def export_pay_period_csv(%Scope{} = scope, period) do
    summaries = list_job_time_summaries(scope, period)

    if Enum.any?(summaries, & &1.unresolved?) do
      {:error, :unresolved_entries}
    else
      {:ok, PayrollExport.to_csv(summaries)}
    end
  end

  ## Drive-time policy

  @doc "The account's drive-time pay policy, for display alongside a cleaner's earnings."
  def drive_time_policy(%Scope{active_account_id: account_id} = scope)
      when not is_nil(account_id) do
    Accounts.get_account!(scope, account_id).drive_time_policy
  end

  ## Pay rates (per-cleaner defaults)

  def get_pay_rate(%Scope{active_account_id: account_id}, cleaner_id)
      when not is_nil(account_id) do
    Repo.get_by(PayRate, account_id: account_id, cleaner_id: cleaner_id)
  end

  def set_pay_rate(%Scope{active_account_id: account_id} = scope, cleaner_id, attrs)
      when not is_nil(account_id) do
    scope
    |> get_pay_rate(cleaner_id)
    |> Kernel.||(%PayRate{account_id: account_id, cleaner_id: cleaner_id})
    |> PayRate.changeset(Map.put(attrs, :cleaner_id, cleaner_id))
    |> Repo.insert_or_update()
  end
end
