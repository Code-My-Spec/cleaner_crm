defmodule CleanerCrmSpex.Story852.Criterion7238Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7238 — Client pays an invoice with a new card

  Per the payments-stripe ADR (see `CleanerCrm.Billing`'s moduledoc),
  a submitted charge only ever moves an invoice to `:charge_pending`
  — final `:paid` status is webhook-driven (criterion 7239). This
  spec's subject is the submission itself, so it asserts the
  submission's own confirmation and receipt rather than a final
  "Paid" status.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "a client pays an invoice with a new card from the portal" do
    scenario "client pays an invoice with a new card" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have an unpaid invoice and no card on file", context do
        client = Fixtures.client_fixture(context.scope, %{card_on_file: false})
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        invoice =
          Fixtures.invoice_fixture(context.scope, job, %{
            amount: Decimal.new("150.00"),
            status: :unpaid
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, invoice: invoice, portal_conn: portal_conn})}
      end

      when_ "I pay the invoice with a new card", context do
        {:ok, invoices_live, _html} = live(context.portal_conn, ~p"/portal/invoices")

        invoices_live
        |> element("[data-test='invoice-#{context.invoice.id}-pay-button']")
        |> render_click()

        invoices_live
        |> form("[data-test='invoice-#{context.invoice.id}-payment-form']",
          payment: %{card_token: "pm_card_visa"}
        )
        |> render_submit()

        {:ok, Map.put(context, :invoices_live, invoices_live)}
      end

      then_ "my payment is submitted for the full invoice amount", context do
        assert render(context.invoices_live) =~ "$150.00"

        {:ok, context}
      end

      then_ "I receive a receipt", context do
        assert_email_sent(to: context.client.email)

        {:ok, context}
      end
    end
  end
end
