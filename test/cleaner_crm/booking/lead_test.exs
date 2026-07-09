defmodule CleanerCrm.Booking.LeadTest do
  @moduledoc """
  Unit coverage for `CleanerCrm.Booking.Lead`'s own changesets: input
  bounds on the calculator's quote fields (issue: any integer was
  accepted with zero validation — a 1-sqft or 40-bedroom quote both
  went through) and `client_email` format on the full acceptance
  changeset (format-only; a click-a-link verification is a separate,
  not-yet-made product decision).
  """

  use ExUnit.Case, async: true

  alias CleanerCrm.Booking.Lead

  describe "quote_changeset/2 room-count bounds" do
    test "accepts bedroom/bathroom counts at the edges of 0..20" do
      changeset = Lead.quote_changeset(%Lead{}, %{bedroom_count: 0, bathroom_count: 20})

      refute changeset.errors[:bedroom_count]
      refute changeset.errors[:bathroom_count]
    end

    test "rejects a bedroom count above 20" do
      changeset = Lead.quote_changeset(%Lead{}, %{bedroom_count: 21})

      assert {_message, _opts} = changeset.errors[:bedroom_count]
    end

    test "rejects a bathroom count above 20" do
      changeset = Lead.quote_changeset(%Lead{}, %{bathroom_count: 21})

      assert {_message, _opts} = changeset.errors[:bathroom_count]
    end
  end

  describe "quote_changeset/2 square footage bounds" do
    test "accepts square footage within 200..20,000" do
      changeset = Lead.quote_changeset(%Lead{}, %{square_feet: 2000})

      refute changeset.errors[:square_feet]
    end

    test "rejects a 1-sqft quote with a friendly message" do
      changeset = Lead.quote_changeset(%Lead{}, %{square_feet: 1})

      assert {"must be between 200 and 20,000 sq ft", _opts} = changeset.errors[:square_feet]
    end

    test "rejects square footage above 20,000 with the same friendly message" do
      changeset = Lead.quote_changeset(%Lead{}, %{square_feet: 20_001})

      assert {"must be between 200 and 20,000 sq ft", _opts} = changeset.errors[:square_feet]
    end
  end

  describe "quote_changeset/2 hours bounds" do
    test "accepts hours within 1..12" do
      changeset = Lead.quote_changeset(%Lead{}, %{hours: 1})

      refute changeset.errors[:hours]
    end

    test "rejects zero hours with a friendly message" do
      changeset = Lead.quote_changeset(%Lead{}, %{hours: 0})

      assert {"must be between 1 and 12 hours", _opts} = changeset.errors[:hours]
    end

    test "rejects more than 12 hours with the same friendly message" do
      changeset = Lead.quote_changeset(%Lead{}, %{hours: 13})

      assert {"must be between 1 and 12 hours", _opts} = changeset.errors[:hours]
    end
  end

  describe "changeset/2 client_email format" do
    defp base_attrs(email) do
      %{
        client_name: "Dana Prescott",
        client_email: email,
        client_phone: "+15555550100",
        total_cents: 10_000
      }
    end

    test "rejects an email with no @ sign" do
      changeset = Lead.changeset(%Lead{}, base_attrs("not-an-email"))

      assert {"must have the @ sign and no spaces", _opts} = changeset.errors[:client_email]
    end

    test "rejects an email containing a space" do
      changeset = Lead.changeset(%Lead{}, base_attrs("dana prescott@example.com"))

      assert {"must have the @ sign and no spaces", _opts} = changeset.errors[:client_email]
    end

    test "accepts a well-formed email" do
      changeset = Lead.changeset(%Lead{}, base_attrs("dana@example.com"))

      refute changeset.errors[:client_email]
    end
  end
end
