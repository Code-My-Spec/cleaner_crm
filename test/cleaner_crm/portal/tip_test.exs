defmodule CleanerCrm.Portal.TipTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Portal.Tip

  @valid_attrs %{
    account_id: Ecto.UUID.generate(),
    invoice_id: Ecto.UUID.generate(),
    cleaner_id: 1,
    amount_cents: 1_000
  }

  describe "changeset/2" do
    test "valid with an account, invoice, cleaner, and positive amount" do
      changeset = Tip.changeset(%Tip{}, @valid_attrs)
      assert changeset.valid?
    end

    test "valid with no cleaner_id — a visit with no assigned cleaner still collects the tip" do
      changeset = Tip.changeset(%Tip{}, Map.delete(@valid_attrs, :cleaner_id))
      assert changeset.valid?
    end

    test "requires account_id, invoice_id, and amount_cents" do
      changeset = Tip.changeset(%Tip{}, %{})
      refute changeset.valid?

      assert %{
               account_id: ["can't be blank"],
               invoice_id: ["can't be blank"],
               amount_cents: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "rejects a zero or negative amount" do
      changeset = Tip.changeset(%Tip{}, %{@valid_attrs | amount_cents: 0})
      refute changeset.valid?
      assert %{amount_cents: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "records the Stripe payment intent it rode in on" do
      changeset =
        Tip.changeset(%Tip{}, Map.put(@valid_attrs, :stripe_payment_intent_id, "pi_123"))

      assert get_change(changeset, :stripe_payment_intent_id) == "pi_123"
    end
  end
end
