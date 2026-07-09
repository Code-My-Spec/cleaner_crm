defmodule CleanerCrm.BookingTest do
  @moduledoc """
  Covers issue 4e985412: `/book/accept/:token`'s slot-selection form
  accepted any date — including years in the past — with zero
  validation, and QA drove a `scheduled_date` of 2020-01-01 all the
  way through card capture into a real scheduled job. Both guards
  added for it are exercised here:

    * `Lead.slot_changeset/3` (via `Booking.select_slot/3`) — the
      form-level guard, rejecting a past date/time outright.
    * `Booking.confirm_booking/3` — the defense-in-depth re-check
      right before a card is charged, in case a slot that was future
      at selection time goes stale (or a lead's slot fields were set
      some other way) by the time the client actually submits payment.

  No spex/BDD story owns this surface, so it's covered here instead,
  mirroring `CleanerCrmWeb.QualityLive.TemplatesTest`'s precedent for
  issue-only coverage.

  Also covers the live UAT regression where `public_scope/0` resolved
  the *newest* account unconditionally: three UAT accounts named
  "Desert First Cleaning" existed, and the newest — with a blank rate
  card — silently became the `/book` storefront. `describe
  "public_scope/0"` below drives the fix (the `storefront` flag, with
  an exactly-one-account fallback and `nil` otherwise) directly.
  """

  use CleanerCrmTest.DataCase, async: true

  import CleanerCrm.UsersFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Booking
  alias CleanerCrm.Users.Scope

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp lead_fixture(scope, attrs \\ %{}) do
    {:ok, lead} =
      Booking.create_lead(
        scope,
        Enum.into(attrs, %{
          pricing_model: :per_room,
          bedroom_count: 3,
          bathroom_count: 2,
          frequency: :one_time,
          total_cents: 19_500,
          status: :accepted,
          client_name: "Dana Prescott",
          client_email: "dana-#{System.unique_integer([:positive])}@example.com",
          client_phone: "+15555550100"
        })
      )

    lead
  end

  describe "select_slot/3" do
    test "rejects a scheduled_date years in the past" do
      lead = lead_fixture(scope_fixture())

      assert {:error, changeset} =
               Booking.select_slot(lead, %{
                 "scheduled_date" => "2020-01-01",
                 "start_time" => "09:00"
               })

      assert "must be today or later" in errors_on(changeset).scheduled_date
    end

    test "rejects today's date once the chosen start time has already passed" do
      lead = lead_fixture(scope_fixture())
      today = Date.utc_today()
      now = DateTime.new!(today, ~T[15:00:00], "Etc/UTC")

      assert {:error, changeset} =
               Booking.select_slot(
                 lead,
                 %{"scheduled_date" => Date.to_iso8601(today), "start_time" => "14:00"},
                 now
               )

      assert "must be later than the current time" in errors_on(changeset).start_time
    end

    test "accepts a future date" do
      lead = lead_fixture(scope_fixture())
      future_date = Date.add(Date.utc_today(), 10)

      assert {:ok, slotted} =
               Booking.select_slot(lead, %{
                 "scheduled_date" => Date.to_iso8601(future_date),
                 "start_time" => "09:00"
               })

      assert slotted.scheduled_date == future_date
    end
  end

  describe "confirm_booking/3 (defense in depth against a past slot)" do
    test "refuses a lead whose slot fields are already in the past, without charging a card" do
      scope = scope_fixture()
      lead = lead_fixture(scope)
      past_lead = %{lead | scheduled_date: ~D[2020-01-01], start_time: ~T[09:00:00]}

      assert {:error, :slot_in_past} =
               Booking.confirm_booking(past_lead, %{
                 "policy_agreed" => "true",
                 "payment_method" => "pm_card_visa"
               })

      reloaded = Booking.get_lead_by_token(lead.acceptance_token)
      assert reloaded.status == :accepted
      assert reloaded.stripe_payment_intent_id == nil
    end

    test "refuses a slot picked for later today once that time has passed by confirmation" do
      scope = scope_fixture()
      lead = lead_fixture(scope)
      today = Date.utc_today()

      {:ok, slotted} =
        Booking.select_slot(
          lead,
          %{"scheduled_date" => Date.to_iso8601(today), "start_time" => "14:00"},
          DateTime.new!(today, ~T[13:00:00], "Etc/UTC")
        )

      assert {:error, :slot_in_past} =
               Booking.confirm_booking(
                 slotted,
                 %{"policy_agreed" => "true", "payment_method" => "pm_card_visa"},
                 DateTime.new!(today, ~T[15:00:00], "Etc/UTC")
               )
    end

    test "still confirms and moves the lead to payment_pending for a genuinely future slot" do
      scope = scope_fixture()
      lead = lead_fixture(scope)

      {:ok, slotted} =
        Booking.select_slot(lead, %{
          "scheduled_date" => Date.to_iso8601(Date.add(Date.utc_today(), 10)),
          "start_time" => "09:00"
        })

      assert {:ok, updated} =
               Booking.confirm_booking(slotted, %{
                 "policy_agreed" => "true",
                 "payment_method" => "pm_card_visa"
               })

      assert updated.status == :payment_pending
    end
  end

  describe "public_scope/0" do
    test "resolves nil when no account exists at all" do
      assert Booking.public_scope().active_account_id == nil
    end

    test "resolves the only account when exactly one exists and none is flagged" do
      scope = scope_fixture()

      assert Booking.public_scope().active_account_id == scope.active_account_id
    end

    test "resolves nil when multiple accounts exist and none is flagged as the storefront" do
      scope_fixture()
      scope_fixture()

      assert Booking.public_scope().active_account_id == nil
    end

    test "resolves the storefront-flagged account even though a newer account exists" do
      older = scope_fixture()
      {:ok, _updated} = Accounts.set_storefront(older, true)
      _newer = scope_fixture()

      assert Booking.public_scope().active_account_id == older.active_account_id
    end

    test "moving the storefront flag to a different account changes which one resolves" do
      first = scope_fixture()
      second = scope_fixture()

      {:ok, _} = Accounts.set_storefront(first, true)
      assert Booking.public_scope().active_account_id == first.active_account_id

      {:ok, _} = Accounts.set_storefront(second, true)
      assert Booking.public_scope().active_account_id == second.active_account_id

      reloaded_first = Accounts.get_account!(first, first.active_account_id)
      refute reloaded_first.storefront
    end

    test "only an owner may set the storefront flag" do
      owner_scope = scope_fixture()
      admin_user = user_fixture()

      {:ok, _member} =
        Accounts.add_user_to_account(
          owner_scope,
          admin_user.id,
          owner_scope.active_account_id,
          :admin
        )

      admin_scope = %{
        Scope.for_user(admin_user)
        | active_account_id: owner_scope.active_account_id
      }

      assert_raise RuntimeError, ~r/Unauthorized/, fn ->
        Accounts.set_storefront(admin_scope, true)
      end
    end
  end
end
