defmodule CleanerCrmSpex.Story852.Criterion7239Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7239 — Invoice marked paid on webhook confirmation

  The charge submission itself is covered by criterion 7238's spec;
  this spec's subject is the webhook-driven final transition, so the
  pending charge is seeded directly via `CleanerCrmSpex.Fixtures` and
  the webhook is posted the same way story 836's criterion 7158
  already proves for the owner-facing invoice.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a portal payment is only marked paid once the provider confirms it" do
    scenario "invoice marked paid on webhook confirmation" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I submitted payment on an invoice and it's awaiting confirmation", context do
        client = Fixtures.client_fixture(context.scope)
        job = Fixtures.job_with_proof_of_work_fixture(context.scope, client)

        invoice =
          Fixtures.invoice_fixture(context.scope, job, %{
            amount: Decimal.new("150.00"),
            status: :charge_pending,
            stripe_payment_intent_id: "pi_test_portal_succeeded_123"
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, invoice: invoice, portal_conn: portal_conn})}
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

      then_ "I see the invoice marked paid in the portal", context do
        {:ok, _invoices_live, html} = live(context.portal_conn, ~p"/portal/invoices")

        assert html =~ "Paid"

        {:ok, context}
      end
    end
  end
end
