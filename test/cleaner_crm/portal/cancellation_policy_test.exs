defmodule CleanerCrm.Portal.CancellationPolicyTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Portal.CancellationPolicy

  @valid_attrs %{notice_window_hours: 48, late_fee_cents: 2_500, same_day_fee_cents: 5_000}

  describe "changeset/2" do
    test "valid with a full notice window and fee set" do
      changeset = CancellationPolicy.changeset(%CancellationPolicy{}, @valid_attrs)
      assert changeset.valid?
    end

    test "defaults to a 24-hour window and zero fees on a fresh struct" do
      policy = %CancellationPolicy{}

      assert policy.notice_window_hours == 24
      assert policy.late_fee_cents == 0
      assert policy.same_day_fee_cents == 0
    end

    test "rejects a negative notice window" do
      changeset =
        CancellationPolicy.changeset(%CancellationPolicy{}, %{
          @valid_attrs
          | notice_window_hours: -1
        })

      refute changeset.valid?
      assert %{notice_window_hours: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "rejects a negative late fee" do
      changeset =
        CancellationPolicy.changeset(%CancellationPolicy{}, %{@valid_attrs | late_fee_cents: -1})

      refute changeset.valid?
      assert %{late_fee_cents: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "accepts optional policy text" do
      changeset =
        CancellationPolicy.changeset(
          %CancellationPolicy{},
          Map.put(@valid_attrs, :policy_text, "Cancel 48h ahead or a fee applies.")
        )

      assert changeset.valid?
      assert get_change(changeset, :policy_text) == "Cancel 48h ahead or a fee applies."
    end
  end
end
