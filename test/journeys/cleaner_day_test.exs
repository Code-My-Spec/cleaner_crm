defmodule CleanerCrmTest.Journeys.CleanerDayTest do
  @moduledoc """
  Journey 2 (.code_my_spec/qa/journey_plan.md): a cleaner works an
  entire day inside `/app/field` — today's jobs in order, a full
  get-in-the-door brief, clocking in/out, working a room-by-room
  checklist, filing an incident report, and being fenced out of every
  office-only surface and every other cleaner's job.

  Client/property/template/job setup goes through context functions
  directly (not the browser) — Journey 1 already regression-tests
  that authoring path; this journey's subject is the cleaner's day,
  not how the office built the job. Only one browser actor is needed:
  the "other cleaner" whose job we must not be able to open is just a
  fixture record, never logged in anywhere.
  """

  use CleanerCrmTest.FeatureCase, async: false

  alias CleanerCrm.Quality

  feature "a cleaner's full day, plus the isolation it can't cross", %{session: session} do
    %{owner_scope: scope, cleaner: cleaner, password: password} = account_with_owner_and_cleaner()
    other_cleaner = cleaner_fixture(scope, scope.active_account)

    client = client_fixture(scope, %{name: "Journey2 QA Client"})

    property =
      property_fixture(scope, client, %{
        service_address: "12 Field Lane",
        entry_method: "Lockbox on gate",
        lockbox_code: "7788",
        pet_notes: "Two cats, keep indoors"
      })

    {:ok, _template} =
      Quality.create_checklist_template(scope, %{
        name: "Journey2 Template",
        property_id: property.id,
        items: [
          %{room: "Kitchen", task: "Wipe counters", required: true},
          %{room: "Bathroom", task: "Scrub tub", required: true}
        ]
      })

    job =
      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: Date.utc_today(),
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        pay_type: :hourly,
        hourly_rate_cents: 2500,
        # The board's own job form always requires a Price ($) —
        # required here too, since a job with no agreed price crashes
        # invoice generation on completion (see issue filed after this
        # test first caught it via job_fixture omitting the field).
        agreed_price_cents: 8000
      })

    other_job =
      job_fixture(scope, property, %{
        cleaner_id: other_cleaner.id,
        scheduled_date: Date.utc_today(),
        start_time: ~T[13:00:00],
        end_time: ~T[15:00:00]
      })

    session = log_in(session, cleaner, password)

    session
    |> visit!("/app/field")
    |> assert_has(css("body", text: "12 Field Lane"))
    |> assert_has(css("body", text: "Lockbox on gate"))
    |> assert_has(css("body", text: "7788"))
    |> assert_has(css("body", text: "Two cats, keep indoors"))
    |> refute_has(css("body", text: "13:00"))
    |> visit!("/app/field/jobs/#{job.id}")
    |> click(css("[data-test='clock-in-button']"))
    |> settle()
    |> assert_has(css("[data-test='elapsed-time']"))

    checklist = Quality.get_checklist_for_job(scope, job)

    session =
      Enum.reduce(checklist.items, session, fn item, s ->
        s |> click(css("[data-test='checklist-item-#{item.id}']")) |> settle()
      end)

    session
    |> assert_has(css("[data-test='checklist-progress']", text: "2 of 2"))
    |> set_field("#incident_type", "unsafe_condition")
    |> set_field("#incident_description", "Frayed cord near the outlet.")
    |> click(button("File Report"))
    |> settle()
    |> assert_has(css("[data-test='incident-report-item']", text: "Frayed cord near the outlet."))
    |> click(css("[data-test='clock-out-button']"))
    |> settle()
    |> click(css("[data-test='mark-complete-button']"))
    |> settle()
    |> assert_has(css("body", text: "Complete"))
    |> assert_has(css("[data-test='job-earnings']"))
    |> visit!("/app/field")
    |> assert_has(css("[data-test='pay-period-total']"))
    |> visit("/app/field/jobs/#{other_job.id}")
    |> settle()
    |> assert_has(css("body", text: "not assigned to you"))
    |> visit("/app/schedule")
    |> settle()
    |> assert_has(css("body", text: "don't have access"))
    |> visit("/app/timesheets")
    |> settle()
    |> assert_has(css("body", text: "don't have access"))
  end
end
