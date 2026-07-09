defmodule CleanerCrmSpex.Story852.Criterion7237Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7237 — Client views invoice list

  Assumes `PortalLive.Invoices` at `/portal/invoices` renders one row
  per invoice (`[data-test='invoice-row-<id>']`) showing its amount
  and paid/unpaid status. This story's other criteria (7238, 7241,
  7242, 7243) assume the same page also carries an inline payment
  form per unpaid invoice (`[data-test='invoice-<id>-pay-button']`
  revealing `[data-test='invoice-<id>-payment-form']` with
  `payment[card_token]`, `payment[save_card]`, and
  `payment[tip_cents]` fields).
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a client sees every invoice for their account in the portal" do
    scenario "client views invoice list" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have one paid invoice and one unpaid invoice", context do
        client = Fixtures.client_fixture(context.scope)

        paid_job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        paid_invoice =
          Fixtures.invoice_fixture(context.scope, paid_job, %{
            amount: Decimal.new("150.00"),
            status: :paid
          })

        unpaid_job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        unpaid_invoice =
          Fixtures.invoice_fixture(context.scope, unpaid_job, %{
            amount: Decimal.new("200.00"),
            status: :unpaid
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok,
         Map.merge(context, %{
           client: client,
           paid_invoice: paid_invoice,
           unpaid_invoice: unpaid_invoice,
           portal_conn: portal_conn
         })}
      end

      when_ "I open my invoices in the portal", context do
        {:ok, invoices_live, _html} = live(context.portal_conn, ~p"/portal/invoices")

        {:ok, Map.put(context, :invoices_live, invoices_live)}
      end

      then_ "I see both invoices with their amounts and statuses", context do
        assert has_element?(
                 context.invoices_live,
                 "[data-test='invoice-row-#{context.paid_invoice.id}']",
                 "$150.00"
               )

        assert has_element?(
                 context.invoices_live,
                 "[data-test='invoice-row-#{context.paid_invoice.id}']",
                 "Paid"
               )

        assert has_element?(
                 context.invoices_live,
                 "[data-test='invoice-row-#{context.unpaid_invoice.id}']",
                 "$200.00"
               )

        assert has_element?(
                 context.invoices_live,
                 "[data-test='invoice-row-#{context.unpaid_invoice.id}']",
                 "Unpaid"
               )

        {:ok, context}
      end
    end
  end
end
