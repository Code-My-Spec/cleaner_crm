defmodule CleanerCrm.Repo.Migrations.CreateBillingTables do
  use Ecto.Migration

  def change do
    create table(:invoices, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :job_id, references(:jobs, type: :binary_id, on_delete: :restrict), null: false
      add :amount_cents, :integer, null: false
      add :status, :string, null: false, default: "unpaid"
      add :stripe_payment_intent_id, :string
      add :payment_token, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:invoices, [:account_id])
    create index(:invoices, [:job_id])
    create unique_index(:invoices, [:payment_token])
    create index(:invoices, [:stripe_payment_intent_id])

    create table(:payments, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :invoice_id, references(:invoices, type: :binary_id, on_delete: :delete_all),
        null: false

      add :amount_cents, :integer, null: false
      add :status, :string, null: false, default: "pending"
      add :provider, :string, null: false, default: "stripe"
      add :stripe_payment_intent_id, :string
      add :source, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:payments, [:account_id])
    create index(:payments, [:invoice_id])
  end
end
