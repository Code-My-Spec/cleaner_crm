defmodule CleanerCrmSpex.Story845.Criterion7180Spex do
  @moduledoc """
  Story 845 — Report damage, missing items, or unsafe conditions from the job
  Criterion 7180 — Submitted report cannot be altered
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a cleaner cannot edit or delete a report once it has been submitted" do
    scenario "submitted report cannot be altered" do
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

      given_ "Ana has already filed a damage report with a photo", context do
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

        {:ok, context}
      end

      when_ "Ana reloads the job screen", context do
        {:ok, job_live, _html} = live(context.conn, ~p"/app/field/jobs/#{context.job.id}")

        {:ok, Map.put(context, :job_live, job_live)}
      end

      then_ "no edit or delete affordance is offered for the report on the job screen", context do
        assert has_element?(context.job_live, "[data-test='incident-report-item']")
        refute has_element?(context.job_live, "[data-test='incident-report-edit-button']")
        refute has_element?(context.job_live, "[data-test='incident-report-delete-button']")

        {:ok, context}
      end

      then_ "no edit or delete affordance is offered for the report when the owner reviews it",
            context do
        {:ok, review_live, html} = live(context.owner_conn, ~p"/app/quality")

        assert html =~ "Living room floor lamp is cracked and will not stand upright"
        refute has_element?(review_live, "[data-test='incident-report-edit-button']")
        refute has_element?(review_live, "[data-test='incident-report-delete-button']")

        {:ok, context}
      end
    end
  end
end
