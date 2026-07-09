defmodule CleanerCrm.Repo.Migrations.AddClientPreferencesToProperties do
  use Ecto.Migration

  def change do
    alter table(:properties) do
      add :client_preferences, :text
    end
  end
end
