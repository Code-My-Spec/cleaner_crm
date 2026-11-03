defmodule CleanerCrmMcp.Tools.Scheduling.ListCleaners do
  use CleanerCrmMcp.Tool, name: "list_cleaners"

  alias CleanerCrm.Scheduling
  alias CleanerCrmMcp.Tools.Scheduling.Shape

  @impl true
  def description,
    do: """
    List the account's cleaners (members who can take jobs), by name.
    Returns [{id, name}]. Use the ids with assign_cleaner, list_jobs and cleaner_schedule.
    """

  @impl true
  def example, do: ~s|for _, c in ipairs(list_cleaners()) do print(c.id, c.name) end|

  @impl true
  def call(_args, scope) do
    {:ok,
     scope
     |> Scheduling.list_cleaners()
     |> Enum.sort_by(&String.downcase(&1.name || ""))
     |> Enum.map(&Shape.cleaner/1)}
  end
end
