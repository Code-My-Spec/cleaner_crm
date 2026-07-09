defmodule CleanerCrmSpex.SharedGivens do
  @moduledoc """
  Shared givens for Cleaner CRM BDD specs.

  Consumer spex modules pull these in with a plain Elixir `import`:

      import CleanerCrmSpex.SharedGivens

      scenario "..." do
        given_ :logged_in_owner_with_account
      end

  | Name | Produces | Requires |
  |---|---|---|
  | `:logged_in_owner_with_account` | `context.conn` (authenticated), `context.user`, `context.scope`, `context.account` | `context.conn` |
  """

  use SexySpex.Givens

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias CleanerCrmSpex.Fixtures

  @endpoint CleanerCrmWeb.Endpoint

  register_given :logged_in_owner_with_account, context do
    user = Fixtures.user_fixture() |> Fixtures.set_password()
    scope = Fixtures.user_scope_fixture(user)
    account = Fixtures.account_fixture(scope)

    {:ok, login_live, _html} = live(context.conn, "/users/log-in")

    form =
      form(login_live, "#login_form_password",
        user: %{
          email: user.email,
          password: Fixtures.valid_user_password(),
          remember_me: true
        }
      )

    conn = submit_form(form, context.conn)

    {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
  end
end
