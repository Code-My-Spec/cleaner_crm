defmodule CleanerCrm.Repo.Migrations.AddFrequencyPricingToRateCards do
  use Ecto.Migration

  def change do
    alter table(:rate_cards) do
      add :weekly_discount_percent, :integer
      add :biweekly_discount_percent, :integer
      add :monthly_discount_percent, :integer
      add :add_on_rates_cents, :map, null: false, default: %{}
    end
  end
end
