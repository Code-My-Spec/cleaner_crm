defmodule CleanerCrmMcp.Tools.BillingTest do
  use CleanerCrmTest.DataCase, async: true

  import CleanerCrm.UsersFixtures

  alias CleanerCrm.{Accounts, Billing, Clients, Portal, Repo, Scheduling}
  alias CleanerCrm.Billing.Payment
  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.Catalog

  alias CleanerCrmMcp.Tools.Billing.{
    GenerateInvoiceForJob,
    GetCancellationPolicy,
    GetInvoice,
    GetPayment,
    ListInvoices,
    ListPayments,
    ListTips
  }

  defp scope_fixture(name) do
    owner_scope = Scope.for_user(user_fixture())
    {:ok, account} = Accounts.create_account(owner_scope, %{name: name})
    %{owner_scope | active_account_id: account.id, active_account: account}
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

  setup do
    scope = scope_fixture("Sparkle")
    other = scope_fixture("Other Co")
    {:ok, client} = Clients.create_client(scope, %{name: "A Client"})
    job = job_fixture(scope, client, %{agreed_price_cents: 15_000})
    %{scope: scope, other: other, client: client, job: job}
  end

  test "every tool is registered in the catalog" do
    for tool <- CleanerCrmMcp.Tools.Billing.tools() do
      assert {:ok, ^tool} = Catalog.fetch(tool.name())
    end
  end

  describe "generate_invoice_for_job" do
    test "creates an invoice once, by job number or id", %{scope: scope, job: job, client: client} do
      {:ok, args} = Catalog.coerce(GenerateInvoiceForJob, %{"job_number" => "##{job.job_number}"})
      assert {:ok, inv} = GenerateInvoiceForJob.call(args, scope)
      assert inv["amount_cents"] == 15_000
      assert inv["amount"] == 150.0
      assert inv["status"] == "unpaid"
      assert inv["client"]["name"] == client.name
      assert inv["already_existed"] == false

      assert {:ok, again} = GenerateInvoiceForJob.call(%{"job_id" => job.id}, scope)
      assert again["id"] == inv["id"]
      assert again["already_existed"] == true
    end

    test "errors for unpriced, unknown, and other-account jobs", %{
      scope: scope,
      other: other,
      job: job,
      client: client
    } do
      unpriced = job_fixture(scope, client, %{agreed_price_cents: nil})

      assert {:error, msg} =
               GenerateInvoiceForJob.call(%{"job_number" => unpriced.job_number}, scope)

      assert msg =~ "no agreed price"

      assert {:error, "no job" <> _} =
               GenerateInvoiceForJob.call(%{"job_number" => 999_999}, scope)

      assert {:error, "no job" <> _} = GenerateInvoiceForJob.call(%{"job_id" => job.id}, other)
      assert {:error, "no job" <> _} = GenerateInvoiceForJob.call(%{"job_id" => "nope"}, scope)
      assert {:error, "give" <> _} = GenerateInvoiceForJob.call(%{}, scope)
    end
  end

  describe "invoices and payments" do
    setup %{scope: scope, job: job} do
      {:ok, invoice} = Billing.generate_for_job(scope, job)

      {:ok, payment} =
        Repo.insert(%Payment{
          account_id: scope.active_account_id,
          invoice_id: invoice.id,
          amount_cents: 15_000,
          status: :failed,
          source: "card_on_file"
        })

      %{invoice: invoice, payment: payment}
    end

    test "list_invoices filters", %{scope: scope, invoice: invoice, client: client} do
      assert {:ok, [i]} = ListInvoices.call(%{"status" => "unpaid"}, scope)
      assert i["id"] == invoice.id
      assert {:ok, []} = ListInvoices.call(%{"status" => "paid"}, scope)
      assert {:ok, [_]} = ListInvoices.call(%{"client_id" => client.id}, scope)
      assert {:ok, []} = ListInvoices.call(%{"client_id" => Ecto.UUID.generate()}, scope)
      today = Date.utc_today()
      assert {:ok, [_]} = ListInvoices.call(%{"from" => today, "to" => today}, scope)
      assert {:ok, []} = ListInvoices.call(%{"to" => Date.add(today, -1)}, scope)
      assert {:error, _} = ListInvoices.call(%{"status" => "bogus"}, scope)
      assert {:error, "client_id" <> _} = ListInvoices.call(%{"client_id" => "zzz"}, scope)
    end

    test "get_invoice includes payments and is account-scoped", %{
      scope: scope,
      other: other,
      invoice: invoice
    } do
      assert {:ok, inv} = GetInvoice.call(%{"id" => invoice.id}, scope)
      assert [%{"status" => "failed", "amount_cents" => 15_000}] = inv["payments"]
      assert {:error, "no invoice" <> _} = GetInvoice.call(%{"id" => invoice.id}, other)
      assert {:ok, []} = ListInvoices.call(%{}, other)
    end

    test "payments", %{scope: scope, other: other, payment: payment, invoice: invoice} do
      assert {:ok, [p]} = ListPayments.call(%{"status" => "failed"}, scope)
      assert p["id"] == payment.id
      assert {:ok, []} = ListPayments.call(%{"status" => "succeeded"}, scope)
      assert {:ok, [_]} = ListPayments.call(%{"invoice_id" => invoice.id}, scope)
      assert {:ok, []} = ListPayments.call(%{}, other)

      assert {:ok, %{"source" => "card_on_file", "amount" => 150.0}} =
               GetPayment.call(%{"id" => payment.id}, scope)

      assert {:error, "no payment" <> _} = GetPayment.call(%{"id" => payment.id}, other)
      assert {:error, "no payment" <> _} = GetPayment.call(%{"id" => "x"}, scope)
    end

    test "tips", %{scope: scope, other: other, invoice: invoice} do
      cleaner =
        CleanerCrm.SchedulingFixtures.cleaner_fixture(scope, scope.active_account, %{name: "Cleo"})

      {:ok, _} =
        %Portal.Tip{
          account_id: scope.active_account_id,
          invoice_id: invoice.id,
          cleaner_id: cleaner.id
        }
        |> Portal.Tip.changeset(%{amount_cents: 500})
        |> Repo.insert()

      assert {:ok, [t]} = ListTips.call(%{}, scope)
      assert t["amount_cents"] == 500
      assert t["cleaner_name"] == "Cleo"
      assert {:ok, [_]} = ListTips.call(%{"cleaner_id" => cleaner.id}, scope)
      assert {:ok, []} = ListTips.call(%{"cleaner_id" => -1}, scope)
      assert {:ok, []} = ListTips.call(%{}, other)
    end
  end

  describe "get_cancellation_policy" do
    test "defaults, then reflects the account's policy", %{scope: scope, other: other} do
      assert {:ok, %{"late_fee_cents" => 0, "notice_window_hours" => 24}} =
               GetCancellationPolicy.call(%{}, scope)

      {:ok, _} =
        Portal.set_cancellation_policy(scope, %{
          late_fee_cents: 2500,
          same_day_fee_cents: 5000,
          policy_text: "24h notice"
        })

      assert {:ok, p} = GetCancellationPolicy.call(%{}, scope)
      assert p["late_fee"] == 25.0
      assert p["same_day_fee_cents"] == 5000
      assert {:ok, %{"late_fee_cents" => 0}} = GetCancellationPolicy.call(%{}, other)
    end
  end
end
