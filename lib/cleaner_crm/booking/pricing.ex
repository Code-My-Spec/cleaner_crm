defmodule CleanerCrm.Booking.Pricing do
  @moduledoc """
  Prices a `CleanerCrm.Booking.Lead` from the account's rate card:
  the base per-room/per-sqft/hourly amount (reusing
  `CleanerCrm.Quoting.Pricing`, the same math the office quote builder
  uses), each selected add-on's configured amount, and the selected
  frequency's recurring discount off that subtotal.

  Pure and side-effect free, exactly like `CleanerCrm.Quoting.Pricing` —
  `CleanerCrmWeb.BookingLive.Quote` calls `summarize/2` on every
  keystroke for the live total.
  """

  alias CleanerCrm.Booking.Lead
  alias CleanerCrm.Quoting.{Quote, RateCard}
  alias CleanerCrm.Quoting.Pricing, as: QuotingPricing

  @type line_item :: QuotingPricing.line_item()

  @type summary :: %{
          line_items: [line_item()],
          add_on_items: [line_item()],
          subtotal_cents: integer(),
          discount_percent: integer(),
          total_cents: integer(),
          priceable?: boolean()
        }

  @doc """
  Every number `CleanerCrmWeb.BookingLive.Quote` needs to render the
  live total in one call.
  """
  @spec summarize(RateCard.t(), Lead.t()) :: summary()
  def summarize(%RateCard{} = rate_card, %Lead{} = lead) do
    line_items = base_line_items(rate_card, lead)
    add_on_items = add_on_line_items(rate_card, lead)

    subtotal_cents =
      QuotingPricing.total_cents(line_items) + QuotingPricing.total_cents(add_on_items)

    discount_percent = discount_percent(rate_card, lead)

    %{
      line_items: line_items,
      add_on_items: add_on_items,
      subtotal_cents: subtotal_cents,
      discount_percent: discount_percent,
      total_cents: apply_discount(subtotal_cents, discount_percent),
      priceable?: priceable_from_items?(line_items, add_on_items)
    }
  end

  @doc "The base (room/sqft/hourly) line items, priced the same way an office quote is."
  @spec base_line_items(RateCard.t(), Lead.t()) :: [line_item()]
  def base_line_items(%RateCard{} = rate_card, %Lead{} = lead) do
    QuotingPricing.line_items(rate_card, %Quote{
      pricing_model: lead.pricing_model,
      bedroom_count: lead.bedroom_count,
      bathroom_count: lead.bathroom_count,
      square_feet: lead.square_feet,
      hours: lead.hours
    })
  end

  @doc """
  One line item per selected add-on, `rate_cents: nil` when the rate
  card hasn't configured a price for it yet — the same "never guess"
  rule `CleanerCrm.Quoting.Pricing.missing_rate?/1` applies to the base
  rates.
  """
  @spec add_on_line_items(RateCard.t(), Lead.t()) :: [line_item()]
  def add_on_line_items(%RateCard{add_on_rates_cents: rates}, %Lead{add_ons: add_ons}) do
    Enum.map(add_ons, fn key ->
      rate_cents = Map.get(rates || %{}, key)

      %{
        description: humanize(key),
        quantity: 1,
        rate_cents: rate_cents,
        amount_cents: rate_cents || 0
      }
    end)
  end

  @doc """
  Whether this lead is priceable at all: at least one priced base line
  item, and no selected item (base or add-on) missing a rate.
  """
  @spec priceable?(RateCard.t(), Lead.t()) :: boolean()
  def priceable?(%RateCard{} = rate_card, %Lead{} = lead) do
    priceable_from_items?(base_line_items(rate_card, lead), add_on_line_items(rate_card, lead))
  end

  defp priceable_from_items?(line_items, add_on_items) do
    line_items != [] and
      not QuotingPricing.missing_rate?(line_items) and
      not QuotingPricing.missing_rate?(add_on_items)
  end

  @doc "The discount percent (0 when unset) the rate card configures for a lead's frequency."
  @spec discount_percent(RateCard.t(), Lead.t()) :: integer()
  def discount_percent(%RateCard{} = rate_card, %Lead{frequency: frequency}) do
    case frequency do
      :weekly -> rate_card.weekly_discount_percent || 0
      :biweekly -> rate_card.biweekly_discount_percent || 0
      :monthly -> rate_card.monthly_discount_percent || 0
      _one_time_or_nil -> 0
    end
  end

  defp apply_discount(subtotal_cents, 0), do: subtotal_cents

  defp apply_discount(subtotal_cents, discount_percent) do
    subtotal_cents
    |> Decimal.new()
    |> Decimal.mult(Decimal.new(100 - discount_percent))
    |> Decimal.div(Decimal.new(100))
    |> Decimal.round(0, :half_up)
    |> Decimal.to_integer()
  end

  defp humanize(key) do
    key
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
