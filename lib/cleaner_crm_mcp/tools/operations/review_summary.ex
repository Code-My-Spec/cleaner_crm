defmodule CleanerCrmMcp.Tools.Operations.ReviewSummary do
  use CleanerCrmMcp.Tool, name: "review_summary"

  alias CleanerCrm.Reviews
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    Summarize submitted customer reviews: average rating, count, rating distribution and low ratings.
    Returns { count, average (nil if none), distribution = { ["1"]..["5"] }, low_ratings = [reviews rated 3 or below], pending_requests }.
    Errors when from is after to.
    """

  @impl true
  def params,
    do: [
      %{name: "from", type: :date, description: "Submitted on or after this day (UTC)"},
      %{name: "to", type: :date, description: "Submitted on or before this day (UTC)"}
    ]

  @impl true
  def example, do: ~s|local s = review_summary({ from = "2026-10-01" })\nreturn s.average|

  @impl true
  def call(args, scope) do
    from = Args.get(args, "from")
    to = Args.get(args, "to")

    with :ok <- Shape.check_range(from, to) do
      all = Reviews.list_reviews(scope)
      pending = Enum.count(all, &is_nil(&1.rating))

      rated =
        Enum.filter(all, &(not is_nil(&1.rating) and Shape.in_range?(&1.submitted_at, from, to)))

      ratings = Enum.map(rated, & &1.rating)

      {:ok,
       %{
         "count" => length(rated),
         "average" =>
           if(ratings == [], do: nil, else: Float.round(Enum.sum(ratings) / length(ratings), 2)),
         "distribution" =>
           Map.new(1..5, fn n -> {to_string(n), Enum.count(ratings, &(&1 == n))} end),
         "low_ratings" => rated |> Enum.filter(&(&1.rating <= 3)) |> Enum.map(&Shape.review/1),
         "pending_requests" => pending
       }}
    end
  end
end
