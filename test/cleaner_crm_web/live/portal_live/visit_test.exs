defmodule CleanerCrmWeb.PortalLive.VisitTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Portal
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

  test "reschedules a visit to a new date and time" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        agreed_price_cents: 15_000,
        scheduled_date: Date.add(Date.utc_today(), 7),
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00]
      })

    {:ok, visit_live, _html} = live(portal_conn(client), ~p"/portal/visits/#{job.id}")

    visit_live
    |> form("[data-test='reschedule-form']",
      visit: %{date: Date.add(Date.utc_today(), 10), start_time: "14:00"}
    )
    |> render_submit()

    assert render(visit_live) =~ "2:00 PM"
    assert has_element?(visit_live, "[data-test='visit-price']", "$150.00")
  end

  test "rescheduling to a past date shows a form error and leaves the visit unchanged" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        scheduled_date: Date.add(Date.utc_today(), 7),
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00]
      })

    {:ok, visit_live, _html} = live(portal_conn(client), ~p"/portal/visits/#{job.id}")

    visit_live
    |> form("[data-test='reschedule-form']", visit: %{date: "2020-01-01", start_time: "14:00"})
    |> render_submit()

    assert render(visit_live) =~ "must be today or later"

    unchanged = Portal.get_visit!(client, job.id)
    assert unchanged.scheduled_date == Date.add(Date.utc_today(), 7)
    assert unchanged.start_time == ~T[10:00:00]
  end

  test "shows the assigned cleaner's email when their name is blank" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    cleaner =
      CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, scope.active_account, %{name: nil})

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        cleaner_id: cleaner.id,
        scheduled_date: Date.add(Date.utc_today(), 7),
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00]
      })

    {:ok, visit_live, _html} = live(portal_conn(client), ~p"/portal/visits/#{job.id}")

    assert has_element?(visit_live, "[data-test='visit-cleaner-name']", cleaner.email)
    refute render(visit_live) =~ "Not yet assigned"
  end

  test "cancelling inside the notice window shows the fee before confirming" do
    scope = owner_scope_fixture()

    {:ok, _policy} =
      Portal.set_cancellation_policy(scope, %{notice_window_hours: 48, late_fee_cents: 2_500})

    client = client_fixture(scope, %{name: "Morgan Blake"})

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        scheduled_date: Date.add(Date.utc_today(), 1),
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00]
      })

    {:ok, visit_live, _html} = live(portal_conn(client), ~p"/portal/visits/#{job.id}")

    visit_live |> element("[data-test='cancel-visit-button']") |> render_click()
    assert has_element?(visit_live, "[data-test='cancellation-fee-notice']", "$25.00")

    visit_live |> element("[data-test='confirm-cancel-button']") |> render_click()
    assert has_element?(visit_live, "[data-test='cancellation-fee-charged']", "$25.00")
  end

  test "a completed visit offers no reschedule or cancel controls" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        scheduled_date: Date.add(Date.utc_today(), -1),
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00],
        status: :completed
      })

    {:ok, visit_live, _html} = live(portal_conn(client), ~p"/portal/visits/#{job.id}")

    refute has_element?(visit_live, "[data-test='reschedule-form']")
    refute has_element?(visit_live, "[data-test='cancel-visit-button']")
  end
end
