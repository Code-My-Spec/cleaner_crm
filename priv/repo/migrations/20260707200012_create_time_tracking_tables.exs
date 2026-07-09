defmodule CleanerCrm.Repo.Migrations.CreateTimeTrackingTables do
  use Ecto.Migration

  def change do
    create table(:time_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false
      add :cleaner_id, references(:users, on_delete: :nilify_all)

      add :clocked_in_at, :utc_datetime_usec, null: false
      add :clocked_out_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:time_entries, [:account_id])
    create index(:time_entries, [:job_id])
    create index(:time_entries, [:cleaner_id, :clocked_out_at])

    create table(:pay_rates, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :cleaner_id, references(:users, on_delete: :delete_all), null: false

      add :basis, :string, null: false
      add :rate_cents, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:pay_rates, [:account_id, :cleaner_id])
  end
end
