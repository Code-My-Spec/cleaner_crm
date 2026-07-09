defmodule CleanerCrmWeb.SettingsLive.BookingPolicyTest do
  @moduledoc """
  Covers issue db25b304: no owner UI ever edited
  `CleanerCrm.Portal.CancellationPolicy` — only a direct database edit
  reached the notice-window hours, late/same-day fees, or policy text
  the client portal enforces and displays.
  """

  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Portal
  alias CleanerCrm.Users.Scope

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp log_in(conn, scope), do: log_in_user(conn, scope.user)

  test "renders the account's current policy, defaulting to zero fees when unset", %{conn: conn} do
    scope = scope_fixture()

    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/settings/booking")

    assert has_element?(lv, "[data-test='notice-window-input']")
    assert has_element?(lv, "[data-test='late-fee-input']")
    assert has_element?(lv, "[data-test='same-day-fee-input']")
    assert has_element?(lv, "[data-test='policy-text-input']")
  end

  test "saves notice window, fees, and policy text, converting dollars to cents", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/settings/booking")

    lv
    |> form("[data-test='cancellation-policy-form']",
      policy: %{
        notice_window_hours: "48",
        late_fee: "25.00",
        same_day_fee: "75.50",
        policy_text: "Cancel 48 hours ahead to avoid a fee."
      }
    )
    |> render_submit()

    policy = Portal.get_cancellation_policy(scope.active_account_id)

    assert policy.notice_window_hours == 48
    assert policy.late_fee_cents == 2_500
    assert policy.same_day_fee_cents == 7_550
    assert policy.policy_text == "Cancel 48 hours ahead to avoid a fee."
  end

  test "an existing saved policy is preloaded into the form for editing", %{conn: conn} do
    scope = scope_fixture()

    {:ok, _policy} =
      Portal.set_cancellation_policy(scope, %{
        notice_window_hours: 24,
        late_fee_cents: 1_000,
        same_day_fee_cents: 5_000
      })

    {:ok, lv, html} = live(log_in(conn, scope), ~p"/settings/booking")

    assert html =~ "value=\"10\""
    assert html =~ "value=\"50\""

    lv
    |> form("[data-test='cancellation-policy-form']",
      policy: %{late_fee: "12.00"}
    )
    |> render_submit()

    assert Portal.get_cancellation_policy(scope.active_account_id).late_fee_cents == 1_200
  end

  test "rejects a negative notice window", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/settings/booking")

    html =
      lv
      |> form("[data-test='cancellation-policy-form']",
        policy: %{notice_window_hours: "-5", late_fee: "10.00", same_day_fee: "20.00"}
      )
      |> render_submit()

    assert html =~ "must be greater than or equal to"
    assert Portal.get_cancellation_policy(scope.active_account_id).notice_window_hours == 24
  end
end
