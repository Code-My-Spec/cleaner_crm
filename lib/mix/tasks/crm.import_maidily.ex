defmodule Mix.Tasks.Crm.ImportMaidily do
  @shortdoc "Imports Maidily data (made by maidily_to_crm.py) into the CRM"
  @moduledoc """
  Basic importer for the files written by `bin/maidily_to_crm.py`
  (`clients.json`, `properties.json`, `cleaners.json`, `jobs.json`, `quotes.json`).

      mix crm.import_maidily DIR --account "Desert First Cleaning" --owner-email EMAIL
          [--limit N] [--only clients,properties,cleaners,jobs,quotes]

  Imports in the order clients, properties, cleaners, jobs, quotes. Every row
  also gets a `CleanerCrm.Imports` record (source "maidily") holding the
  Maidily id, the source reference (job/invoice number) and the raw row, so
  foreign ids never touch the domain tables.

  Basic by decision: no deduplication (running twice imports twice), no
  idempotency, no recurring-plan reconstruction (the `recurrence` field stays
  in the raw record only). Rows that fail are reported and skipped. Nothing is
  emailed or texted: only context functions that write rows are used, and
  cleaners get placeholder emails, not invitations.

  `--limit N` caps rows per kind.
  """

  use Mix.Task
  use Boundary, classify_to: CleanerCrm

  alias CleanerCrm.{Accounts, Clients, Imports, Repo, Scheduling, Users}
  alias CleanerCrm.Quoting.Quote
  alias CleanerCrm.Users.Scope

  @requirements ["app.start"]
  @source "maidily"
  @kinds ~w(clients properties cleaners jobs quotes)
  @max_failures 20

  @impl true
  def run(args) do
    {opts, rest, _} =
      OptionParser.parse(args,
        strict: [account: :string, owner_email: :string, limit: :integer, only: :string]
      )

    dir =
      case rest do
        [dir] -> dir
        _ -> Mix.raise(usage())
      end

    account = opts[:account] || Mix.raise(usage())
    email = opts[:owner_email] || Mix.raise(usage())

    only =
      case opts[:only] do
        nil -> @kinds
        csv -> String.split(csv, ",", trim: true) |> Enum.map(&String.trim/1)
      end

    case Enum.reject(only, &(&1 in @kinds)) do
      [] -> :ok
      bad -> Mix.raise("unknown kinds: #{Enum.join(bad, ", ")}")
    end

    result =
      run_import(dir, account: account, owner_email: email, limit: opts[:limit], only: only)

    print(result)
  end

  defp usage,
    do:
      ~s|usage: mix crm.import_maidily DIR --account "Name" --owner-email EMAIL [--limit N] [--only clients,properties,cleaners,jobs,quotes]|

  @doc """
  Runs the import. Options: `:account` (name), `:owner_email`, `:limit`, `:only`
  (list of kinds). Returns `%{scope: scope, counts: %{kind => %{ok: n, failed: n}},
  failures: [{kind, source_id, reason}]}`.
  """
  def run_import(dir, opts) do
    scope = build_scope!(Keyword.fetch!(opts, :account), Keyword.fetch!(opts, :owner_email))
    only = Keyword.get(opts, :only, @kinds)
    limit = Keyword.get(opts, :limit)

    initial = %{
      scope: scope,
      ids: %{clients: %{}, properties: %{}, cleaners: %{}},
      counts: %{},
      failures: []
    }

    state =
      Enum.reduce(@kinds, initial, fn kind, state ->
        if kind in only, do: import_kind(state, kind, load(dir, kind, limit)), else: state
      end)

    %{scope: scope, counts: state.counts, failures: Enum.reverse(state.failures)}
  end

  ## Setup

  defp build_scope!(account_name, email) do
    user =
      case Users.get_user_by_email(email) do
        nil ->
          {:ok, user} = Users.register_user(%{email: email})
          user

        user ->
          user
      end

    base = Scope.for_user(user)

    account =
      Enum.find(Accounts.list_accounts(base), &(&1.name == account_name)) ||
        case Accounts.create_account(base, %{name: account_name}) do
          {:ok, account} -> account
          {:error, cs} -> Mix.raise("could not create account: #{inspect(cs.errors)}")
        end

    %{base | active_account: account, active_account_id: account.id}
  end

  defp load(dir, kind, limit) do
    path = Path.join(dir, kind <> ".json")

    rows =
      case File.read(path) do
        {:ok, body} -> Jason.decode!(body)
        {:error, :enoent} -> []
        {:error, reason} -> Mix.raise("cannot read #{path}: #{inspect(reason)}")
      end

    if limit, do: Enum.take(rows, limit), else: rows
  end

  ## Per-kind import

  defp import_kind(state, kind, rows) do
    Enum.reduce(rows, state, fn row, state ->
      source_id = to_string(row["source_id"])

      result =
        try do
          insert(kind, row, state)
        rescue
          e -> {:error, Exception.message(e)}
        end

      case result do
        {:ok, target_id} ->
          case Imports.record(state.scope, %{
                 source: @source,
                 kind: singular(kind),
                 source_id: source_id,
                 source_ref: row["source_ref"] && to_string(row["source_ref"]),
                 target_id: target_id,
                 raw: row
               }) do
            {:ok, _} -> state |> bump(kind, :ok) |> remember(kind, source_id, target_id)
            {:error, cs} -> fail(state, kind, source_id, "import record: #{reason(cs)}")
          end

        {:error, why} ->
          fail(state, kind, source_id, reason(why))
      end
    end)
  end

  defp singular("clients"), do: "client"
  defp singular("properties"), do: "property"
  defp singular("cleaners"), do: "cleaner"
  defp singular("jobs"), do: "job"
  defp singular("quotes"), do: "quote"

  defp remember(state, kind, source_id, target_id) when kind in ~w(clients properties cleaners) do
    put_in(state, [:ids, String.to_existing_atom(kind), source_id], target_id)
  end

  defp remember(state, _kind, _source_id, _target_id), do: state

  defp bump(state, kind, key) do
    update_in(state.counts, fn counts ->
      Map.update(
        counts,
        kind,
        Map.put(%{ok: 0, failed: 0}, key, 1),
        &Map.update!(&1, key, fn n -> n + 1 end)
      )
    end)
  end

  defp fail(state, kind, source_id, why) do
    state = bump(state, kind, :failed)
    %{state | failures: [{kind, source_id, why} | state.failures]}
  end

  defp insert("clients", row, state) do
    attrs = take(row, ~w(name email phone active))

    with {:ok, client} <- Clients.create_client(state.scope, attrs), do: {:ok, client.id}
  end

  defp insert("properties", row, state) do
    case state.ids.clients[to_string(row["client_source_id"])] do
      nil ->
        {:error, "client #{row["client_source_id"]} was not imported"}

      client_id ->
        attrs =
          row |> take(~w(service_address entry_method)) |> Map.put("client_id", client_id)

        with {:ok, property} <- Clients.create_property(state.scope, attrs),
             do: {:ok, property.id}
    end
  end

  defp insert("cleaners", row, state) do
    with {:ok, user} <- Scheduling.register_cleaner(state.scope, to_string(row["name"])),
         do: {:ok, user.id}
  end

  defp insert("jobs", row, state) do
    property_id = state.ids.properties[to_string(row["client_source_id"])]
    client_id = state.ids.clients[to_string(row["client_source_id"])]

    cleaner_id =
      row["cleaner_source_id"] && state.ids.cleaners[to_string(row["cleaner_source_id"])]

    cond do
      is_nil(client_id) ->
        {:error, "client #{row["client_source_id"]} was not imported"}

      row["scheduled_date"] in [nil, ""] ->
        {:error, "no scheduled date"}

      true ->
        attrs =
          row
          |> take(~w(scheduled_date start_time end_time status agreed_price_cents))
          |> Map.merge(%{"client_id" => client_id, "property_id" => property_id})
          |> put_unless_nil("cleaner_id", cleaner_id)

        with {:ok, job} <- Scheduling.create_job(state.scope, attrs), do: {:ok, job.id}
    end
  end

  defp insert("quotes", row, state) do
    attrs =
      row
      |> take(
        ~w(client_name client_phone pricing_model bedroom_count bathroom_count total_cents status)
      )
      |> put_unless_nil("client_id", state.ids.clients[to_string(row["client_source_id"])])

    with {:ok, quote} <-
           %Quote{account_id: state.scope.active_account_id}
           |> Quote.changeset(attrs)
           |> Repo.insert(),
         do: {:ok, quote.id}
  end

  defp take(row, keys), do: row |> Map.take(keys) |> Map.reject(fn {_, v} -> is_nil(v) end)

  defp put_unless_nil(map, _key, nil), do: map
  defp put_unless_nil(map, key, value), do: Map.put(map, key, value)

  defp reason(%Ecto.Changeset{} = cs) do
    Enum.map_join(cs.errors, "; ", fn {field, {msg, _}} -> "#{field} #{msg}" end)
  end

  defp reason(other) when is_binary(other), do: other
  defp reason(other), do: inspect(other)

  ## Output

  defp print(%{counts: counts, failures: failures}) do
    Mix.shell().info("Import finished:")

    for kind <- @kinds, c = counts[kind] do
      Mix.shell().info("  #{String.pad_trailing(kind, 11)} imported #{c.ok}, failed #{c.failed}")
    end

    if failures != [] do
      Mix.shell().info(
        "First failures (#{min(length(failures), @max_failures)} of #{length(failures)}):"
      )

      for {kind, source_id, why} <- Enum.take(failures, @max_failures) do
        Mix.shell().info("  #{kind} #{source_id}: #{why}")
      end
    end
  end
end
