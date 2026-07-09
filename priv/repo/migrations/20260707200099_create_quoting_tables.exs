defmodule CleanerCrm.Repo.Migrations.CreateQuotingTables do
  use Ecto.Migration

  def change do
    create table(:rate_cards, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :per_room_bedroom_rate_cents, :integer
      add :per_room_bathroom_rate_cents, :integer
      add :per_sqft_rate_cents, :integer
      add :hourly_rate_cents, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:rate_cards, [:account_id])

    create table(:quotes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :client_id, references(:clients, type: :binary_id)
      add :client_name, :string
      add :client_phone, :string
      add :pricing_model, :string, null: false
      add :bedroom_count, :integer
      add :bathroom_count, :integer
      add :square_feet, :integer
      add :hours, :integer
      add :status, :string, null: false, default: "draft"
      add :total_cents, :integer, null: false, default: 0
      add :sent_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:quotes, [:account_id])
    create index(:quotes, [:client_id])

    create table(:quote_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quote_id, references(:quotes, type: :binary_id, on_delete: :delete_all), null: false
      add :description, :string, null: false
      add :quantity, :integer, null: false
      add :rate_cents, :integer, null: false
      add :amount_cents, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:quote_items, [:quote_id])
  end
end
