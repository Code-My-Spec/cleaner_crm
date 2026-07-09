defmodule CleanerCrmWeb.ScheduleLive.JobFormComponentTest do
  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures
  import CleanerCrm.SchedulingFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Notifications
  alias CleanerCrm.Scheduling
  alias CleanerCrm.Scheduling.Job
  alias CleanerCrm.Users.Scope
  alias CleanerCrmWeb.ScheduleLive.JobFormComponent

  # Hosts the component in isolation (no router route required), same
  # pattern as ClientLive.PropertyFormComponentTest. Forwards the
  # component's parent notification to the test process so assertions
  # can use `assert_receive`.
  defmodule Host do
    use CleanerCrmWeb, :live_view

    @impl true
    def mount(_params, session, socket) do
      {:ok,
       assign(socket, %{
         test_pid: session["test_pid"],
         current_scope: session["scope"],
         action: session["action"],
         job: session["job"]
       })}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <.live_component
        module={JobFormComponent}
        id="job-form"
        current_scope={@current_scope}
        action={@action}
        job={@job}
      />
      """
    end

    @impl true
    def handle_info({JobFormComponent, _} = message, socket) do
      send(socket.assigns.test_pid, message)
      {:noreply, socket}
    end
  end

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp render_host(session) do
    session = Map.put(session, "test_pid", self())
    live_isolated(build_conn(), Host, session: session)
  end

  describe "creating a job" do
    test "renders the job form with the account's properties" do
      scope = scope_fixture()
      client = client_fixture(scope, %{name: "Jamie Rivera"})
      property_fixture(scope, client, %{service_address: "12 Oak Lane"})

      {:ok, _lv, html} =
        render_host(%{"scope" => scope, "action" => :new, "job" => %Job{}})

      assert html =~ "12 Oak Lane"
      assert html =~ "job-form"
    end

    test "creates an unassigned job and navigates to its show page" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "job" => %Job{}})

      {:error, {:live_redirect, %{to: path}}} =
        lv
        |> form("[data-test='job-form']",
          job: %{
            property_id: property.id,
            date: Date.to_iso8601(Date.add(Date.utc_today(), 14)),
            start_time: "09:00",
            end_time: "11:00"
          }
        )
        |> render_submit()

      job_id = path |> String.split("/") |> List.last()
      job = Scheduling.get_job!(scope, job_id)

      assert job.property_id == property.id
      assert job.cleaner_id == nil
      assert job.start_time == ~T[09:00:00]
    end

    test "creates a job pre-assigned to a cleaner" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "job" => %Job{}})

      {:error, {:live_redirect, %{to: path}}} =
        lv
        |> form("[data-test='job-form']",
          job: %{
            property_id: property.id,
            cleaner_id: cleaner.id,
            date: Date.to_iso8601(Date.add(Date.utc_today(), 14)),
            start_time: "10:00",
            end_time: "12:00"
          }
        )
        |> render_submit()

      job_id = path |> String.split("/") |> List.last()
      job = Scheduling.get_job!(scope, job_id)

      assert job.cleaner_id == cleaner.id
    end

    test "creates a job with hourly pay for the assigned cleaner" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "job" => %Job{}})

      lv
      |> form("[data-test='job-form']", job: %{pay_type: "hourly"})
      |> render_change()

      {:error, {:live_redirect, %{to: path}}} =
        lv
        |> form("[data-test='job-form']",
          job: %{
            property_id: property.id,
            cleaner_id: cleaner.id,
            date: Date.to_iso8601(Date.add(Date.utc_today(), 14)),
            start_time: "09:00",
            end_time: "11:00",
            pay_type: "hourly",
            hourly_rate: "25.00"
          }
        )
        |> render_submit()

      job_id = path |> String.split("/") |> List.last()
      job = Scheduling.get_job!(scope, job_id)

      assert job.pay_type == :hourly
      assert job.hourly_rate_cents == 2500
      assert job.piece_rate_cents == nil
    end

    test "creates a job with piece-rate pay" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "job" => %Job{}})

      lv
      |> form("[data-test='job-form']", job: %{pay_type: "piece_rate"})
      |> render_change()

      {:error, {:live_redirect, %{to: path}}} =
        lv
        |> form("[data-test='job-form']",
          job: %{
            property_id: property.id,
            date: Date.to_iso8601(Date.add(Date.utc_today(), 14)),
            start_time: "09:00",
            end_time: "11:00",
            pay_type: "piece_rate",
            piece_rate: "80.00"
          }
        )
        |> render_submit()

      job_id = path |> String.split("/") |> List.last()
      job = Scheduling.get_job!(scope, job_id)

      assert job.pay_type == :piece_rate
      assert job.piece_rate_cents == 8000
      assert job.hourly_rate_cents == nil
    end

    test "rejects a submission missing the required date" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :new, "job" => %Job{}})

      html =
        lv
        |> form("[data-test='job-form']",
          job: %{property_id: property.id, date: "", start_time: "09:00", end_time: "11:00"}
        )
        |> render_submit()

      assert has_element?(lv, "[data-test='job-form']")
      assert html =~ "can&#39;t be blank" or html =~ "is required"
    end
  end

  describe "assigning a cleaner to an existing job" do
    test "renders the assignment form" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      job = job_fixture(scope, property)

      {:ok, _lv, html} = render_host(%{"scope" => scope, "action" => :assign, "job" => job})

      assert html =~ "assignment-form"
    end

    test "assigns the cleaner when there is no conflict" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      job =
        job_fixture(scope, property, %{
          scheduled_date: next_tuesday(),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00]
        })

      {:ok, lv, _html} = render_host(%{"scope" => scope, "action" => :assign, "job" => job})

      lv
      |> form("[data-test='assignment-form']", assignment: %{cleaner_id: cleaner.id})
      |> render_submit()

      assert_receive {JobFormComponent, {:saved, %Job{} = updated}}
      assert updated.cleaner_id == cleaner.id
    end

    test "rejects the assignment when the cleaner has a time-off block that day" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)
      friday = next_friday()

      availability_block_fixture(scope, cleaner, %{date: friday, all_day: true})

      job =
        job_fixture(scope, property, %{
          scheduled_date: friday,
          start_time: ~T[10:00:00],
          end_time: ~T[12:00:00]
        })

      {:ok, lv, _html} = render_host(%{"scope" => scope, "action" => :assign, "job" => job})

      html =
        lv
        |> form("[data-test='assignment-form']", assignment: %{cleaner_id: cleaner.id})
        |> render_submit()

      assert html =~ "conflict"
      assert html =~ "unavailable"
      refute_receive {JobFormComponent, {:saved, _}}
    end

    test "rejects the assignment when it overlaps another booking for that cleaner" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)
      booking_date = Date.add(Date.utc_today(), 14)

      job_fixture(scope, property, %{
        cleaner_id: cleaner.id,
        scheduled_date: booking_date,
        start_time: ~T[10:00:00],
        end_time: ~T[12:00:00]
      })

      second_job =
        job_fixture(scope, property, %{
          scheduled_date: booking_date,
          start_time: ~T[11:00:00],
          end_time: ~T[13:00:00]
        })

      {:ok, lv, _html} =
        render_host(%{"scope" => scope, "action" => :assign, "job" => second_job})

      html =
        lv
        |> form("[data-test='assignment-form']", assignment: %{cleaner_id: cleaner.id})
        |> render_submit()

      assert html =~ "overlap"
      refute_receive {JobFormComponent, {:saved, _}}
    end
  end

  describe "editing an existing job" do
    test "sets pay type and rate on a job that had none" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      job = job_fixture(scope, property)

      {:ok, lv, _html} = render_host(%{"scope" => scope, "action" => :edit, "job" => job})

      lv
      |> form("[data-test='job-form']", job: %{pay_type: "hourly"})
      |> render_change()

      lv
      |> form("[data-test='job-form']",
        job: %{
          date: Date.to_iso8601(job.scheduled_date),
          start_time: "09:00",
          end_time: "11:00",
          pay_type: "hourly",
          hourly_rate: "20.00"
        }
      )
      |> render_submit()

      assert_receive {JobFormComponent, {:job_updated, %Job{} = updated}}
      assert updated.pay_type == :hourly
      assert updated.hourly_rate_cents == 2000
    end

    # Story 843 (issue ca2cb170): rescheduling only via the board's
    # inline start-time input notified the assigned cleaner
    # (`ScheduleLive.Index`'s `reschedule_job` handler); saving the
    # same reschedule through the "Edit Job" dialog silently skipped
    # it. Both paths must land the same schedule-change notification.
    test "notifies the assigned cleaner when the edit dialog reschedules the job" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      job =
        job_fixture(scope, property, %{
          cleaner_id: cleaner.id,
          scheduled_date: next_tuesday(),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00]
        })

      {:ok, lv, _html} = render_host(%{"scope" => scope, "action" => :edit, "job" => job})

      lv
      |> form("[data-test='job-form']",
        job: %{
          date: Date.to_iso8601(job.scheduled_date),
          start_time: "13:00",
          end_time: "15:00"
        }
      )
      |> render_submit()

      assert_receive {JobFormComponent, {:job_updated, %Job{} = updated}}
      assert updated.start_time == ~T[13:00:00]

      assert [notification] = schedule_change_notifications(scope, job.id)
      assert notification.cleaner_id == cleaner.id
      assert notification.status == :pending
      assert notification.change_summary =~ "9:00 AM"
      assert notification.change_summary =~ "1:00 PM"
    end

    test "does not notify the cleaner when only the price changes" do
      scope = scope_fixture()
      client = client_fixture(scope)
      property = property_fixture(scope, client)
      cleaner = cleaner_fixture(scope, scope.active_account)

      job =
        job_fixture(scope, property, %{
          cleaner_id: cleaner.id,
          scheduled_date: next_tuesday(),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00]
        })

      {:ok, lv, _html} = render_host(%{"scope" => scope, "action" => :edit, "job" => job})

      lv
      |> form("[data-test='job-form']",
        job: %{
          date: Date.to_iso8601(job.scheduled_date),
          start_time: "09:00",
          end_time: "11:00",
          agreed_price: "150.00"
        }
      )
      |> render_submit()

      assert_receive {JobFormComponent, {:job_updated, %Job{} = updated}}
      assert Decimal.equal?(updated.agreed_price, Decimal.new("150.00"))
      assert schedule_change_notifications(scope, job.id) == []
    end
  end

  defp schedule_change_notifications(scope, job_id) do
    scope
    |> Notifications.list_notifications()
    |> Enum.filter(&(&1.job_id == job_id and &1.kind == :schedule_change))
  end

  defp next_tuesday do
    today = Date.utc_today()
    offset = Integer.mod(2 - Date.day_of_week(today) - 1, 7) + 1
    Date.add(today, offset + 7)
  end

  defp next_friday do
    today = Date.utc_today()
    offset = Integer.mod(5 - Date.day_of_week(today) - 1, 7) + 1
    Date.add(today, offset + 7)
  end
end
