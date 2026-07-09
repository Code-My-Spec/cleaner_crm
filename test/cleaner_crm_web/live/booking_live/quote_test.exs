defmodule CleanerCrmWeb.BookingLive.QuoteTest do
  @moduledoc """
  Covers the live UAT regression where `/book` resolved the *newest*
  account unconditionally (three UAT accounts named "Desert First
  Cleaning" existed, and the newest — with a blank rate card — silently
  became the public storefront), plus the input-bounds and
  minimum-visit-price fixes that shipped alongside it. Story 848's own
  spex drives the calculator's core pricing behavior; this covers the
  issue-only surfaces it doesn't.
  """

  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Quoting
  alias CleanerCrm.Users.Scope

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp rate_card_fixture(scope, attrs) do
    rate_card = Quoting.get_or_create_rate_card(scope)
    {:ok, rate_card} = Quoting.update_rate_card(scope, rate_card, attrs)
    rate_card
  end

  describe "storefront account resolution" do
    test "renders the unavailable state when no business account exists at all", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/book")

      assert html =~ "Online quotes are not open yet"
    end

    test "renders the unavailable state when two accounts exist and neither is the storefront",
         %{conn: conn} do
      scope_fixture()
      scope_fixture()

      {:ok, _lv, html} = live(conn, ~p"/book")

      assert html =~ "Online quotes are not open yet"
    end

    test "prices against the storefront-flagged account even though a newer account exists", %{
      conn: conn
    } do
      older = scope_fixture()
      {:ok, _} = Accounts.set_storefront(older, true)
      rate_card_fixture(older, %{per_room_bedroom_rate_cents: 5000})

      newer = scope_fixture()
      rate_card_fixture(newer, %{per_room_bedroom_rate_cents: 999_999})

      {:ok, lv, _html} = live(conn, ~p"/book")

      lv
      |> form("[data-test='quote-form']", quote: %{pricing_model: "per_room", bedroom_count: 1})
      |> render_change()

      assert has_element?(lv, "[data-test='quote-total']", "$50.00")
    end
  end

  describe "quote input bounds" do
    setup %{conn: conn} do
      scope = scope_fixture()
      rate_card_fixture(scope, %{per_sqft_rate_cents: 12, hourly_rate_cents: 4000})
      {:ok, lv, _html} = live(conn, ~p"/book")
      %{lv: lv}
    end

    test "rejects square footage below 200 with a friendly message", %{lv: lv} do
      html =
        lv
        |> form("[data-test='quote-form']", quote: %{pricing_model: "per_sqft", square_feet: 1})
        |> render_change()

      assert html =~ "must be between 200 and 20,000 sq ft"
      refute has_element?(lv, "[data-test='quote-total']")
    end

    test "rejects more than 12 hours with a friendly message", %{lv: lv} do
      html =
        lv
        |> form("[data-test='quote-form']", quote: %{pricing_model: "hourly", hours: 13})
        |> render_change()

      assert html =~ "must be between 1 and 12 hours"
      refute has_element?(lv, "[data-test='quote-total']")
    end
  end

  describe "minimum visit price" do
    test "clamps a below-minimum quote up to the floor and shows the note", %{conn: conn} do
      scope = scope_fixture()

      rate_card_fixture(scope, %{
        per_sqft_rate_cents: 12,
        minimum_visit_cents: 8_900
      })

      {:ok, lv, _html} = live(conn, ~p"/book")

      lv
      |> form("[data-test='quote-form']", quote: %{pricing_model: "per_sqft", square_feet: 200})
      |> render_change()

      assert has_element?(lv, "[data-test='quote-total']", "$89.00")
      assert has_element?(lv, "[data-test='minimum-visit-price-note']")
    end

    test "does not show the note when the total is already above the minimum", %{conn: conn} do
      scope = scope_fixture()

      rate_card_fixture(scope, %{
        per_sqft_rate_cents: 100,
        minimum_visit_cents: 8_900
      })

      {:ok, lv, _html} = live(conn, ~p"/book")

      lv
      |> form("[data-test='quote-form']", quote: %{pricing_model: "per_sqft", square_feet: 1000})
      |> render_change()

      assert has_element?(lv, "[data-test='quote-total']", "$1,000.00")
      refute has_element?(lv, "[data-test='minimum-visit-price-note']")
    end
  end
end
