defmodule CleanerCrm.BillingTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Accounts
  alias CleanerCrm.Billing
  alias CleanerCrm.Billing.Invoice
  alias CleanerCrm.Clients
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Users.Scope

  import CleanerCrm.UsersFixtures

  setup do
    owner = user_fixture()
    owner_scope = Scope.for_user(owner)
    {:ok, account} = Accounts.create_account(owner_scope, %{name: "Sparkle Co"})
    scope = %{owner_scope | active_account_id: account.id, active_account: account}

    {:ok, client} = Clients.create_client(scope, %{name: "A Client"})

    %{scope: scope, client: client}
  end

  defp job_fixture(scope, client, attrs) do
    {:ok, job} =
      Scheduling.create_job(
        scope,
        Enum.into(attrs, %{
          client_id: client.id,
          scheduled_date: Date.utc_today(),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00],
          status: :scheduled
        })
      )

    job
  end

  describe "generate_for_job/2" do
    test "generates an invoice for the job's agreed price", %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{agreed_price_cents: 15_000})

      assert {:ok, %Invoice{} = invoice} = Billing.generate_for_job(scope, job)
      assert invoice.amount_cents == 15_000
      assert invoice.job_id == job.id
    end

    # Regression: a job materialized from a recurring plan with no price
    # (e.g. `CleanerCrm.Scheduling.Recurrence.job_attrs/1` on an unpriced
    # plan) has `agreed_price_cents: nil`. Generating its invoice used to
    # attempt an insert with a `nil` `amount_cents` and crash on the
    # column's NOT NULL constraint — completing the job must still
    # succeed, so this must return an error tuple, never raise.
    test "skips invoice creation and returns {:error, :no_price} for a nil-priced job, without touching the database",
         %{scope: scope, client: client} do
      job = job_fixture(scope, client, %{agreed_price_cents: nil})

      assert {:error, :no_price} = Billing.generate_for_job(scope, job)
      assert Billing.list_invoices(scope) == []
    end
  end

  describe "create_invoice/2" do
    test "refuses a nil amount_cents with a changeset error instead of crashing", %{
      scope: scope,
      client: client
    } do
      job = job_fixture(scope, client, %{agreed_price_cents: nil})

      assert {:error, %Ecto.Changeset{} = changeset} =
               Billing.create_invoice(scope, %{job_id: job.id, status: :unpaid})

      assert %{amount_cents: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
