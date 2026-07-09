defmodule CleanerCrmWeb.QuoteLive.RateCardTest do
  @moduledoc """
  Covers issue 29ca9136: the public `/book` instant-quote calculator
  prices from `CleanerCrm.Quoting.RateCard`'s base rates, frequency
  discounts, and add-on prices, but no owner UI ever set the discount
  or add-on fields (QA had to seed them via psql). No spex/BDD story
  owns this surface (story 835's own spex covers the narrower,
  cents-denominated rate-card form embedded in `QuoteLive.Builder`),
  so it's covered here instead.
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

  defp log_in(conn, scope), do: log_in_user(conn, scope.user)

  test "renders the current rate card's base rates, discounts, and add-ons", %{conn: conn} do
    scope = scope_fixture()

    {:ok, _rate_card} =
      Quoting.update_rate_card(scope, Quoting.get_or_create_rate_card(scope), %{
        per_room_bedroom_rate_cents: 3500,
        per_sqft_rate_cents: 12,
        hourly_rate_cents: 4000,
        weekly_discount_percent: 10,
        add_on_rates_cents: %{"inside_fridge" => 1500}
      })

    {:ok, lv, html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    assert html =~ "35"
    assert has_element?(lv, "[data-test='per-room-bedroom-rate-input']")
    assert has_element?(lv, "[data-test='weekly-discount-input']")
    assert has_element?(lv, "[data-test='add-on-row-0']")
    assert has_element?(lv, "[data-test='add-on-name-input-0']")
  end

  test "saves base rates and frequency discounts, converting dollars to cents", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    lv
    |> form("[data-test='rate-card-form']",
      rate_card: %{
        per_room_bedroom_rate: "35.00",
        per_room_bathroom_rate: "20.00",
        per_sqft_rate: "0.12",
        hourly_rate: "40.00",
        weekly_discount_percent: "10",
        biweekly_discount_percent: "5",
        monthly_discount_percent: "15"
      }
    )
    |> render_submit()

    rate_card = Quoting.get_or_create_rate_card(scope)

    assert rate_card.per_room_bedroom_rate_cents == 3500
    assert rate_card.per_room_bathroom_rate_cents == 2000
    assert rate_card.per_sqft_rate_cents == 12
    assert rate_card.hourly_rate_cents == 4000
    assert rate_card.weekly_discount_percent == 10
    assert rate_card.biweekly_discount_percent == 5
    assert rate_card.monthly_discount_percent == 15
  end

  test "saves a minimum visit price, converting dollars to cents", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    lv
    |> form("[data-test='rate-card-form']", rate_card: %{minimum_visit_rate: "89.00"})
    |> render_submit()

    assert Quoting.get_or_create_rate_card(scope).minimum_visit_cents == 8_900
  end

  test "leaves the minimum visit price unset (no floor) when left blank", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    lv
    |> form("[data-test='rate-card-form']", rate_card: %{minimum_visit_rate: ""})
    |> render_submit()

    assert Quoting.get_or_create_rate_card(scope).minimum_visit_cents == nil
  end

  test "rejects a negative minimum visit price", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    html =
      lv
      |> form("[data-test='rate-card-form']", rate_card: %{minimum_visit_rate: "-10.00"})
      |> render_submit()

    assert html =~ "must be greater than or equal to"
    assert Quoting.get_or_create_rate_card(scope).minimum_visit_cents == nil
  end

  test "Add add-on control appends a blank row that can be named, priced, and saved", %{
    conn: conn
  } do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    refute has_element?(lv, "[data-test='add-on-row-0']")

    lv |> element("[data-test='add-add-on-button']") |> render_click()

    assert has_element?(lv, "[data-test='add-on-row-0']")

    lv
    |> form("[data-test='rate-card-form']",
      rate_card: %{add_ons: %{"0" => %{name: "Inside fridge", dollars: "15.00"}}}
    )
    |> render_submit()

    rate_card = Quoting.get_or_create_rate_card(scope)
    assert rate_card.add_on_rates_cents == %{"Inside fridge" => 1500}
  end

  test "Remove control drops a persisted add-on on save", %{conn: conn} do
    scope = scope_fixture()

    {:ok, _rate_card} =
      Quoting.update_rate_card(scope, Quoting.get_or_create_rate_card(scope), %{
        add_on_rates_cents: %{"inside_fridge" => 1500}
      })

    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")
    assert has_element?(lv, "[data-test='add-on-row-0']")

    lv |> element("[data-test='remove-add-on-0']") |> render_click()
    refute has_element?(lv, "[data-test='add-on-row-0']")

    lv
    |> form("[data-test='rate-card-form']", rate_card: %{})
    |> render_submit()

    rate_card = Quoting.get_or_create_rate_card(scope)
    assert rate_card.add_on_rates_cents == %{}
  end

  test "rejects a named add-on left unpriced", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/quotes/rate-card")

    lv |> element("[data-test='add-add-on-button']") |> render_click()

    html =
      lv
      |> form("[data-test='rate-card-form']",
        rate_card: %{add_ons: %{"0" => %{name: "Inside fridge", dollars: ""}}}
      )
      |> render_submit()

    assert html =~ "must map add-on names to whole cent amounts"
    assert Quoting.get_or_create_rate_card(scope).add_on_rates_cents == %{}
  end
end
