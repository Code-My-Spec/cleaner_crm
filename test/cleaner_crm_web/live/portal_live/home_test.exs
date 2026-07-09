defmodule CleanerCrmWeb.PortalLive.HomeTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Quality
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  defp owner_scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)
    {:ok, account} = Accounts.create_account(scope, %{name: "Sparkle Co"})
    %{scope | active_account: account, active_account_id: account.id}
  end

  defp portal_conn(client) do
    build_conn()
    |> init_test_session(%{})
    |> put_session(:portal_client_id, client.id)
  end

  test "shows an upcoming visit's assigned cleaner and a completed visit's proof-of-work" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    cleaner = CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, scope.active_account)

    upcoming =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        cleaner_id: cleaner.id,
        scheduled_date: Date.add(Date.utc_today(), 7),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })
      |> then(fn {:ok, job} -> job end)

    {:ok, completed} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        scheduled_date: Date.add(Date.utc_today(), -7),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        status: :completed
      })

    {:ok, _checklist} =
      Quality.complete_checklist(scope, completed, [
        %{
          task: "Kitchen counters wiped down",
          before_photo: "before.jpg",
          after_photo: "after.jpg"
        }
      ])

    {:ok, portal_live, _html} = live(portal_conn(client), ~p"/portal")

    assert has_element?(portal_live, "[data-test='upcoming-visits']")
    assert has_element?(portal_live, "[data-test='visit-#{upcoming.id}']", cleaner.name)

    assert has_element?(
             portal_live,
             "[data-test='service-history'] [data-test='visit-#{completed.id}']",
             "Kitchen counters wiped down"
           )

    assert has_element?(
             portal_live,
             "[data-test='visit-#{completed.id}'] [data-test='before-photo']"
           )
  end

  test "an unassigned upcoming visit shows a placeholder instead of a cleaner" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        scheduled_date: Date.add(Date.utc_today(), 7),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00]
      })

    {:ok, portal_live, _html} = live(portal_conn(client), ~p"/portal")

    assert has_element?(
             portal_live,
             "[data-test='visit-#{job.id}'] [data-test='cleaner-not-assigned']"
           )
  end

  test "redirects to request-link when there is no portal session" do
    assert {:error, {:redirect, %{to: "/portal/request-link"}}} = live(build_conn(), ~p"/portal")
  end
end
