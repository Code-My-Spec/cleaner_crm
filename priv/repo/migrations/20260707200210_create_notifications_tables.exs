defmodule CleanerCrm.Repo.Migrations.CreateNotificationsTables do
  use Ecto.Migration

  def change do
    create table(:reminder_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :lead_time_hours, :integer, null: false, default: 24

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:reminder_settings, [:account_id])

    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all)
      add :cleaner_id, references(:users, on_delete: :nilify_all)
      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false

      add :kind, :string, null: false
      add :channel, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :token, :string, null: false
      add :provider_message_id, :string
      add :failure_reason, :string
      add :change_summary, :string

      add :pushed_at, :utc_datetime_usec
      add :sent_at, :utc_datetime_usec
      add :delivered_at, :utc_datetime_usec
      add :confirmed_at, :utc_datetime_usec
      add :reschedule_requested_at, :utc_datetime_usec
      add :acknowledged_at, :utc_datetime_usec
      add :escalated_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:notifications, [:token])
    create index(:notifications, [:account_id])
    create index(:notifications, [:job_id])
    create index(:notifications, [:client_id])
    create index(:notifications, [:cleaner_id])
    create index(:notifications, [:provider_message_id])
  end
end
