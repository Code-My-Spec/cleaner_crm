defmodule CleanerCrmSpex.Story852.Criterion7240Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7240 — Declined card leaves invoice unpaid

  Mirrors story 836's criterion 7157 for the owner-facing invoice:
  the Test Stripe adapter always submits successfully, so a decline is
  only ever driven by posting the failure webhook directly.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a declined card leaves a portal invoice unpaid" do
    scenario "declined card leaves invoice unpaid" do
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
            stripe_payment_intent_id: "pi_test_portal_declined_123"
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, Map.merge(context, %{client: client, invoice: invoice, portal_conn: portal_conn})}
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

      then_ "the invoice remains unpaid and I can try again", context do
        {:ok, invoices_live, html} = live(context.portal_conn, ~p"/portal/invoices")

        assert html =~ "Unpaid"

        assert has_element?(
                 invoices_live,
                 "[data-test='invoice-#{context.invoice.id}-pay-button']"
               )

        {:ok, context}
      end
    end
  end
end
