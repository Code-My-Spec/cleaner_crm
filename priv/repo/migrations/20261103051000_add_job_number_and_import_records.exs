defmodule CleanerCrm.Repo.Migrations.AddJobNumberAndImportRecords do
  use Ecto.Migration

  # Job numbers are the CRM's own, human-sized references ("#1042") that get
  # quoted in texts and calls. Per account, starting at 1001. Existing jobs are
  # numbered in the order they were created.
  #
  # Import records hold everything that came from another system (Maidily ids,
  # their job numbers, raw payloads) so none of it leaks onto domain tables.
  def up do
    alter table(:jobs) do
      add :job_number, :integer
    end

    execute """
    UPDATE jobs SET job_number = numbered.n
    FROM (
      SELECT id, 1000 + row_number() OVER (PARTITION BY account_id ORDER BY inserted_at, id) AS n
      FROM jobs
    ) AS numbered
    WHERE jobs.id = numbered.id
    """

    create unique_index(:jobs, [:account_id, :job_number])

    create table(:import_records, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :source, :string, null: false
      add :kind, :string, null: false
      add :source_id, :string, null: false
      add :source_ref, :string
      add :target_id, :string
      add :raw, :map

      timestamps(type: :utc_datetime_usec)
    end

    create index(:import_records, [:account_id, :source, :kind, :source_id])
    create index(:import_records, [:account_id, :kind, :target_id])
  end

  def down do
    drop table(:import_records)
    drop index(:jobs, [:account_id, :job_number])

    alter table(:jobs) do
      remove :job_number
    end
  end
end
