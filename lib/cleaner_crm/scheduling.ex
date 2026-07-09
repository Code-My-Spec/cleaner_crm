defmodule CleanerCrm.Scheduling do
  @moduledoc """
  Recurring plans and the jobs they generate, cleaner time-off, and
  conflict-aware assignment.

  Every function is scoped to the caller's active account.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Accounts
  alias CleanerCrm.Audit.Recorder
  alias CleanerCrm.Clients.Property
  alias CleanerCrm.Repo

  alias CleanerCrm.Scheduling.{
    AvailabilityBlock,
    ConflictDetector,
    Job,
    Recurrence,
    RecurringPlan
  }

  alias CleanerCrm.Users.Scope
  alias CleanerCrm.Users.User

  ## Jobs

  def get_job!(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    Job
    |> where([j], j.account_id == ^account_id)
    |> preload([:cleaner, :property, :client])
    |> Repo.get!(id)
  end

  def change_job(%Scope{}, %Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end

  @doc """
  Creates a job. Recorded in the audit trail as authored by the
  caller, unless `actor: :system` is passed — used when the job is one
  occurrence materialized from a recurring plan rather than a job a
  human directly asked for (see `create_recurring_plan/2`).
  """
  def create_job(%Scope{active_account_id: account_id} = scope, attrs, opts \\ [])
      when not is_nil(account_id) do
    with {:ok, job} <-
           %Job{account_id: account_id}
           |> Job.changeset(derive_client_id(account_id, attrs))
           |> Repo.insert() do
      record_job_created(scope, job, Keyword.get(opts, :actor, :user))
      {:ok, job}
    end
  end

  # The board's own job form (and a recurring plan's own materialized
  # occurrences, via `Recurrence.job_attrs/1`) only ever carry a
  # `property_id` — never a `client_id` — so a job created either way
  # otherwise saves with `client_id: nil`. That breaks anything reading
  # the client straight off the job rather than through its property
  # (story 836's invoicing does both a card-on-file charge lookup and
  # the invoice's own client label this way), so every job creation
  # backfills `client_id` from its property here rather than requiring
  # every caller to remember to. A caller that already supplies a
  # `client_id` (fixtures with only a client on hand, no property) is
  # left alone.
  defp derive_client_id(account_id, attrs) do
    if blank?(fetch_attr(attrs, :client_id)) do
      case fetch_attr(attrs, :property_id) do
        value when value in [nil, ""] -> attrs
        property_id -> put_client_id_from_property(attrs, account_id, property_id)
      end
    else
      attrs
    end
  end

  defp put_client_id_from_property(attrs, account_id, property_id) do
    case Repo.get_by(Property, id: property_id, account_id: account_id) do
      %Property{client_id: client_id} when not is_nil(client_id) ->
        # Match whichever key style (atom or string) `attrs` already
        # uses — `Ecto.Changeset.cast/4` raises on a map mixing both.
        if Map.has_key?(attrs, :property_id) do
          Map.put(attrs, :client_id, client_id)
        else
          Map.put(attrs, "client_id", client_id)
        end

      _ ->
        attrs
    end
  end

  defp fetch_attr(attrs, key), do: Map.get(attrs, key) || Map.get(attrs, to_string(key))

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_value), do: false

  defp record_job_created(scope, job, :system) do
    Recorder.record_system(scope, "job_created", "Job", job.id, %{}, job_created_values(job))
  end

  defp record_job_created(scope, job, :user) do
    Recorder.record(scope, "job_created", "Job", job.id, %{}, job_created_values(job))
  end

  # Deliberately omits `scheduled_date`: a "created" entry's own
  # subject label (job → property/client) is enough to identify which
  # job this is, and surfacing it here would read as a schedule change
  # (`field_changes/1`'s "Scheduled date: ..." line) indistinguishable
  # from an actual reschedule recorded later by `update_job/3`.
  defp job_created_values(job) do
    %{"cleaner_id" => job.cleaner_id}
  end

  @doc """
  Lists every job scheduled between `week_start` and six days later,
  cleaner/property/client preloaded, ordered for the board.
  """
  def list_jobs_for_week(%Scope{active_account_id: account_id}, %Date{} = week_start)
      when not is_nil(account_id) do
    week_end = Date.add(week_start, 6)

    Job
    |> where(
      [j],
      j.account_id == ^account_id and j.scheduled_date >= ^week_start and
        j.scheduled_date <= ^week_end and j.status != :cancelled
    )
    |> order_by([j], asc: j.scheduled_date, asc: j.start_time)
    |> preload([:cleaner, :property, :client])
    |> Repo.all()
  end

  @doc """
  Lists every non-cancelled job for the account, cleaner/property/client
  preloaded, ordered for the board. Unlike `list_jobs_for_week/2`, this
  isn't bounded to a single week — a recurring plan's series can span
  months, and the board needs to account for all of it at a glance.

  `:include_cancelled_ids` (default `[]`) admits specific cancelled
  jobs back in anyway — the board's own escape hatch for a cancelled
  job that still carries an unacknowledged schedule-change
  notification (story 843): the office needs to keep seeing its
  ack-status until the cleaner acknowledges, and the escalation check
  needs the job rendered at all to ever run. Other callers passing no
  opts see the same non-cancelled set as before.
  """
  def list_jobs(%Scope{active_account_id: account_id}, opts \\ [])
      when not is_nil(account_id) do
    include_cancelled_ids = Keyword.get(opts, :include_cancelled_ids, [])

    Job
    |> where(
      [j],
      j.account_id == ^account_id and
        (j.status != :cancelled or j.id in ^include_cancelled_ids)
    )
    |> order_by([j], asc: j.scheduled_date, asc: j.start_time)
    |> preload([:cleaner, :property, :client])
    |> Repo.all()
  end

  @doc """
  Assigns (or reassigns) a job to a cleaner, rejecting the move with
  `{:error, :unavailable}` or `{:error, :overlap}` when it conflicts
  with that cleaner's time off or an existing booking. A `nil`
  `cleaner_id` always succeeds (unassigning never conflicts).
  """
  def assign_cleaner(%Scope{active_account_id: account_id} = scope, %Job{} = job, cleaner_id)
      when not is_nil(account_id) do
    with :ok <-
           ConflictDetector.check_assignment(
             scope,
             cleaner_id,
             job.scheduled_date,
             job.start_time,
             job.end_time,
             exclude_job_id: job.id
           ),
         {:ok, updated} <- job |> Job.changeset(%{cleaner_id: cleaner_id}) |> Repo.update() do
      Recorder.record(
        scope,
        "job_reassigned",
        "Job",
        updated.id,
        %{"cleaner_id" => job.cleaner_id},
        %{"cleaner_id" => cleaner_id}
      )

      {:ok, updated}
    end
  end

  def cancel_job(%Scope{active_account_id: account_id} = scope, %Job{} = job)
      when not is_nil(account_id) do
    with {:ok, updated} <- job |> Job.changeset(%{status: :cancelled}) |> Repo.update() do
      Recorder.record(
        scope,
        "job_cancelled",
        "Job",
        updated.id,
        %{"status" => to_string(job.status)},
        %{"status" => "cancelled"}
      )

      {:ok, updated}
    end
  end

  @doc """
  Updates a job's schedule and/or price — a reschedule, a price
  change, or both, made directly from the board rather than through
  `assign_cleaner/3`'s conflict-checked path. Records only the fields
  that actually changed to the audit trail, attributed to the caller.
  """
  def update_job(%Scope{active_account_id: account_id} = scope, %Job{} = job, attrs)
      when not is_nil(account_id) do
    changeset = Job.changeset(job, derive_client_id(account_id, attrs))

    with {:ok, updated} <- Repo.update(changeset) do
      record_job_updated(scope, job, changeset, updated)
      {:ok, updated}
    end
  end

  @audited_update_fields ~w(scheduled_date start_time end_time agreed_price_cents status)a

  defp record_job_updated(scope, job, changeset, updated) do
    changed_fields =
      changeset.changes
      |> Map.keys()
      |> Enum.filter(&(&1 in @audited_update_fields))

    if changed_fields != [] do
      Recorder.record(
        scope,
        update_action(changed_fields),
        "Job",
        updated.id,
        audit_snapshot(job, changed_fields),
        audit_snapshot(updated, changed_fields)
      )
    end
  end

  defp update_action(changed_fields) do
    cond do
      Enum.any?(changed_fields, &(&1 in [:scheduled_date, :start_time, :end_time])) ->
        "job_rescheduled"

      :agreed_price_cents in changed_fields ->
        "job_price_changed"

      true ->
        "job_updated"
    end
  end

  defp audit_snapshot(job, fields),
    do: Map.new(fields, &{to_string(&1), audit_value(Map.get(job, &1))})

  defp audit_value(%Date{} = value), do: to_string(value)
  defp audit_value(%Time{} = value), do: to_string(value)
  defp audit_value(value), do: value

  @doc """
  Removes a job from the board without hard-deleting its row — the
  row (and any audit entries already about it) stays resolvable for
  the trail. Distinct from `cancel_job/2`: this is the office
  correcting a mistaken entry rather than calling off an appointment,
  so it's recorded as "deleted" rather than "cancelled" and never
  notifies the assigned cleaner.
  """
  def delete_job(%Scope{active_account_id: account_id} = scope, %Job{} = job)
      when not is_nil(account_id) do
    with {:ok, updated} <- job |> Job.changeset(%{status: :cancelled}) |> Repo.update() do
      Recorder.record(
        scope,
        "job_deleted",
        "Job",
        updated.id,
        %{"status" => to_string(job.status)},
        %{"status" => "cancelled"}
      )

      {:ok, updated}
    end
  end

  @doc """
  Whether the account has no non-cancelled job overlapping this exact
  date/time window, regardless of cleaner assignment.

  This is the coarser, single-crew-capacity check the public booking
  funnel (`CleanerCrm.Booking`) needs before confirming a slot — as
  opposed to `assign_cleaner/3`'s `ConflictDetector`, which is scoped
  to one specific cleaner's own calendar and never conflicts with an
  unassigned job.
  """
  def slot_available?(%Scope{active_account_id: account_id}, %Date{} = date, start_time, end_time)
      when not is_nil(account_id) do
    Job
    |> where(
      [j],
      j.account_id == ^account_id and j.scheduled_date == ^date and j.status != :cancelled
    )
    |> Repo.all()
    |> Enum.all?(&(not overlaps?(&1.start_time, &1.end_time, start_time, end_time)))
  end

  defp overlaps?(start_a, end_a, start_b, end_b) do
    Time.compare(start_a, end_b) == :lt and Time.compare(start_b, end_a) == :lt
  end

  ## Recurring plans

  def get_recurring_plan!(%Scope{active_account_id: account_id}, id)
      when not is_nil(account_id) do
    RecurringPlan
    |> where([p], p.account_id == ^account_id)
    |> preload([:property, :cleaner])
    |> Repo.get!(id)
  end

  def change_recurring_plan(%Scope{}, %RecurringPlan{} = plan, attrs \\ %{}) do
    RecurringPlan.preview_changeset(plan, attrs)
  end

  @doc """
  Runs conflict detection for a (possibly unsaved) plan's full series
  against its preferred cleaner, without persisting anything. Returns
  only the conflicting occurrences, as `[%{index:, date:, reason:}]`.
  """
  def preview_conflicts(scope, %RecurringPlan{} = plan) do
    ConflictDetector.check_occurrences(scope, plan, Recurrence.occurrences(plan))
  end

  @doc """
  Saves a recurring plan and materializes its full series of jobs.
  Conflicting occurrences are still created and still assigned to the
  preferred cleaner — conflicts are for the owner to review and
  resolve, never a silent block on saving.
  """
  def create_recurring_plan(%Scope{active_account_id: account_id} = scope, attrs)
      when not is_nil(account_id) do
    Repo.transact(fn ->
      with {:ok, plan} <-
             %RecurringPlan{account_id: account_id}
             |> RecurringPlan.changeset(attrs)
             |> Repo.insert() do
        jobs =
          plan
          |> Recurrence.job_attrs()
          |> Enum.map(fn job_attrs ->
            {:ok, job} = create_job(scope, job_attrs, actor: :system)
            job
          end)

        {:ok, {plan, jobs}}
      end
    end)
  end

  ## Availability blocks

  def change_availability_block(%Scope{}, %AvailabilityBlock{} = block, attrs \\ %{}) do
    AvailabilityBlock.changeset(block, attrs)
  end

  def create_availability_block(%Scope{active_account_id: account_id}, attrs)
      when not is_nil(account_id) do
    %AvailabilityBlock{account_id: account_id}
    |> AvailabilityBlock.changeset(attrs)
    |> Repo.insert()
  end

  ## Cleaners (account members who take jobs)

  @doc """
  Lists the account's members as candidate cleaners for the board and
  assignment pickers.
  """
  def list_cleaners(%Scope{active_account_id: account_id} = scope) when not is_nil(account_id) do
    scope
    |> Accounts.list_account_members(account_id)
    |> Enum.map(& &1.user)
  end

  @doc """
  Registers a new cleaner: a user identified by display name (rather
  than login credentials) added to the account as a member, so jobs
  and availability can be assigned to them. There is no login flow for
  a cleaner created this way — see `CleanerCrmSpex.Fixtures.cleaner_fixture/3`
  for the (real, login-capable) path other stories seed cleaners
  through.
  """
  def register_cleaner(%Scope{active_account_id: account_id} = scope, name)
      when not is_nil(account_id) and is_binary(name) do
    with {:ok, user} <- insert_cleaner_user(name),
         {:ok, _member} <- Accounts.add_user_to_account(scope, user.id, account_id, :member) do
      {:ok, user}
    end
  end

  @doc """
  Fetches a single cleaner by id, for their detail page. Draws from
  the same membership list as `list_cleaners/1`, so a user who isn't
  a member of this account can't be looked up here either. Raises if
  not found.
  """
  def get_cleaner!(%Scope{} = scope, id) do
    cleaner_id = parse_cleaner_id(id)

    scope
    |> list_cleaners()
    |> Enum.find(&(&1.id == cleaner_id))
    |> case do
      nil -> raise Ecto.NoResultsError, queryable: User
      cleaner -> cleaner
    end
  end

  @doc """
  Lists a cleaner's time-off blocks for their detail page, soonest
  first.
  """
  def list_availability_blocks(%Scope{active_account_id: account_id}, cleaner_id)
      when not is_nil(account_id) do
    cleaner_id = parse_cleaner_id(cleaner_id)

    AvailabilityBlock
    |> where([b], b.account_id == ^account_id and b.cleaner_id == ^cleaner_id)
    |> order_by([b], asc: b.date)
    |> Repo.all()
  end

  @doc """
  Lists a cleaner's upcoming (today or later, non-cancelled) jobs for
  their detail page, soonest first.
  """
  def list_upcoming_jobs_for_cleaner(%Scope{active_account_id: account_id}, cleaner_id)
      when not is_nil(account_id) do
    cleaner_id = parse_cleaner_id(cleaner_id)

    Job
    |> where(
      [j],
      j.account_id == ^account_id and j.cleaner_id == ^cleaner_id and
        j.status != :cancelled and j.scheduled_date >= ^Date.utc_today()
    )
    |> order_by([j], asc: j.scheduled_date, asc: j.start_time)
    |> preload([:property, :client])
    |> Repo.all()
  end

  defp parse_cleaner_id(id) when is_integer(id), do: id
  defp parse_cleaner_id(id) when is_binary(id), do: String.to_integer(id)

  defp insert_cleaner_user(name) do
    %User{}
    |> Ecto.Changeset.cast(%{name: name, email: placeholder_email(name)}, [:name, :email])
    |> Ecto.Changeset.validate_required([:name, :email])
    |> Repo.insert()
  end

  defp placeholder_email(name) do
    slug =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, ".")
      |> String.trim(".")

    "#{slug}-#{System.unique_integer([:positive])}@cleaners.local"
  end

  ## Cancellation policy (story 851)

  @doc """
  Sets the account's reschedule/cancel policy. A thin delegate onto
  `CleanerCrm.Portal`, which actually owns `CancellationPolicy` (the
  client portal's own reschedule/cancel enforcement is what reads it
  back) — kept reachable here too since "the account's scheduling
  policy" is naturally where a caller that doesn't otherwise need to
  know about the portal would look for it.
  """
  defdelegate set_cancellation_policy(scope, attrs), to: CleanerCrm.Portal
end
