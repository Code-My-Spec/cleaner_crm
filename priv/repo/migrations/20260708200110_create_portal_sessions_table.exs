defmodule CleanerCrm.Repo.Migrations.CreatePortalSessionsTable do
  use Ecto.Migration

  def change do
    create table(:portal_sessions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false

      add :token_hash, :binary, null: false
      add :expires_at, :utc_datetime_usec, null: false
      add :last_used_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:portal_sessions, [:token_hash])
    create index(:portal_sessions, [:account_id])
    create index(:portal_sessions, [:client_id])
  end
end
