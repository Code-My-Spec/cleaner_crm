defmodule CleanerCrmWeb.FieldLive.ChecklistComponentTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Billing
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  defp owner_scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{user: user, scope: %{scope | active_account: account, active_account_id: account.id}}
  end

  # Regression for the accepted issue: completing a job with no agreed
  # price crashed invoice generation on the `invoices.amount_cents` NOT
  # NULL constraint. An unpriced recurring plan materializes visits
  # with no price (`CleanerCrm.Scheduling.Recurrence.job_attrs/1`), so
  # this drives that exact real-usage path end to end: create such a
  # plan, then complete the job it generated through the live UI.
  test "completing a plan-generated job with no agreed price completes without crashing and skips its invoice" do
    %{user: owner, scope: scope} = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Jamie Rivera"})
    property = property_fixture(scope, client)

    {:ok, {_plan, [job]}} =
      Scheduling.create_recurring_plan(scope, %{
        property_id: property.id,
        recurrence: :weekly,
        start_date: Date.add(Date.utc_today(), 7),
        occurrence_count: 1
      })

    refute job.agreed_price_cents

    conn = log_in_user(build_conn(), owner)
    {:ok, job_live, _html} = live(conn, ~p"/app/field/jobs/#{job.id}")

    job_live
    |> element("[data-test='mark-complete-button']")
    |> render_click()

    # `ChecklistComponent`'s `send(self(), :job_completed)` lands in the
    # LiveView's mailbox after the click's own render returns — matching
    # story 836's own criterion 7153 spec, a fresh `render/1` is needed
    # to observe the follow-up reload it triggers.
    assert render(job_live) =~ "Complete"

    assert Scheduling.get_job!(scope, job.id).status == :completed
    assert Billing.list_invoices(scope) == []
  end
end
