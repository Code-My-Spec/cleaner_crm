defmodule CleanerCrmWeb.PageControllerTest do
  use CleanerCrmTest.ConnCase

  test "GET / shows the landing page with public CTAs", %{conn: conn} do
    conn = get(conn, ~p"/")
    html = html_response(conn, 200)

    assert html =~ "Cleaner CRM"
    assert html =~ "Get an instant quote"
    assert html =~ "Client portal"
    assert html =~ "Business log in"
    refute html =~ "Go to app"
  end

  test "GET / offers Go to app for a signed-in office user", %{conn: conn} do
    user = CleanerCrm.UsersFixtures.user_fixture()
    scope = CleanerCrm.Users.Scope.for_user(user)
    {:ok, _account} = CleanerCrm.Accounts.create_account(scope, %{name: "Sparkle Co"})

    conn = conn |> log_in_user(user) |> get(~p"/")
    html = html_response(conn, 200)

    assert html =~ "Go to app"
    assert html =~ ~p"/schedule"
  end
end
