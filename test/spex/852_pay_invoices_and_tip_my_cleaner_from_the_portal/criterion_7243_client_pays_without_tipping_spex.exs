defmodule CleanerCrmSpex.Story852.Criterion7243Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7243 — Client pays without tipping

  Counterpart to criterion 7242: leaving the tip field blank must
  still let the payment go through, and must add nothing to the
  cleaner's earnings.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a client can pay an invoice without adding a tip" do
    scenario "client pays without tipping" do
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

      when_ "I pay the invoice leaving the tip blank", context do
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

      then_ "my payment is submitted for the invoice amount alone", context do
        assert render(context.invoices_live) =~ "$150.00"

        {:ok, context}
      end

      then_ "nothing is added to my cleaner's earnings", context do
        {:ok, today_live, _html} = live(context.cleaner_conn, ~p"/app/field")

        assert has_element?(today_live, "[data-test='pay-period-total']", "$0.00")

        {:ok, context}
      end
    end
  end
end
