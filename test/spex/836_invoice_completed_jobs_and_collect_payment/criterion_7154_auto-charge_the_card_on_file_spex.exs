defmodule CleanerCrmSpex.Story836.Criterion7154Spex do
  @moduledoc """
  Story 836 — Invoice completed jobs and collect payment
  Criterion 7154 — Auto-charge the card on file

  Job completion and invoice generation are covered end-to-end by
  criterion 7153's own spec. This spec's subject is the
  charge-the-card-on-file decision, so the completed job and its
  invoice are seeded directly via `CleanerCrmSpex.Fixtures` rather
  than re-driving completion here.
  """

  use CleanerCrmSpex.Case

  import Swoosh.TestAssertions

  alias CleanerCrmSpex.Fixtures

  spex "charging the client's card on file for a generated invoice" do
    scenario "auto-charge the card on file" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client has a valid card on file", context do
        client =
          Fixtures.client_fixture(context.scope, %{
            card_on_file: true,
            card_token: "pm_card_visa"
          })

        {:ok, Map.put(context, :client, client)}
      end

      given_ "the invoice is generated for a completed job", context do
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, context.client)
        invoice = Fixtures.invoice_fixture(context.scope, job, %{amount: job.agreed_price})

        {:ok, Map.merge(context, %{job: job, invoice: invoice})}
      end

      when_ "the owner charges the card on file", context do
        {:ok, invoice_live, _html} = live(context.conn, ~p"/app/invoices/#{context.invoice.id}")

        invoice_live
        |> element("[data-test='charge-card-button']")
        |> render_click()

        {:ok, Map.put(context, :invoice_live, invoice_live)}
      end

      then_ "the card is charged for the invoice amount", context do
        assert render(context.invoice_live) =~ "$150.00"

        {:ok, context}
      end

      then_ "the client receives a receipt", context do
        assert_email_sent(to: context.client.email)

        {:ok, context}
      end
    end
  end
end
