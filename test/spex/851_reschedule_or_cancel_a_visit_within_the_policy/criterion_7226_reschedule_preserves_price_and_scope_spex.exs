defmodule CleanerCrmSpex.Story851.Criterion7226Spex do
  @moduledoc """
  Story 851 — Reschedule or cancel a visit within the policy
  Criterion 7226 — Reschedule preserves price and scope

  "Scope" here is the visit's agreed price and its assigned cleaner —
  the two things a reschedule must leave untouched. Assumes
  `PortalLive.Visit` renders the agreed price
  (`[data-test='visit-price']`) and the assigned cleaner's name
  (`[data-test='visit-cleaner-name']`).
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "rescheduling a visit changes only its date and time" do
    scenario "reschedule preserves price and scope" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)

        {:ok, Map.merge(context, %{user: user, scope: scope, account: account})}
      end

      given_ "I have an upcoming visit with an assigned cleaner and an agreed price", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{name: "Jamie Rivera"})

        client = Fixtures.client_fixture(context.scope)

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            scheduled_date: Date.add(Date.utc_today(), 7),
            start_time: ~T[10:00:00],
            end_time: ~T[12:00:00],
            agreed_price: Decimal.new("150.00")
          })

        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok,
         Map.merge(context, %{
           cleaner: cleaner,
           client: client,
           job: job,
           portal_conn: portal_conn
         })}
      end

      when_ "I reschedule the visit to a new date and time", context do
        {:ok, visit_live, _html} =
          live(context.portal_conn, ~p"/portal/visits/#{context.job.id}")

        visit_live
        |> form("[data-test='reschedule-form']",
          visit: %{date: Date.add(Date.utc_today(), 10), start_time: "14:00"}
        )
        |> render_submit()

        {:ok, Map.put(context, :visit_live, visit_live)}
      end

      then_ "the agreed price and assigned cleaner are unchanged", context do
        html = render(context.visit_live)

        assert has_element?(context.visit_live, "[data-test='visit-price']", "$150.00")
        assert html =~ "Jamie Rivera"

        {:ok, context}
      end
    end
  end
end
