defmodule CleanerCrmWeb.PortalLive.InvoicesTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures
  import Swoosh.TestAssertions

  alias CleanerCrm.Accounts
  alias CleanerCrm.Billing
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

  defp completed_job_fixture(scope, client) do
    {:ok, job} =
      Scheduling.create_job(scope, %{
        client_id: client.id,
        scheduled_date: Date.add(Date.utc_today(), -1),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        status: :completed
      })

    job
  end

  test "lists invoices with their amounts and statuses" do
    scope = owner_scope_fixture()
    client = client_fixture(scope, %{name: "Morgan Blake"})

    paid_job = completed_job_fixture(scope, client)

    {:ok, paid} =
      Billing.create_invoice(scope, %{job_id: paid_job.id, amount_cents: 15_000, status: :paid})

    unpaid_job = completed_job_fixture(scope, client)
    {:ok, unpaid} = Billing.create_invoice(scope, %{job_id: unpaid_job.id, amount_cents: 20_000})

    {:ok, invoices_live, _html} = live(portal_conn(client), ~p"/portal/invoices")

    assert has_element?(invoices_live, "[data-test='invoice-row-#{paid.id}']", "$150.00")
    assert has_element?(invoices_live, "[data-test='invoice-row-#{paid.id}']", "Paid")
    assert has_element?(invoices_live, "[data-test='invoice-row-#{unpaid.id}']", "$200.00")
    assert has_element?(invoices_live, "[data-test='invoice-row-#{unpaid.id}']", "Unpaid")
  end

  test "pays an invoice with a new card, saves it on file, and emails a receipt" do
    scope = owner_scope_fixture()

    client =
      client_fixture(scope, %{
        name: "Morgan Blake",
        email: "morgan@example.com",
        card_on_file: false
      })

    job = completed_job_fixture(scope, client)
    {:ok, invoice} = Billing.create_invoice(scope, %{job_id: job.id, amount_cents: 15_000})

    {:ok, invoices_live, _html} = live(portal_conn(client), ~p"/portal/invoices")

    invoices_live
    |> element("[data-test='invoice-#{invoice.id}-pay-button']")
    |> render_click()

    invoices_live
    |> form("[data-test='invoice-#{invoice.id}-payment-form']",
      payment: %{card_token: "pm_card_visa", save_card: "true"}
    )
    |> render_submit()

    assert has_element?(invoices_live, "[data-test='card-on-file-badge']")
    assert_email_sent(to: client.email)
  end

  test "a tip added at payment reaches the assigned cleaner's earnings" do
    scope = owner_scope_fixture()
    cleaner = CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, scope.active_account)
    client = client_fixture(scope, %{name: "Morgan Blake"})
    job = completed_job_fixture(scope, client)
    {:ok, job} = Scheduling.assign_cleaner(scope, job, cleaner.id)
    {:ok, invoice} = Billing.create_invoice(scope, %{job_id: job.id, amount_cents: 15_000})

    {:ok, invoices_live, _html} = live(portal_conn(client), ~p"/portal/invoices")

    invoices_live
    |> element("[data-test='invoice-#{invoice.id}-pay-button']")
    |> render_click()

    invoices_live
    |> form("[data-test='invoice-#{invoice.id}-payment-form']",
      payment: %{card_token: "pm_card_visa", tip_cents: "1000"}
    )
    |> render_submit()

    period = CleanerCrm.TimeTracking.current_pay_period(scope)
    assert CleanerCrm.Portal.tip_cents_for_cleaner(scope, cleaner.id, period) == 1_000
  end
end
