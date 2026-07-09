defmodule CleanerCrmTest.Journeys.PreferredCleanerContinuityTest do
  @moduledoc """
  Journey 4 (.code_my_spec/qa/journey_plan.md): a recurring plan's
  visits default to its preferred cleaner, a one-off reassignment
  warns but doesn't rewrite the plan, and a no-preference plan warns
  on nothing.
  """

  use CleanerCrmTest.FeatureCase, async: false

  import Ecto.Query

  alias CleanerCrm.Repo
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.RecurringPlan

  feature "recurring plans default to (and protect) the preferred cleaner", %{session: session} do
    %{owner_scope: scope, owner: owner, cleaner: preferred, password: password} =
      account_with_owner_and_cleaner()

    other_cleaner = cleaner_fixture(scope, scope.active_account)

    client = client_fixture(scope, %{name: "Journey4 QA Client"})
    property = client |> then(&property_fixture(scope, &1, %{service_address: "4 Plan Pl"}))

    session = log_in(session, owner, password)

    start_date = Date.utc_today() |> Date.add(7) |> Date.to_iso8601()

    session
    |> visit!("/schedule/plans/new")
    |> set_field("#plan_property_id", property.id)
    |> set_field("#plan_cleaner_id", to_string(preferred.id))
    |> set_field("#plan_recurrence", "weekly")
    |> set_field("#plan_start_date", start_date)
    |> set_field("#plan_occurrence_count", "3")
    |> click(css("[data-test='save-plan-button']"))
    |> settle()

    [plan] = plans_for_property(property)
    visits = Scheduling.list_jobs(scope) |> Enum.filter(&(&1.recurring_plan_id == plan.id))
    assert length(visits) == 3
    assert Enum.all?(visits, &(&1.cleaner_id == preferred.id))

    [first_visit, second_visit, third_visit] = Enum.sort_by(visits, & &1.scheduled_date)

    session
    |> visit!("/schedule")
    |> set_field(
      "[data-test='job-#{first_visit.id}-cleaner-select']",
      to_string(other_cleaner.id)
    )
    |> settle()
    |> assert_has(css("body", text: "assigned away from the client's preferred cleaner"))

    reloaded_plan = Scheduling.get_recurring_plan!(scope, plan.id)
    assert reloaded_plan.cleaner_id == preferred.id

    for visit <- [second_visit, third_visit] do
      reloaded = Scheduling.get_job!(scope, visit.id)
      assert reloaded.cleaner_id == preferred.id
    end

    # Second plan, no preferred cleaner — reassigning a visit warns
    # about nothing.
    session
    |> visit!("/schedule/plans/new")
    |> set_field("#plan_property_id", property.id)
    |> set_field("#plan_recurrence", "weekly")
    |> set_field("#plan_start_date", Date.utc_today() |> Date.add(60) |> Date.to_iso8601())
    |> set_field("#plan_occurrence_count", "2")
    |> click(css("[data-test='save-plan-button']"))
    |> settle()

    [_first_plan, second_plan] = plans_for_property(property)

    second_visit =
      Scheduling.list_jobs(scope) |> Enum.find(&(&1.recurring_plan_id == second_plan.id))

    refute second_visit.cleaner_id

    session
    |> visit!("/schedule")
    |> set_field(
      "[data-test='job-#{second_visit.id}-cleaner-select']",
      to_string(other_cleaner.id)
    )
    |> settle()
    |> refute_has(css("body", text: "assigned away from the client's preferred cleaner"))
  end

  defp plans_for_property(property) do
    RecurringPlan
    |> where([p], p.property_id == ^property.id)
    |> order_by([p], asc: p.inserted_at)
    |> Repo.all()
  end
end
