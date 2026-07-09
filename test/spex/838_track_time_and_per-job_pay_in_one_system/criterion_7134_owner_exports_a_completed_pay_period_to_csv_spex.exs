defmodule CleanerCrmSpex.Story838.Criterion7134Spex do
  @moduledoc """
  Story 838 — Track time and per-job pay in one system
  Criterion 7134 — Owner exports a completed pay period to CSV

  Clocking in and out through the UI is covered end-to-end by story
  838's own "cleaner clocks in and out of an assigned job" spec. This
  spec's subject is the payroll CSV export across multiple cleaners,
  so resolved time entries in a closed pay period are seeded directly
  via `CleanerCrmSpex.Fixtures`.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the owner exports a completed pay period's earnings to CSV" do
    scenario "owner exports a completed pay period to csv" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, scope: scope, account: account})}
      end

      given_ "three cleaners each have a resolved time entry in a closed pay period", context do
        cleaner1 =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "csv-hourly-#{System.unique_integer([:positive])}@example.com"
          })

        client1 = Fixtures.client_fixture(context.scope)

        job1 =
          Fixtures.job_fixture(context.scope, client1, %{
            cleaner_id: cleaner1.id,
            pay_type: :hourly,
            hourly_rate_cents: 2500,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, job1, %{
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 11:00:00Z]
        })

        cleaner2 =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "csv-piece-rate-#{System.unique_integer([:positive])}@example.com"
          })

        client2 = Fixtures.client_fixture(context.scope)

        job2 =
          Fixtures.job_fixture(context.scope, client2, %{
            cleaner_id: cleaner2.id,
            pay_type: :piece_rate,
            piece_rate_cents: 8000,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, job2, %{
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 12:00:00Z]
        })

        cleaner3 =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "csv-hourly-two-#{System.unique_integer([:positive])}@example.com"
          })

        client3 = Fixtures.client_fixture(context.scope)

        job3 =
          Fixtures.job_fixture(context.scope, client3, %{
            cleaner_id: cleaner3.id,
            pay_type: :hourly,
            hourly_rate_cents: 2000,
            status: :completed
          })

        Fixtures.time_entry_fixture(context.scope, job3, %{
          clocked_in_at: ~U[2024-01-08 09:00:00Z],
          clocked_out_at: ~U[2024-01-08 12:00:00Z]
        })

        {:ok, Map.merge(context, %{cleaner1: cleaner1, cleaner2: cleaner2, cleaner3: cleaner3})}
      end

      when_ "the owner exports that closed pay period to CSV", context do
        {:ok, timesheet_live, _html} = live(context.conn, ~p"/app/timesheets")

        timesheet_live
        |> element("[data-test='export-csv-button']")
        |> render_click()

        {path, _flash} = assert_redirect(timesheet_live)

        {:ok, Map.put(context, :export_path, path)}
      end

      then_ "the CSV has one row per cleaner with hours, job count, and gross pay", context do
        download_conn = get(context.conn, context.export_path)

        [content_type] = get_resp_header(download_conn, "content-type")
        body = response(download_conn, 200)
        lines = String.split(body, "\n")

        assert content_type =~ "csv"

        row1 = Enum.find(lines, &(&1 =~ context.cleaner1.email))
        row2 = Enum.find(lines, &(&1 =~ context.cleaner2.email))
        row3 = Enum.find(lines, &(&1 =~ context.cleaner3.email))

        assert row1 =~ "$50.00"
        assert row2 =~ "$80.00"
        assert row3 =~ "$60.00"

        {:ok, context}
      end
    end
  end
end
