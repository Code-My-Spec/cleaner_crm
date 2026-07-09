defmodule CleanerCrm.Repo.Migrations.AddAgreedPriceCentsToRecurringPlans do
  use Ecto.Migration

  def change do
    alter table(:recurring_plans) do
      add :agreed_price_cents, :integer
    end
  end
end
