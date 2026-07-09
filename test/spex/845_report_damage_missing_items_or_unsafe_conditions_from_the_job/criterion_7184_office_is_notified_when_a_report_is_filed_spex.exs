defmodule CleanerCrmSpex.Story845.Criterion7184Spex do
  @moduledoc """
  Story 845 — Report damage, missing items, or unsafe conditions from the job
  Criterion 7184 — Office is notified when a report is filed
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the office is notified as soon as a cleaner files a report" do
    scenario "office is notified when a report is filed" do
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

      when_ "Ana files a missing-item report with a description and a photo", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        photo_upload =
          file_input(job_live, "[data-test='incident-photo-upload']", :photo, [
            %{name: "missing_vacuum.jpg", content: "photo-bytes", type: "image/jpeg"}
          ])

        render_upload(photo_upload, "missing_vacuum.jpg")

        job_live
        |> form("[data-test='incident-report-form']",
          incident: %{
            type: "missing_item",
            description: "Cordless vacuum is missing from the hall closet"
          }
        )
        |> render_submit()

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "the office sees a notification that a new report has been filed", context do
        {:ok, review_live, _html} = live(context.owner_conn, ~p"/app/quality")

        assert has_element?(review_live, "[data-test='incident-notification']")

        {:ok, Map.put(context, :review_live, review_live)}
      end

      then_ "the notification identifies the job and the reported issue", context do
        assert render(context.review_live) =~ "Cordless vacuum is missing from the hall closet"
        assert render(context.review_live) =~ context.client.name

        {:ok, context}
      end
    end
  end
end
