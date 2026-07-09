defmodule CleanerCrm.Booking.PricingTest do
  @moduledoc """
  Unit coverage for `CleanerCrm.Booking.Pricing.summarize/2`'s minimum
  visit price floor (the rate card's `minimum_visit_cents`) — kills the
  "1-sqft, $0.12 quote" abuse class outright, independent of (and ahead
  of) `CleanerCrm.Booking.Lead`'s own input bounds.
  """

  use ExUnit.Case, async: true

  alias CleanerCrm.Booking.Lead
  alias CleanerCrm.Booking.Pricing
  alias CleanerCrm.Quoting.RateCard

  describe "summarize/2 minimum visit price" do
    test "leaves the total untouched and the flag false when no minimum is configured" do
      rate_card = %RateCard{per_sqft_rate_cents: 12, minimum_visit_cents: nil}
      lead = %Lead{pricing_model: :per_sqft, square_feet: 200, add_ons: []}

      summary = Pricing.summarize(rate_card, lead)

      assert summary.total_cents == 2_400
      refute summary.minimum_applied?
    end

    test "clamps a below-minimum total up to the configured floor and flags it" do
      rate_card = %RateCard{per_sqft_rate_cents: 12, minimum_visit_cents: 8_900}
      lead = %Lead{pricing_model: :per_sqft, square_feet: 200, add_ons: []}

      summary = Pricing.summarize(rate_card, lead)

      assert summary.total_cents == 8_900
      assert summary.minimum_applied?
    end

    test "leaves an at-or-above-minimum total untouched" do
      rate_card = %RateCard{per_sqft_rate_cents: 100, minimum_visit_cents: 8_900}
      lead = %Lead{pricing_model: :per_sqft, square_feet: 200, add_ons: []}

      summary = Pricing.summarize(rate_card, lead)

      assert summary.total_cents == 20_000
      refute summary.minimum_applied?
    end

    test "the floor still applies after a frequency discount pulls the total below it" do
      rate_card = %RateCard{
        per_sqft_rate_cents: 100,
        weekly_discount_percent: 90,
        minimum_visit_cents: 8_900
      }

      lead = %Lead{pricing_model: :per_sqft, square_feet: 200, frequency: :weekly, add_ons: []}

      # Subtotal $200.00, discounted 90% -> $20.00, below the $89 floor.
      summary = Pricing.summarize(rate_card, lead)

      assert summary.total_cents == 8_900
      assert summary.minimum_applied?
    end
  end
end
