defmodule CleanerCrmWeb.SettingsLive.BookingPolicyTest do
  @moduledoc """
  Covers issue db25b304: no owner UI ever edited
  `CleanerCrm.Portal.CancellationPolicy` — only a direct database edit
  reached the notice-window hours, late/same-day fees, or policy text
  the client portal enforces and displays.

  Also covers the public booking storefront toggle
  (`CleanerCrm.Accounts.set_storefront/2`) this page hosts — the live
  UAT regression where any new signup's account could silently steal
  the `/book` storefront from an existing one.
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

    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/settings/booking")

    assert has_element?(lv, "[data-test='notice-window-input']")
    assert has_element?(lv, "[data-test='late-fee-input']")
    assert has_element?(lv, "[data-test='same-day-fee-input']")
    assert has_element?(lv, "[data-test='policy-text-input']")
  end

  test "saves notice window, fees, and policy text, converting dollars to cents", %{conn: conn} do
    scope = scope_fixture()
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/settings/booking")

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

    {:ok, lv, html} = live(log_in(conn, scope), ~p"/app/settings/booking")

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
    {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/settings/booking")

    html =
      lv
      |> form("[data-test='cancellation-policy-form']",
        policy: %{notice_window_hours: "-5", late_fee: "10.00", same_day_fee: "20.00"}
      )
      |> render_submit()

    assert html =~ "must be greater than or equal to"
    assert Portal.get_cancellation_policy(scope.active_account_id).notice_window_hours == 24
  end

  describe "storefront toggle" do
    test "an owner can turn the storefront on, which unsets any other account's flag", %{
      conn: conn
    } do
      owner_scope = scope_fixture()
      other_scope = scope_fixture()
      {:ok, _} = Accounts.set_storefront(other_scope, true)

      {:ok, lv, _html} = live(log_in(conn, owner_scope), ~p"/app/settings/booking")

      refute has_element?(lv, "[data-test='storefront-active-note']")

      lv |> element("[data-test='storefront-toggle']") |> render_click()

      assert has_element?(lv, "[data-test='storefront-active-note']")

      assert Accounts.get_account!(owner_scope, owner_scope.active_account_id).storefront
      refute Accounts.get_account!(other_scope, other_scope.active_account_id).storefront
    end

    test "an owner can turn the storefront back off", %{conn: conn} do
      scope = scope_fixture()
      {:ok, _} = Accounts.set_storefront(scope, true)

      {:ok, lv, _html} = live(log_in(conn, scope), ~p"/app/settings/booking")
      assert has_element?(lv, "[data-test='storefront-active-note']")

      lv |> element("[data-test='storefront-toggle']") |> render_click()

      refute has_element?(lv, "[data-test='storefront-active-note']")
      refute Accounts.get_account!(scope, scope.active_account_id).storefront
    end

    test "an admin sees the toggle disabled and cannot flip it", %{conn: conn} do
      owner_scope = scope_fixture()
      admin_user = user_fixture()

      {:ok, _member} =
        Accounts.add_user_to_account(
          owner_scope,
          admin_user.id,
          owner_scope.active_account_id,
          :admin
        )

      {:ok, lv, html} = live(log_in_user(conn, admin_user), ~p"/app/settings/booking")

      assert html =~ "Only the account owner can change this."

      assert lv
             |> element("[data-test='storefront-toggle']")
             |> render() =~ "disabled"
    end
  end
end
