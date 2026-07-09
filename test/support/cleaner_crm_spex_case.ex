defmodule CleanerCrmSpex.Case do
  @moduledoc """
  Base case for spex (BDD spec) tests.

  Wires up Phoenix.ConnTest for HTTP assertions, Phoenix.LiveViewTest
  for driving LiveViews, the SexySpex DSL (spex/scenario/given_/when_/then_),
  and the DB sandbox.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint CleanerCrmWeb.Endpoint

      use CleanerCrmWeb, :verified_routes
      use SexySpex

      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import CleanerCrmSpex.Case
    end
  end

  setup tags do
    CleanerCrmTest.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
