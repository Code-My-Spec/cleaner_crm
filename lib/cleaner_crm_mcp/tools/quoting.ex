defmodule CleanerCrmMcp.Tools.Quoting do
  @moduledoc """
  Tool group: Quoting: Quotes and the rate card (pricing).

  Each tool is a module under `CleanerCrmMcp.Tools.Quoting.*` implementing
  `CleanerCrmMcp.Tool`. List it in `tools/0` to make it callable from scripts.
  """

  @doc "Tool modules in this group, in documentation order."
  def tools,
    do: [
      __MODULE__.ListQuotes,
      __MODULE__.GetQuote,
      __MODULE__.EstimatePrice,
      __MODULE__.CreateQuote,
      __MODULE__.GetRateCard,
      __MODULE__.UpdateRateCard
    ]
end
