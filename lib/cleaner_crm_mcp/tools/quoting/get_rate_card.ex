defmodule CleanerCrmMcp.Tools.Quoting.GetRateCard do
  use CleanerCrmMcp.Tool, name: "get_rate_card"

  alias CleanerCrm.Quoting
  alias CleanerCrmMcp.Tools.Quoting.Shape

  @impl true
  def description,
    do: """
    Get the account's rate card (pricing).
    Returns bedroom_rate, bathroom_rate, sqft_rate, hourly_rate, minimum_visit (each {x_cents, x}, nil when unset), weekly/biweekly/monthly_discount_percent and add_on_rates (name -> price). A blank rate means that model is not priced yet. Creates a blank rate card on first use.
    """

  @impl true
  def example, do: ~s|return get_rate_card().hourly_rate|

  @impl true
  def call(_args, scope),
    do: {:ok, scope |> Quoting.get_or_create_rate_card() |> Shape.rate_card()}
end
