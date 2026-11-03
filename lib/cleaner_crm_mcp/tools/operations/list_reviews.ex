defmodule CleanerCrmMcp.Tools.Operations.ListReviews do
  use CleanerCrmMcp.Tool, name: "list_reviews"

  alias CleanerCrm.Reviews
  alias CleanerCrmMcp.Tools.Operations.Shape

  @impl true
  def description,
    do: """
    List customer reviews and private complaints, newest first. Includes requested-but-unanswered reviews unless a rating filter is given.
    Returns a list of { id, rating, text, status ("review_requested", "published" or "private"), submitted_at, job, client, cleaner }.
    Ratings of 3 or below are private complaints. Errors when from is after to.
    """

  @impl true
  def params,
    do: [
      %{name: "min_rating", type: :integer, description: "Only ratings at or above this (1-5)"},
      %{
        name: "max_rating",
        type: :integer,
        description: "Only ratings at or below this (1-5), e.g. 3 for complaints"
      },
      %{name: "from", type: :date, description: "Submitted on or after this day (UTC)"},
      %{name: "to", type: :date, description: "Submitted on or before this day (UTC)"},
      %{name: "limit", type: :integer, description: "Max results (default 50, max 500)"}
    ]

  @impl true
  def example, do: ~s|return list_reviews({ max_rating = 3, from = "2026-10-01" })|

  @impl true
  def call(args, scope) do
    from = Args.get(args, "from")
    to = Args.get(args, "to")
    min = Args.get(args, "min_rating")
    max = Args.get(args, "max_rating")

    with :ok <- Shape.check_range(from, to) do
      reviews =
        scope
        |> Reviews.list_reviews()
        |> Enum.filter(&rating_ok?(&1.rating, min, max))
        |> Enum.filter(
          &((is_nil(from) and is_nil(to)) or Shape.in_range?(&1.submitted_at, from, to))
        )
        |> Enum.take(Shape.limit(Args.get(args, "limit")))
        |> Enum.map(&Shape.review/1)

      {:ok, reviews}
    end
  end

  defp rating_ok?(_rating, nil, nil), do: true
  defp rating_ok?(nil, _, _), do: false

  defp rating_ok?(rating, min, max),
    do: (is_nil(min) or rating >= min) and (is_nil(max) or rating <= max)
end
