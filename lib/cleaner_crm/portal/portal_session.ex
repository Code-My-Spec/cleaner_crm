defmodule CleanerCrm.Portal.PortalSession do
  @moduledoc """
  A magic-link access token that lets a client into their portal with
  no password account.

  The plaintext token is only ever held in memory — in the `:token`
  virtual field, right after `build_changeset/2` creates it — to be
  mailed or handed to the client; only its SHA-256 hash is persisted.
  This mirrors `CleanerCrm.Users.UserToken`'s own magic-link scheme, so
  read access to the database alone can never reconstruct a working
  token.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @hash_algorithm :sha256
  @rand_size 32
  @default_validity_in_days 7

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          token: String.t() | nil,
          token_hash: binary() | nil,
          expires_at: DateTime.t() | nil,
          last_used_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "portal_sessions" do
    field :token, :string, virtual: true
    field :token_hash, :binary
    field :expires_at, :utc_datetime_usec
    field :last_used_at, :utc_datetime_usec

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Builds a fresh session for `client`: a random plaintext token (held
  only in the returned changeset's `:token` virtual field, for the
  caller to mail or hand back) and its hash, expiring
  #{@default_validity_in_days} days out unless `attrs` gives its own
  `:expires_at`.
  """
  def build_changeset(%{id: client_id, account_id: account_id}, attrs) do
    token = generate_token()

    %__MODULE__{account_id: account_id, client_id: client_id}
    |> cast(attrs, [:expires_at, :last_used_at])
    |> put_change(:token, token)
    |> put_change(:token_hash, hash_token(token))
    |> put_default_expiry()
    |> validate_required([:account_id, :client_id, :token_hash, :expires_at])
  end

  @doc "Marks the session used just now."
  def touch_changeset(%__MODULE__{} = session) do
    change(session, last_used_at: DateTime.utc_now())
  end

  @doc "Hashes a plaintext token the same way `build_changeset/2` does, for lookup by token."
  def hash_token(token) when is_binary(token), do: :crypto.hash(@hash_algorithm, token)

  @doc "True once `expires_at` has passed."
  def expired?(%__MODULE__{expires_at: expires_at}),
    do: DateTime.compare(expires_at, DateTime.utc_now()) == :lt

  defp put_default_expiry(changeset) do
    case get_field(changeset, :expires_at) do
      nil ->
        put_change(
          changeset,
          :expires_at,
          DateTime.add(DateTime.utc_now(), @default_validity_in_days, :day)
        )

      _expires_at ->
        changeset
    end
  end

  defp generate_token,
    do: @rand_size |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
end
