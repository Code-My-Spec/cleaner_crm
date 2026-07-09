defmodule CleanerCrmSpex.Story836.Criterion7155Spex do
  @moduledoc """
  Story 836 — Invoice completed jobs and collect payment
  Criterion 7155 — Client with no card on file pays via payment link

  As in criterion 7154, job completion and invoice generation are
  seeded via `CleanerCrmSpex.Fixtures` (covered end-to-end by
  criterion 7153) so this spec can focus on the payment-link
  collection path.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "collecting payment via a payment link when no card is on file" do
    scenario "client with no card on file pays via payment link" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "a client has no card on file", context do
        client = Fixtures.client_fixture(context.scope, %{card_on_file: false})

        {:ok, Map.put(context, :client, client)}
      end

      given_ "an invoice exists for that client's completed job", context do
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, context.client)
        invoice = Fixtures.invoice_fixture(context.scope, job, %{amount: job.agreed_price})

        {:ok, Map.merge(context, %{job: job, invoice: invoice})}
      end

      when_ "the owner sends the invoice as a payment link and the client pays it online",
            context do
        {:ok, invoice_live, _html} = live(context.conn, ~p"/invoices/#{context.invoice.id}")

        html_after_send =
          invoice_live
          |> element("[data-test='send-payment-link-button']")
          |> render_click()

        [_, payment_path] = Regex.run(~r{href="(/pay/[^"]+)"}, html_after_send)

        client_conn =
          Phoenix.ConnTest.build_conn()
          |> post(payment_path, %{"payment_method" => "pm_card_visa", "save_card" => "true"})

        {:ok, Map.put(context, :client_conn, client_conn)}
      end

      then_ "the invoice is collected", context do
        assert Phoenix.ConnTest.html_response(context.client_conn, 200) =~ "Payment received"

        {:ok, context}
      end

      then_ "the client's card can be saved for next time", context do
        assert Phoenix.ConnTest.html_response(context.client_conn, 200) =~ "save your card"

        {:ok, context}
      end
    end
  end
end
