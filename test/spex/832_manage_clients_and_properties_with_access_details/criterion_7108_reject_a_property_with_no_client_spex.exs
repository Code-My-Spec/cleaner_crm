defmodule CleanerCrmSpex.Story832.Criterion7108Spex do
  @moduledoc """
  Story 832 — Manage clients and properties with access details
  Criterion 7108 — Every property must belong to exactly one client;
  submitting a property with no client selected is rejected.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "owner tries to save a property with no client" do
    scenario "the property without a client is rejected" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "the owner is creating a new property", context do
        {:ok, new_live, _html} = live(context.conn, ~p"/app/properties/new")
        {:ok, Map.put(context, :new_live, new_live)}
      end

      when_ "the owner submits the property without selecting a client", context do
        context.new_live
        |> form("[data-test='property-form']", property: %{service_address: "123 Oak St"})
        |> render_submit()

        {:ok, context}
      end

      then_ "the property is not saved", context do
        assert has_element?(context.new_live, "[data-test='property-form']")

        {:ok, context}
      end

      then_ "the owner sees an error that a client is required", context do
        assert has_element?(context.new_live, "[data-test='client-error']", "is required")

        {:ok, context}
      end
    end
  end
end
