defmodule CleanerCrm.Repo.Migrations.CreateReviewsTable do
  use Ecto.Migration

  def change do
    create table(:reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :job_id, references(:jobs, type: :binary_id, on_delete: :delete_all), null: false
      add :client_id, references(:clients, type: :binary_id, on_delete: :delete_all), null: false
      add :cleaner_id, references(:users, on_delete: :nilify_all)

      add :rating, :integer
      add :text, :text
      add :status, :string, null: false, default: "review_requested"
      add :token, :string, null: false
      add :review_request_sent_at, :utc_datetime_usec
      add :submitted_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:reviews, [:token])
    create unique_index(:reviews, [:job_id])
    create index(:reviews, [:account_id])
    create index(:reviews, [:client_id])
    create index(:reviews, [:cleaner_id])
  end
end
