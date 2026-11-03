defmodule CleanerCrmMcp.Tools.Operations.GetScorecard do
  use CleanerCrmMcp.Tool, name: "get_scorecard"

  alias CleanerCrm.Quality
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    Get a cleaner's quality scorecard across their completed jobs.
    Returns { cleaner_id, average (1-5, nil if no completed jobs), trend ("up", "down" or "flat"), count }.
    Errors when cleaner_id is not a member of this account.
    """

  @impl true
  def params,
    do: [
      %{name: "cleaner_id", type: :integer, required: true, description: "The cleaner's user id"}
    ]

  @impl true
  def example, do: ~s|local s = get_scorecard({ cleaner_id = 12 })\nreturn s.average|

  @impl true
  def call(%{"cleaner_id" => cleaner_id}, scope) do
    with :ok <- Shape.ensure_cleaner(scope, cleaner_id) do
      card = Quality.cleaner_scorecard(scope, cleaner_id)

      {:ok,
       %{
         "cleaner_id" => cleaner_id,
         "average" => card.average && Float.round(card.average * 1.0, 2),
         "trend" => Present.plain(card.trend),
         "count" => card.count
       }}
    end
  end
end
