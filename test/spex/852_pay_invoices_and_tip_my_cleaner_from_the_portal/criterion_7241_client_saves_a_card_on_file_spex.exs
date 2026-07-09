defmodule CleanerCrmSpex.Story852.Criterion7241Spex do
  @moduledoc """
  Story 852 — Pay invoices and tip my cleaner from the portal
  Criterion 7241 — Client saves a card on file

  Assumes the payment form's `payment[save_card]` checkbox, once
  submitted checked, is reflected back on `/portal/invoices` as
  `[data-test='card-on-file-badge']`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a client can save their card on file while paying an invoice" do
    scenario "client saves a card on file" do
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

      when_ "I pay with a new card and choose to save it", context do
        {:ok, invoices_live, _html} = live(context.portal_conn, ~p"/portal/invoices")

        invoices_live
        |> element("[data-test='invoice-#{context.invoice.id}-pay-button']")
        |> render_click()

        invoices_live
        |> form("[data-test='invoice-#{context.invoice.id}-payment-form']",
          payment: %{card_token: "pm_card_visa", save_card: "true"}
        )
        |> render_submit()

        {:ok, Map.put(context, :invoices_live, invoices_live)}
      end

      then_ "my card is on file for next time", context do
        assert has_element?(context.invoices_live, "[data-test='card-on-file-badge']")

        {:ok, context}
      end
    end
  end
end
