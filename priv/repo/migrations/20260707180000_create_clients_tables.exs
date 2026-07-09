defmodule CleanerCrm.Repo.Migrations.CreateClientsTables do
  use Ecto.Migration

  def change do
    create table(:clients, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :active, :boolean, null: false, default: true
      add :card_on_file, :boolean, null: false, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:clients, [:account_id])

    create table(:properties, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false
      add :service_address, :string, null: false
      add :entry_method, :string
      add :lockbox_code, :binary
      add :alarm_code, :binary
      add :parking_notes, :text
      add :pet_notes, :text
      add :emergency_contact_name, :string
      add :emergency_contact_phone, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:properties, [:account_id])
    create index(:properties, [:client_id])
  end
end
