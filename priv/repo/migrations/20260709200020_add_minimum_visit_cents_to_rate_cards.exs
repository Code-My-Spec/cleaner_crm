defmodule CleanerCrm.Repo.Migrations.AddMinimumVisitCentsToRateCards do
  use Ecto.Migration

  def change do
    alter table(:rate_cards) do
      add :minimum_visit_cents, :integer
    end
  end
end
