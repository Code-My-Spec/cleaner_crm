defmodule CleanerCrmWeb.PortalLive.RequestLinkTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures
  import Swoosh.TestAssertions

  alias CleanerCrm.Accounts
  alias CleanerCrm.Portal
  alias CleanerCrm.Users.Scope

  defp owner_scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)
    {:ok, account} = Accounts.create_account(scope, %{name: "Sparkle Co"})
    %{scope | active_account: account, active_account_id: account.id}
  end

  test "an existing client's email creates a session and shows the generic message" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{email: "morgan@example.com"})

    {:ok, request_link_live, _html} = live(build_conn(), ~p"/portal/request-link")

    request_link_live
    |> form("#request_link_form", request_link: %{email: "morgan@example.com"})
    |> render_submit()

    assert_redirected(request_link_live, ~p"/portal/request-link")
    assert_email_sent(to: "morgan@example.com")
    assert Portal.get_client!(client.id)
  end

  test "an unknown email shows the same generic message and sends nothing" do
    {:ok, request_link_live, _html} = live(build_conn(), ~p"/portal/request-link")

    request_link_live
    |> form("#request_link_form", request_link: %{email: "nobody@example.com"})
    |> render_submit()

    assert_redirected(request_link_live, ~p"/portal/request-link")
    assert_no_email_sent()
  end

  test "PortalAuth redirects a sessionless /portal visit here" do
    assert {:error, {:redirect, %{to: "/portal/request-link"}}} = live(build_conn(), ~p"/portal")
  end
end
