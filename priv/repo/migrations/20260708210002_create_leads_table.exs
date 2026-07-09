defmodule CleanerCrm.Repo.Migrations.CreateLeadsTable do
  use Ecto.Migration

  def change do
    create table(:leads, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :pricing_model, :string
      add :bedroom_count, :integer
      add :bathroom_count, :integer
      add :square_feet, :integer
      add :hours, :integer
      add :frequency, :string, null: false, default: "one_time"
      add :add_ons, {:array, :string}, null: false, default: []
      add :total_cents, :integer

      add :status, :string, null: false, default: "quoted"

      add :client_name, :string
      add :client_email, :string
      add :client_phone, :string

      add :acceptance_token, :string

      add :scheduled_date, :date
      add :start_time, :time
      add :end_time, :time
      add :policy_agreed_at, :utc_datetime_usec

      add :stripe_payment_intent_id, :string

      add :client_id, references(:clients, type: :binary_id)
      add :property_id, references(:properties, type: :binary_id)
      add :job_id, references(:jobs, type: :binary_id)
      add :recurring_plan_id, references(:recurring_plans, type: :binary_id)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:leads, [:account_id])
    create unique_index(:leads, [:acceptance_token])
  end
end
