defmodule CleanerCrm.Repo.Migrations.AddNameToUsers do
  use Ecto.Migration

  @moduledoc """
  Adds an optional display name to users. Scheduling (story 833) needs a
  human-facing name for cleaners created directly through the schedule's
  own cleaner roster form, distinct from their login email.
  """

  def change do
    alter table(:users) do
      add :name, :string
    end
  end
end
