defmodule CleanerCrm.Repo.Migrations.CreateSchedulingTables do
  use Ecto.Migration

  def change do
    create table(:recurring_plans, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :property_id, references(:properties, type: :binary_id, on_delete: :delete_all),
        null: false

      add :cleaner_id, references(:users, on_delete: :nilify_all)
      add :recurrence, :string, null: false
      add :start_date, :date, null: false
      add :occurrence_count, :integer
      add :start_time, :time, null: false, default: fragment("'09:00:00'")
      add :end_time, :time, null: false, default: fragment("'11:00:00'")

      timestamps(type: :utc_datetime_usec)
    end

    create index(:recurring_plans, [:account_id])
    create index(:recurring_plans, [:property_id])
    create index(:recurring_plans, [:cleaner_id])

    create table(:jobs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :client_id, references(:clients, type: :binary_id)
      add :property_id, references(:properties, type: :binary_id)
      add :cleaner_id, references(:users, on_delete: :nilify_all)

      add :recurring_plan_id,
          references(:recurring_plans, type: :binary_id, on_delete: :nilify_all)

      add :scheduled_date, :date, null: false
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :status, :string, null: false, default: "scheduled"
      add :agreed_price_cents, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:jobs, [:account_id])
    create index(:jobs, [:client_id])
    create index(:jobs, [:property_id])
    create index(:jobs, [:cleaner_id])
    create index(:jobs, [:recurring_plan_id])
    create index(:jobs, [:cleaner_id, :scheduled_date])

    create table(:availability_blocks, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :cleaner_id, references(:users, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :all_day, :boolean, null: false, default: false
      add :start_time, :time
      add :end_time, :time

      timestamps(type: :utc_datetime_usec)
    end

    create index(:availability_blocks, [:account_id])
    create index(:availability_blocks, [:cleaner_id, :date])
  end
end
