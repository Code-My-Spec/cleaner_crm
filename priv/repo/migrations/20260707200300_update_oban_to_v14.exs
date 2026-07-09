defmodule CleanerCrm.Repo.Migrations.UpdateObanToV14 do
  use Ecto.Migration

  # The oban dependency resolved to 2.23.0, which requires schema v14;
  # the original jobs-table migration only brought it to v12.
  def up, do: Oban.Migration.up(version: 14)
  def down, do: Oban.Migration.down(version: 12)
end
