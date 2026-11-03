defmodule CleanerCrmMcp.Tools.Operations.Shape do
  @moduledoc """
  Shared helpers and presenters for the Operations tools: job and cleaner
  resolution (always through scoped context functions), date-range filtering
  and plain-map shapes.
  """

  alias CleanerCrm.{Accounts, Scheduling}
  alias CleanerCrm.TimeTracking.{Earnings, TimeEntry}
  alias CleanerCrmMcp.Present

  @default_limit 50
  @max_limit 500

  def default_limit, do: @default_limit

  @doc "Clamps an optional `limit` argument."
  def limit(nil), do: @default_limit
  def limit(n) when is_integer(n), do: n |> max(1) |> min(@max_limit)

  @doc "Resolves a job in the caller's account by job number."
  def resolve_job(scope, job_number) do
    case Scheduling.get_job_by_number(scope, job_number) do
      nil -> {:error, "No job with number #{job_number} in this account"}
      job -> {:ok, job}
    end
  end

  @doc "Ok when `cleaner_id` is a member of the caller's account."
  def ensure_cleaner(scope, cleaner_id) do
    members = Accounts.list_account_members(scope, scope.active_account_id)

    if Enum.any?(members, &(member_user_id(&1) == cleaner_id)),
      do: :ok,
      else: {:error, "No cleaner with id #{cleaner_id} in this account"}
  end

  defp member_user_id(%{user_id: id}), do: id
  defp member_user_id(%{user: %{id: id}}), do: id
  defp member_user_id(%{id: id}), do: id

  @doc "Validates that `from` is not after `to` (either may be nil)."
  def check_range(%Date{} = from, %Date{} = to) do
    if Date.compare(from, to) == :gt,
      do: {:error, "`from` must not be after `to`"},
      else: :ok
  end

  def check_range(_from, _to), do: :ok

  @doc "True when the datetime's UTC date lies within the optional inclusive range."
  def in_range?(nil, from, to), do: is_nil(from) and is_nil(to)

  def in_range?(%DateTime{} = at, from, to) do
    date = DateTime.to_date(at)

    (is_nil(from) or Date.compare(date, from) != :lt) and
      (is_nil(to) or Date.compare(date, to) != :gt)
  end

  def user(nil), do: nil
  def user(u), do: %{"id" => u.id, "name" => Map.get(u, :name), "email" => Map.get(u, :email)}

  def job_ref(nil), do: nil

  def job_ref(job) do
    Present.pick(job, [:id, :job_number, :scheduled_date, :start_time, :end_time, :status])
  end

  def hours(seconds), do: Float.round(seconds / 3600, 2)

  def time_entry(entry) do
    seconds =
      if TimeEntry.resolved?(entry), do: Earnings.worked_seconds(entry)

    %{
      "id" => entry.id,
      "job" => entry |> Map.get(:job) |> job_ref(),
      "cleaner" => entry |> Map.get(:cleaner) |> user(),
      "clocked_in_at" => Present.plain(entry.clocked_in_at),
      "clocked_out_at" => Present.plain(entry.clocked_out_at),
      "open" => is_nil(entry.clocked_out_at),
      "worked_hours" => seconds && hours(seconds)
    }
  end

  def pay_rate(nil), do: nil

  def pay_rate(rate) do
    Map.merge(
      %{"cleaner_id" => rate.cleaner_id, "basis" => Present.plain(rate.basis)},
      Present.money("rate", rate.rate_cents)
    )
  end

  def template(t) do
    %{
      "id" => t.id,
      "name" => t.name,
      "property_id" => t.property_id,
      "items" =>
        Enum.map(t.items, fn i ->
          %{"room" => i.room, "task" => i.task, "required" => i.required}
        end)
    }
  end

  def checklist_item(i) do
    %{
      "room" => i.room,
      "task" => i.task,
      "required" => i.required,
      "checked" => i.checked,
      "skipped" => i.skipped,
      "skip_reason" => i.skip_reason,
      "photos" => length(i.photos)
    }
  end

  def incident(r) do
    %{
      "id" => r.id,
      "type" => Present.plain(r.type),
      "description" => r.description,
      "filed_at" => Present.plain(r.filed_at),
      "job" => job_ref(r.job),
      "cleaner" => user(r.cleaner),
      "photo_count" => length(r.photos)
    }
  end

  def review(r) do
    %{
      "id" => r.id,
      "rating" => r.rating,
      "text" => r.text,
      "status" => Present.plain(r.status),
      "submitted_at" => Present.plain(r.submitted_at),
      "job" => job_ref(r.job),
      "client" => r.client && %{"id" => r.client.id, "name" => r.client.name},
      "cleaner" => user(r.cleaner)
    }
  end

  def notification(n) do
    %{
      "id" => n.id,
      "kind" => Present.plain(n.kind),
      "channel" => Present.plain(n.channel),
      "status" => Present.plain(n.status),
      "job_id" => n.job_id,
      "client" => n.client && %{"id" => n.client.id, "name" => n.client.name},
      "cleaner" => user(n.cleaner),
      "sent_at" => Present.plain(n.sent_at),
      "delivered_at" => Present.plain(n.delivered_at),
      "confirmed_at" => Present.plain(n.confirmed_at),
      "reschedule_requested_at" => Present.plain(n.reschedule_requested_at),
      "acknowledged_at" => Present.plain(n.acknowledged_at),
      "failure_reason" => n.failure_reason,
      "change_summary" => n.change_summary
    }
  end

  def audit_entry(e) do
    %{
      "id" => e.id,
      "at" => Present.plain(e.inserted_at),
      "action" => e.action,
      "subject_type" => e.subject_type,
      "subject_id" => e.subject_id,
      "system" => e.system,
      "actor" => user(e.actor),
      "old_value" => Present.plain(e.old_value),
      "new_value" => Present.plain(e.new_value)
    }
  end
end
