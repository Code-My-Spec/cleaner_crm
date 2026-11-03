defmodule CleanerCrm.Clients do
  @moduledoc """
  Clients and their properties: addresses, parking notes, entry
  methods and codes, pets, and cleaning preferences — the authoritative
  access and scope record every job carries.

  Every function is scoped to the caller's active account.
  """

  import Ecto.Query, warn: false

  alias CleanerCrm.Repo
  alias CleanerCrm.Users.Scope
  alias CleanerCrm.Clients.{Client, Property}
  alias CleanerCrm.Audit.Recorder

  ## Clients

  def list_clients(%Scope{active_account_id: account_id}) when not is_nil(account_id) do
    Client
    |> where([c], c.account_id == ^account_id)
    |> order_by([c], asc: c.name)
    |> Repo.all()
  end

  def get_client!(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    Client
    |> where([c], c.account_id == ^account_id)
    |> Repo.get!(id)
  end

  def create_client(%Scope{active_account_id: account_id}, attrs) when not is_nil(account_id) do
    %Client{account_id: account_id}
    |> Client.changeset(attrs)
    |> Repo.insert()
  end

  def change_client(%Scope{}, %Client{} = client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  @doc """
  Lists only active clients, for the account's day-to-day client list.
  """
  def list_active_clients(%Scope{} = scope) do
    scope |> list_clients() |> Enum.filter(& &1.active)
  end

  def update_client(%Scope{active_account_id: account_id}, %Client{} = client, attrs)
      when not is_nil(account_id) do
    client
    |> Client.changeset(attrs)
    |> Repo.update()
  end

  def deactivate_client(%Scope{} = scope, %Client{} = client) do
    update_client(scope, client, %{"active" => false})
  end

  def reactivate_client(%Scope{} = scope, %Client{} = client) do
    update_client(scope, client, %{"active" => true})
  end

  @doc """
  Permanently deletes a client and its properties.

  Refuses to delete a client that still has dependent records (e.g.
  scheduled jobs) elsewhere in the system — the database's foreign key
  constraints are the source of truth for what's "dependent," so this
  context stays ignorant of any other bounded context's schema.
  """
  def delete_client(%Scope{active_account_id: account_id}, %Client{} = client)
      when not is_nil(account_id) do
    Repo.delete(client)
  rescue
    Ecto.ConstraintError -> {:error, :has_upcoming_jobs}
  end

  ## Properties

  @doc """
  Lists a client's properties, ordered by address.
  """
  def list_properties(%Scope{active_account_id: account_id}, %Client{id: client_id})
      when not is_nil(account_id) do
    Property
    |> where([p], p.account_id == ^account_id and p.client_id == ^client_id)
    |> order_by([p], asc: p.service_address)
    |> Repo.all()
  end

  def get_property!(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    Property
    |> where([p], p.account_id == ^account_id)
    |> Repo.get!(id)
  end

  def create_property(%Scope{active_account_id: account_id} = scope, attrs)
      when not is_nil(account_id) do
    %Property{account_id: account_id}
    |> Property.changeset(attrs)
    |> validate_client_ownership(scope)
    |> Repo.insert()
  end

  @doc """
  Updates a property. When entry method, lockbox code, or alarm code
  change, records an audit entry naming the changed fields (never the
  code values themselves).
  """
  def update_property(
        %Scope{active_account_id: account_id} = scope,
        %Property{} = property,
        attrs
      )
      when not is_nil(account_id) do
    changeset =
      property
      |> Property.changeset(attrs)
      |> validate_client_ownership(scope)

    with {:ok, updated} <- Repo.update(changeset) do
      record_access_code_changes(scope, changeset, updated.id)
      {:ok, updated}
    end
  end

  def change_property(%Scope{}, %Property{} = property, attrs \\ %{}) do
    Property.changeset(property, attrs)
  end

  defp validate_client_ownership(changeset, %Scope{active_account_id: account_id}) do
    case Ecto.Changeset.get_change(changeset, :client_id) do
      nil ->
        changeset

      client_id ->
        query = where(Client, [c], c.id == ^client_id and c.account_id == ^account_id)

        if Repo.exists?(query) do
          changeset
        else
          Ecto.Changeset.add_error(changeset, :client_id, "is invalid")
        end
    end
  end

  @doc """
  Lists audit entries recorded against a property, most recent first.
  """
  def list_property_audit_entries(%Scope{} = scope, %Property{} = property) do
    Recorder.list_for_subject(scope, "Property", property.id)
  end

  defp record_access_code_changes(scope, changeset, property_id) do
    changed_fields =
      Property.access_code_fields()
      |> Enum.filter(&Ecto.Changeset.get_change(changeset, &1))
      |> Enum.map(&to_string/1)

    case changed_fields do
      [] ->
        :ok

      fields ->
        Recorder.record(scope, "access_details_updated", "Property", property_id, %{}, %{
          "changed_fields" => fields
        })
    end
  end

  ## Agent-facing lookups

  @doc """
  Searches the account's clients by name, email or phone.

  The query matches name and email case-insensitively as a substring. When it
  looks like a phone number, it is also matched against the digits of each
  stored phone, so `"(928) 598-4841"`, `"9285984841"` and `"+19285984841"` all
  find the same client.

  Options: `:active` (`true`/`false`, default: both), `:limit` (default 25,
  max 200).
  """
  def search_clients(%Scope{active_account_id: account_id}, query, opts \\ [])
      when not is_nil(account_id) do
    limit = opts |> Keyword.get(:limit, 25) |> max(1) |> min(200)
    query = String.trim(to_string(query || ""))

    base =
      Client
      |> where([c], c.account_id == ^account_id)
      |> order_by([c], asc: c.name)
      |> limit(^limit)

    base =
      case Keyword.get(opts, :active) do
        nil -> base
        active -> where(base, [c], c.active == ^active)
      end

    if query == "" do
      Repo.all(base)
    else
      like = "%" <> escape_like(query) <> "%"
      digits = phone_digits(query)

      conditions =
        if phone_like?(query) and String.length(digits) >= 3 do
          dynamic(
            [c],
            ilike(c.name, ^like) or ilike(c.email, ^like) or
              fragment(
                "regexp_replace(coalesce(?, ''), '\\D', '', 'g') LIKE ?",
                c.phone,
                ^("%" <> digits <> "%")
              )
          )
        else
          dynamic([c], ilike(c.name, ^like) or ilike(c.email, ^like) or ilike(c.phone, ^like))
        end

      base |> where(^conditions) |> Repo.all()
    end
  end

  defp phone_like?(query), do: Regex.match?(~r/^[\d\s().+\-]+$/, query)

  defp phone_digits(query) do
    digits = String.replace(query, ~r/\D/, "")

    if String.length(digits) == 11 and String.starts_with?(digits, "1"),
      do: binary_part(digits, 1, 10),
      else: digits
  end

  defp escape_like(text), do: String.replace(text, ~r/([\\%_])/, "\\\\\\1")

  @doc """
  Fetches a client in the caller's account by id: `{:ok, client}` or
  `{:error, :not_found}` (also for ids that are not valid UUIDs).
  """
  def fetch_client(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(id),
         %Client{} = client <-
           Repo.one(from c in Client, where: c.account_id == ^account_id and c.id == ^uuid) do
      {:ok, client}
    else
      _ -> {:error, :not_found}
    end
  end

  @doc """
  Fetches a property in the caller's account by id: `{:ok, property}` or
  `{:error, :not_found}` (also for ids that are not valid UUIDs).
  """
  def fetch_property(%Scope{active_account_id: account_id}, id) when not is_nil(account_id) do
    with {:ok, uuid} <- Ecto.UUID.cast(id),
         %Property{} = property <-
           Repo.one(from p in Property, where: p.account_id == ^account_id and p.id == ^uuid) do
      {:ok, property}
    else
      _ -> {:error, :not_found}
    end
  end
end
