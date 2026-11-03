defmodule CleanerCrmMcp.Tools.Quoting.UpdateRateCard do
  use CleanerCrmMcp.Tool, name: "update_rate_card", mutates: true

  alias CleanerCrm.Quoting
  alias CleanerCrmMcp.Tools.Quoting.Shape

  @rates [
    {"bedroom_rate", :per_room_bedroom_rate_cents, "Per-bedroom price in dollars"},
    {"bathroom_rate", :per_room_bathroom_rate_cents, "Per-bathroom price in dollars"},
    {"sqft_rate", :per_sqft_rate_cents, "Per-square-foot price in dollars, e.g. 0.12"},
    {"hourly_rate", :hourly_rate_cents, "Hourly price in dollars"},
    {"minimum_visit", :minimum_visit_cents, "Minimum price of a visit in dollars"}
  ]

  @impl true
  def description,
    do: """
    Change the account's rate card; only the given fields change.
    Changes pricing for FUTURE quotes and estimates (already-saved quotes keep their frozen amounts). Rates are in dollars. add_on_rates (name -> dollars) is merged into the existing add-ons; An add-on cannot be removed, only repriced.
    Returns the updated rate card. Errors on negative amounts or discounts outside 0-100.
    """

  @impl true
  def params,
    do:
      Enum.map(@rates, fn {name, _, desc} ->
        %{name: name, type: :number, required: false, description: desc}
      end) ++
        [
          %{
            name: "weekly_discount_percent",
            type: :integer,
            required: false,
            description: "0-100"
          },
          %{
            name: "biweekly_discount_percent",
            type: :integer,
            required: false,
            description: "0-100"
          },
          %{
            name: "monthly_discount_percent",
            type: :integer,
            required: false,
            description: "0-100"
          },
          %{
            name: "add_on_rates",
            type: :map,
            required: false,
            description: "Add-on name to dollars, e.g. { inside_fridge = 15 }"
          }
        ]

  @impl true
  def example,
    do: ~s|return update_rate_card({ hourly_rate = 45, add_on_rates = { inside_fridge = 15 } })|

  @impl true
  def call(args, scope) do
    rate_card = Quoting.get_or_create_rate_card(scope)

    attrs =
      Enum.reduce(@rates, %{}, fn {name, field, _}, acc ->
        if Map.has_key?(args, name), do: Map.put(acc, field, Args.to_cents(args[name])), else: acc
      end)
      |> Map.merge(
        Args.take(
          args,
          ~w(weekly_discount_percent biweekly_discount_percent monthly_discount_percent)
        )
      )
      |> put_add_ons(args["add_on_rates"], rate_card)

    case Quoting.update_rate_card(scope, rate_card, attrs) do
      {:ok, updated} -> {:ok, Shape.rate_card(updated)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp put_add_ons(attrs, nil, _), do: attrs

  defp put_add_ons(attrs, rates, rate_card) do
    new = Map.new(rates, fn {k, v} -> {to_string(k), Args.to_cents(v)} end)
    Map.put(attrs, :add_on_rates_cents, Map.merge(rate_card.add_on_rates_cents || %{}, new))
  end
end
