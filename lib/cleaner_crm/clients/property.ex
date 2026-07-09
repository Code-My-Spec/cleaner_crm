defmodule CleanerCrm.Clients.Property do
  @moduledoc """
  A serviced location with address, parking, pet, and access-detail
  notes (entry method, lockbox/alarm codes, emergency contact).

  Every property belongs to exactly one client. Lockbox and alarm
  codes are stored encrypted at rest — see `CleanerCrm.Encrypted.Binary`.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias CleanerCrm.Encrypted

  @access_detail_fields ~w(entry_method lockbox_code alarm_code parking_notes pet_notes
                            emergency_contact_name emergency_contact_phone)a

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          account_id: Ecto.UUID.t() | nil,
          client_id: Ecto.UUID.t() | nil,
          service_address: String.t() | nil,
          entry_method: String.t() | nil,
          lockbox_code: String.t() | nil,
          alarm_code: String.t() | nil,
          parking_notes: String.t() | nil,
          pet_notes: String.t() | nil,
          client_preferences: String.t() | nil,
          emergency_contact_name: String.t() | nil,
          emergency_contact_phone: String.t() | nil,
          client: CleanerCrm.Clients.Client.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "properties" do
    field :service_address, :string
    field :entry_method, :string
    field :lockbox_code, Encrypted.Binary
    field :alarm_code, Encrypted.Binary
    field :parking_notes, :string
    field :pet_notes, :string
    field :client_preferences, :string
    field :emergency_contact_name, :string
    field :emergency_contact_phone, :string

    belongs_to :account, CleanerCrm.Accounts.Account, type: :binary_id
    belongs_to :client, CleanerCrm.Clients.Client, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Fields whose changes are sensitive enough to warrant an audit entry
  when updated (see `CleanerCrm.Clients.update_property/3`).
  """
  def access_code_fields, do: ~w(entry_method lockbox_code alarm_code)a

  def changeset(property, attrs) do
    property
    |> cast(blank_client_id_to_nil(attrs), [
      :client_id,
      :service_address,
      :client_preferences | @access_detail_fields
    ])
    |> validate_required([:client_id, :service_address], message: "is required")
    |> assoc_constraint(:client)
  end

  defp blank_client_id_to_nil(%{"client_id" => ""} = attrs), do: %{attrs | "client_id" => nil}
  defp blank_client_id_to_nil(attrs), do: attrs
end
