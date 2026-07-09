defmodule CleanerCrm.Quality.Scorecard do
  @moduledoc """
  Pure scoring math: a single job's quality score, and the
  average/trend across a cleaner's completed jobs. No querying and
  no persistence — `CleanerCrm.Quality` owns fetching the checklists
  and scores this operates on.
  """

  alias CleanerCrm.Quality.Checklist

  @scale 5

  @doc """
  A single checklist's quality score, on a 1-5 scale: the completion
  ratio of its items (checked or skipped-with-reason, over the
  total) scaled to 5, alone until the owner rates the job, then
  blended evenly with that 1-5 rating.

  Expects `checklist.items` preloaded, as returned by
  `CleanerCrm.Quality.get_checklist_for_job/2`.
  """
  def score(%Checklist{items: items, owner_rating: nil}) do
    completion_ratio(items) * @scale
  end

  def score(%Checklist{items: items, owner_rating: rating}) do
    (completion_ratio(items) * @scale + rating) / 2
  end

  defp completion_ratio([]), do: 0.0

  defp completion_ratio(items) do
    done = Enum.count(items, &(&1.checked or &1.skipped))
    done / length(items)
  end

  @doc """
  Aggregates a cleaner's quality scores, given oldest first, into an
  average and a trend (`:up`, `:down`, or `:flat` — comparing the
  average of the first half of jobs against the second).
  """
  def aggregate([]), do: %{average: nil, trend: :flat, count: 0}

  def aggregate(scores) do
    %{average: average(scores), trend: trend(scores), count: length(scores)}
  end

  defp average(scores), do: Enum.sum(scores) / length(scores)

  defp trend(scores) when length(scores) < 2, do: :flat

  defp trend(scores) do
    {first_half, second_half} = Enum.split(scores, div(length(scores), 2))
    compare(average(first_half), average(second_half))
  end

  defp compare(first, second) when second > first, do: :up
  defp compare(first, second) when second < first, do: :down
  defp compare(_first, _second), do: :flat
end
