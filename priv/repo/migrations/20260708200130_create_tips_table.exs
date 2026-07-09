defmodule CleanerCrm.Repo.Migrations.CreateTipsTable do
  use Ecto.Migration

  def change do
    create table(:tips, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :invoice_id, references(:invoices, type: :binary_id, on_delete: :delete_all),
        null: false

      add :cleaner_id, references(:users, on_delete: :nilify_all)
      add :amount_cents, :integer, null: false
      add :stripe_payment_intent_id, :string

      timestamps(type: :utc_datetime_usec)
    end

    create index(:tips, [:account_id])
    create index(:tips, [:invoice_id])
    create index(:tips, [:cleaner_id])
  end
end
