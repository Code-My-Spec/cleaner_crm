defmodule CleanerCrmMcp.Tools.Scheduling.Shape do
  @moduledoc """
  Shared presenters and lookups for the scheduling tools, so every tool
  returns jobs, cleaners, plans and blocks in the same shape.
  """

  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.{AvailabilityBlock, Job, RecurringPlan}
  alias CleanerCrm.Users.User
  alias CleanerCrmMcp.Present

  @statuses ~w(scheduled in_progress completed cancelled)

  @doc "A job: number, id, window, status, price, client, property, cleaner (or nil), plan id."
  def job(%Job{} = job) do
    client = loaded(job.client) || property_client(job.property)

    %{
      "job_number" => job.job_number,
      "id" => job.id,
      "date" => Present.plain(job.scheduled_date),
      "start_time" => Present.plain(job.start_time),
      "end_time" => Present.plain(job.end_time),
      "status" => Present.plain(job.status),
      "client" => client && %{"id" => client.id, "name" => client.name, "phone" => client.phone},
      "property" => property(loaded(job.property)),
      "cleaner" => cleaner_ref(loaded(job.cleaner)),
      "recurring_plan_id" => job.recurring_plan_id
    }
    |> Map.merge(Present.money("price", job.agreed_price_cents))
  end

  @doc "A cleaner: id and name."
  def cleaner(%User{} = user), do: %{"id" => user.id, "name" => user.name}

  @doc "A recurring plan, with its property and preferred cleaner."
  def plan(%RecurringPlan{} = plan) do
    %{
      "id" => plan.id,
      "recurrence" => Present.plain(plan.recurrence),
      "start_date" => Present.plain(plan.start_date),
      "occurrence_count" => plan.occurrence_count,
      "start_time" => Present.plain(plan.start_time),
      "end_time" => Present.plain(plan.end_time),
      "property" => property(loaded(plan.property)),
      "cleaner" => cleaner_ref(loaded(plan.cleaner))
    }
    |> Map.merge(Present.money("price", plan.agreed_price_cents))
  end

  @doc "A time-off block."
  def block(%AvailabilityBlock{} = b) do
    %{
      "id" => b.id,
      "cleaner_id" => b.cleaner_id,
      "date" => Present.plain(b.date),
      "all_day" => b.all_day,
      "start_time" => Present.plain(b.start_time),
      "end_time" => Present.plain(b.end_time)
    }
  end

  @doc "Params that identify a job: job_number or id."
  def job_ref_params do
    [
      %{
        name: "job_number",
        type: :integer,
        required: false,
        description: "The job's number, e.g. 1042 (or \"#1042\")"
      },
      %{
        name: "id",
        type: :string,
        required: false,
        description: "The job's id (alternative to job_number)"
      }
    ]
  end

  @doc "Params describing a recurring plan."
  def plan_params do
    [
      %{
        name: "property_id",
        type: :string,
        required: true,
        description: "Property id the plan cleans"
      },
      %{
        name: "recurrence",
        type: :string,
        required: true,
        description: "weekly | biweekly | every_3_weeks | monthly (monthly = every 28 days)"
      },
      %{
        name: "start_date",
        type: :date,
        required: true,
        description: "First visit date, YYYY-MM-DD"
      },
      %{
        name: "occurrence_count",
        type: :integer,
        required: true,
        description: "Number of visits in the series (> 0)"
      },
      %{
        name: "start_time",
        type: :time,
        required: false,
        description: "Visit start, default 09:00"
      },
      %{name: "end_time", type: :time, required: false, description: "Visit end, default 11:00"},
      %{name: "price", type: :number, required: false, description: "Price per visit in dollars"},
      %{
        name: "cleaner_id",
        type: :integer,
        required: false,
        description: "Preferred cleaner; visits are assigned to them"
      }
    ]
  end

  @doc "Plan attrs from coerced args (cleaner already validated by the caller)."
  def plan_attrs(args) do
    %{
      property_id: args["property_id"],
      recurrence: args["recurrence"],
      start_date: args["start_date"],
      occurrence_count: args["occurrence_count"],
      cleaner_id: args["cleaner_id"]
    }
    |> put_unless_nil(:start_time, args["start_time"])
    |> put_unless_nil(:end_time, args["end_time"])
    |> put_unless_nil(:agreed_price_cents, CleanerCrmMcp.Args.to_cents(args["price"]))
  end

  defp put_unless_nil(map, _key, nil), do: map
  defp put_unless_nil(map, key, value), do: Map.put(map, key, value)

  @doc "Valid status strings."
  def statuses, do: @statuses

  @doc "Finds a job by `job_number` or `id` args."
  def find_job(scope, args) do
    cond do
      n = args["job_number"] ->
        case Scheduling.get_job_by_number(scope, n) do
          nil -> {:error, "no job with job_number #{n}"}
          job -> {:ok, job}
        end

      id = args["id"] ->
        case Scheduling.fetch_job(scope, id) do
          nil -> {:error, "no job with id #{id}"}
          job -> {:ok, job}
        end

      true ->
        {:error, "give job_number or id"}
    end
  end

  @doc "Reloads a job with associations preloaded, as a presented map."
  def reload_job(scope, %Job{id: id}), do: job(Scheduling.fetch_job(scope, id))

  @doc "A cleaner of this account by integer id."
  def find_cleaner(scope, id) do
    case Scheduling.fetch_cleaner(scope, id) do
      nil -> {:error, "no cleaner with id #{id} in this account"}
      user -> {:ok, user}
    end
  end

  @doc "A property of this account by id."
  def find_property(scope, id) do
    case Scheduling.fetch_property(scope, id) do
      nil -> {:error, "no property with id #{id}"}
      prop -> {:ok, prop}
    end
  end

  @doc "Like `find_cleaner/2` but passes `nil` through."
  def maybe_cleaner(_scope, nil), do: {:ok, nil}
  def maybe_cleaner(scope, id), do: find_cleaner(scope, id)

  @doc "Maps context assignment errors to messages."
  def error(:unavailable), do: "the cleaner has time off covering that slot"
  def error(:overlap), do: "the cleaner already has another job overlapping that time"
  def error(other), do: other

  defp property(nil), do: nil
  defp property(p), do: %{"id" => p.id, "address" => p.service_address}

  defp cleaner_ref(nil), do: nil
  defp cleaner_ref(u), do: cleaner(u)

  defp property_client(%{client: %CleanerCrm.Clients.Client{} = c}), do: c
  defp property_client(_), do: nil

  defp loaded(%Ecto.Association.NotLoaded{}), do: nil
  defp loaded(other), do: other
end
