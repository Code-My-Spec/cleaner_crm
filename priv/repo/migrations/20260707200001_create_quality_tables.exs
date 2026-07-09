defmodule CleanerCrm.Repo.Migrations.CreateQualityTables do
  use Ecto.Migration

  def change do
    create table(:checklist_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :property_id, references(:properties, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, null: false
      add :items, {:array, :map}, null: false, default: []

      timestamps(type: :utc_datetime_usec)
    end

    create index(:checklist_templates, [:account_id])
    create index(:checklist_templates, [:property_id])

    create table(:checklists, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false

      add :checklist_template_id,
          references(:checklist_templates, type: :binary_id, on_delete: :nilify_all)

      add :owner_rating, :integer
      add :quality_score, :float
      add :completed_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:checklists, [:account_id])
    create unique_index(:checklists, [:job_id])
    create index(:checklists, [:checklist_template_id])

    create table(:checklist_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :checklist_id, references(:checklists, type: :binary_id, on_delete: :delete_all),
        null: false

      add :room, :string
      add :task, :string, null: false
      add :required, :boolean, null: false, default: true
      add :checked, :boolean, null: false, default: false
      add :checked_at, :utc_datetime_usec
      add :skipped, :boolean, null: false, default: false
      add :skip_reason, :string
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime_usec)
    end

    create index(:checklist_items, [:checklist_id])

    create table(:incident_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false
      add :cleaner_id, references(:users, on_delete: :nilify_all)
      add :type, :string, null: false
      add :description, :text, null: false
      add :filed_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:incident_reports, [:account_id])
    create index(:incident_reports, [:job_id])

    # Defense in depth: incident reports are append-only. Application
    # code never exposes update/delete; these rules block it even if
    # it did.
    execute(
      "CREATE RULE incident_reports_no_update AS ON UPDATE TO incident_reports DO INSTEAD NOTHING",
      "DROP RULE IF EXISTS incident_reports_no_update ON incident_reports"
    )

    execute(
      "CREATE RULE incident_reports_no_delete AS ON DELETE TO incident_reports DO INSTEAD NOTHING",
      "DROP RULE IF EXISTS incident_reports_no_delete ON incident_reports"
    )

    create table(:photos, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :checklist_item_id,
          references(:checklist_items, type: :binary_id, on_delete: :delete_all)

      add :incident_report_id,
          references(:incident_reports, type: :binary_id, on_delete: :delete_all)

      add :kind, :string, null: false
      add :upload_state, :string, null: false, default: "pending"
      add :storage_key, :string
      add :captured_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:photos, [:account_id])
    create index(:photos, [:checklist_item_id])
    create index(:photos, [:incident_report_id])
  end
end
