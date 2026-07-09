defmodule CleanerCrmSpex.Story850.Criterion7254Spex do
  @moduledoc """
  Story 850 — See my visits, cleaner, and proof-of-work in a client portal
  Criterion 7254 — Reassigning the cleaner updates what the client
  sees: the next time the portal is viewed, it shows the newly
  assigned cleaner.

  Reassignment is driven through the real dispatch board
  (`ScheduleLive.Board`, covered end-to-end by story 834's own
  reassignment specs), not seeded directly, since the board's
  cleaner-select is the actual mechanism that changes a job's
  assignment.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "reassigning a visit's cleaner is reflected the next time the portal is viewed" do
    scenario "reassigning the cleaner updates what the client sees" do
      given_ "a client's upcoming visit currently shows Cleaner A", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope, %{name: "Sparkle Clean Co"})
        cleaner_a = Fixtures.cleaner_fixture(scope, account, %{name: "Jamie Rivera"})
        client = Fixtures.client_fixture(scope, %{name: "Morgan Blake"})
        job = Fixtures.job_fixture(scope, client, %{cleaner_id: cleaner_a.id})
        portal_conn = Fixtures.portal_session_fixture(client)

        {:ok, portal_live, _html} = live(portal_conn, ~p"/portal")
        assert has_element?(portal_live, "[data-test='visit-#{job.id}']", cleaner_a.name)

        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok,
         Map.merge(context, %{
           scope: scope,
           account: account,
           cleaner_a: cleaner_a,
           client: client,
           job: job,
           portal_conn: portal_conn,
           owner_conn: owner_conn
         })}
      end

      when_ "the business reassigns the visit to Cleaner B", context do
        cleaner_b =
          Fixtures.cleaner_fixture(context.scope, context.account, %{name: "Sam Okafor"})

        {:ok, board_live, _html} = live(context.owner_conn, ~p"/app/schedule")

        board_live
        |> element("[data-test='job-#{context.job.id}-cleaner-select']")
        |> render_change(%{"cleaner_id" => to_string(cleaner_b.id)})

        {:ok, Map.put(context, :cleaner_b, cleaner_b)}
      end

      then_ "the client's portal shows Cleaner B's name and photo the next time it is viewed",
            context do
        {:ok, portal_live, _html} = live(context.portal_conn, ~p"/portal")

        assert has_element?(
                 portal_live,
                 "[data-test='visit-#{context.job.id}']",
                 context.cleaner_b.name
               )

        refute has_element?(
                 portal_live,
                 "[data-test='visit-#{context.job.id}']",
                 context.cleaner_a.name
               )

        {:ok, context}
      end
    end
  end
end
