defmodule CleanerCrmSpex.Story845.Criterion7178Spex do
  @moduledoc """
  Story 845 — Report damage, missing items, or unsafe conditions from the job
  Criterion 7178 — Cleaner files a damage report from the job screen
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner files a damage report directly from the job screen" do
    scenario "cleaner files a damage report from the job screen" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        owner_conn = Fixtures.log_in_user(context.conn, user)

        {:ok,
         Map.merge(context, %{owner_conn: owner_conn, user: user, scope: scope, account: account})}
      end

      given_ "cleaner Ana is logged in on her assigned, in-progress job", context do
        client = Fixtures.client_fixture(context.scope)

        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{email: "ana@example.com"})

        job =
          Fixtures.job_fixture(context.scope, client, %{
            cleaner_id: cleaner.id,
            status: :in_progress
          })

        conn = Fixtures.log_in_user(build_conn(), cleaner)

        {:ok, Map.merge(context, %{client: client, cleaner: cleaner, job: job, conn: conn})}
      end

      when_ "Ana files a damage report with a description and a photo of the damage", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        photo_upload =
          file_input(job_live, "[data-test='incident-photo-upload']", :photo, [
            %{name: "broken_lamp.jpg", content: "photo-bytes", type: "image/jpeg"}
          ])

        render_upload(photo_upload, "broken_lamp.jpg")

        job_live
        |> form("[data-test='incident-report-form']",
          incident: %{
            type: "damage",
            description: "Living room floor lamp is cracked and will not stand upright"
          }
        )
        |> render_submit()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the damage report appears on the job screen as filed", context do
        assert has_element?(context.job_live, "[data-test='incident-report-item']")

        assert render(context.job_live) =~
                 "Living room floor lamp is cracked and will not stand upright"

        {:ok, context}
      end

      then_ "the owner sees the filed damage report when reviewing incidents", context do
        {:ok, _review_live, html} = live(context.owner_conn, ~p"/app/quality")

        assert html =~ "Living room floor lamp is cracked and will not stand upright"

        {:ok, context}
      end
    end
  end
end
