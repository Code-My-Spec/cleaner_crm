defmodule CleanerCrmSpex.Story850.Criterion7257Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7257 — Portal proof-of-work matches the invoice's
  evidence: the checklist and photos shown in the portal for a
  completed visit are exactly the same evidence attached to that
  visit's invoice.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the portal shows the same proof-of-work attached to the visit's invoice" do
    scenario "portal proof-of-work matches the invoice's evidence" do
      given_ "a completed visit has an invoice with attached checklist and photos as dispute evidence",
             context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})
        job = Fixtures.job_with_proof_of_work_fixture(scope, client)
        invoice = Fixtures.invoice_fixture(scope, job, %{amount: job.agreed_price})

        owner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), user)
        {:ok, invoice_live, invoice_html} = live(owner_conn, ~p"/invoices/#{invoice.id}")
        assert has_element?(invoice_live, "[data-test='proof-of-work-photo']")

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok,
         Map.merge(context, %{
           client: client,
           job: job,
           invoice: invoice,
           invoice_html: invoice_html,
           portal_conn: portal_conn
         })}
      end

      when_ "the client views that same visit in the portal", context do
        {:ok, portal_live, html} = live(context.portal_conn, ~p"/portal")

        {:ok, Map.merge(context, %{portal_live: portal_live, portal_html: html})}
      end

      then_ "the checklist and photos shown match exactly what is attached to the invoice",
            context do
        assert context.portal_html =~ "Kitchen counters wiped down"
        assert context.portal_html =~ "Bathrooms sanitized"
        assert context.invoice_html =~ "Kitchen counters wiped down"
        assert context.invoice_html =~ "Bathrooms sanitized"

        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='before-photo']"
               )

        assert has_element?(
                 context.portal_live,
                 "[data-test='visit-#{context.job.id}'] [data-test='after-photo']"
               )

        {:ok, context}
      end
    end
  end
end
