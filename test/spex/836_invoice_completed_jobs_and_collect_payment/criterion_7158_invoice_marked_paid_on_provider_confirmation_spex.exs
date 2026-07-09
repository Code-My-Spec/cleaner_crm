defmodule CleanerCrmSpex.Story836.Criterion7158Spex do
  @moduledoc """
  Story 836 — Invoice completed jobs and collect payment
  Criterion 7158 — Invoice marked paid on provider confirmation
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "marking an invoice paid only on provider confirmation" do
    scenario "invoice marked paid on provider confirmation" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "an invoice charge has been submitted to the payment provider", context do
        client = Fixtures.client_fixture(context.scope, %{card_on_file: true})
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        invoice =
          Fixtures.invoice_fixture(context.scope, job, %{
            amount: job.agreed_price,
            status: :charge_pending,
            stripe_payment_intent_id: "pi_test_succeeded_123"
          })

        {:ok, Map.merge(context, %{client: client, job: job, invoice: invoice})}
      end

      when_ "the provider confirms the charge succeeded", context do
        payload = %{
          "type" => "payment_intent.succeeded",
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

      then_ "the invoice is marked paid", context do
        {:ok, _invoice_live, html} = live(context.conn, ~p"/app/invoices/#{context.invoice.id}")

        assert html =~ "Paid"

        {:ok, context}
      end

      then_ "the owner sees it settled in the billing queue", context do
        {:ok, _invoices_live, html} = live(context.conn, ~p"/app/invoices")

        assert html =~ context.client.name
        assert html =~ "Paid"

        {:ok, context}
      end
    end
  end
end
