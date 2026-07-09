defmodule CleanerCrmWeb.ScheduleLive.PlanFormComponentTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures
  import CleanerCrm.SchedulingFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling.{Job, RecurringPlan}
  alias CleanerCrm.Users.Scope
  alias CleanerCrmWeb.ScheduleLive.PlanFormComponent

  # Hosts the component in isolation (no router route required), same
  # pattern as ClientLive.PropertyFormComponentTest.
  defmodule Host do
    use CleanerCrmWeb, :live_view

    @impl true
    def mount(_params, session, socket) do
      {:ok,
       assign(socket, %{
         test_pid: session["test_pid"],
         current_scope: session["scope"],
         action: session["action"],
         plan: session["plan"]
       })}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.live_component
        module={PlanFormComponent}
        id="plan-form"
        current_scope={@current_scope}
        action={@action}
        plan={@plan}
      />
      """
    end

    @impl true
    def handle_info({PlanFormComponent, _} = message, socket) do
      send(socket.assigns.test_pid, message)
      {:noreply, socket}
    end
  end

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp render_host(session) do
    session = Map.put(session, "test_pid", self())
    live_isolated(build_conn(), Host, session: session)
  end

  defp first_visit_date, do: Date.add(Date.utc_today(), 14)
  defp visit_date(n), do: Date.add(first_visit_date(), (n - 1) * 7)

  describe "creating a recurring plan" do
    test "renders the plan form with the account's properties and cleaners" do
      scope = scope_fixture()
      client = client_fixture(scope, %{name: "Jamie Rivera"})
      property_fixture(scope, client, %{service_address: "12 Oak Lane"})
      cleaner_fixture(scope, scope.active_account, %{name: "Alex Morgan"})

      {:ok, _lv, html} =
        render_host(%{"scope" => scope, "action" => :new, "plan" => %RecurringPlan{}})

      assert html =~ "12 Oak Lane"
      assert html =~ "Alex Morgan"
      assert has_element?(_lv, "[data-test='save-plan-button']")
    end

    test "a conflict-free weekly series saves cleanly and materializes every job" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "plan" => %RecurringPlan{}})

      lv
      |> form("[data-test='plan-form']",
        plan: %{
          property_id: property.id,
          cleaner_id: cleaner.id,
          recurrence: "weekly",
          start_date: Date.to_iso8601(first_visit_date()),
          occurrence_count: 8
        }
      )
      |> render_change()

      lv
      |> element("[data-test='save-plan-button']")
      |> render_click()

      assert_receive {PlanFormComponent, {:saved, %RecurringPlan{} = plan}}
      assert Repo.aggregate(Job, :count) == 8
      refute has_element?(lv, "[data-test^='conflict-visit-']")
      assert plan.occurrence_count == 8
    end

    test "a price set on the plan carries through to every materialized job" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "plan" => %RecurringPlan{}})

      lv
      |> form("[data-test='plan-form']",
        plan: %{
          property_id: property.id,
          cleaner_id: cleaner.id,
          recurrence: "weekly",
          start_date: Date.to_iso8601(first_visit_date()),
          occurrence_count: 3,
          agreed_price: "125.00"
        }
      )
      |> render_change()

      lv
      |> element("[data-test='save-plan-button']")
      |> render_click()

      assert_receive {PlanFormComponent, {:saved, %RecurringPlan{} = plan}}
      assert plan.agreed_price_cents == 12_500

      jobs = Repo.all(Job)
      assert length(jobs) == 3
      assert Enum.all?(jobs, &(&1.agreed_price_cents == 12_500))
    end

    test "flags a conflicting later occurrence without blocking the save, and keeps showing it after" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      availability_block_fixture(scope, cleaner, %{date: visit_date(4), all_day: true})

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "plan" => %RecurringPlan{}})

      lv
      |> form("[data-test='plan-form']",
        plan: %{
          property_id: property.id,
          cleaner_id: cleaner.id,
          recurrence: "weekly",
          start_date: Date.to_iso8601(first_visit_date()),
          occurrence_count: 8
        }
      )
      |> render_change()

      lv
      |> element("[data-test='save-plan-button']")
      |> render_click()

      assert_receive {PlanFormComponent, {:saved, _plan}}
      assert Repo.aggregate(Job, :count) == 8

      html = render(lv)
      assert has_element?(lv, "[data-test='conflict-visit-4']")
      assert html =~ "Visit 4"
      refute has_element?(lv, "[data-test='conflict-visit-1']")
    end

    test "shows conflicts and override controls as a live preview before saving" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      availability_block_fixture(scope, cleaner, %{date: visit_date(4), all_day: true})
      availability_block_fixture(scope, cleaner, %{date: visit_date(7), all_day: true})

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "plan" => %RecurringPlan{}})

      lv
      |> form("[data-test='plan-form']",
        plan: %{
          property_id: property.id,
          cleaner_id: cleaner.id,
          recurrence: "weekly",
          start_date: Date.to_iso8601(first_visit_date())
        }
      )
      |> render_change()

      lv
      |> form("[data-test='plan-form']", plan: %{occurrence_count: 8})
      |> render_change()

      assert has_element?(lv, "[data-test='conflict-visit-4']")
      assert has_element?(lv, "[data-test='conflict-visit-7']")
      assert has_element?(lv, "[data-test='override-conflict-4']")
      assert has_element?(lv, "[data-test='override-conflict-7']")
      assert has_element?(lv, "[data-test='save-plan-button']")
      assert Repo.aggregate(Job, :count) == 0
    end

    test "overriding a conflict removes its warning" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      availability_block_fixture(scope, cleaner, %{date: visit_date(4), all_day: true})

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "plan" => %RecurringPlan{}})

      lv
      |> form("[data-test='plan-form']",
        plan: %{
          property_id: property.id,
          cleaner_id: cleaner.id,
          recurrence: "weekly",
          start_date: Date.to_iso8601(first_visit_date()),
          occurrence_count: 8
        }
      )
      |> render_change()

      assert has_element?(lv, "[data-test='conflict-visit-4']")

      lv
      |> element("[data-test='override-conflict-4']")
      |> render_click()

      refute has_element?(lv, "[data-test='conflict-visit-4']")
    end
  end
end
