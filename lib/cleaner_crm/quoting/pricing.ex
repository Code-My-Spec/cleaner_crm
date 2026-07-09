defmodule CleanerCrm.Quoting.Pricing do
  @moduledoc """
  Computes a quote's line items and total from a rate card, and decides
  whether a quote is ready to send.

  Pure and side-effect free: it never touches the database, so
  `CleanerCrmWeb.QuoteLive.Builder` can call it on every keystroke for
  live totals, and `CleanerCrm.Quoting.send_quote/3` can call it again
  at the moment of persistence.

  Per the money-handling ADR, rate math is done in `Decimal` and
  rounded half-up to whole cents.
  """

  alias CleanerCrm.Quoting.{Quote, RateCard}

  @type line_item :: %{
          description: String.t(),
          quantity: integer(),
          rate_cents: integer() | nil,
          amount_cents: integer()
        }

  @doc """
  The quote form field names (as submitted param keys) that belong to
  a given pricing model — used to drop inputs left over from a
  previously selected model when the owner switches models.
  """
  @spec fields_for_model(String.t()) :: [String.t()]
  def fields_for_model("per_room"), do: ~w(bedroom_count bathroom_count)
  def fields_for_model("per_sqft"), do: ~w(square_feet)
  def fields_for_model("hourly"), do: ~w(hours)
  def fields_for_model(_other), do: []

  @doc """
  The priced line items for a quote's chosen model. Only items with a
  positive quantity are included — an empty or zero field never
  demands a rate. A `nil` `rate_cents` means the rate card has nothing
  configured yet for that item, and its amount is zero.
  """
  @spec line_items(RateCard.t(), Quote.t()) :: [line_item()]
  def line_items(%RateCard{} = rate_card, %Quote{} = quote) do
    quote.pricing_model
    |> model_items(rate_card, quote)
    |> Enum.filter(&(&1.quantity > 0))
  end

  defp model_items(:per_room, rate_card, quote) do
    [
      item("Bedrooms", quote.bedroom_count, rate_card.per_room_bedroom_rate_cents),
      item("Bathrooms", quote.bathroom_count, rate_card.per_room_bathroom_rate_cents)
    ]
  end

  defp model_items(:per_sqft, rate_card, quote) do
    [item("Square footage", quote.square_feet, rate_card.per_sqft_rate_cents)]
  end

  defp model_items(:hourly, rate_card, quote) do
    [item("Hours", quote.hours, rate_card.hourly_rate_cents)]
  end

  defp model_items(nil, _rate_card, _quote), do: []

  defp item(description, quantity, rate_cents) do
    quantity = quantity || 0

    %{
      description: description,
      quantity: quantity,
      rate_cents: rate_cents,
      amount_cents: amount_cents(quantity, rate_cents)
    }
  end

  defp amount_cents(quantity, rate_cents)
       when is_integer(quantity) and is_integer(rate_cents) and quantity > 0 do
    quantity
    |> Decimal.new()
    |> Decimal.mult(Decimal.new(rate_cents))
    |> Decimal.round(0, :half_up)
    |> Decimal.to_integer()
  end

  defp amount_cents(_quantity, _rate_cents), do: 0

  @doc "Sums a quote's line items into its total, in cents."
  @spec total_cents([line_item()]) :: integer()
  def total_cents(line_items), do: Enum.reduce(line_items, 0, &(&1.amount_cents + &2))

  @doc "Whether any priced line item is missing a rate from the rate card."
  @spec missing_rate?([line_item()]) :: boolean()
  def missing_rate?(line_items), do: Enum.any?(line_items, &is_nil(&1.rate_cents))

  @doc """
  Whether a quote is ready to send: at least one priced line item,
  every one of them rated, and a positive total.
  """
  @spec finalizable?([line_item()]) :: boolean()
  def finalizable?(line_items) do
    line_items != [] and not missing_rate?(line_items) and total_cents(line_items) > 0
  end
end
