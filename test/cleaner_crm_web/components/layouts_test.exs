defmodule CleanerCrmWeb.LayoutsTest do
  @moduledoc """
  Covers the role-aware app nav built for the UI/navigation pass: an
  office role (owner/admin) gets the full grouped nav, everyone else
  signed in gets just "My Day" — and the two must never both render.
  `/app/field` is reachable by both roles, so it's the one route these
  tests can share.
  """

  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias CleanerCrm.Accounts
  alias CleanerCrm.Users.Scope
  alias CleanerCrmWeb.Layouts

  describe "nav_role/1 and signed_in_home/1" do
    test "signed out has no role and no signed-in home" do
      assert Layouts.nav_role(nil) == nil
      assert Layouts.signed_in_home(nil) == nil
    end
  end

  describe "role-aware nav on /field" do
    setup %{conn: conn} do
      owner = CleanerCrm.UsersFixtures.user_fixture()
      owner_scope = Scope.for_user(owner)
      {:ok, account} = Accounts.create_account(owner_scope, %{name: "Sparkle Co"})

      member = CleanerCrm.UsersFixtures.user_fixture()
      {:ok, _member} = Accounts.add_user_to_account(owner_scope, member.id, account.id, :member)

      %{conn: conn, owner: owner, member: member}
    end

    test "an owner sees the office nav, not the cleaner's My Day link",
         %{conn: conn, owner: owner} do
      {:ok, _view, html} = conn |> log_in_user(owner) |> live(~p"/app/field")

      assert html =~ ~s(data-test="office-nav")
      assert html =~ ~p"/app/schedule"
      assert html =~ "Field view"
      refute html =~ ~s(data-test="cleaner-nav")
    end

    test "a cleaner sees only My Day, no office nav", %{conn: conn, member: member} do
      {:ok, _view, html} = conn |> log_in_user(member) |> live(~p"/app/field")

      assert html =~ ~s(data-test="cleaner-nav")
      refute html =~ ~s(data-test="office-nav")
      refute html =~ ~p"/app/schedule"
    end
  end
end
