defmodule CleanerCrmSpex.Story852.Criterion7242Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7242 — Client adds a tip at payment

  Route contract: a tip is "recorded per cleaner" and "tips appear in
  cleaner earnings". Observed on `CleanerCrmWeb.FieldLive.EarningsComponent`
  (`[data-test='pay-period-total']` on `/field`), the same surface
  story 838's time-tracking criteria already read the cleaner's
  earnings from.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a tip a client adds at payment reaches the assigned cleaner's earnings" do
    scenario "client adds a tip at payment" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have an unpaid invoice for a visit done by my assigned cleaner", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)
        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_with_proof_of_work_fixture(context.scope, client, %{
            cleaner_id: cleaner.id
          })

        invoice =
          Fixtures.invoice_fixture(context.scope, job, %{
            amount: Decimal.new("150.00"),
            status: :unpaid
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok,
         Map.merge(context, %{
           cleaner: cleaner,
           cleaner_conn: cleaner_conn,
           client: client,
           invoice: invoice,
           portal_conn: portal_conn
         })}
      end

      when_ "I pay the invoice and add a $10 tip", context do
        {:ok, invoices_live, _html} = live(context.portal_conn, ~p"/portal/invoices")

        invoices_live
        |> element("[data-test='invoice-#{context.invoice.id}-pay-button']")
        |> render_click()

        invoices_live
        |> form("[data-test='invoice-#{context.invoice.id}-payment-form']",
          payment: %{card_token: "pm_card_visa", tip_cents: "1000"}
        )
        |> render_submit()

        {:ok, context}
      end

      then_ "my tip appears in my cleaner's earnings", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/field")

        assert has_element?(today_live, "[data-test='pay-period-total']", "$10.00")

        {:ok, context}
      end
    end
  end
end
