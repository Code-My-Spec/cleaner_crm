defmodule CleanerCrm.Imports do
  @moduledoc """
  Bookkeeping for data imported from other systems (Maidily first).

  The importer writes one `ImportRecord` per imported row: where it came from
  (`source`, `kind`, `source_id`, `source_ref`), the raw payload, and which CRM
  record it became (`target_id`). Domain models never carry foreign ids; ask
  this context instead, e.g. "which CRM job was Maidily job 20260520-77058?".
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Imports.ImportRecord
  alias CleanerCrm.Repo
  alias CleanerCrm.Users.Scope

  @doc "Records one imported row for the scope's account."
  def record(%Scope{active_account_id: account_id}, attrs) when not is_nil(account_id) do
    %ImportRecord{account_id: account_id}
    |> ImportRecord.changeset(stringify_ids(attrs))
    |> Repo.insert()
  end

  @doc """
  Lists import records. Filters: `:source`, `:kind`, `:source_id`,
  `:source_ref`, `:target_id`, `:limit` (default 100).
  """
  def list_records(%Scope{active_account_id: account_id}, filters \\ [])
      when not is_nil(account_id) do
    filters = Map.new(filters)

    ImportRecord
    |> where([r], r.account_id == ^account_id)
    |> filter(:source, filters[:source])
    |> filter(:kind, filters[:kind])
    |> filter(:source_id, filters[:source_id] && to_string(filters[:source_id]))
    |> filter(:source_ref, filters[:source_ref])
    |> filter(:target_id, filters[:target_id] && to_string(filters[:target_id]))
    |> order_by([r], desc: r.inserted_at)
    |> limit(^Map.get(filters, :limit, 100))
    |> Repo.all()
  end

  @doc "The CRM id a source row became, or nil."
  def target_id(%Scope{} = scope, source, kind, source_id) do
    case list_records(scope, source: source, kind: kind, source_id: source_id, limit: 1) do
      [%ImportRecord{target_id: target_id}] -> target_id
      [] -> nil
    end
  end

  @doc """
  Finds import records by kind and source id and/or source ref. Returns a list
  (a source ref such as a job number may match more than one row).
  """
  def find_records(%Scope{} = scope, kind, filters \\ []) do
    filters = Map.new(filters)

    list_records(scope,
      source: filters[:source] || "maidily",
      kind: kind,
      source_id: filters[:source_id],
      source_ref: filters[:source_ref],
      limit: Map.get(filters, :limit, 20)
    )
  end

  defp filter(query, _field, nil), do: query
  defp filter(query, field, value), do: where(query, [r], field(r, ^field) == ^value)

  defp stringify_ids(attrs) do
    attrs
    |> Map.new()
    |> Map.update(:source_id, nil, &to_string_or_nil/1)
    |> Map.update(:target_id, nil, &to_string_or_nil/1)
  end

  defp to_string_or_nil(nil), do: nil
  defp to_string_or_nil(value), do: to_string(value)
end
