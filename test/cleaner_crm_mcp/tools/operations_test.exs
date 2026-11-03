defmodule CleanerCrmMcp.Tools.OperationsTest do
  use CleanerCrmTest.DataCase, async: false

  import Swoosh.TestAssertions

  alias CleanerCrm.{
    Accounts,
    Clients,
    Notifications,
    Quality,
    Reviews,
    Scheduling,
    TimeTracking,
    UsersFixtures
  }

  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.Catalog
  alias CleanerCrmMcp.Tools.Operations

  alias CleanerCrmMcp.Tools.Operations.{
    GetJobChecklist,
    GetPayRate,
    GetReminderSettings,
    GetScorecard,
    ListAuditEntries,
    ListChecklistTemplates,
    ListIncidents,
    ListNotifications,
    ListReviews,
    ListTimeEntries,
    PayrollSummary,
    ReviewSummary,
    SendJobReminder,
    SetPayRate,
    UpdateReminderSettings
  }

  defp account_scope(name) do
    owner = UsersFixtures.user_fixture()
    scope = Scope.for_user(owner)
    {:ok, account} = Accounts.create_account(scope, %{name: name})
    %{scope | active_account_id: account.id, active_account: account}
  end

  defp make_job(scope, client, cleaner, attrs \\ %{}) do
    {:ok, job} =
      Scheduling.create_job(
        scope,
        Enum.into(attrs, %{
          client_id: client.id,
          cleaner_id: cleaner.id,
          scheduled_date: Date.utc_today(),
          start_time: ~T[09:00:00],
          end_time: ~T[11:00:00],
          status: :scheduled,
          pay_type: :hourly,
          hourly_rate_cents: 2000
        })
      )

    job
  end

  setup do
    scope = account_scope("Sparkle Co")
    cleaner = UsersFixtures.user_fixture()
    {:ok, _} = Accounts.add_user_to_account(scope, cleaner.id, scope.active_account_id, :member)

    {:ok, client} =
      Clients.create_client(scope, %{
        name: "Jamie",
        email: "jamie-#{System.unique_integer([:positive])}@example.com"
      })

    job = make_job(scope, client, cleaner)

    other = account_scope("Other Co")

    {:ok, other_client} =
      Clients.create_client(other, %{name: "Other Client", email: "o@example.com"})

    other_cleaner = UsersFixtures.user_fixture()

    {:ok, _} =
      Accounts.add_user_to_account(other, other_cleaner.id, other.active_account_id, :member)

    other_job = make_job(other, other_client, other_cleaner)

    %{
      scope: scope,
      cleaner: cleaner,
      client: client,
      job: job,
      other: other,
      other_job: other_job,
      other_cleaner: other_cleaner
    }
  end

  defp entry(scope, job, cleaner, in_at, out_at) do
    {:ok, e} =
      TimeTracking.create_time_entry(scope, %{
        job_id: job.id,
        cleaner_id: cleaner.id,
        clocked_in_at: in_at,
        clocked_out_at: out_at
      })

    e
  end

  test "group lists every tool with unique names" do
    names = Enum.map(Operations.tools(), & &1.name())
    assert length(names) == length(Enum.uniq(names))
    assert "send_job_reminder" in names

    assert Enum.all?(
             Operations.tools(),
             &(&1.description() |> String.split("\n") |> hd() |> String.length() > 10)
           )
  end

  describe "time and pay" do
    test "list_time_entries filters by job and stays inside the account", ctx do
      %{
        scope: scope,
        job: job,
        cleaner: cleaner,
        other: other,
        other_job: other_job,
        other_cleaner: oc
      } = ctx

      entry(scope, job, cleaner, ~U[2026-11-02 09:00:00Z], ~U[2026-11-02 11:00:00Z])
      entry(other, other_job, oc, ~U[2026-11-02 09:00:00Z], ~U[2026-11-02 11:00:00Z])

      assert {:ok, [e]} = ListTimeEntries.call(%{}, scope)
      assert e["worked_hours"] == 2.0
      assert e["open"] == false
      assert e["job"]["job_number"] == job.job_number

      assert {:ok, [_]} = ListTimeEntries.call(%{"job_number" => job.job_number}, scope)
      assert {:ok, []} = ListTimeEntries.call(%{"from" => ~D[2026-11-03]}, scope)

      assert {:error, _} =
               ListTimeEntries.call(%{"job_number" => other_job.job_number + 999}, scope)

      assert {:error, msg} =
               ListTimeEntries.call(%{"from" => ~D[2026-11-05], "to" => ~D[2026-11-01]}, scope)

      assert msg =~ "from"
    end

    test "payroll_summary totals per cleaner and flags unresolved", ctx do
      %{scope: scope, job: job, cleaner: cleaner, client: client} = ctx
      entry(scope, job, cleaner, ~U[2026-11-02 09:00:00Z], ~U[2026-11-02 11:00:00Z])
      open_job = make_job(scope, client, cleaner)
      entry(scope, open_job, cleaner, ~U[2026-11-03 09:00:00Z], nil)

      assert {:ok, p} =
               PayrollSummary.call(%{"from" => ~D[2026-11-02], "to" => ~D[2026-11-08]}, scope)

      assert [row] = p["cleaners"]
      assert row["total_cents"] == 4000
      assert row["total"] == 40.0
      assert row["worked_hours"] == 2.0
      assert row["unresolved_jobs"] == 1
      assert p["ready_for_payroll"] == false
      assert p["total_cents"] == 4000
    end

    test "payroll_summary excludes other accounts", ctx do
      %{scope: scope, other: other, other_job: j, other_cleaner: oc} = ctx
      entry(other, j, oc, ~U[2026-11-02 09:00:00Z], ~U[2026-11-02 11:00:00Z])

      assert {:ok, %{"cleaners" => []}} =
               PayrollSummary.call(%{"from" => ~D[2026-11-02], "to" => ~D[2026-11-08]}, scope)
    end

    test "set_pay_rate and get_pay_rate round-trip", %{scope: scope, cleaner: c} do
      assert {:ok, nil} = GetPayRate.call(%{"cleaner_id" => c.id}, scope)
      assert SetPayRate.mutates?()

      assert {:ok, %{"basis" => "hourly", "rate_cents" => 2250, "rate" => 22.5}} =
               SetPayRate.call(
                 %{"cleaner_id" => c.id, "basis" => "hourly", "rate" => 22.5},
                 scope
               )

      assert {:ok, %{"rate_cents" => 2250}} = GetPayRate.call(%{"cleaner_id" => c.id}, scope)

      assert {:ok, %{"basis" => "piece_rate", "rate_cents" => 8000}} =
               SetPayRate.call(
                 %{"cleaner_id" => c.id, "basis" => "piece_rate", "rate" => 80},
                 scope
               )
    end

    test "pay rate tools reject bad input and foreign cleaners", ctx do
      %{scope: scope, cleaner: c, other_cleaner: oc} = ctx
      assert {:error, "No cleaner" <> _} = GetPayRate.call(%{"cleaner_id" => oc.id}, scope)

      assert {:error, "No cleaner" <> _} =
               SetPayRate.call(%{"cleaner_id" => oc.id, "basis" => "hourly", "rate" => 20}, scope)

      assert {:error, %Ecto.Changeset{}} =
               SetPayRate.call(%{"cleaner_id" => c.id, "basis" => "weekly", "rate" => 20}, scope)

      assert {:error, _} =
               SetPayRate.call(%{"cleaner_id" => c.id, "basis" => "hourly", "rate" => 0}, scope)
    end
  end

  describe "quality" do
    test "templates and job checklist", %{scope: scope, job: job, other: other} do
      assert {:ok, []} = ListChecklistTemplates.call(%{}, scope)

      {:ok, _} =
        Quality.create_checklist_template(scope, %{
          name: "Standard",
          items: [%{room: "Kitchen", task: "Wipe counters", required: true}]
        })

      assert {:ok, [t]} = ListChecklistTemplates.call(%{}, scope)
      assert t["name"] == "Standard"
      assert [%{"task" => "Wipe counters", "room" => "Kitchen"}] = t["items"]
      assert {:ok, []} = ListChecklistTemplates.call(%{}, other)

      assert {:ok, nil} = GetJobChecklist.call(%{"job_number" => job.job_number}, scope)

      {:ok, _} =
        Quality.create_checklist(scope, job, [
          %{task: "Mop", required: true},
          %{task: "Dust", required: false}
        ])

      assert {:ok, c} = GetJobChecklist.call(%{"job_number" => job.job_number}, scope)
      assert c["total"] == 2
      assert c["checked"] == 0
      assert c["completed"] == false
      assert length(c["items"]) == 2

      assert {:error, "No job" <> _} = GetJobChecklist.call(%{"job_number" => 99_999}, scope)
    end

    test "incidents and scorecard", ctx do
      %{scope: scope, job: job, cleaner: cleaner, other: other} = ctx
      cleaner_scope = %{scope | user: cleaner}

      {:ok, _} =
        Quality.file_incident_report(cleaner_scope, job, %{
          type: "unsafe_condition",
          description: "Wet floor"
        })

      assert {:ok, [i]} = ListIncidents.call(%{}, scope)
      assert i["type"] == "unsafe_condition"
      assert i["job"]["job_number"] == job.job_number
      assert i["cleaner"]["id"] == cleaner.id
      assert {:ok, [_]} = ListIncidents.call(%{"cleaner_id" => cleaner.id}, scope)
      assert {:ok, []} = ListIncidents.call(%{"cleaner_id" => cleaner.id + 1000}, scope)
      assert {:ok, []} = ListIncidents.call(%{"from" => Date.add(Date.utc_today(), 1)}, scope)
      assert {:ok, []} = ListIncidents.call(%{}, other)

      assert {:ok, %{"average" => nil, "trend" => "flat", "count" => 0}} =
               GetScorecard.call(%{"cleaner_id" => cleaner.id}, scope)

      assert {:error, _} = GetScorecard.call(%{"cleaner_id" => cleaner.id}, other)
    end
  end

  describe "reviews" do
    test "list_reviews and review_summary", ctx do
      %{scope: scope, client: client, cleaner: cleaner, other: other} = ctx

      for {rating, text} <- [{5, "Great"}, {4, "Good"}, {2, "Missed spots"}] do
        review_job = make_job(scope, client, cleaner)

        {:ok, _} =
          Reviews.create_review(scope, %{
            job_id: review_job.id,
            client_id: client.id,
            cleaner_id: cleaner.id,
            rating: rating,
            token: "tok-#{System.unique_integer([:positive])}",
            text: text,
            status: if(rating > 3, do: :published, else: :private),
            submitted_at: DateTime.utc_now()
          })
      end

      assert {:ok, all} = ListReviews.call(%{}, scope)
      assert length(all) == 3
      assert {:ok, [low]} = ListReviews.call(%{"max_rating" => 3}, scope)
      assert low["text"] == "Missed spots"
      assert low["status"] == "private"
      assert {:ok, [_, _]} = ListReviews.call(%{"min_rating" => 4}, scope)
      assert {:ok, []} = ListReviews.call(%{"to" => ~D[2020-01-01]}, scope)
      assert {:ok, []} = ListReviews.call(%{}, other)

      assert {:ok, s} = ReviewSummary.call(%{}, scope)
      assert s["count"] == 3
      assert_in_delta s["average"], 3.67, 0.01
      assert s["distribution"]["5"] == 1
      assert [%{"rating" => 2}] = s["low_ratings"]

      assert {:ok, %{"count" => 0, "average" => nil}} = ReviewSummary.call(%{}, other)
    end
  end

  describe "notifications" do
    test "reminder settings", %{scope: scope, other: other} do
      assert {:ok, %{"lead_time_hours" => 24, "enabled" => false}} =
               GetReminderSettings.call(%{}, scope)

      assert UpdateReminderSettings.mutates?()

      assert {:ok, %{"lead_time_hours" => 48, "enabled" => true}} =
               UpdateReminderSettings.call(%{"lead_time_hours" => 48}, scope)

      assert {:ok, %{"lead_time_hours" => 48, "enabled" => true}} =
               GetReminderSettings.call(%{}, scope)

      assert {:ok, %{"lead_time_hours" => 24}} = GetReminderSettings.call(%{}, other)

      assert {:error, %Ecto.Changeset{}} =
               UpdateReminderSettings.call(%{"lead_time_hours" => 0}, scope)
    end

    test "send_job_reminder emails the client and logs it; list_notifications shows it", ctx do
      %{scope: scope, job: job, client: client, other: other} = ctx
      assert SendJobReminder.mutates?()
      assert SendJobReminder.description() =~ "customer"

      assert {:ok, n} = SendJobReminder.call(%{"job_number" => job.job_number}, scope)
      assert n["kind"] == "reminder"
      assert n["channel"] == "email"
      assert n["status"] == "sent"
      assert n["client"]["name"] == "Jamie"
      assert_email_sent(to: client.email)

      assert {:ok, [listed]} = ListNotifications.call(%{}, scope)
      assert listed["id"] == n["id"]

      assert {:ok, [_]} =
               ListNotifications.call(
                 %{"job_number" => job.job_number, "kind" => "reminder"},
                 scope
               )

      assert {:ok, []} = ListNotifications.call(%{"kind" => "schedule_change"}, scope)
      assert {:error, _} = ListNotifications.call(%{"kind" => "bogus"}, scope)
      assert {:ok, []} = ListNotifications.call(%{}, other)
    end

    test "send_job_reminder cannot reach a job in another account", ctx do
      %{scope: scope, other_job: other_job} = ctx

      # same job_number can exist in both accounts: it must resolve within the caller's account only
      assert {:error, "job not found"} = Notifications.send_job_reminder(scope, other_job)
      assert_no_email_sent()
    end
  end

  describe "audit" do
    test "lists entries by job number and stays in the account", ctx do
      %{scope: scope, job: job, other: other} = ctx
      assert {:ok, entries} = ListAuditEntries.call(%{"job_number" => job.job_number}, scope)
      assert entries != []
      assert Enum.all?(entries, &(&1["subject_id"] == job.id))

      assert {:ok, [_]} =
               ListAuditEntries.call(%{"job_number" => job.job_number, "limit" => 1}, scope)

      assert {:ok, by_type} = ListAuditEntries.call(%{"subject_type" => "Job"}, scope)
      assert Enum.all?(by_type, &(&1["subject_type"] == "Job"))
      assert {:ok, []} = ListAuditEntries.call(%{"subject_id" => job.id}, other)
      assert {:ok, []} = ListAuditEntries.call(%{"to" => ~D[2020-01-01]}, scope)
    end
  end

  describe "through the catalog" do
    test "coerces raw script args" do
      assert {:ok, %{"job_number" => 1001, "from" => ~D[2026-11-02]}} =
               Catalog.coerce(ListTimeEntries, %{"job_number" => "1001", "from" => "2026-11-02"})

      assert {:error, msg} = Catalog.coerce(SetPayRate, %{"cleaner_id" => 1})
      assert msg =~ "basis"
      assert {:error, msg} = Catalog.coerce(GetPayRate, %{"cleaner_id" => 1, "oops" => 1})
      assert msg =~ "unknown argument"
    end
  end
end
