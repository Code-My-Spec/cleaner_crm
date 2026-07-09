defmodule CleanerCrm.Audit do
  @moduledoc """
  Read-side of the append-only audit trail: filtered listing of the
  entries `CleanerCrm.Audit.Recorder` appends.

  Every function is scoped to the caller's active account.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Audit.AuditEntry
  alias CleanerCrm.Repo
  alias CleanerCrm.Users.Scope

  @doc """
  Lists the account's audit entries, most recent first, optionally
  narrowed by a filter map (string or atom keys):

  - `:subject_id` — exact match against the subject the entry is about
  - `:subject_type` — exact match against the subject's type (e.g. "Job")
  - `:actor_id` — exact match against the human actor who made the change
  - `:system` — when truthy, narrows to system-attributed entries
  - `:date_from` — inclusive lower bound (a `Date` or an ISO 8601 string)
  - `:date_to` — inclusive upper bound (a `Date` or an ISO 8601 string)

  A blank or absent value for any key leaves that filter off.
  """
  def list_entries(%Scope{active_account_id: account_id}, filters \\ %{})
      when not is_nil(account_id) do
    AuditEntry
    |> where([e], e.account_id == ^account_id)
    |> filter_by_subject(fetch(filters, :subject_id))
    |> filter_by_subject_type(fetch(filters, :subject_type))
    |> filter_by_actor(fetch(filters, :actor_id))
    |> filter_by_system(fetch(filters, :system))
    |> filter_by_date_from(fetch(filters, :date_from))
    |> filter_by_date_to(fetch(filters, :date_to))
    |> order_by([e], desc: e.inserted_at)
    |> preload(:actor)
    |> Repo.all()
  end

  @doc """
  Lists the distinct subject types recorded for the account, for
  populating a record-type filter.
  """
  def list_subject_types(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    AuditEntry
    |> where([e], e.account_id == ^account_id)
    |> select([e], e.subject_type)
    |> distinct(true)
    |> order_by([e], asc: e.subject_type)
    |> Repo.all()
  end

  defp fetch(filters, key), do: Map.get(filters, key) || Map.get(filters, to_string(key))

  defp filter_by_subject(query, blank) when blank in [nil, ""], do: query

  defp filter_by_subject(query, subject_id),
    do: where(query, [e], e.subject_id == ^subject_id)

  defp filter_by_subject_type(query, blank) when blank in [nil, ""], do: query

  defp filter_by_subject_type(query, subject_type),
    do: where(query, [e], e.subject_type == ^subject_type)

  defp filter_by_actor(query, blank) when blank in [nil, ""], do: query

  defp filter_by_actor(query, actor_id) when is_integer(actor_id),
    do: where(query, [e], e.actor_id == ^actor_id)

  defp filter_by_actor(query, actor_id) when is_binary(actor_id) do
    case Integer.parse(actor_id) do
      {id, ""} -> filter_by_actor(query, id)
      _ -> query
    end
  end

  defp filter_by_system(query, blank) when blank in [nil, "", false, "false"], do: query
  defp filter_by_system(query, _truthy), do: where(query, [e], e.system == true)

  defp filter_by_date_from(query, blank) when blank in [nil, ""], do: query

  defp filter_by_date_from(query, %Date{} = date),
    do: where(query, [e], e.inserted_at >= ^start_of_day(date))

  defp filter_by_date_from(query, date_string) when is_binary(date_string),
    do: filter_by_date_from(query, Date.from_iso8601!(date_string))

  defp filter_by_date_to(query, blank) when blank in [nil, ""], do: query

  defp filter_by_date_to(query, %Date{} = date),
    do: where(query, [e], e.inserted_at < ^start_of_day(Date.add(date, 1)))

  defp filter_by_date_to(query, date_string) when is_binary(date_string),
    do: filter_by_date_to(query, Date.from_iso8601!(date_string))

  defp start_of_day(date), do: DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
end
