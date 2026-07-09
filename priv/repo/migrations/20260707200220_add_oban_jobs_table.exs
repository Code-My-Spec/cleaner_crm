defmodule CleanerCrm.Repo.Migrations.AddObanJobsTable do
  use Ecto.Migration

  def up do
    Oban.Migration.up(version: 12)
  end

  # Intentionally does not roll all the way back — see Oban's own
  # migration guidance.
  def down do
    Oban.Migration.down(version: 1)
  end
end
