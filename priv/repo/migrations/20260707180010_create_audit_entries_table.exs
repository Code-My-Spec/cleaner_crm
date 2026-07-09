defmodule CleanerCrm.Repo.Migrations.CreateAuditEntriesTable do
  use Ecto.Migration

  def change do
    create table(:audit_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :actor_id, references(:users, on_delete: :nilify_all)
      add :system, :boolean, null: false, default: false
      add :action, :string, null: false
      add :subject_type, :string, null: false
      add :subject_id, :binary_id, null: false
      add :old_value, :map, null: false, default: %{}
      add :new_value, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:audit_entries, [:account_id])
    create index(:audit_entries, [:subject_type, :subject_id])

    # Defense in depth: audit entries are append-only. Application code
    # never exposes update/delete; these rules block it even if it did.
    execute(
      "CREATE RULE audit_entries_no_update AS ON UPDATE TO audit_entries DO INSTEAD NOTHING",
      "DROP RULE IF EXISTS audit_entries_no_update ON audit_entries"
    )

    execute(
      "CREATE RULE audit_entries_no_delete AS ON DELETE TO audit_entries DO INSTEAD NOTHING",
      "DROP RULE IF EXISTS audit_entries_no_delete ON audit_entries"
    )
  end
end
