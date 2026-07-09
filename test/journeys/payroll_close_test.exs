defmodule CleanerCrmTest.Journeys.PayrollCloseTest do
  @moduledoc """
  Journey 5 (.code_my_spec/qa/journey_plan.md): a pay period with a
  mix of hourly and piece-rate jobs, a forgotten clock-out that blocks
  export until resolved, and a CSV export that matches the on-screen
  totals once it's unblocked.

  Nulling a clock-out is done directly through `Repo` — this test's
  equivalent of the sanctioned psql step from manual QA.
  """

  use CleanerCrmTest.FeatureCase, async: false

  alias CleanerCrm.TimeTracking

  feature "a pay period closes correctly once every clock-out is resolved", %{session: session} do
    %{owner_scope: scope, owner: owner, cleaner: cleaner, password: password} =
      account_with_owner_and_cleaner()

    client = client_fixture(scope, %{name: "Journey5 QA Client"})
    property = property_fixture(scope, client, %{service_address: "5 Payroll Way"})

    today = Date.utc_today()

    hourly_job =
      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: today,
        start_time: ~T[09:00:00],
        end_time: ~T[11:00:00],
        pay_type: :hourly,
        hourly_rate_cents: 2500,
        agreed_price_cents: 8000,
        status: :completed
      })

    piece_rate_job =
      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: today,
        start_time: ~T[13:00:00],
        end_time: ~T[15:00:00],
        pay_type: :piece_rate,
        piece_rate_cents: 4500,
        agreed_price_cents: 4500,
        status: :completed
      })

    {:ok, hourly_entry} =
      TimeTracking.create_time_entry(scope, %{
        job_id: hourly_job.id,
        cleaner_id: cleaner.id,
        clocked_in_at: DateTime.new!(today, ~T[09:00:00]),
        clocked_out_at: DateTime.new!(today, ~T[11:00:00])
      })

    {:ok, _piece_entry} =
      TimeTracking.create_time_entry(scope, %{
        job_id: piece_rate_job.id,
        cleaner_id: cleaner.id,
        clocked_in_at: DateTime.new!(today, ~T[13:00:00]),
        clocked_out_at: DateTime.new!(today, ~T[15:00:00])
      })

    session = log_in(session, owner, password)

    session
    |> visit!("/timesheets")
    |> assert_has(css("body", text: "$50.00"))
    |> assert_has(css("body", text: "$45.00"))
    |> assert_has(css("body", text: "$95.00"))

    # Introduce a forgotten clock-out — the entry gets flagged and
    # export is blocked.
    {:ok, _} =
      hourly_entry
      |> Ecto.Changeset.change(clocked_out_at: nil)
      |> CleanerCrm.Repo.update()

    session
    |> visit!("/timesheets")
    |> assert_has(css("body", text: "Missing clock-out"))
    |> assert_has(css("body", text: "Resolve the unresolved time entry before exporting"))

    assert_export_disabled(session, true)

    # Resolve it via the timesheet form — pay recomputes and export
    # unblocks.
    session
    |> set_field(
      "#resolve-form-#{hourly_job.id} input[name='time_entry[clock_out_time]']",
      "11:00:00"
    )
    |> click(css("#resolve-form-#{hourly_job.id} button"))
    |> settle()
    |> assert_has(css("body", text: "$95.00"))
    |> refute_has(css("body", text: "Missing clock-out"))

    assert_export_disabled(session, false)

    # Cross-check the export against the on-screen total.
    period = TimeTracking.current_pay_period(scope)
    {:ok, csv} = TimeTracking.export_pay_period_csv(scope, period)
    refute csv =~ owner.email
    assert csv =~ cleaner.email
    assert csv =~ "$95.00"
  end

  defp assert_export_disabled(session, expected) do
    Wallaby.Browser.execute_script(
      session,
      "return document.querySelector('[data-test=\"export-csv-button\"]').disabled",
      fn disabled -> send(self(), {:export_disabled, disabled}) end
    )

    assert_receive {:export_disabled, ^expected}
  end
end
