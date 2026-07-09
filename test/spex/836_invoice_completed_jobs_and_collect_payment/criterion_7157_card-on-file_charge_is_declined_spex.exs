defmodule CleanerCrmSpex.Story836.Criterion7157Spex do
  @moduledoc """
  Story 836 — Invoice completed jobs and collect payment
  Criterion 7157 — Card-on-file charge is declined

  The charge submission itself is covered by criterion 7154's spec;
  this spec's subject is how a decline response from the payment
  provider is handled, so the pending charge is seeded directly via
  `CleanerCrmSpex.Fixtures`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "handling a declined card-on-file charge" do
    scenario "card-on-file charge is declined" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "an invoice is set to auto-charge the card on file", context do
        client = Fixtures.client_fixture(context.scope, %{card_on_file: true})
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        invoice =
          Fixtures.invoice_fixture(context.scope, job, %{
            amount: job.agreed_price,
            status: :charge_pending,
            stripe_payment_intent_id: "pi_test_declined_123"
          })

        {:ok, Map.merge(context, %{client: client, job: job, invoice: invoice})}
      end

      when_ "the payment provider declines the card", context do
        payload = %{
          "type" => "payment_intent.payment_failed",
          "data" => %{
            "object" => %{
              "id" => context.invoice.stripe_payment_intent_id,
              "metadata" => %{"invoice_id" => to_string(context.invoice.id)}
            }
          }
        }

        response =
          Phoenix.ConnTest.build_conn()
          |> Plug.Conn.put_req_header("content-type", "application/json")
          |> post("/webhooks/stripe", payload)
          |> Phoenix.ConnTest.json_response(200)

        {:ok, Map.put(context, :webhook_response, response)}
      end

      then_ "the invoice remains unpaid", context do
        {:ok, _invoice_live, html} = live(context.conn, ~p"/app/invoices/#{context.invoice.id}")

        assert html =~ "Unpaid"

        {:ok, context}
      end

      then_ "the owner is alerted to retry the charge or send a payment link", context do
        {:ok, invoice_live, _html} = live(context.conn, ~p"/app/invoices/#{context.invoice.id}")

        assert has_element?(invoice_live, "[data-test='retry-charge-button']")
        assert has_element?(invoice_live, "[data-test='send-payment-link-button']")

        {:ok, context}
      end
    end
  end
end
