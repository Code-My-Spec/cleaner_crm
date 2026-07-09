defmodule CleanerCrm.PortalCrossClientTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Portal
  alias CleanerCrmSpex.Fixtures

  describe "get_visit!/2 cross-client isolation" do
    test "raises NoResultsError (prod 404) for another client's visit on the same account" do
      user = Fixtures.user_fixture()
      scope = Fixtures.user_scope_fixture(user)
      _account = Fixtures.account_fixture(scope)

      client_a = Fixtures.client_fixture(scope)

      client_b =
        Fixtures.client_fixture(scope, %{name: "Other Client", email: "other@example.com"})

      job_b = Fixtures.job_fixture(scope, client_b, %{})

      assert_raise Ecto.NoResultsError, fn ->
        Portal.get_visit!(client_a, job_b.id)
      end
    end

    test "returns the visit for its own client" do
      user = Fixtures.user_fixture()
      scope = Fixtures.user_scope_fixture(user)
      _account = Fixtures.account_fixture(scope)

      client = Fixtures.client_fixture(scope)
      job = Fixtures.job_fixture(scope, client, %{})

      assert Portal.get_visit!(client, job.id).id == job.id
    end
  end
end
