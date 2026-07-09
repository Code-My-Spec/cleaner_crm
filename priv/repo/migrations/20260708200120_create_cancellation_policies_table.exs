defmodule CleanerCrm.Repo.Migrations.CreateCancellationPoliciesTable do
  use Ecto.Migration

  def change do
    create table(:cancellation_policies, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :notice_window_hours, :integer, null: false, default: 24
      add :late_fee_cents, :integer, null: false, default: 0
      add :same_day_fee_cents, :integer, null: false, default: 0
      add :policy_text, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:cancellation_policies, [:account_id])
  end
end
