defmodule CleanerCrmMcp.Tools.Quoting.EstimatePrice do
  use CleanerCrmMcp.Tool, name: "estimate_price"

  alias CleanerCrm.Quoting
  alias CleanerCrmMcp.Tools.Quoting.Shape

  @impl true
  def description,
    do: """
    Price a visit from the rate card without saving anything.
    Returns line_items, add_on_items, subtotal, discount_percent (from frequency), total (with the minimum-visit floor applied), minimum_applied and priceable. Money is {x_cents, x}.
    priceable is false (and the total unreliable) when a needed rate or add-on price is not set on the rate card; errors on an unknown pricing_model or frequency, or when no size field is given.
    """

  @impl true
  def params,
    do:
      Shape.size_params() ++
        [
          %{
            name: "frequency",
            type: :string,
            required: false,
            description: "one_time (default), weekly, biweekly or monthly"
          },
          %{
            name: "add_ons",
            type: :list,
            required: false,
            description: "Add-on keys priced on the rate card, e.g. {\"inside_fridge\"}"
          }
        ]

  @impl true
  def example,
    do:
      ~s|local p = estimate_price({ bedrooms = 3, bathrooms = 2, frequency = "weekly", add_ons = {"inside_fridge"} })\nreturn p.total|

  @impl true
  def call(args, scope) do
    with {:ok, model} <- Shape.resolve_model(args),
         {:ok, frequency} <- Shape.parse_frequency(args["frequency"]) do
      attrs =
        args
        |> Shape.size_attrs()
        |> Map.merge(%{
          pricing_model: model,
          add_ons: Enum.map(args["add_ons"] || [], &to_string/1)
        })
        |> then(&if frequency, do: Map.put(&1, :frequency, frequency), else: &1)

      s = Quoting.estimate_price(scope, attrs)

      {:ok,
       %{
         "pricing_model" => Present.plain(model),
         "line_items" => Enum.map(s.line_items, &Shape.line_item/1),
         "add_on_items" => Enum.map(s.add_on_items, &Shape.line_item/1),
         "discount_percent" => s.discount_percent,
         "minimum_applied" => s.minimum_applied?,
         "priceable" => s.priceable?
       }
       |> Map.merge(Present.money("subtotal", s.subtotal_cents))
       |> Map.merge(Present.money("total", s.total_cents))}
    end
  end
end
